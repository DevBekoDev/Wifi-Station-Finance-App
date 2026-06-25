import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'manager_dashboard_state.dart';

class ManagerDashboardCubit extends Cubit<ManagerDashboardState> {
  ManagerDashboardCubit() : super(ManagerDashboardInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadDashboard(String centerId) async {
    emit(ManagerDashboardLoading());

    try {
      final centerDoc =
          await _firestore.collection('centers').doc(centerId).get();

      if (!centerDoc.exists) {
        emit(ManagerDashboardError("Center not found."));
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

      double totalSales = 0;
      for (final doc in salesSnapshot.docs) {
        final data = doc.data();
        final value = data['totalAmount'];
        if (value is int) {
          totalSales += value.toDouble();
        } else if (value is double) {
          totalSales += value;
        }
      }

      double totalExpenses = 0;
      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        final value = data['amount'];
        if (value is int) {
          totalExpenses += value.toDouble();
        } else if (value is double) {
          totalExpenses += value;
        }
      }

      emit(
        ManagerDashboardLoaded(
          centerId: centerId,
          centerName: centerData['name'] ?? 'My Center',
          location: centerData['location'] ?? 'Unknown Location',
          managerName: centerData['managerName'] ?? 'Manager',
          totalSales: totalSales,
          totalExpenses: totalExpenses,
          profit: totalSales - totalExpenses,
          salesCount: salesSnapshot.docs.length,
          expensesCount: expensesSnapshot.docs.length,
          totalCards: centerData['totalCards'] ?? 0,
        ),
      );
    } catch (e) {
      emit(ManagerDashboardError("Failed to load dashboard."));
    }
  }
}