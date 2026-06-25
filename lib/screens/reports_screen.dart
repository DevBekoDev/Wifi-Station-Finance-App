import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wsfm/cubits/reports/reports_cubit.dart';
import 'package:wsfm/cubits/reports/reports_state.dart';
import 'package:wsfm/services/report_export_service.dart';

class ReportsScreen extends StatelessWidget {
  final String centerId;

  const ReportsScreen({
    super.key,
    required this.centerId,
  });

  Future<void> _exportCsv(
    BuildContext context,
    ReportsLoaded data,
  ) async {
    try {
      final file = await ReportExportService().exportCenterReportCsv(
        centerName: data.centerName,
        rows: data.filteredRecords,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exported report for ${data.centerName}',
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
      create: (_) => ReportsCubit()..loadReport(centerId),
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FB),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF0F172A),
              title: const Text(
                'Center Report',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (state is ReportsLoaded)
                  IconButton(
                    tooltip: 'Export CSV',
                    onPressed: state.filteredRecords.isEmpty
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

  Widget _buildBody(BuildContext context, ReportsState state) {
    if (state is ReportsInitial || state is ReportsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ReportsError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final data = state as ReportsLoaded;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReportsCubit>().loadReport(centerId);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Center Report",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.centerName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Location: ${data.location}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.22,
            children: [
              _SummaryCard(
                title: 'Sales',
                value: data.totalSales.toStringAsFixed(0),
                subtitle: 'Filtered income',
                icon: Icons.trending_up_rounded,
              ),
              _SummaryCard(
                title: 'Expenses',
                value: data.totalExpenses.toStringAsFixed(0),
                subtitle: 'Filtered costs',
                icon: Icons.payments_rounded,
              ),
              _SummaryCard(
                title: 'Profit',
                value: data.profit.toStringAsFixed(0),
                subtitle: 'Sales - Expenses',
                icon: Icons.account_balance_wallet_rounded,
              ),
              _SummaryCard(
                title: 'Cards Sold',
                value: data.totalCardsSold.toString(),
                subtitle: 'Filtered quantity',
                icon: Icons.confirmation_number_rounded,
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _InsightCard(
                  title: 'Best Selling Package',
                  value: data.bestSellingPackage,
                  subtitle: data.bestSellingPackageQty > 0
                      ? '${data.bestSellingPackageQty} sold'
                      : 'No sales yet',
                  icon: Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightCard(
                  title: 'Biggest Expense',
                  value: data.biggestExpenseCategory,
                  subtitle: data.biggestExpenseAmount > 0
                      ? data.biggestExpenseAmount.toStringAsFixed(0)
                      : 'No expenses yet',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ReportPeriodFilter>(
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
                      value: ReportPeriodFilter.all,
                      child: Text('All Time'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriodFilter.today,
                      child: Text('Today'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriodFilter.week,
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriodFilter.month,
                      child: Text('This Month'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ReportsCubit>().changePeriod(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<ReportTypeFilter>(
                  value: data.selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ReportTypeFilter.all,
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: ReportTypeFilter.sales,
                      child: Text('Sales'),
                    ),
                    DropdownMenuItem(
                      value: ReportTypeFilter.expenses,
                      child: Text('Expenses'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ReportsCubit>().changeType(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${data.filteredRecords.length} rows',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (data.filteredRecords.isEmpty)
            const _EmptyCard(text: 'No data found for the selected filters.')
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
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Description')),
                  ],
                  rows: data.filteredRecords.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_formatDate(row.createdAt))),
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
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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
      padding: const EdgeInsets.all(10),
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
          const Spacer(),
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
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
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}