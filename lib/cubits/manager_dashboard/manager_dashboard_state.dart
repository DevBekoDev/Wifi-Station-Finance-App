abstract class ManagerDashboardState {}

class ManagerDashboardInitial extends ManagerDashboardState {}

class ManagerDashboardLoading extends ManagerDashboardState {}

class ManagerDashboardLoaded extends ManagerDashboardState {
  final String centerId;
  final String centerName;
  final String location;
  final String managerName;
  final double totalSales;
  final double totalExpenses;
  final double profit;
  final int salesCount;
  final int expensesCount;
  final int totalCards;

  ManagerDashboardLoaded({
    required this.centerId,
    required this.centerName,
    required this.location,
    required this.managerName,
    required this.totalSales,
    required this.totalExpenses,
    required this.profit,
    required this.salesCount,
    required this.expensesCount,
    required this.totalCards,
  });
}

class ManagerDashboardError extends ManagerDashboardState {
  final String message;

  ManagerDashboardError(this.message);
}