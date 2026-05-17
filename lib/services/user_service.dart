import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  // Kullanıcıyı ilk kayıt sırasında Firestore'a yaz
  Future<void> saveUser(User user) async {
    await _db.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": user.email,
      "name": user.displayName ?? "",
      "photo": user.photoURL ?? "",
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Profil bilgilerini güncelle (city, country, name)
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String city,
    required String country,
  }) async {
    await _db.collection("users").doc(uid).set({
      "name":    name,
      "city":    city,
      "country": country,
    }, SetOptions(merge: true));
  }

  // ── Profil ekranı için kullanıcı bilgisi stream'i ───────────────────
  // Neden statsStream'den ayrı? Stats her trip'te değişir, profil nadiren
  // değişir. Ayrı stream = gereksiz rebuild yok.
  Stream<Map<String, dynamic>> userStream(String uid) {
    return _db.collection("users").doc(uid).snapshots().map((snap) {
      final d = snap.data() ?? {};
      return {
        'name':    d['name']    ?? '',
        'city':    d['city']    ?? '',
        'country': d['country'] ?? '',
      };
    });
  }

  //Trip tamamlandığında istatistikleri güncelle
  Future<void> incrementStats({
    required String uid,
    required double distanceKm,
    required String city,
    required String country,
    required int museumCount,
  }) async {
    final ref = _db.collection("users").doc(uid);

    // Şehir/ülke tekrar sayılmasın diye önce mevcut listeyi oku
    final snap = await ref.get();
    final data = snap.data();
    final existingCities    = List<String>.from(data?['cities']    ?? []);
    final existingCountries = List<String>.from(data?['countries'] ?? []);

    final isNewCity    = !existingCities.contains(city);
    final isNewCountry = !existingCountries.contains(country);

    await ref.set({
      'totalKm':    FieldValue.increment(distanceKm),
      'museumCount': FieldValue.increment(museumCount),
      if (isNewCity) ...{
        'cityCount': FieldValue.increment(1),
        'cities':    FieldValue.arrayUnion([city]),
      },
      if (isNewCountry) ...{
        'countryCount': FieldValue.increment(1),
        'countries':    FieldValue.arrayUnion([country]),
      },
    }, SetOptions(merge: true));
  }

  // ── Profil ekranı için stats stream'i ───────────────────────────────
  Stream<Map<String, dynamic>> statsStream(String uid) {
    return _db.collection("users").doc(uid).snapshots().map((snap) {
      final d = snap.data() ?? {};
      return {
        'cityCount':    (d['cityCount']    as num?)?.toInt()    ?? 0,
        'museumCount':  (d['museumCount']  as num?)?.toInt()    ?? 0,
        'totalKm':      (d['totalKm']      as num?)?.toDouble() ?? 0.0,
        'countryCount': (d['countryCount'] as num?)?.toInt()    ?? 0,
      };
    });
  }

  // Not Ekle
  Future<void> addNote({
    required String uid,
    required String title,
    required String note,
    required String imageUrl,
    required bool isLocal,
  }) async {
    await _db.collection("users").doc(uid).collection("notes").add({
      "title":     title,
      "note":      note,
      "imageUrl":  imageUrl,
      "isLocal":   isLocal,
      "date":      DateFormat('dd.MM.yyyy').format(DateTime.now()),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // Notları Dinle
  Stream<List<Map<String, dynamic>>> notesStream(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => {"id": doc.id, ...doc.data()})
        .toList());
  }

  // Not Sil
  Future<void> deleteNote(String uid, String noteId) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .doc(noteId)
        .delete();
  }

  // Not Güncelle
  Future<void> updateNote({
    required String uid,
    required String noteId,
    required String title,
    required String note,
    required String imageUrl,
    required bool isLocal,
  }) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .doc(noteId)
        .update({
      "title":     title,
      "note":      note,
      "imageUrl":  imageUrl,
      "isLocal":   isLocal,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}