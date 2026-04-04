import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/admin_dashboard/admin_dashboard_cubit.dart';
import 'package:wsfm/cubits/admin_dashboard/admin_dashboard_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit()..loadDashboard(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
            builder: (context, state) {
              if (state is AdminDashboardLoading ||
                  state is AdminDashboardInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is AdminDashboardError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final data = state as AdminDashboardLoaded;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopHeader(),
                    const SizedBox(height: 20),

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _SummaryCard(
                          title: 'Total Centers',
                          value: data.totalCenters.toString(),
                          subtitle: 'All registered branches',
                          icon: Icons.wifi_rounded,
                        ),
                        _SummaryCard(
                          title: 'Managers',
                          value: data.totalManagers.toString(),
                          subtitle: 'Active manager accounts',
                          icon: Icons.people_alt_rounded,
                        ),
                        _SummaryCard(
                          title: 'Revenue',
                          value: '\$${data.monthlyRevenue.toStringAsFixed(0)}',
                          subtitle: 'This month',
                          icon: Icons.trending_up_rounded,
                        ),
                        _SummaryCard(
                          title: 'Expenses',
                          value: '\$${data.monthlyExpenses.toStringAsFixed(0)}',
                          subtitle: 'This month',
                          icon: Icons.payments_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _SectionTitle(
                      title: 'Performance Leaderboard',
                      actionText: 'See all',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),

                    ...data.leaderboard.map(
                      (item) => _LeaderboardTile(
                        rank: item['rank'],
                        name: item['name'],
                        location: item['location'],
                        profit: item['profit'].toDouble(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    _SectionTitle(
                      title: 'Monthly Reports',
                      actionText: 'Open reports',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),

                    const _MonthlyReportCard(),

                    const SizedBox(height: 22),

                    _SectionTitle(
                      title: 'Quick Actions',
                      actionText: '',
                      onTap: null,
                    ),
                    const SizedBox(height: 12),

                    const Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Create Center',
                            subtitle: 'Add a new WiFi station',
                            icon: Icons.add_business_rounded,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Add Manager',
                            subtitle: 'Generate manager account',
                            icon: Icons.person_add_alt_1_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _SectionTitle(
                      title: 'Active Centers',
                      actionText: 'Manage',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),

                    ...data.centers.map(
                      (center) => _CenterTile(
                        name: center['name'],
                        location: center['location'],
                        manager: center['manager'],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Monitor centers, compare performance, and manage operations.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF00695C),
          ),
        ),
      ],
    );
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
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (actionText.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFF00695C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final String location;
  final double profit;

  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.location,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0F2F1),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xFF00695C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            '\$${profit.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF00695C),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyReportCard extends StatelessWidget {
  const _MonthlyReportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'April Monthly Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open the monthly report to review revenue, expenses, and center comparisons.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF00695C),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _QuickActionCard({
    required this.title,
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
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterTile extends StatelessWidget {
  final String name;
  final String location;
  final String manager;

  const _CenterTile({
    required this.name,
    required this.location,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE0F2F1),
            child: Icon(Icons.wifi_rounded, color: Color(0xFF00695C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: $location',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manager: $manager',
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}