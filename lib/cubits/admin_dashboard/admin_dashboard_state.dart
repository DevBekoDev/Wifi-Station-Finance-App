abstract class AdminDashboardState {}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final int totalCenters;
  final int totalManagers;
  final double monthlyRevenue;
  final double monthlyExpenses;
  final List<Map<String, dynamic>> leaderboard;
  final List<Map<String, dynamic>> centers;

  AdminDashboardLoaded({
    required this.totalCenters,
    required this.totalManagers,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.leaderboard,
    required this.centers,
  });
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  AdminDashboardError(this.message);
}