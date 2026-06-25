import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_reports_state.dart';

class AdminReportsCubit extends Cubit<AdminReportsState> {
  AdminReportsCubit() : super(AdminReportsInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminReportPeriod _selectedPeriod = AdminReportPeriod.month;

  Future<void> loadReports() async {
    emit(AdminReportsLoading());

    try {
      final centersSnapshot = await _firestore.collection('centers').get();
      final salesSnapshot = await _firestore.collection('sales').get();
      final expensesSnapshot = await _firestore.collection('expenses').get();

      final centersDocs = centersSnapshot.docs;
      final salesDocs = salesSnapshot.docs;
      final expensesDocs = expensesSnapshot.docs;

      final filteredSales = salesDocs.where((doc) {
        final data = doc.data();
        final createdAt = _extractDate(data['createdAt'], data['date']);
        return _matchesPeriod(createdAt);
      }).toList();

      final filteredExpenses = expensesDocs.where((doc) {
        final data = doc.data();
        final createdAt = _extractDate(data['createdAt'], data['date']);
        return _matchesPeriod(createdAt);
      }).toList();

      final Map<String, double> salesByCenter = {};
      final Map<String, double> expensesByCenter = {};
      final Map<String, int> salesCountByCenter = {};
      final Map<String, int> expenseCountByCenter = {};
      final List<AdminReportRow> allRecords = [];

      int totalCardsSold = 0;

      for (final doc in filteredSales) {
        final data = doc.data();
        final centerId = data['centerId'] ?? '';
        final amount = _toDouble(data['totalAmount']);
        final quantity = _toInt(data['quantity'] ?? data['cardsSold']);
        final date = _extractDate(data['createdAt'], data['date']);

        salesByCenter[centerId] = (salesByCenter[centerId] ?? 0) + amount;
        salesCountByCenter[centerId] = (salesCountByCenter[centerId] ?? 0) + 1;
        totalCardsSold += quantity;

        allRecords.add(
          AdminReportRow(
            id: doc.id,
            centerId: centerId,
            centerName: '',
            createdAt: date,
            type: 'Sale',
            itemName: data['packageName'] ?? 'Unknown Package',
            quantity: quantity,
            amount: amount,
            description: '-',
          ),
        );
      }

      for (final doc in filteredExpenses) {
        final data = doc.data();
        final centerId = data['centerId'] ?? '';
        final amount = _toDouble(data['amount']);
        final date = _extractDate(data['createdAt'], data['date']);

        expensesByCenter[centerId] = (expensesByCenter[centerId] ?? 0) + amount;
        expenseCountByCenter[centerId] =
            (expenseCountByCenter[centerId] ?? 0) + 1;

        allRecords.add(
          AdminReportRow(
            id: doc.id,
            centerId: centerId,
            centerName: '',
            createdAt: date,
            type: 'Expense',
            itemName: data['category'] ?? 'Unknown',
            quantity: null,
            amount: amount,
            description: data['description'] ?? '',
          ),
        );
      }

      final List<AdminCenterReportItem> centerReports = [];
      double totalSales = 0;
      double totalExpenses = 0;

      final Map<String, String> centerNames = {};

      for (final doc in centersDocs) {
        final data = doc.data();
        final centerId = doc.id;
        final centerName = data['name'] ?? 'Unknown Center';
        final location = data['location'] ?? 'Unknown Location';
        final managerName = data['managerName'] ?? 'No Manager';

        centerNames[centerId] = centerName;

        final sales = salesByCenter[centerId] ?? 0;
        final expenses = expensesByCenter[centerId] ?? 0;
        final profit = sales - expenses;

        totalSales += sales;
        totalExpenses += expenses;

        centerReports.add(
          AdminCenterReportItem(
            centerId: centerId,
            centerName: centerName,
            location: location,
            managerName: managerName,
            sales: sales,
            expenses: expenses,
            profit: profit,
            salesCount: salesCountByCenter[centerId] ?? 0,
            expenseCount: expenseCountByCenter[centerId] ?? 0,
          ),
        );
      }

      final recordsWithNames = allRecords
          .map(
            (row) => AdminReportRow(
              id: row.id,
              centerId: row.centerId,
              centerName: centerNames[row.centerId] ?? 'Unknown Center',
              createdAt: row.createdAt,
              type: row.type,
              itemName: row.itemName,
              quantity: row.quantity,
              amount: row.amount,
              description: row.description,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      centerReports.sort((a, b) => b.profit.compareTo(a.profit));

      emit(
        AdminReportsLoaded(
          selectedPeriod: _selectedPeriod,
          totalSales: totalSales,
          totalExpenses: totalExpenses,
          totalProfit: totalSales - totalExpenses,
          totalCenters: centerReports.length,
          totalCardsSold: totalCardsSold,
          centers: centerReports,
          records: recordsWithNames,
        ),
      );
    } catch (e) {
      emit(AdminReportsError('Failed to load admin reports.'));
    }
  }

  Future<void> changePeriod(AdminReportPeriod period) async {
    _selectedPeriod = period;
    await loadReports();
  }

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case AdminReportPeriod.all:
        return true;
      case AdminReportPeriod.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case AdminReportPeriod.week:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return !date.isBefore(startOfWeek);
      case AdminReportPeriod.month:
        return date.year == now.year && date.month == now.month;
    }
  }

  DateTime _extractDate(dynamic createdAt, dynamic fallbackDate) {
    if (createdAt is Timestamp) return createdAt.toDate();

    if (fallbackDate is String) {
      try {
        return DateTime.parse(fallbackDate);
      } catch (_) {}
    }

    return DateTime.now();
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}