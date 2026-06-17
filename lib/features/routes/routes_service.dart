import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../trip_result/trip_result_model.dart';
import 'routes_model.dart';

class RoutesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _tripsRef =>
      _db.collection('users').doc(_uid).collection('saved_trips');

Future<String> saveTrip({
  required TripResult result,
  required String title,
  DateTime? tripDate,
  DateTime? startDate,
}) async {
  if (_uid == null) throw Exception('User is not logged in');

  final now = DateTime.now();
  final dynamicTitle = "$title"; 
  final summary = await _generateSummary(result);
  final imageUrl = await _fetchCityImage(result.city);
  final dayPlansMap = result.dayPlans.map((day) => {
    'day': day.dayNumber,
    'places': day.places.map((p) => {
      'name': p.name,
      'description': p.description,
      'timeSlot': p.timeSlot,
      'duration': p.duration,
      'crowdLevel': p.crowdLevel,
      'lat': p.lat,
      'lng': p.lng,
      'photoUrl': p.photoUrl, 
      'placeId': p.placeId,  
    }).toList(),
  }).toList();
  
  final resolvedStart = startDate ?? tripDate;
  final resolvedEnd = resolvedStart != null
      ? resolvedStart.add(Duration(days: result.days - 1))
      : null;

  final docRef = _tripsRef.doc();
  final trip = SavedTrip(
    id: docRef.id,
    title: dynamicTitle, 
    city: result.city,
    days: result.days,
    budget: result.budget,
    preferences: [], 
    summary: summary,
    imageUrl: imageUrl,
    tripDate: tripDate,
    startDate: resolvedStart,
    endDate: resolvedEnd,
    completionRate: 0.0,
    dayPlans: dayPlansMap,
    createdAt: DateTime.now(),
  );

  await docRef.set(trip.toMap());
  return docRef.id;
}

  Stream<List<SavedTrip>> getTrips() {
    if (_uid == null) return Stream.value([]);
    return _tripsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SavedTrip.fromMap(doc.data()))
            .toList());
  }

  //En yakın aktif/yaklaşan plan
  Stream<SavedTrip?> getUpcomingTrip() {
    if (_uid == null) return Stream.value(null);
    return _tripsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final trips =
      snap.docs.map((doc) => SavedTrip.fromMap(doc.data())).toList();

      // Önce aktif olanlar (bugün başlamış, bitmemiş)
      final active = trips.where((t) => t.isActive).toList();
      if (active.isNotEmpty) {
        active.sort((a, b) => (a.startDate ?? DateTime(9999))
            .compareTo(b.startDate ?? DateTime(9999)));
        return active.first;
      }

      // Aktif yoksa yaklaşan planlar
      final upcoming = trips.where((t) => t.isUpcoming).toList();
      if (upcoming.isNotEmpty) {
        upcoming.sort((a, b) => (a.startDate ?? DateTime(9999))
            .compareTo(b.startDate ?? DateTime(9999)));
        return upcoming.first;
      }

      // startDate'siz eski kayıtlar için fallback
      final noDate = trips.where((t) => t.startDate == null).toList();
      return noDate.isNotEmpty ? noDate.first : null;
    });
  }

  //tamamlanma oranı güncellemesi
  Future<void> updateCompletionRate(String tripId, double rate) async {
    if (_uid == null) return;
    final clamped = rate.clamp(0.0, 1.0);
    await _tripsRef.doc(tripId).update({'completionRate': clamped});
  }


      // Planı sil
  Future<void> deleteTrip(String id) async {
    if (_uid == null) return;

    // 1. Önce silinecek trip'in bilgilerini oku
    final doc = await _tripsRef.doc(id).get();
    final data = doc.data();
    final city    = data?['city']    as String?;
    final country = data?['country'] as String?;

    // 2. Trip'i sil
    await _tripsRef.doc(id).delete();

    // 3. Bu şehir başka bir trip'te hâlâ var mı kontrol et
    if (city != null) {
      final remaining = await _tripsRef
          .where('city', isEqualTo: city)
          .limit(1)
          .get();

      // Başka trip yoksa cities array'inden ve count'tan düş
      if (remaining.docs.isEmpty) {
        final userRef = _db.collection('users').doc(_uid);
        await userRef.set({
          'cities':    FieldValue.arrayRemove([city]),
          'cityCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    }
  }

  //Başlık / tarih 
  Future<void> updateTrip(
      String id, {
        String? title,
        DateTime? tripDate,
        DateTime? startDate,
        int? days,
      }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (tripDate != null) updates['tripDate'] = tripDate.toIso8601String();
    if (startDate != null) {updates['startDate'] = startDate.toIso8601String();
      if (days != null) {
        final end = startDate.add(Duration(days: days - 1));
        updates['endDate'] = end.toIso8601String();
        updates['days'] = days;
      }
    }
    await _tripsRef.doc(id).update(updates);
  }

  // özet
Future<String> _generateSummary(TripResult result) async {
    try {
      final key = dotenv.env['GEMINI_API_KEY'] ?? '';
      const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

      String places = '';
      try {
        if (result.dayPlans != null && result.dayPlans.isNotEmpty) {
          places = result.dayPlans
              .where((d) => d != null && d.places != null)
              .expand((d) => d.places)
              .take(5)
              .map((p) => p != null ? p.name.toString() : '')
              .where((name) => name.isNotEmpty)
              .join(', ');
        }
      } catch (innerError) {
        print('⚠️ Voyixi Veri Hatası (places işlenemedi): $innerError'); // 💡 print yapıldı
        places = result.city;
      }

      final prompt =
          'A travel itinerary for a ${result.days}-day trip to ${result.city} '
          'with a budget of ${result.budget}, covering places like $places. '
          'Write a brief summary in English, not exceeding 3 sentences.';

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
            'maxOutputTokens': 200
          }
        }),
      ).timeout(const Duration(seconds: 15));

      print('🤖 VOYIXI AI STATUS: ${res.statusCode}'); // 💡 print yapıldı

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'] as String;
        return aiText.trim();
      } else {
        print('❌ VOYIXI AI REFUSAL: ${res.body}'); // 💡 print yapıldı
      }
    } catch (e) {
      print('💥 VOYIXI SERVICE CRASHED: $e'); // 💡 print yapıldı
    }

    return 'A ${result.days}-day trip to ${result.city} planned with a budget of ${result.budget}.';
  }

  // ── Places API City Image
  Future<String?> _fetchCityImage(String city) async {
    try {
      final key = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      final res = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(city)}'
            '&key=$key',
      )).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final photos = results[0]['photos'] as List?;
      if (photos == null || photos.isEmpty) return null;

      final ref = photos[0]['photo_reference'] as String?;
      if (ref == null) return null;

      return 'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=800&photoreference=$ref&key=$key';
    } catch (_) {
      return null;
    }
  }
}
