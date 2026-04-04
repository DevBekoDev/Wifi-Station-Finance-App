import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit() : super(AdminDashboardInitial());

  Future<void> loadDashboard() async {
    emit(AdminDashboardLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      emit(
        AdminDashboardLoaded(
          totalCenters: 12,
          totalManagers: 12,
          monthlyRevenue: 18500,
          monthlyExpenses: 6200,
          leaderboard: [
            {
              'name': 'WiFi Kadikoy',
              'location': 'Istanbul',
              'profit': 4200,
              'rank': 1,
            },
            {
              'name': 'WiFi Taksim',
              'location': 'Istanbul',
              'profit': 3900,
              'rank': 2,
            },
            {
              'name': 'WiFi Ankara 1',
              'location': 'Ankara',
              'profit': 3150,
              'rank': 3,
            },
          ],
          centers: [
            {
              'name': 'WiFi Kadikoy',
              'location': 'Istanbul',
              'manager': 'Ahmet',
            },
            {
              'name': 'WiFi Taksim',
              'location': 'Istanbul',
              'manager': 'Merve',
            },
            {
              'name': 'WiFi Ankara 1',
              'location': 'Ankara',
              'manager': 'Yusuf',
            },
            {
              'name': 'WiFi Bursa',
              'location': 'Bursa',
              'manager': 'Ece',
            },
          ],
        ),
      );
    } catch (e) {
      emit(AdminDashboardError('Failed to load dashboard.'));
    }
  }
}