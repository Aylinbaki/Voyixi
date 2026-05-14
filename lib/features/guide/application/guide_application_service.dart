// lib/features/guide/application/guide_application_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guide_application_model.dart';

class GuideApplicationService {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> submitApplication(GuideApplication app) async {
    await _db.collection('guide_applications').doc(app.id).set(app.toMap());
  }

  // Başvuru var mı — sadece aktif (silinmemiş) olanları say
  Future<bool> hasApplied() async {
    if (_uid == null) return false;
    final snap = await _db
        .collection('guide_applications')
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<GuideApplication?> getMyApplication() async {
    if (_uid == null) return null;
    final snap = await _db
        .collection('guide_applications')
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return GuideApplication.fromMap(snap.docs.first.data());
  }
}