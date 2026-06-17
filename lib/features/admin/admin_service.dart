// lib/features/admin/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../guide/models/guide_application_model.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isAdmin() async {
    if (_uid == null) return false;
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['isAdmin'] == true;
  }

  Future<bool> isGuide() async {
    if (_uid == null) return false;
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['isGuide'] == true;
  }

  Stream<List<GuideApplication>> getAllApplications() => _db
      .collection('guide_applications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => GuideApplication.fromMap(d.data()))
          .toList());

  Stream<List<Map<String, dynamic>>> getAllGuides() => _db
      .collection('users')
      .where('isGuide', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  // Onayla → kullanıcıyı rehber yap
  Future<void> approveApplication(GuideApplication app) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('guide_applications').doc(app.id),
      {'status': 'approved'},
    );
    batch.update(
      _db.collection('users').doc(app.userId),
      {'isGuide': true},
    );
    await batch.commit();
  }

  // Reddet → başvuruyu sil 
  Future<void> rejectApplication( GuideApplication app) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('guide_applications').doc(app.id),
      {'status': 'rejected'},
    );
    batch.update(
      _db.collection('users').doc(app.userId),
      {
      'isPending': false,
      'isRejected': true,
      },
    );
    await batch.commit();
  }

  // Rehberliği kaldır → başvurusunu da sil 
  Future<void> removeGuide(String userId) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('users').doc(userId),
      {'isGuide': false},
    );
    // O kullanıcının başvurusunu da sil
    final apps = await _db
        .collection('guide_applications')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in apps.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}