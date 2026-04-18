import 'package:cloud_firestore/cloud_firestore.dart';

class SaleHistoryItem {
  final String id;
  final String packageName;
  final double packagePrice;
  final int quantity;
  final double totalAmount;
  final DateTime createdAt;

  const SaleHistoryItem({
    required this.id,
    required this.packageName,
    required this.packagePrice,
    required this.quantity,
    required this.totalAmount,
    required this.createdAt,
  });

  factory SaleHistoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    double toDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    DateTime createdAt = DateTime.now();
    final ts = data['createdAt'];
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    }

    return SaleHistoryItem(
      id: doc.id,
      packageName: data['packageName'] ?? 'Unknown Package',
      packagePrice: toDouble(data['packagePrice']),
      quantity: toInt(data['quantity']),
      totalAmount: toDouble(data['totalAmount']),
      createdAt: createdAt,
    );
  }
}

class SalesState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final double totalSalesAmount;
  final int totalQuantity;
  final List<SaleHistoryItem> recentSales;

  const SalesState({
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
    required this.successMessage,
    required this.totalSalesAmount,
    required this.totalQuantity,
    required this.recentSales,
  });

  factory SalesState.initial() {
    return const SalesState(
      isLoading: true,
      isSaving: false,
      errorMessage: null,
      successMessage: null,
      totalSalesAmount: 0,
      totalQuantity: 0,
      recentSales: [],
    );
  }

  SalesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    double? totalSalesAmount,
    int? totalQuantity,
    List<SaleHistoryItem>? recentSales,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      totalSalesAmount: totalSalesAmount ?? this.totalSalesAmount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      recentSales: recentSales ?? this.recentSales,
    );
  }
}