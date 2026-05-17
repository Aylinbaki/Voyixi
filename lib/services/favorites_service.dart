import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Favori Mekan Modeli ───────────────────────────────────────────────────────
class FavoritePlace {
  final String? id;       // Firestore doc ID
  final String name;
  final String description;
  final String city;
  final String? photoUrl;
  final String? placeId;  // Google Places ID
  final double? lat;
  final double? lng;

  FavoritePlace({
    this.id,
    required this.name,
    required this.description,
    required this.city,
    this.photoUrl,
    this.placeId,
    this.lat,
    this.lng,
  });

  factory FavoritePlace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoritePlace(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      city: data['city'] ?? '',
      photoUrl: data['photoUrl'],
      placeId: data['placeId'],
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'city': city,
    'photoUrl': photoUrl,
    'placeId': placeId,
    'lat': lat,
    'lng': lng,
    'savedAt': FieldValue.serverTimestamp(),
  };
}

// ── Favori Rota Modeli ────────────────────────────────────────────────────────
class FavoriteRoute {
  final String? id;       // Firestore doc ID
  final String routeId;   // routes_model SavedTrip.id
  final String title;
  final String city;
  final int days;
  final String budget;
  final String? imageUrl;
  final String summary;

  FavoriteRoute({
    this.id,
    required this.routeId,
    required this.title,
    required this.city,
    required this.days,
    required this.budget,
    this.imageUrl,
    required this.summary,
  });

  factory FavoriteRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteRoute(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      title: data['title'] ?? '',
      city: data['city'] ?? '',
      days: data['days'] ?? 0,
      budget: data['budget'] ?? '',
      imageUrl: data['imageUrl'],
      summary: data['summary'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'routeId': routeId,
    'title': title,
    'city': city,
    'days': days,
    'budget': budget,
    'imageUrl': imageUrl,
    'summary': summary,
    'savedAt': FieldValue.serverTimestamp(),
  };
}

// ── Servis ────────────────────────────────────────────────────────────────────
class FavoritesService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  // Koleksiyon referansları
  static CollectionReference? get _placesRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('favorite_places');
  }

  static CollectionReference? get _routesRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('favorite_routes');
  }

  // ── MEKAN FAVORİLERİ ──────────────────────────────────────────────────────
  static Future<void> addFavoritePlace(FavoritePlace place) async {
    final ref = _placesRef;
    if (ref == null) return;
    // placeId varsa ona göre, yoksa name+city'ye göre kontrol et
    Query query;
    if (place.placeId != null && place.placeId!.isNotEmpty) {
      query = ref.where('placeId', isEqualTo: place.placeId);
    } else {
      query = ref
          .where('name', isEqualTo: place.name)
          .where('city', isEqualTo: place.city);
    }

    final existing = await query.limit(1).get();
    if (existing.docs.isEmpty) {
      await ref.add(place.toMap());
    }
  }

  static Future<void> removeFavoritePlace(String docId) async {
    await _placesRef?.doc(docId).delete();
  }

  static Future<bool> isPlaceFavorited(String name, String city) async {
    final ref = _placesRef;
    if (ref == null) return false;
    final result = await ref.where('name', isEqualTo: name)
        .where('city', isEqualTo: city).get();
    return result.docs.isNotEmpty;
  }

  static Stream<List<FavoritePlace>> favoritePlacesStream() {
    final ref = _placesRef;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FavoritePlace.fromFirestore).toList());
  }

  // ── ROTA FAVORİLERİ ───────────────────────────────────────────────────────

  static Future<void> addFavoriteRoute(FavoriteRoute route) async {
    final ref = _routesRef;
    if (ref == null) return;
    // Aynı rota zaten varsa tekrar ekleme
    final existing = await ref.where('routeId', isEqualTo: route.routeId).get();
    if (existing.docs.isEmpty) {
      await ref.add(route.toMap());
    }
  }

  static Future<void> removeFavoriteRoute(String docId) async {
    await _routesRef?.doc(docId).delete();
  }

  static Future<bool> isRouteFavorited(String routeId) async {
    final ref = _routesRef;
    if (ref == null) return false;
    final result = await ref.where('routeId', isEqualTo: routeId).get();
    return result.docs.isNotEmpty;
  }

  // favoriteDocId döner — silmek için lazım
  static Future<String?> getFavoriteRouteDocId(String routeId) async {
    final ref = _routesRef;
    if (ref == null) return null;
    final result = await ref.where('routeId', isEqualTo: routeId).get();
    if (result.docs.isEmpty) return null;
    return result.docs.first.id;
  }

  static Stream<List<FavoriteRoute>> favoriteRoutesStream() {
    final ref = _routesRef;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FavoriteRoute.fromFirestore).toList());
  }
}