import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<UserModel?> getUserData(String uid) async {
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // Ham veriyi modelimize gönderip tertemiz bir obje alıyoruz
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print("Failed to load user data: $e");
    }
    return null;
  }

  // EMAIL SIGN UP
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return user.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // EMAIL LOGIN
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }
  // PASSWORD RESET
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}

