import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../trip_planner/trip_plan_model.dart';
import 'trip_result_model.dart';

class GeminiService {

  String get _geminiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _placesKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Main method: Generate plan with Gemini → Enrich with Google Places API
  Future<TripResult> generateTripPlan(TripPlanModel input) async {
    try {
      print('🚀 Gemini call starting...');
      print('📍 City: ${input.city}, Days: ${input.days}');
      print('🔑 Gemini key: ${_geminiKey.isEmpty ? "(empty)" : "(set)"}');

      final rawJson = await _callGemini(input);
      print('✅ Gemini response: $rawJson');

      final parsed = _parseGeminiResponse(rawJson);
      final dayPlans = parsed['days'] as List<DayPlan>;
      final totalKm = parsed['totalKm'] as double;
      final country = parsed['country'] as String;
      print('📅 Parsed: ${dayPlans.length} days');

      final enriched = await _enrichWithPlaces(dayPlans, input.city);
      print('📸 Places enrichment completed');

      return TripResult(
        city: input.city,
        days: input.days,
        budget: input.budget,
        dayPlans: enriched,
        totalDistanceKm: totalKm,
        country: country,
      );
    } catch (e, stack) {
      print('❌ ERROR: $e');
      print('📚 Stack: $stack');
      rethrow;
    }
  }

  Future<String> _callGemini(TripPlanModel input) async {
    final prompt = _buildPrompt(input);

    final res = await http.post(
      Uri.parse('$_geminiUrl?key=$_geminiKey'),
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
          'temperature': 0.7,
          'responseMimeType': 'application/json', // JSON zorunluluğunu aktif etmek iyi olabilir
        },
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Gemini API Error: ${res.statusCode}\n${res.body}');
    }

    final data = jsonDecode(res.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  // ── 1. ÇEVİRİ: Gemini System Promptu İngilizceye Çevrildi
  String _buildPrompt(TripPlanModel input) {
    return '''
You are a professional travel guide. Create a ${input.days}-day travel itinerary for ${input.city} based on the following details.

Budget: ${input.budget}
Preferences: ${input.preferences.join(', ')}
City: ${input.city}

RULES:
- Include 2-4 places for each day. Arrange them in a logical geographical order.
- Recommend restaurants/cafes for lunch and dinner.
- Crowd prediction options: early morning = "Calm", noon = "Busy", afternoon = "Moderate", evening = "Very Busy".
- Choose places appropriate for the budget (economic = free/cheap, medium = paid/moderate, luxury = premium).
- timeSlot format must be: "HH:mm - HH:mm"
- Make an estimate based on the time you set the location. crowdLevel strictly must be one of: "Calm" | "Moderate" | "Busy" | "Very Busy"
- Sort the places based on their physical distance to one another to minimize travel time.
- total_distance_km: Calculate the total estimated distance between all places across all days in kilometers and add it to the JSON.

Respond ONLY in the following JSON format, do not include any other text or explanations:
Do not use markdown formatting (such as ```json). Provide pure raw JSON.
{
  "total_distance_km": 8.5,
  "country": "Turkey",
  "days": [
    {
      "day": 1,
      "places": [
        {
          "name": "Place Name",
          "description": "Short description (max 80 characters)",
          "timeSlot": "09:00 - 11:00",
          "duration": "2 h 30m",
          "crowdLevel": "Moderate",
          "lat": 41.0082,
          "lng": 28.9784
        }
      ]
    }
  ]
}
''';
  }

  Map<String, dynamic> _parseGeminiResponse(String raw) {
    try {
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      final days = (data['days'] as List)
        .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
        .toList();

      final totalKm = (data['total_distance_km'] as num?)?.toDouble() ?? 0.0;
      final country = (data['country'] as String?) ?? '';

      return {'days': days, 'totalKm': totalKm, 'country': country};
    } catch (e) {
      throw Exception('Failed to parse Gemini response: $e\nRaw: $raw');
    }
  }

  Future<List<DayPlan>> _enrichWithPlaces(
      List<DayPlan> days, String city) async {
    for (final day in days) {
      for (int i = 0; i < day.places.length; i++) {
        final place = day.places[i];
        try {
          final details = await _fetchPlaceDetails(place.name, city);
          if (details != null) {
            day.places[i] = place.copyWith(
              photoUrl: details['photoUrl'],
              placeId: details['placeId'],
              lat: details['lat'] ?? place.lat,
              lng: details['lng'] ?? place.lng,
            );
          }
        } catch (_) { }
      }
    }
    return days;
  }

  Future<Map<String, dynamic>?> _fetchPlaceDetails(String name, String city) async {
    print('📸 Places Request: $name');
    final searchRes = await http.get(
      Uri.parse(
              'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent('$name $city')}'
            '&key=$_placesKey',
      ),
    );

    print('📸 Places Response: ${searchRes.statusCode}');
    if (searchRes.statusCode != 200) return null;
    final searchData = jsonDecode(searchRes.body);
    final results = searchData['results'] as List?;
    if (results == null || results.isEmpty) return null;

    final first = results[0] as Map<String, dynamic>;
    final placeId = first['place_id'] as String?;
    final loc = first['geometry']?['location'];

    String? photoUrl;
    final photos = first['photos'] as List?;
    if (photos != null && photos.isNotEmpty) {
  final ref = photos[0]['photo_reference'] as String?;
  if (ref != null) {
    photoUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=200&photoreference=$ref&key=$_placesKey';
  }
}

    return {
      'placeId': placeId,
      'photoUrl': photoUrl,
      'lat': (loc?['lat'] as num?)?.toDouble(),
      'lng': (loc?['lng'] as num?)?.toDouble(),
    };
  }

  // ── 2. ÇEVİRİ: Alternatif Mekan İstemi (Alternative Place Prompt) İngilizceye Çevrildi
  Future<PlaceItem> getAlternativePlace({
    required String city,
    required String timeSlot,
    required String budget,
    required List<String> excludeNames,
  }) async {
    final prompt = '''
Recommend a SINGLE place suitable for the time slot ${timeSlot} in the city of ${city}.
Budget: $budget
Exclude the following places: ${excludeNames.join(', ')}

Respond ONLY in the following JSON format:
{
  "name": "Place Name",
  "description": "Short description",
  "timeSlot": "$timeSlot",
  "duration": "X hours",
  "crowdLevel": "Moderate",
  "lat": 0.0,
  "lng": 0.0
}
''';
    final res = await http.post(
      Uri.parse('$_geminiUrl?key=$_geminiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'parts': [{'text': prompt}]}
        ],
        'generationConfig': {
          'temperature': 0.9,
          'responseMimeType': 'application/json',
        },
      }),
    );

    final data = jsonDecode(res.body);
    final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
    final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final placeJson = jsonDecode(cleaned) as Map<String, dynamic>;
    final place = PlaceItem.fromJson(placeJson);
    try {
      final details = await _fetchPlaceDetails(place.name, city);
      if (details != null) {
        return place.copyWith(
          photoUrl: details['photoUrl'],
          placeId: details['placeId'],
          lat: details['lat'] ?? place.lat,
          lng: details['lng'] ?? place.lng,
        );
      }
    } catch (_) {}
    return place;
  }
}