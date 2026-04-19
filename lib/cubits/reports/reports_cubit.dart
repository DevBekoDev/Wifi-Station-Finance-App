import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit() : super(ReportsInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _centerId = '';
  String _centerName = '';
  String _location = '';

  List<ReportRecordRow> _allRecords = [];

  ReportPeriodFilter _selectedPeriod = ReportPeriodFilter.all;
  ReportTypeFilter _selectedType = ReportTypeFilter.all;

  Future<void> loadReport(String centerId) async {
    emit(ReportsLoading());

    try {
      final centerDoc =
          await _firestore.collection('centers').doc(centerId).get();

      if (!centerDoc.exists) {
        emit(ReportsError("Center not found."));
        return;
      }

      final centerData = centerDoc.data() as Map<String, dynamic>;

      final salesSnapshot = await _firestore
          .collection('sales')
          .where('centerId', isEqualTo: centerId)
          .get();

      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('centerId', isEqualTo: centerId)
          .get();

      _centerId = centerId;
      _centerName = centerData['name'] ?? 'My Center';
      _location = centerData['location'] ?? 'Unknown Location';

      _allRecords = [
        ...salesSnapshot.docs.map((doc) {
          final data = doc.data();

          int toInt(dynamic value) {
            if (value is int) return value;
            return int.tryParse(value?.toString() ?? '0') ?? 0;
          }

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

          return ReportRecordRow(
            id: doc.id,
            createdAt: createdAt,
            type: 'Sale',
            itemName: data['packageName'] ?? 'Unknown Package',
            quantity: toInt(data['quantity']),
            amount: toDouble(data['totalAmount']),
            description: '-',
          );
        }),
        ...expensesSnapshot.docs.map((doc) {
          final data = doc.data();

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

          return ReportRecordRow(
            id: doc.id,
            createdAt: createdAt,
            type: 'Expense',
            itemName: data['category'] ?? 'Unknown',
            quantity: null,
            amount: toDouble(data['amount']),
            description: data['description'] ?? '',
          );
        }),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _selectedPeriod = ReportPeriodFilter.all;
      _selectedType = ReportTypeFilter.all;

      _emitLoaded();
    } catch (e) {
      emit(ReportsError("Failed to load report."));
    }
  }

  void changePeriod(ReportPeriodFilter period) {
    _selectedPeriod = period;
    _emitLoaded();
  }

  void changeType(ReportTypeFilter type) {
    _selectedType = type;
    _emitLoaded();
  }

  void _emitLoaded() {
    final filtered = _applyFilters(_allRecords);

    double totalSales = 0;
    double totalExpenses = 0;
    int totalCardsSold = 0;

    final Map<String, int> packageCountMap = {};
    final Map<String, double> expenseCategoryMap = {};

    for (final row in filtered) {
      if (row.type == 'Sale') {
        totalSales += row.amount;
        totalCardsSold += row.quantity ?? 0;
        packageCountMap[row.itemName] =
            (packageCountMap[row.itemName] ?? 0) + (row.quantity ?? 0);
      } else {
        totalExpenses += row.amount;
        expenseCategoryMap[row.itemName] =
            (expenseCategoryMap[row.itemName] ?? 0) + row.amount;
      }
    }

    String bestSellingPackage = 'No Sales';
    int bestSellingPackageQty = 0;
    packageCountMap.forEach((key, value) {
      if (value > bestSellingPackageQty) {
        bestSellingPackage = key;
        bestSellingPackageQty = value;
      }
    });

    String biggestExpenseCategory = 'No Expenses';
    double biggestExpenseAmount = 0;
    expenseCategoryMap.forEach((key, value) {
      if (value > biggestExpenseAmount) {
        biggestExpenseCategory = key;
        biggestExpenseAmount = value;
      }
    });

    emit(
      ReportsLoaded(
        centerId: _centerId,
        centerName: _centerName,
        location: _location,
        selectedPeriod: _selectedPeriod,
        selectedType: _selectedType,
        allRecords: _allRecords,
        filteredRecords: filtered,
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        profit: totalSales - totalExpenses,
        totalCardsSold: totalCardsSold,
        bestSellingPackage: bestSellingPackage,
        bestSellingPackageQty: bestSellingPackageQty,
        biggestExpenseCategory: biggestExpenseCategory,
        biggestExpenseAmount: biggestExpenseAmount,
      ),
    );
  }

  List<ReportRecordRow> _applyFilters(List<ReportRecordRow> rows) {
    final now = DateTime.now();

    return rows.where((row) {
      final typeMatch = switch (_selectedType) {
        ReportTypeFilter.all => true,
        ReportTypeFilter.sales => row.type == 'Sale',
        ReportTypeFilter.expenses => row.type == 'Expense',
      };

      final periodMatch = switch (_selectedPeriod) {
        ReportPeriodFilter.all => true,
        ReportPeriodFilter.today => _isSameDay(row.createdAt, now),
        ReportPeriodFilter.week => row.createdAt.isAfter(
            _startOfWeek(now).subtract(const Duration(seconds: 1))),
        ReportPeriodFilter.month => row.createdAt.isAfter(
            _startOfMonth(now).subtract(const Duration(seconds: 1))),
      };

      return typeMatch && periodMatch;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  DateTime _startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
}