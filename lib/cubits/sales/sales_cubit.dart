import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  SalesCubit() : super(SalesState.initial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _salesSubscription;

  // ───────────────────────────────────────────────────────────────────────────
  // Load Sales
  // ───────────────────────────────────────────────────────────────────────────

  void loadSales(String centerId) {
    _salesSubscription?.cancel();

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    _salesSubscription = _firestore
        .collection('sales')
        .where('centerId', isEqualTo: centerId)
        .snapshots()
        .listen(
      (snapshot) {
        final sales = snapshot.docs.map(SaleHistoryItem.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        double totalSales = 0;
        int totalQuantity = 0;

        for (final sale in sales) {
          totalSales += sale.totalAmount;
          totalQuantity += sale.quantity;
        }

        emit(
          state.copyWith(
            isLoading: false,
            recentSales: sales,
            totalSalesAmount: totalSales,
            totalQuantity: totalQuantity,
            clearError: true,
          ),
        );
      },
      onError: (_) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to load sales.',
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Add Sale
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> addSale({
    required String centerId,
    required String packageName,
    required double packagePrice,
    required int quantity,
  }) async {
    if (centerId.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Center ID is missing.',
          clearSuccess: true,
        ),
      );
      return;
    }

    if (packageName.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Package name is missing.',
          clearSuccess: true,
        ),
      );
      return;
    }

    if (packagePrice <= 0) {
      emit(
        state.copyWith(
          errorMessage: 'Package price must be greater than 0.',
          clearSuccess: true,
        ),
      );
      return;
    }

    if (quantity < 1 || quantity > 999) {
      emit(
        state.copyWith(
          errorMessage: 'Quantity must be between 1 and 999.',
          clearSuccess: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final totalAmount = packagePrice * quantity;
      final now = DateTime.now();
      final currentUser = _auth.currentUser;

      await _firestore.collection('sales').add({
        'centerId': centerId,
        'packageName': packageName,
        'packagePrice': packagePrice,
        'quantity': quantity,
        'totalAmount': totalAmount,
        'createdBy': currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),

        // Useful for reports/filtering.
        'date': _dateString(now),

        // Useful for future audit/report logic.
        'updatedAt': null,
        'updatedBy': null,
      });

      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Sale saved successfully.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save sale.',
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Edit Sale
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> editSale({
  required String centerId,
  required String saleId,
  required int quantity,
}) async {
  if (centerId.trim().isEmpty) {
    emit(
      state.copyWith(
        errorMessage: 'Center ID is missing.',
        clearSuccess: true,
      ),
    );
    return;
  }

  if (saleId.trim().isEmpty) {
    emit(
      state.copyWith(
        errorMessage: 'Sale ID is missing.',
        clearSuccess: true,
      ),
    );
    return;
  }

  if (quantity < 1 || quantity > 999) {
    emit(
      state.copyWith(
        errorMessage: 'Quantity must be between 1 and 999.',
        clearSuccess: true,
      ),
    );
    return;
  }

  emit(
    state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    ),
  );

  try {
    final saleRef = _firestore.collection('sales').doc(saleId);
    final currentUser = _auth.currentUser;

    await _firestore.runTransaction((transaction) async {
      final saleSnap = await transaction.get(saleRef);

      if (!saleSnap.exists) {
        throw Exception('Sale not found');
      }

      final data = saleSnap.data();

      if (data == null) {
        throw Exception('Sale data is empty');
      }

      final saleCenterId = data['centerId']?.toString();

      if (saleCenterId != centerId) {
        throw Exception(
          'Center mismatch. Sale centerId: $saleCenterId, screen centerId: $centerId',
        );
      }

      final packagePriceValue = data['packagePrice'];

      if (packagePriceValue == null) {
        throw Exception('Package price is missing');
      }

      final packagePrice = (packagePriceValue as num).toDouble();
      final newTotalAmount = packagePrice * quantity;

      transaction.update(saleRef, {
        'quantity': quantity,
        'totalAmount': newTotalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser?.uid,
      });
    });

    emit(
      state.copyWith(
        isSaving: false,
        successMessage: 'Sale updated successfully.',
      ),
    );
  } catch (e) {
    print('EDIT SALE ERROR: $e');

    emit(
      state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update sale: $e',
      ),
    );
  }
}
  // ───────────────────────────────────────────────────────────────────────────
  // Delete Sale
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> deleteSale({
    required String centerId,
    required String saleId,
  }) async {
    if (centerId.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Center ID is missing.',
          clearSuccess: true,
        ),
      );
      return;
    }

    if (saleId.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Sale ID is missing.',
          clearSuccess: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final saleRef = _firestore.collection('sales').doc(saleId);

      await _firestore.runTransaction((transaction) async {
        final saleSnap = await transaction.get(saleRef);

        if (!saleSnap.exists) {
          throw Exception('Sale not found');
        }

        final data = saleSnap.data();

        if (data == null) {
          throw Exception('Sale data is empty');
        }

        if (data['centerId'] != centerId) {
          throw Exception('This sale does not belong to this center');
        }

        transaction.delete(saleRef);
      });

      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Sale deleted successfully.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to delete sale.',
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Messages
  // ───────────────────────────────────────────────────────────────────────────

  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Close
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _salesSubscription?.cancel();
    return super.close();
  }
}