import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Neden özel exception sınıfları?
// home_screen'de hata tipine göre farklı mesaj göstermek istiyoruz.
class LocationPermissionDeniedException implements Exception {}
class LocationPermissionPermanentlyDeniedException implements Exception {}
class NearbyPlacesFetchException implements Exception {
  final String message;
  NearbyPlacesFetchException(this.message);
}

class TourService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Popüler turlar
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

        // imageUrl null ise city'ye göre Places API'den çek
        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = await _fetchCityImage(data['city'] ?? '');
        }

        tours.add({
          'id': doc.id,
          ...data,
          'imageUrl': imageUrl, // null olsa bile override et
        });
      }
      return tours;
    });
  }
  // imageUrl null olabilir — city adıyla Places API'den görsel çekiyoruz.
  // ── Places API ile şehir görseli ────────────────────────────────────
  Future<String?> _fetchCityImage(String city) async {
    if (city.isEmpty) return null;
    try {
      final key = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      final res = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(city)}'
            '&key=$key',
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
          '?maxwidth=600&photoreference=$ref&key=$key';
    } catch (_) {
      return null;
    }
  }

  // ── Civarı Keşfet: GPS → Gemini → Places zinciri ────────────────────
  // Hata durumunda fallback değil exception fırlatıyoruz.
  // home_screen bu exception'ı yakalayıp duruma özel mesaj gösterir.
  Future<List<Map<String, dynamic>>> getNearbyPlaces() async {
    // 1. Konum al — izin yoksa exception fırlat
    final position = await _getLocation();

    // 2. Gemini'dan 4 yer önerisi al
    final suggestions = await _askGeminiForPlaces(
      lat: position.latitude,
      lng: position.longitude,
    );

    if (suggestions.isEmpty) {
      throw NearbyPlacesFetchException('Gemini yer önerisi döndürmedi.');
    }

    // 3. Her yer için Places API'den detay çek
    final places = await Future.wait(
      suggestions.map((name) => _fetchPlaceDetails(name)),
    );

    final validPlaces = places.whereType<Map<String, dynamic>>().toList();

    if (validPlaces.isEmpty) {
      throw NearbyPlacesFetchException('Yerler için detay alınamadı.');
    }

    return validPlaces;
  }

  // ── 1. Konum al ──────────────────────────────────────────────────────
  Future<Position> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,  // medium → low
        timeLimit: const Duration(seconds: 30), // 10 → 30 saniye
      );
    } catch (e) {
      // Timeout'ta last known location'ı dene
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw NearbyPlacesFetchException('Konum alınamadı: $e');
    }
  }

  // ── 2. Gemini'dan yer önerileri ──────────────────────────────────────
  Future<List<String>> _askGeminiForPlaces({
    required double lat,
    required double lng,
  }) async {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-04-17:generateContent';

    final prompt = '''
Sen bir seyahat asistanısın.
Koordinatlar: enlem $lat, boylam $lng

Bu koordinatlara yakın, turistler için ilgi çekici 4 yer öner.
Sadece aşağıdaki JSON formatında yanıt ver, başka hiçbir şey yazma:
{"places": ["Yer Adı 1", "Yer Adı 2", "Yer Adı 3", "Yer Adı 4"]}

Yer isimlerini Google Maps'te aranabilecek şekilde yaz (örn: "Topkapı Sarayı, İstanbul").
''';

    final res = await http.post(
      Uri.parse('$url?key=$key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 200,
        },
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw NearbyPlacesFetchException('Gemini API hatası: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final text =
    data['candidates'][0]['content']['parts'][0]['text'] as String;

    final cleaned =
    text.replaceAll('```json', '').replaceAll('```', '').trim();
    final parsed = jsonDecode(cleaned);
    final placesList = parsed['places'] as List?;
    if (placesList == null) return [];

    return placesList.map((e) => e.toString()).toList();
  }

  // ── 3. Places API'den tek yer detayı ────────────────────────────────
  Future<Map<String, dynamic>?> _fetchPlaceDetails(String placeName) async {
    try {
      final key = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

      final searchRes = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?query=${Uri.encodeComponent(placeName)}'
              '&key=$key',
        ),
      ).timeout(const Duration(seconds: 10));

      if (searchRes.statusCode != 200) return null;

      final searchData = jsonDecode(searchRes.body);
      final results = searchData['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final place = results[0];
      final photos = place['photos'] as List?;
      final photoRef = photos != null && photos.isNotEmpty
          ? photos[0]['photo_reference']
          : null;

      final imageUrl = photoRef != null
          ? 'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=600&photoreference=$photoRef&key=$key'
          : null;

      final shortName =
      (place['name'] as String? ?? placeName).split(',').first.trim();

      return {
        'name': shortName,
        'image': imageUrl ?? '',
        'rating': (place['rating'] as num?)?.toDouble() ?? 0.0,
        'address': place['formatted_address'] ?? '',
        'placeId': place['place_id'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }
}