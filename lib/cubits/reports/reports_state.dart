enum ReportPeriodFilter { all, today, week, month }

enum ReportTypeFilter { all, sales, expenses }

class ReportRecordRow {
  final String id;
  final DateTime createdAt;
  final String type; // Sale / Expense
  final String itemName; // packageName or category
  final int? quantity;
  final double amount;
  final String description;

  const ReportRecordRow({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.itemName,
    required this.quantity,
    required this.amount,
    required this.description,
  });
}

abstract class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final String centerId;
  final String centerName;
  final String location;

  final ReportPeriodFilter selectedPeriod;
  final ReportTypeFilter selectedType;

  final List<ReportRecordRow> allRecords;
  final List<ReportRecordRow> filteredRecords;

  final double totalSales;
  final double totalExpenses;
  final double profit;
  final int totalCardsSold;

  final String bestSellingPackage;
  final int bestSellingPackageQty;

  final String biggestExpenseCategory;
  final double biggestExpenseAmount;

  ReportsLoaded({
    required this.centerId,
    required this.centerName,
    required this.location,
    required this.selectedPeriod,
    required this.selectedType,
    required this.allRecords,
    required this.filteredRecords,
    required this.totalSales,
    required this.totalExpenses,
    required this.profit,
    required this.totalCardsSold,
    required this.bestSellingPackage,
    required this.bestSellingPackageQty,
    required this.biggestExpenseCategory,
    required this.biggestExpenseAmount,
  });
}

class ReportsError extends ReportsState {
  final String message;

  ReportsError(this.message);
}