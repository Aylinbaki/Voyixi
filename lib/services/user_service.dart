import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserService {

  final _db = FirebaseFirestore.instance;

  Future<void> saveUser(User user) async {

    await _db.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": user.email,
      "name": user.displayName ?? "",
      "photo": user.photoURL ?? "",
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── YENİ: Trip tamamlandığında istatistikleri güncelle ──────────────
  // Neden increment? Çünkü mevcut değerin ne olduğunu bilmeden güvenle
  // artırabiliyoruz — race condition yok, okuma→yazma döngüsü yok.
  Future<void> incrementStats({
    required String uid,
    required double distanceKm,
    required String city,         // tekrar sayılmaması için Set mantığı
    required String country,
    required int museumCount,     // bu trip'te kaç müze var
  }) async {
    final ref = _db.collection("users").doc(uid);

    // 1. Önce mevcut cities listesini oku (şehir tekrar eklenmesin)
    final snap = await ref.get();
    final data = snap.data();
    final existingCities = List<String>.from(data?['cities'] ?? []);
    final existingCountries = List<String>.from(data?['countries'] ?? []);

    final isNewCity = !existingCities.contains(city);
    final isNewCountry = !existingCountries.contains(country);

    await ref.set({
      // km her zaman eklenir
      'totalKm': FieldValue.increment(distanceKm),
      // müze sayısı her zaman eklenir
      'museumCount': FieldValue.increment(museumCount),
      // şehir sadece ilk kez eklenirse sayılır
      if (isNewCity) ...{
        'cityCount': FieldValue.increment(1),
        'cities': FieldValue.arrayUnion([city]),
      },
      if (isNewCountry) ...{                                               // ← YENİ
        'countryCount': FieldValue.increment(1),
        'countries':    FieldValue.arrayUnion([country]),
      },
    }, SetOptions(merge: true));
  }

  // ── YENİ: Profil ekranı için stats stream'i ─────────────────────────
  Stream<Map<String, dynamic>> statsStream(String uid) {
    return _db.collection("users").doc(uid).snapshots().map((snap) {
      final d = snap.data() ?? {};
      return {
        'cityCount':   (d['cityCount']   as num?)?.toInt() ?? 0,
        'museumCount': (d['museumCount'] as num?)?.toInt() ?? 0,
        'totalKm':     (d['totalKm']     as num?)?.toDouble() ?? 0.0,
        'countryCount':(d['countryCount']as num?)?.toInt() ?? 0,
      };
    });
  }

  // Firebase'e Not Kaydetme ──────────────────────────────
  Future<void> addNote({
    required String uid,
    required String title,
    required String note,
    required String imageUrl,
    required bool isLocal,
  }) async {
    await _db.collection("users").doc(uid).collection("notes").add({
      "title": title,
      "note": note,
      "imageUrl": imageUrl,
      "isLocal": isLocal,
      "date": DateFormat('dd.MM.yyyy').format(DateTime.now()),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> notesStream(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {
      "id": doc.id,
      ...doc.data(),
    }).toList());
  }
  //Not Silme
  Future<void> deleteNote(String uid, String noteId) async {
    await _db.collection("users").doc(uid).collection("notes").doc(noteId).delete();
  }

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
      "title": title,
      "note": note,
      "imageUrl": imageUrl,
      "isLocal": isLocal,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}