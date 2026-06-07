import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../active_trip_state_model.dart';

class ActiveTripService {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _ref(String tripId) => _db
      .collection('users')
      .doc(_uid)
      .collection('saved_trips')
      .doc(tripId);

  // Firebase'e kaydet ----------------------------------------------
  Future<void> saveProgress(
      String tripId, List<TripPlaceState> states) async {
        
    await _ref(tripId).update({
      'progress': states.map((s) => s.toMap()).toList(),
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  // Firebase'den yükle ----------------------------------------------
  Future<List<TripPlaceState>> loadProgress(String tripId) async {
    final doc = await _ref(tripId).get();
    final data = doc.data();
    if (data == null || data['progress'] == null) return [];
    return (data['progress'] as List)
        .map((m) => TripPlaceState.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // Tek mekan yorum güncelle ----------------------------------------------
  Future<void> updateReview(
    String tripId,
    int dayIdx,
    int placeIdx, {
    required int rating,
    required String review,
  }) async {
    final doc = await _ref(tripId).get();
    final data = doc.data();
    if (data == null) return;

    final progress = List<Map<String, dynamic>>.from(
      (data['progress'] as List? ?? [])
          .map((m) => Map<String, dynamic>.from(m as Map)),
    );

    final idx = progress.indexWhere(
        (m) => m['dayIdx'] == dayIdx && m['placeIdx'] == placeIdx);
    if (idx != -1) {
      progress[idx]['rating'] = rating;
      progress[idx]['review'] = review;
      await _ref(tripId).update({'progress': progress});
    }
  }
}