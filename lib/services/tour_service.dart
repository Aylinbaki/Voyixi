import 'package:cloud_firestore/cloud_firestore.dart';

class TourService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Popüler turları getirir
  Stream<List<Map<String, dynamic>>> getPopularTours() {
    return _db.collection('popular_tours').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // Civardaki mekanları getirir (Şimdilik İstanbul koleksiyonu)
  Stream<List<Map<String, dynamic>>> getNearbyPlaces() {
    return _db.collection('nearby_places').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }
}