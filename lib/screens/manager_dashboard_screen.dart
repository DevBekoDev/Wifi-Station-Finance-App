import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/manager_dashboard/manager_dashboard_cubit.dart';
import 'package:wsfm/cubits/manager_dashboard/manager_dashboard_state.dart';
import 'package:wsfm/screens/expenses_screen.dart';
import 'package:wsfm/screens/reports_screen.dart';
import 'package:wsfm/screens/sales_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  final String centerId;

  const ManagerDashboardScreen({
    super.key,
    required this.centerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerDashboardCubit()..loadDashboard(centerId),
      child: const _ManagerDashboardView(),
    );
  }
}

class _ManagerDashboardView extends StatelessWidget {
  const _ManagerDashboardView();

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: BlocBuilder<ManagerDashboardCubit, ManagerDashboardState>(
          builder: (context, state) {
            if (state is ManagerDashboardInitial ||
                state is ManagerDashboardLoading) {
              return const _DashboardLoadingView();
            }

            if (state is ManagerDashboardError) {
              return _DashboardErrorView(
                message: state.message,
                onRetry: () {
                  final screen =
                      context.findAncestorWidgetOfExactType<ManagerDashboardScreen>();
                  if (screen != null) {
                    context.read<ManagerDashboardCubit>().loadDashboard(screen.centerId);
                  }
                },
              );
            }

            final data = state as ManagerDashboardLoaded;
            final screen =
                context.findAncestorWidgetOfExactType<ManagerDashboardScreen>();

            return RefreshIndicator(
              color: const Color(0xFF0B7A75),
              onRefresh: () async {
                if (screen != null) {
                  context.read<ManagerDashboardCubit>().loadDashboard(screen.centerId);
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _DashboardTopBar(
                    centerName: data.centerName,
                    managerName: data.managerName,
                  ),
                  const SizedBox(height: 18),

                  _HeroOverviewCard(
                    centerName: data.centerName,
                    location: data.location,
                    managerName: data.managerName,
                    totalSales: data.totalSales,
                    totalExpenses: data.totalExpenses,
                    profit: data.profit,
                  ),
                  const SizedBox(height: 20),

                  const _SectionTitle(
                    title: 'Today Overview',
                    subtitle: 'A quick look at your center performance',
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.08,
                    children: [
                      _MetricCard(
                        title: 'Sales',
                        value: _formatMoney(data.totalSales),
                        subtitle: '${data.salesCount} sales records',
                        icon: Icons.trending_up_rounded,
                        accent: const Color(0xFF0B7A75),
                        softAccent: const Color(0xFFE8F7F5),
                      ),
                      _MetricCard(
                        title: 'Expenses',
                        value: _formatMoney(data.totalExpenses),
                        subtitle: '${data.expensesCount} expense records',
                        icon: Icons.receipt_long_rounded,
                        accent: const Color(0xFFB45309),
                        softAccent: const Color(0xFFFFF4E5),
                      ),
                      _MetricCard(
                        title: 'Profit',
                        value: _formatMoney(data.profit),
                        subtitle: data.profit >= 0
                            ? 'Healthy balance'
                            : 'Needs attention',
                        icon: Icons.account_balance_wallet_rounded,
                        accent: data.profit >= 0
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFDC2626),
                        softAccent: data.profit >= 0
                            ? const Color(0xFFEAF2FF)
                            : const Color(0xFFFDECEC),
                      ),
                      _MetricCard(
                        title: 'Total Cards',
                        value: data.totalCards.toString(),
                        subtitle: '${data.totalCards} cards in stock',
                        icon: Icons.wifi_rounded,
                        accent: const Color(0xFF7C3AED),
                        softAccent: const Color(0xFFF1EBFF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _InsightBanner(
                    profit: data.profit,
                    totalSales: data.totalSales,
                    totalExpenses: data.totalExpenses,
                  ),
                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'Quick Actions',
                    subtitle: 'Jump directly into your daily tasks',
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.9,
                    children: [
                      _ActionCard(
                        title: 'Sales',
                        subtitle: 'Add and manage center sales',
                        icon: Icons.point_of_sale_rounded,
                        accent: const Color(0xFF0B7A75),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalesScreen(centerId: data.centerId),
                            ),
                          );
                        },
                      ),
                      _ActionCard(
                        title: 'Expenses',
                        subtitle: 'Track daily operating costs',
                        icon: Icons.payments_rounded,
                        accent: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpensesScreen(centerId: data.centerId),
                            ),
                          );
                        },
                      ),
                      _ActionCard(
                        title: 'Reports',
                        subtitle: 'View summaries and analysis',
                        icon: Icons.bar_chart_rounded,
                        accent: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportsScreen(centerId: data.centerId),
                            ),
                          );
                        },
                      ),
                      _ActionCard(
                        title: 'Overview',
                        subtitle: 'Stay updated on center activity',
                        icon: Icons.dashboard_customize_rounded,
                        accent: const Color(0xFF7C3AED),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'Manager Notes',
                    subtitle: 'Helpful reminders for better daily workflow',
                  ),
                  const SizedBox(height: 12),

                  const _NotesCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final String centerName;
  final String managerName;

  const _DashboardTopBar({
    required this.centerName,
    required this.managerName,
  });

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manager Dashboard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome back, $managerName',
                style: const TextStyle(
                  fontSize: 14.5,
                  color: textSoft,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF0F172A),
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _HeroOverviewCard extends StatelessWidget {
  final String centerName;
  final String location;
  final String managerName;
  final double totalSales;
  final double totalExpenses;
  final double profit;

  const _HeroOverviewCard({
    required this.centerName,
    required this.location,
    required this.managerName,
    required this.totalSales,
    required this.totalExpenses,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B7A75);
    const primaryDark = Color(0xFF075E59);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [primaryDark, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_tethering_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Center Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            centerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Location: $location',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manager: $managerName',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroMiniStat(
                  label: 'Sales',
                  value: _formatMoney(totalSales),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Expenses',
                  value: _formatMoney(totalExpenses),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Profit',
                  value: _formatMoney(profit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color softAccent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.softAccent,
  });

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: softAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: textSoft,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textSoft,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: accent,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final double profit;
  final double totalSales;
  final double totalExpenses;

  const _InsightBanner({
    required this.profit,
    required this.totalSales,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final bool good = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: good ? const Color(0xFFEFFAF7) : const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: good ? const Color(0xFFD7F0E7) : const Color(0xFFF5D5D5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                good ? const Color(0xFFDDF4EC) : const Color(0xFFFCE1E1),
            child: Icon(
              good ? Icons.insights_rounded : Icons.warning_amber_rounded,
              color: good ? const Color(0xFF0B7A75) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  good ? 'Performance Insight' : 'Attention Needed',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: good ? const Color(0xFF0F172A) : const Color(0xFF7F1D1D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  good
                      ? 'Your center is currently running with positive profit. Keep monitoring expenses to maintain healthy growth.'
                      : 'Expenses are higher than sales right now. Review recent costs and boost sales activity to recover balance.',
                  style: TextStyle(
                    fontSize: 13.2,
                    color: good ? const Color(0xFF48606A) : const Color(0xFF7F1D1D),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            color: textSoft,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard();

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    final notes = [
      'Check sales and expenses regularly to keep records accurate.',
      'Use reports to quickly review your center performance.',
      'Update new expenses as soon as they happen to avoid missing data.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(notes.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == notes.length - 1 ? 0 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0B7A75),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notes[index],
                    style: const TextStyle(
                      color: textSoft,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0B7A75),
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF0F172A);
    const textSoft = Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFDC2626),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: textSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B7A75),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final bool isNegative = value < 0;
  final String raw = value.abs().toStringAsFixed(0);

  final buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final positionFromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return '${isNegative ? '-' : ''}$buffer';
}