import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}