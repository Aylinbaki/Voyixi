import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../trip_planner/models/trip_plan_model.dart';
import '../models/trip_result_model.dart';

class GeminiService {
  
  String get _geminiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _placesKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static const _geminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Ana metod: Gemini ile plan üret → Places API ile fotoğraf/koordinat ekle
  Future<TripResult> generateTripPlan(TripPlanModel input) async {
    try{
    print('🚀 Gemini çağrısı başlıyor...');
    print('📍 Şehir: ${input.city}, Gün: ${input.days}');
    print('🔑 Gemini key: $_geminiKey');  // key geliyor mu?
    
    final rawJson = await _callGemini(input);
    print('✅ Gemini yanıtı: $rawJson');
    
    final dayPlans = _parseGeminiResponse(rawJson);
    print('📅 Parse edildi: ${dayPlans.length} gün');
    
    final enriched = await _enrichWithPlaces(dayPlans, input.city);
    print('📸 Places tamamlandı');
    
    return TripResult(
      city: input.city,
      days: input.days,
      budget: input.budget,
      dayPlans: enriched,
    );
    }catch(e,stack){
    print('❌ HATA: $e');
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
         // 'responseMimeType': 'application/json',
        },
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Gemini API hatası: ${res.statusCode}\n${res.body}');
    }

    final data = jsonDecode(res.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  String _buildPrompt(TripPlanModel input) {
    return '''
Sen bir profesyonel seyahat rehberisin. Aşağıdaki bilgilere göre ${input.days} günlük ${input.city} seyahat planı oluştur.

Bütçe: ${input.budget}
Tercihler: ${input.preferences.join(', ')}
Şehir: ${input.city}

KURALLAR:
- Her güne 2-4 mekan ekle. Mekanlar arası mantıklı coğrafi sıralama yap.
- Öğle ve akşam yemekleri için restoran/kafe öner.
- Kalabalık tahmini: sabah erken = Sakin, öğle = Yoğun, öğleden sonra = Orta, akşam = Çok Yoğun.
- Bütçeye uygun mekanlar seç (ekonomik=ücretsiz/ucuz, orta=ücretli, lüks=premium).
- timeSlot formatı: "HH:mm - HH:mm"
- crowdLevel: "Sakin" | "Orta" | "Yoğun" | "Çok Yoğun"
- Sıralamayı ise birbirine mesafelerine göre yap.

SADECE şu JSON formatında yanıt ver, başka hiçbir şey yazma:
Cevabı sadece saf JSON formatında ver, markdown (```json) kullanma.
{
  "days": [
    {
      "day": 1,
      "places": [
        {
          "name": "Mekan Adı",
          "description": "Kısa açıklama (max 80 karakter)",
          "timeSlot": "09:00 - 11:00",
          "duration": "2 saat",
          "crowdLevel": "Orta",
          "lat": 41.0082,
          "lng": 28.9784
        }
      ]
    }
  ]
}
''';
  }

  List<DayPlan> _parseGeminiResponse(String raw) {
    try {
      // Bazen Gemini ```json ``` bloğu içinde döndürür
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      final days = data['days'] as List;
      return days.map((d) => DayPlan.fromJson(d as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Gemini yanıtı parse edilemedi: $e\nRaw: $raw');
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

  Future<Map<String, dynamic>?> _fetchPlaceDetails(
      
   
      String name, String city) async {
          print('📸 Places isteği: $name'); 
    final searchRes = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent('$name $city')}'
        '&key=$_placesKey',
      ),
    );
      
  print('📸 Places yanıtı: ${searchRes.statusCode} - ${searchRes.body.substring(0, 200)}');
    if (searchRes.statusCode != 200) return null;
    final searchData = jsonDecode(searchRes.body);
    final results = searchData['results'] as List?;
    if (results == null || results.isEmpty) return null;

    final first = results[0] as Map<String, dynamic>;
    final placeId = first['place_id'] as String?;
    final loc = first['geometry']?['location'];

    // Fotoğraf referansı varsa URL oluştur
    String? photoUrl;
    final photos = first['photos'] as List?;
    if (photos != null && photos.isNotEmpty) {
      final ref = photos[0]['photo_reference'] as String?;
      if (ref != null) {
        photoUrl = 'https://maps.googleapis.com/maps/api/place/photo'
            '?maxwidth=600&photoreference=$ref&key=$_placesKey';
      }
    }

    return {
      'placeId': placeId,
      'photoUrl': photoUrl,
      'lat': (loc?['lat'] as num?)?.toDouble(),
      'lng': (loc?['lng'] as num?)?.toDouble(),
    };
  }
  Future<PlaceItem> getAlternativePlace({
    required String city,
    required String timeSlot,
    required String budget,
    required List<String> excludeNames,
  }) async {
    final prompt = '''
${city} şehrinde ${timeSlot} saatleri arasına uygun TEK BİR mekan öner.
Bütçe: $budget
Hariç tut: ${excludeNames.join(', ')}

SADECE şu JSON formatında yanıt ver:
{
  "name": "Mekan Adı",
  "description": "Kısa açıklama",
  "timeSlot": "$timeSlot",
  "duration": "X saat",
  "crowdLevel": "Orta",
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