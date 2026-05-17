// lib/features/guide/panel/guide_tour_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guide_tour_model.dart';

class GuideTourService {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Tüm turları getir (home screen — popüler turlar)
  Stream<List<GuideTour>> getAllTours() => _db
      .collection('guide_tours')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => GuideTour.fromMap(d.data())).toList());

  // Rehberin kendi turları
  Stream<List<GuideTour>> getMyTours() => _db
      .collection('guide_tours')
      .where('guideId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => GuideTour.fromMap(d.data())).toList());

  // Tur oluştur
  Future<void> createTour(GuideTour tour) async {
    await _db.collection('guide_tours').doc(tour.id).set(tour.toMap());
  }

  // Tur güncelle
  Future<void> updateTour(GuideTour tour) async {
    await _db.collection('guide_tours').doc(tour.id).update(tour.toMap());
  }

  // Tur sil
  Future<void> deleteTour(String id) async {
    await _db.collection('guide_tours').doc(id).delete();
  }

  // Beğen / beğeniyi kaldır
  Future<void> toggleLike(String tourId) async {
    if (_uid == null) return;
    final ref = _db.collection('guide_tours').doc(tourId);
    final doc = await ref.get();
    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
    if (likedBy.contains(_uid)) {
      likedBy.remove(_uid);
    } else {
      likedBy.add(_uid!);
    }
    await ref.update({'likedBy': likedBy});
  }
}