enum AdminReportPeriod { all, today, week, month }

class AdminCenterReportItem {
  final String centerId;
  final String centerName;
  final String location;
  final String managerName;
  final double sales;
  final double expenses;
  final double profit;
  final int salesCount;
  final int expenseCount;

  const AdminCenterReportItem({
    required this.centerId,
    required this.centerName,
    required this.location,
    required this.managerName,
    required this.sales,
    required this.expenses,
    required this.profit,
    required this.salesCount,
    required this.expenseCount,
  });
}

class AdminRecordRow {
  final String id;
  final String centerId;
  final String centerName;
  final DateTime createdAt;
  final String type; // Sale / Expense
  final String itemName;
  final int? quantity;
  final double amount;
  final String description;

  const AdminRecordRow({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.createdAt,
    required this.type,
    required this.itemName,
    required this.quantity,
    required this.amount,
    required this.description,
  });
}

abstract class AdminReportsState {}

class AdminReportsInitial extends AdminReportsState {}

class AdminReportsLoading extends AdminReportsState {}

class AdminReportsLoaded extends AdminReportsState {
  final AdminReportPeriod selectedPeriod;
  final double totalSales;
  final double totalExpenses;
  final double totalProfit;
  final int totalCenters;
  final List<AdminCenterReportItem> centers;
  final List<AdminRecordRow> records;

  AdminReportsLoaded({
    required this.selectedPeriod,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalProfit,
    required this.totalCenters,
    required this.centers,
    required this.records,
  });
}

class AdminReportsError extends AdminReportsState {
  final String message;

  AdminReportsError(this.message);
}