import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wsfm/cubits/admin_reports/admin_reports_cubit.dart';
import 'package:wsfm/cubits/admin_reports/admin_reports_state.dart';
import 'package:wsfm/services/admin_report_export_servive.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<void> _exportCsv(BuildContext context, AdminReportsLoaded data) async {
    try {
      final file = await AdminReportExportService().exportAdminReportCsv(
        rows: data.records,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Admin report export',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminReportsCubit()..loadReports(),
      child: BlocBuilder<AdminReportsCubit, AdminReportsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FB),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF0F172A),
              title: const Text(
                'Admin Reports',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (state is AdminReportsLoaded)
                  IconButton(
                    tooltip: 'Download CSV',
                    onPressed: state.records.isEmpty
                        ? null
                        : () => _exportCsv(context, state),
                    icon: const Icon(Icons.download_rounded),
                  ),
              ],
            ),
            body: SafeArea(
              child: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminReportsState state) {
    if (state is AdminReportsInitial || state is AdminReportsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AdminReportsError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final data = state as AdminReportsLoaded;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<AdminReportsCubit>().loadReports();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF00897B)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Monitor all centers, revenue, expenses, and profit performance.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<AdminReportPeriod>(
            value: data.selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Period',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: AdminReportPeriod.all,
                child: Text('All Time'),
              ),
              DropdownMenuItem(
                value: AdminReportPeriod.today,
                child: Text('Today'),
              ),
              DropdownMenuItem(
                value: AdminReportPeriod.week,
                child: Text('This Week'),
              ),
              DropdownMenuItem(
                value: AdminReportPeriod.month,
                child: Text('This Month'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                context.read<AdminReportsCubit>().changePeriod(value);
              }
            },
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              _SummaryCard(
                title: 'Centers',
                value: data.totalCenters.toString(),
                subtitle: 'Active centers',
                icon: Icons.wifi_rounded,
              ),
              _SummaryCard(
                title: 'Revenue',
                value: data.totalSales.toStringAsFixed(0),
                subtitle: 'Filtered sales',
                icon: Icons.trending_up_rounded,
              ),
              _SummaryCard(
                title: 'Expenses',
                value: data.totalExpenses.toStringAsFixed(0),
                subtitle: 'Filtered expenses',
                icon: Icons.payments_rounded,
              ),
              _SummaryCard(
                title: 'Profit',
                value: data.totalProfit.toStringAsFixed(0),
                subtitle: 'Revenue - Expenses',
                icon: Icons.account_balance_wallet_rounded,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Center Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          ...data.centers.map(
            (center) => _CenterPerformanceCard(center: center),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Records',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${data.records.length} rows',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (data.records.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'No records found for this period.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 22,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Center')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Description')),
                  ],
                  rows: data.records.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatDate(row.createdAt))),
                        DataCell(Text(row.centerName)),
                        DataCell(Text(row.type)),
                        DataCell(Text(row.itemName)),
                        DataCell(Text(row.quantity?.toString() ?? '-')),
                        DataCell(Text(row.amount.toStringAsFixed(0))),
                        DataCell(Text(row.description)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0F2F1),
            child: Icon(icon, color: const Color(0xFF00695C)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterPerformanceCard extends StatelessWidget {
  final AdminCenterReportItem center;

  const _CenterPerformanceCard({
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            center.centerName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Location: ${center.location}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            'Manager: ${center.managerName}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Sales: ${center.sales.toStringAsFixed(0)}'),
              Text('Expenses: ${center.expenses.toStringAsFixed(0)}'),
              Text('Profit: ${center.profit.toStringAsFixed(0)}'),
              Text('Sales rows: ${center.salesCount}'),
              Text('Expense rows: ${center.expenseCount}'),
            ],
          ),
        ],
      ),
    );
  }
}