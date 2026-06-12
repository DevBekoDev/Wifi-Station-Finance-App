import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.totalSales,
    required this.totalExpenses,
    required this.cardsSold,
    required this.salesCount,
    required this.expensesCount,
  });

  final double totalSales;
  final double totalExpenses;
  final int cardsSold;
  final int salesCount;
  final int expensesCount;

  double get profit => totalSales - totalExpenses;

  String get profitStatus {
    if (profit > 0) return 'profit';
    if (profit < 0) return 'loss';
    return 'break-even';
  }

  String toAiText({
    required String title,
  }) {
    return '''
$title:
- Total sales: $totalSales
- Total expenses: $totalExpenses
- Profit: $profit
- Profit status: $profitStatus
- Cards sold: $cardsSold
- Sales records count: $salesCount
- Expenses records count: $expensesCount
''';
  }
}

class FinanceAiContextService {
  FinanceAiContextService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String salesCollection = 'sales';
  static const String expensesCollection = 'expenses';

  static const String centerIdField = 'centerId';
  static const String createdAtField = 'createdAt';

  static const String saleAmountField = 'totalAmount';
  static const String quantityField = 'quantity';

  static const String expenseAmountField = 'amount';

  Future<String> buildAiFinanceContext({
    required String centerId,
  }) async {
    if (centerId.trim().isEmpty) {
      return '''
Finance data status:
- No centerId was provided.
- The assistant cannot read center finance data.
''';
    }

    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final todaySummary = await getSummary(
      centerId: centerId,
      startDate: todayStart,
      endDate: tomorrowStart,
    );

    final monthSummary = await getSummary(
      centerId: centerId,
      startDate: monthStart,
      endDate: nextMonthStart,
    );

    final allTimeSummary = await getSummary(
      centerId: centerId,
    );

    return '''
Real WSFM finance context:

Center ID:
$centerId

${todaySummary.toAiText(title: 'Today summary')}

${monthSummary.toAiText(title: 'This month summary')}

${allTimeSummary.toAiText(title: 'All time summary')}

AI rules:
- Use only the finance numbers above.
- Do not invent missing sales, expenses, profit, or card data.
- Profit formula: profit = total sales - total expenses.
- If the user asks for all centers summary and does not mention today, this month, or a specific date, use All time all centers summary.
- If the user asks about recent activity, use Last 90 days all centers summary.
- If the user asks about today, use Today all centers summary.
- If the user asks about this month, use This month all centers summary.
''';
  }

  Future<FinanceSummary> getSummary({
    required String centerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final salesSnapshot = await _salesQuery(
      centerId: centerId,
      startDate: startDate,
      endDate: endDate,
    ).get();

    final expensesSnapshot = await _expensesQuery(
      centerId: centerId,
      startDate: startDate,
      endDate: endDate,
    ).get();

    double totalSales = 0;
    double totalExpenses = 0;
    int cardsSold = 0;

    for (final doc in salesSnapshot.docs) {
      final data = doc.data();

      totalSales += _toDouble(data[saleAmountField]);
      cardsSold += _toInt(data[quantityField]);
    }

    for (final doc in expensesSnapshot.docs) {
      final data = doc.data();

      totalExpenses += _toDouble(data[expenseAmountField]);
    }

    return FinanceSummary(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      cardsSold: cardsSold,
      salesCount: salesSnapshot.docs.length,
      expensesCount: expensesSnapshot.docs.length,
    );
  }
Future<String> buildAdminFinanceContext() async {
  final now = DateTime.now();

  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));

  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonthStart = DateTime(now.year, now.month + 1, 1);

  final todaySummary = await getAdminSummary(
    startDate: todayStart,
    endDate: tomorrowStart,
  );

  final monthSummary = await getAdminSummary(
    startDate: monthStart,
    endDate: nextMonthStart,
  );

  final allTimeSummary = await getAdminSummary();

  return '''
Real WSFM admin finance context:

Scope:
All centers

${todaySummary.toAiText(title: 'Today all centers summary')}

${monthSummary.toAiText(title: 'This month all centers summary')}

${allTimeSummary.toAiText(title: 'All time all centers summary')}

AI rules:
- Use only the finance numbers above.
- Do not invent missing sales, expenses, profit, or card data.
- Profit formula: profit = total sales - total expenses.
- If the user asks about today, use Today all centers summary.
- If the user asks about this month, use This month all centers summary.
- If the user does not specify a period, use This month all centers summary first.
''';
}
Future<FinanceSummary> getAdminSummary({
  DateTime? startDate,
  DateTime? endDate,
}) async {
  Query<Map<String, dynamic>> salesQuery =
      _firestore.collection(salesCollection);

  Query<Map<String, dynamic>> expensesQuery =
      _firestore.collection(expensesCollection);

  if (startDate != null) {
    salesQuery = salesQuery.where(
      createdAtField,
      isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
    );

    expensesQuery = expensesQuery.where(
      createdAtField,
      isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
    );
  }

  if (endDate != null) {
    salesQuery = salesQuery.where(
      createdAtField,
      isLessThan: Timestamp.fromDate(endDate),
    );

    expensesQuery = expensesQuery.where(
      createdAtField,
      isLessThan: Timestamp.fromDate(endDate),
    );
  }

  final salesSnapshot = await salesQuery.get();
  final expensesSnapshot = await expensesQuery.get();

  double totalSales = 0;
  double totalExpenses = 0;
  int cardsSold = 0;

  for (final doc in salesSnapshot.docs) {
    final data = doc.data();

    totalSales += _toDouble(data[saleAmountField]);
    cardsSold += _toInt(data[quantityField]);
  }

  for (final doc in expensesSnapshot.docs) {
    final data = doc.data();

    totalExpenses += _toDouble(data[expenseAmountField]);
  }

  return FinanceSummary(
    totalSales: totalSales,
    totalExpenses: totalExpenses,
    cardsSold: cardsSold,
    salesCount: salesSnapshot.docs.length,
    expensesCount: expensesSnapshot.docs.length,
  );
}
  Query<Map<String, dynamic>> _salesQuery({
    required String centerId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(salesCollection)
        .where(centerIdField, isEqualTo: centerId);

    if (startDate != null) {
      query = query.where(
        createdAtField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        createdAtField,
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    return query;
  }

  Query<Map<String, dynamic>> _expensesQuery({
    required String centerId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(expensesCollection)
        .where(centerIdField, isEqualTo: centerId);

    if (startDate != null) {
      query = query.where(
        createdAtField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        createdAtField,
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    return query;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}