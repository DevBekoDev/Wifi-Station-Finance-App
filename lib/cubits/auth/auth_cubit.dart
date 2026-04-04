import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // 🔐 Email Login
  Future<void> loginWithEmail(String email, String password) async {
  emit(AuthLoading());

  try {
    final user = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (user == null) {
      emit(AuthError("Login failed"));
      return;
    }

    print("Firebase Auth success. UID: ${user.uid}");

    final userData = await _firestoreService.getUserData(user.uid);

    print("Firestore user data: $userData");

    if (userData == null) {
      await _authService.signOut();
      emit(AuthError("User exists in Auth but not in Firestore"));
      return;
    }

    emit(AuthSuccess(
      role: userData['role'],
      centerId: userData['centerId'],
    ));
  } on FirebaseAuthException catch (e) {
    print("FirebaseAuthException code: ${e.code}");
    print("FirebaseAuthException message: ${e.message}");
    emit(AuthError(e.message ?? e.code));
  } on FirebaseException catch (e) {
    print("FirebaseException code: ${e.code}");
    print("FirebaseException message: ${e.message}");
    emit(AuthError(e.message ?? e.code));
  } catch (e) {
    print("Unknown login error: $e");
    emit(AuthError(e.toString()));
  }
}

  // 🔴 Google Login
  Future<void> loginWithGoogle() async {
    emit(AuthLoading());

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        emit(AuthError("Google sign-in cancelled"));
        return;
      }

      final userData =
          await _firestoreService.getUserData(user.uid);

      if (userData == null) {
        await _authService.signOut();
        emit(AuthError("User not registered"));
        return;
      }

      emit(AuthSuccess(
        role: userData['role'],
        centerId: userData['centerId'],
      ));
    } catch (e) {
      emit(AuthError("Google sign-in failed"));
    }
  }

  // 🔁 Forgot Password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      emit(AuthError("Password reset email sent"));
    } catch (e) {
      emit(AuthError("Failed to send reset email"));
    }
  }
}