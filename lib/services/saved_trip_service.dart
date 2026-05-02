import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedTrip {
  final String? id;
  final String title;
  final String city;
  final String imageUrl;
  final String dateRange;
  final int pointCount;
  bool isFavorite;

  SavedTrip({
    this.id,
    required this.title,
    required this.city,
    required this.imageUrl,
    required this.dateRange,
    required this.pointCount,
    this.isFavorite = true,
  });

  factory SavedTrip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedTrip(
      id: doc.id,
      title: data['title'] ?? '',
      city: data['city'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      dateRange: data['dateRange'] ?? '',
      pointCount: data['pointCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'city': city,
    'imageUrl': imageUrl,
    'dateRange': dateRange,
    'pointCount': pointCount,
    'savedAt': FieldValue.serverTimestamp(),
  };
}

class SavedTripService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference? _userTripsRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('saved_trips');
  }

  static Future<void> saveTrip(SavedTrip trip) async {
    final ref = _userTripsRef();
    if (ref == null) return;
    final existing = await ref.where('title', isEqualTo: trip.title).get();
    if (existing.docs.isEmpty) {
      await ref.add(trip.toMap());
    }
  }

  static Future<void> removeTrip(String tripId) async {
    final ref = _userTripsRef();
    if (ref == null) return;
    await ref.doc(tripId).delete();
  }

  static Future<bool> isSaved(String title) async {
    final ref = _userTripsRef();
    if (ref == null) return false;
    final result = await ref.where('title', isEqualTo: title).get();
    return result.docs.isNotEmpty;
  }

  static Stream<List<SavedTrip>> savedTripsStream() {
    final ref = _userTripsRef();
    if (ref == null) return const Stream.empty();
    return ref
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedTrip.fromFirestore).toList());
  }
}
