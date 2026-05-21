import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPermissionDeniedException implements Exception {}
class LocationPermissionPermanentlyDeniedException implements Exception {}
class NearbyPlacesFetchException implements Exception {
  final String message;
  NearbyPlacesFetchException(this.message);
  @override
  String toString() => message;
}

class TourService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _placesKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  Stream<List<Map<String, dynamic>>> getPopularTours() {
    return _db
        .collection('guide_tours')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> tours = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        String? imageUrl = data['imageUrl'] as String?;

        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = await _fetchCityImage(data['city'] ?? '');
        }

        tours.add({
          'id': doc.id,
          ...data,
          'imageUrl': imageUrl,
        });
      }
      return tours;
    });
  }

  Future<String?> _fetchCityImage(String city) async {
    if (city.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(city)}'
            '&key=$_placesKey',
      )).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final photos = results[0]['photos'] as List?;
      if (photos == null || photos.isEmpty) return null;
      final ref = photos[0]['photo_reference'] as String?;
      if (ref == null) return null;

      return 'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=600&photoreference=$ref&key=$_placesKey';
    } catch (_) {
      return null;
    }
  }

  /// GPS + Google Places (rota kaydetmede çalışan textsearch API'si).
  Future<List<Map<String, dynamic>>> getNearbyPlaces() async {
    debugPrint('📍 [Nearby] Starting…');

    if (_placesKey.isEmpty) {
      throw NearbyPlacesFetchException(
        'GOOGLE_PLACES_API_KEY is missing from .env',
      );
    }

    final position = await _getLocation();
    debugPrint(
      '📍 [Nearby] GPS ${position.latitude}, ${position.longitude}',
    );

    final errors = <String>[];

    for (final label in ['textsearch', 'nearbysearch']) {
      try {
        final places = label == 'textsearch'
            ? await _fetchNearbyTextSearch(
                lat: position.latitude,
                lng: position.longitude,
              )
            : await _fetchNearbyLegacySearch(
                lat: position.latitude,
                lng: position.longitude,
              );

        if (places.isNotEmpty) {
          debugPrint('📍 [Nearby] OK via $label (${places.length} places)');
          return places.take(4).toList();
        }
        errors.add('$label: no results');
      } on NearbyPlacesFetchException catch (e) {
        errors.add('$label: ${e.message}');
        debugPrint('📍 [Nearby] $label failed: ${e.message}');
      } catch (e) {
        errors.add('$label: $e');
        debugPrint('📍 [Nearby] $label error: $e');
      }
    }

    throw NearbyPlacesFetchException(
      errors.isEmpty
          ? 'No nearby places found.'
          : errors.join(' | '),
    );
  }

  Future<Position> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    // Önce hızlı son bilinen konum (Samsung'da GPS timeout'unu önler)
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      debugPrint('📍 [Nearby] Using last known position');
      return last;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (e) {
      throw NearbyPlacesFetchException(
        'GPS timeout. Enable location and try again outdoors. ($e)',
      );
    }
  }

  /// Rota görsellerinde çalışan endpoint — konum + yarıçap ile arama.
  Future<List<Map<String, dynamic>>> _fetchNearbyTextSearch({
    required double lat,
    required double lng,
  }) async {
    final res = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
      '?query=${Uri.encodeComponent('tourist attractions')}'
      '&location=$lat,$lng'
      '&radius=8000'
      '&key=$_placesKey',
    )).timeout(const Duration(seconds: 15));

    return _parsePlacesResponse(res);
  }

  Future<List<Map<String, dynamic>>> _fetchNearbyLegacySearch({
    required double lat,
    required double lng,
  }) async {
    final res = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=5000'
      '&type=tourist_attraction'
      '&key=$_placesKey',
    )).timeout(const Duration(seconds: 15));

    return _parsePlacesResponse(res);
  }

  List<Map<String, dynamic>> _parsePlacesResponse(http.Response res) {
    if (res.statusCode != 200) {
      throw NearbyPlacesFetchException('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      if (status == 'ZERO_RESULTS') return [];
      final detail = data['error_message'] as String? ?? '';
      throw NearbyPlacesFetchException('$status $detail'.trim());
    }

    final results = data['results'] as List? ?? [];
    final places = <Map<String, dynamic>>[];

    for (final raw in results.take(8)) {
      final place = raw as Map<String, dynamic>;
      final photos = place['photos'] as List?;
      final photoRef = photos != null && photos.isNotEmpty
          ? photos[0]['photo_reference'] as String?
          : null;
      final imageUrl = photoRef != null
          ? 'https://maps.googleapis.com/maps/api/place/photo'
              '?maxwidth=600&photoreference=$photoRef&key=$_placesKey'
          : '';

      places.add({
        'name': (place['name'] as String? ?? '').split(',').first.trim(),
        'image': imageUrl,
        'rating': (place['rating'] as num?)?.toDouble() ?? 0.0,
        'address':
            place['vicinity'] ?? place['formatted_address'] ?? '',
        'placeId': place['place_id'] ?? '',
      });
    }

    return places;
  }

  Future<Map<String, dynamic>?> _fetchPlaceDetails(String placeName) async {
    try {
      final searchRes = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?query=${Uri.encodeComponent(placeName)}'
              '&key=$_placesKey',
        ),
      ).timeout(const Duration(seconds: 10));

      if (searchRes.statusCode != 200) return null;

      final list = _parsePlacesResponse(searchRes);
      return list.isEmpty ? null : list.first;
    } catch (_) {
      return null;
    }
  }
}
