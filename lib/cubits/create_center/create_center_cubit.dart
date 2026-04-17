import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'create_center_state.dart';

class CreateCenterCubit extends Cubit<CreateCenterState> {
  CreateCenterCubit() : super(CreateCenterInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RegExp _emailRegex = RegExp(
    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
  );

  Future<void> createCenter({
    required String centerName,
    required String location,
    required String managerName,
    required String managerEmail,
  }) async {
    final cleanCenterName = centerName.trim();
    final cleanLocation = location.trim();
    final cleanManagerName = managerName.trim();
    final cleanManagerEmail = managerEmail.trim().toLowerCase();

    if (cleanCenterName.isEmpty ||
        cleanLocation.isEmpty ||
        cleanManagerName.isEmpty ||
        cleanManagerEmail.isEmpty) {
      emit(CreateCenterError("Please fill in all fields."));
      return;
    }

    if (cleanCenterName.length < 3) {
      emit(CreateCenterError("Center name must be at least 3 characters."));
      return;
    }

    if (cleanLocation.length < 2) {
      emit(CreateCenterError("Location must be at least 2 characters."));
      return;
    }

    if (cleanManagerName.length < 3) {
      emit(CreateCenterError("Manager name must be at least 3 characters."));
      return;
    }

    if (!_emailRegex.hasMatch(cleanManagerEmail)) {
      emit(CreateCenterError("Please enter a valid manager email."));
      return;
    }

    emit(CreateCenterLoading());

    try {
      final duplicateCheck = await _firestore
          .collection('centers')
          .where('name', isEqualTo: cleanCenterName)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        emit(CreateCenterError("A center with this name already exists."));
        return;
      }

      final centerRef = _firestore.collection('centers').doc();
      final requestRef = _firestore.collection('manager_requests').doc();

      final batch = _firestore.batch();

      batch.set(centerRef, {
        'name': cleanCenterName,
        'location': cleanLocation,
        'managerName': cleanManagerName,
        'managerEmail': cleanManagerEmail,
        'managerUid': null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'monthlyRevenue': 0,
        'monthlyExpenses': 0,
        'profit': 0,
      });

      batch.set(requestRef, {
        'centerId': centerRef.id,
        'centerName': cleanCenterName,
        'location': cleanLocation,
        'managerName': cleanManagerName,
        'managerEmail': cleanManagerEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      emit(CreateCenterSuccess("Center created successfully."));
    } catch (e) {
      print("Create center error: $e");
      emit(CreateCenterError("Failed to create center."));
    }
  }
}