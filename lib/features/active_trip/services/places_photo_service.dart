import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Eksik mekan fotoğraflarını Google Places API ile tamamlar.
class PlacesPhotoService {
  String get _key => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  Future<String?> fetchPhotoUrl({
    required String name,
    required String city,
    String? placeId,
  }) async {
    if (_key.isEmpty) return null;

    try {
      if (placeId != null && placeId.isNotEmpty) {
        final fromId = await _photoFromPlaceId(placeId);
        if (fromId != null) return fromId;
      }
      return _photoFromTextSearch('$name $city');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _photoFromPlaceId(String placeId) async {
    final res = await http
        .get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=photos'
          '&key=$_key',
        ))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return null;
    final photos =
        (jsonDecode(res.body) as Map)['result']?['photos'] as List?;
    return _buildPhotoUrl(photos);
  }

  Future<String?> _photoFromTextSearch(String query) async {
    final res = await http
        .get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&key=$_key',
        ))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return null;
    final results = (jsonDecode(res.body) as Map)['results'] as List?;
    if (results == null || results.isEmpty) return null;
    final photos = (results.first as Map)['photos'] as List?;
    return _buildPhotoUrl(photos);
  }

  String? _buildPhotoUrl(List? photos) {
    if (photos == null || photos.isEmpty) return null;
    final ref = (photos.first as Map)['photo_reference'] as String?;
    if (ref == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400&photoreference=$ref&key=$_key';
  }
}
