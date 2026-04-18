import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'manager_activation_state.dart';

class ManagerActivationCubit extends Cubit<ManagerActivationState> {
  ManagerActivationCubit() : super(ManagerActivationInitial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RegExp _emailRegex = RegExp(
    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
  );

  Future<void> activateManager({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanEmail.isEmpty ||
        cleanPassword.isEmpty ||
        cleanConfirmPassword.isEmpty) {
      emit(ManagerActivationError("Please fill in all fields."));
      return;
    }

    if (!_emailRegex.hasMatch(cleanEmail)) {
      emit(ManagerActivationError("Please enter a valid email."));
      return;
    }

    if (cleanPassword.length < 6) {
      emit(ManagerActivationError("Password must be at least 6 characters."));
      return;
    }

    if (cleanPassword != cleanConfirmPassword) {
      emit(ManagerActivationError("Passwords do not match."));
      return;
    }

    emit(ManagerActivationLoading());

    UserCredential? userCredential;

    try {
      final requestQuery = await _firestore
          .collection('manager_requests')
          .where('managerEmail', isEqualTo: cleanEmail)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (requestQuery.docs.isEmpty) {
        emit(
          ManagerActivationError(
            "No pending manager activation found for this email.",
          ),
        );
        return;
      }

      final requestDoc = requestQuery.docs.first;
      final requestData = requestDoc.data();

      final String centerId = requestData['centerId'];
      final String managerName = requestData['managerName'] ?? '';
      final String centerName = requestData['centerName'] ?? '';

      userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = userCredential.user;

      if (user == null) {
        emit(ManagerActivationError("Failed to create manager account."));
        return;
      }

      final batch = _firestore.batch();

      final userRef = _firestore.collection('users').doc(user.uid);
      final centerRef = _firestore.collection('centers').doc(centerId);
      final requestRef = _firestore
          .collection('manager_requests')
          .doc(requestDoc.id);

      batch.set(userRef, {
        'email': cleanEmail,
        'role': 'manager',
        'centerId': centerId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(centerRef, {
        'managerUid': user.uid,
        'managerEmail': cleanEmail,
        'managerName': managerName,
      });

      batch.update(requestRef, {
        'status': 'accepted',
        'managerUid': user.uid,
        'activatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await _auth.signOut();

      emit(
        ManagerActivationSuccess(
          "Account activated successfully for $centerName. Please log in.",
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        emit(
          ManagerActivationError(
            "This email is already in use. Try logging in instead.",
          ),
        );
      } else if (e.code == 'invalid-email') {
        emit(ManagerActivationError("Invalid email."));
      } else if (e.code == 'weak-password') {
        emit(ManagerActivationError("Password is too weak."));
      } else {
        emit(ManagerActivationError(e.message ?? "Activation failed."));
      }
    } on FirebaseException catch (e) {
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
        } catch (_) {}
      }

      emit(ManagerActivationError(e.message ?? "Activation failed."));
    } catch (e) {
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
        } catch (_) {}
      }

      emit(ManagerActivationError("Activation failed."));
    }
  }
}