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
        final sales = snapshot.docs
            .map(SaleHistoryItem.fromDoc)
            .toList()
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

  Future<void> addSale({
    required String centerId,
    required String packageName,
    required double packagePrice,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      emit(
        state.copyWith(
          errorMessage: 'Quantity must be at least 1.',
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
        'date':
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });

      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Sale saved successfully.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save sale.',
        ),
      );
    }
  }

  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _salesSubscription?.cancel();
    return super.close();
  }
}