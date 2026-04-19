import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit() : super(ExpensesState.initial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSubscription;

  void loadExpenses(String centerId) {
    _expensesSubscription?.cancel();

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    _expensesSubscription = _firestore
        .collection('expenses')
        .where('centerId', isEqualTo: centerId)
        .snapshots()
        .listen(
      (snapshot) {
        final expenses = snapshot.docs
            .map(ExpenseHistoryItem.fromDoc)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        double totalExpenses = 0;
        for (final expense in expenses) {
          totalExpenses += expense.amount;
        }

        emit(
          state.copyWith(
            isLoading: false,
            recentExpenses: expenses,
            totalExpensesAmount: totalExpenses,
            totalExpensesCount: expenses.length,
            clearError: true,
          ),
        );
      },
      onError: (_) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to load expenses.',
          ),
        );
      },
    );
  }

  Future<void> addExpense({
    required String centerId,
    required String category,
    required double amount,
    required String description,
  }) async {
    final cleanDescription = description.trim();

    if (amount <= 0) {
      emit(
        state.copyWith(
          errorMessage: 'Amount must be greater than 0.',
          clearSuccess: true,
        ),
      );
      return;
    }

    if (cleanDescription.isEmpty || cleanDescription.length < 3) {
      emit(
        state.copyWith(
          errorMessage: 'Description must be at least 3 characters.',
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
      final now = DateTime.now();
      final currentUser = _auth.currentUser;

      await _firestore.collection('expenses').add({
        'centerId': centerId,
        'category': category,
        'amount': amount,
        'description': cleanDescription,
        'createdBy': currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'date':
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });

      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Expense saved successfully.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save expense.',
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
    _expensesSubscription?.cancel();
    return super.close();
  }
}