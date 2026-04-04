import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 Email & Password Login
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // 🔴 Google Sign-In for google_sign_in 7.x
  Future<User?> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  // 🔁 Forgot Password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 🚪 Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }
}