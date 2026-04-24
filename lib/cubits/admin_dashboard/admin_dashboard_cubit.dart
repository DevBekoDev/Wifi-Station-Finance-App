import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit() : super(AdminDashboardInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadDashboard() async {
    emit(AdminDashboardLoading());

    try {
      final centersSnapshot = await _firestore.collection('centers').get();
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get();
      final salesSnapshot = await _firestore.collection('sales').get();
      final expensesSnapshot = await _firestore.collection('expenses').get();

      final now = DateTime.now();

      final int totalCenters = centersSnapshot.docs.length;
      final int totalManagers = usersSnapshot.docs.length;

      double totalSales = 0;
      int totalCardsSold = 0;

      double monthlyRevenue = 0;
      double monthlyExpenses = 0;

      final Map<String, double> monthlySalesByCenter = {};
      final Map<String, double> monthlyExpensesByCenter = {};

      for (final doc in salesSnapshot.docs) {
        final data = doc.data();

        final double amount = _toDouble(data['totalAmount']);
        final int quantity = _toInt(data['quantity'] ?? data['cardsSold']);
        final String centerId = data['centerId'] ?? '';
        final DateTime createdAt = _extractDate(
          data['createdAt'],
          data['date'],
        );

        totalSales += amount;
        totalCardsSold += quantity;

        if (createdAt.year == now.year && createdAt.month == now.month) {
          monthlyRevenue += amount;
          monthlySalesByCenter[centerId] =
              (monthlySalesByCenter[centerId] ?? 0) + amount;
        }
      }

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();

        final double amount = _toDouble(data['amount']);
        final String centerId = data['centerId'] ?? '';
        final DateTime createdAt = _extractDate(
          data['createdAt'],
          data['date'],
        );

        if (createdAt.year == now.year && createdAt.month == now.month) {
          monthlyExpenses += amount;
          monthlyExpensesByCenter[centerId] =
              (monthlyExpensesByCenter[centerId] ?? 0) + amount;
        }
      }

      final List<Map<String, dynamic>> centers = centersSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Center',
          'location': data['location'] ?? 'Unknown Location',
          'manager': data['managerName'] ?? 'No Manager',
        };
      }).toList();

      final List<Map<String, dynamic>> leaderboard = centersSnapshot.docs.map((doc) {
        final data = doc.data();
        final centerId = doc.id;

        final sales = monthlySalesByCenter[centerId] ?? 0;
        final expenses = monthlyExpensesByCenter[centerId] ?? 0;
        final profit = sales - expenses;

        return {
          'id': centerId,
          'name': data['name'] ?? 'Unknown Center',
          'location': data['location'] ?? 'Unknown Location',
          'profit': profit,
        };
      }).toList();

      leaderboard.sort(
        (a, b) => (b['profit'] as double).compareTo(a['profit'] as double),
      );

      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i]['rank'] = i + 1;
      }

      emit(
        AdminDashboardLoaded(
          totalCenters: totalCenters,
          totalManagers: totalManagers,
          monthlyRevenue: monthlyRevenue,
          monthlyExpenses: monthlyExpenses,
          totalSales: totalSales,
          totalCardsSold: totalCardsSold,
          leaderboard: leaderboard,
          centers: centers,
        ),
      );
    } catch (e) {
      emit(AdminDashboardError('Failed to load dashboard.'));
    }
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

  DateTime _extractDate(dynamic createdAt, dynamic fallbackDate) {
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    if (fallbackDate is String) {
      try {
        return DateTime.parse(fallbackDate);
      } catch (_) {}
    }

    return DateTime.now();
  }
}