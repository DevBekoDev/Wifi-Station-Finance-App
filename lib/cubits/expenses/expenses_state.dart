import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseHistoryItem {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime createdAt;

  const ExpenseHistoryItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory ExpenseHistoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    double toDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    DateTime createdAt = DateTime.now();
    final ts = data['createdAt'];
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    }

    return ExpenseHistoryItem(
      id: doc.id,
      category: data['category'] ?? 'Unknown',
      amount: toDouble(data['amount']),
      description: data['description'] ?? '',
      createdAt: createdAt,
    );
  }
}

class ExpensesState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final double totalExpensesAmount;
  final int totalExpensesCount;
  final List<ExpenseHistoryItem> recentExpenses;

  const ExpensesState({
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
    required this.successMessage,
    required this.totalExpensesAmount,
    required this.totalExpensesCount,
    required this.recentExpenses,
  });

  factory ExpensesState.initial() {
    return const ExpensesState(
      isLoading: true,
      isSaving: false,
      errorMessage: null,
      successMessage: null,
      totalExpensesAmount: 0,
      totalExpensesCount: 0,
      recentExpenses: [],
    );
  }

  ExpensesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    double? totalExpensesAmount,
    int? totalExpensesCount,
    List<ExpenseHistoryItem>? recentExpenses,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ExpensesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      totalExpensesAmount: totalExpensesAmount ?? this.totalExpensesAmount,
      totalExpensesCount: totalExpensesCount ?? this.totalExpensesCount,
      recentExpenses: recentExpenses ?? this.recentExpenses,
    );
  }
}