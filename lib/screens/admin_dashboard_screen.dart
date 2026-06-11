import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/admin_dashboard/admin_dashboard_cubit.dart';
import 'package:wsfm/cubits/admin_dashboard/admin_dashboard_state.dart';
import 'package:wsfm/services/admin_report_export_serviVe.dart';
import 'package:wsfm/screens/create_center_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wsfm/screens/admin_center_edit.dart';
import 'package:wsfm/screens/admin_reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit()..loadDashboard(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashColors.pageBg,
      body: SafeArea(
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            if (state is AdminDashboardLoading ||
                state is AdminDashboardInitial) {
              return const _DashboardLoadingView();
            }

            if (state is AdminDashboardError) {
              return _DashboardErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<AdminDashboardCubit>().loadDashboard(),
              );
            }

            final data = state as AdminDashboardLoaded;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final summaryCrossAxisCount = width >= 1100
                    ? 4
                    : width >= 700
                    ? 2
                    : 2;

                return RefreshIndicator(
                  color: _DashColors.primary,
                  onRefresh: () async {
                    context.read<AdminDashboardCubit>().loadDashboard();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 400),
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeroHeader(
                              onRefresh: () {
                                context
                                    .read<AdminDashboardCubit>()
                                    .loadDashboard();
                              },
                            ),
                            const SizedBox(height: 20),

                            GridView.count(
                              crossAxisCount: summaryCrossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: width >= 1100 ? 1.45 : .9,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _SummaryCard(
                                  title: 'Total Sales',
                                  value:
                                      '\$${data.totalSales.toStringAsFixed(0)}',
                                  subtitle: 'All sales amount',
                                  icon: Icons.point_of_sale_rounded,
                                  accent: _DashColors.blue,
                                ),
                                _SummaryCard(
                                  title: 'Cards Sold',
                                  value: data.totalCardsSold.toString(),
                                  subtitle: 'Total quantity sold',
                                  icon: Icons.confirmation_number_rounded,
                                  accent: _DashColors.primary,
                                ),

                                // _SummaryCard(
                                //   title: 'Total Centers',
                                //   value: data.totalCenters.toString(),
                                //   subtitle: 'All registered branches',
                                //   icon: Icons.wifi_rounded,
                                //   accent: _DashColors.primary,
                                // ),
                                // _SummaryCard(
                                //   title: 'Managers',
                                //   value: data.totalManagers.toString(),
                                //   subtitle: 'Active manager accounts',
                                //   icon: Icons.people_alt_rounded,
                                //   accent: _DashColors.blue,
                                // ),
                                _SummaryCard(
                                  title: 'Revenue',
                                  value:
                                      '\$${data.monthlyRevenue.toStringAsFixed(0)}',
                                  subtitle: 'This month',
                                  icon: Icons.trending_up_rounded,
                                  accent: _DashColors.success,
                                ),
                                _SummaryCard(
                                  title: 'Expenses',
                                  value:
                                      '\$${data.monthlyExpenses.toStringAsFixed(0)}',
                                  subtitle: 'This month',
                                  icon: Icons.payments_rounded,
                                  accent: _DashColors.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            _SectionHeader(
                              title: 'Monthly Reports',
                              subtitle:
                                  'Open the latest admin reports and review the monthly financial picture.',
                              actionText: 'Open reports',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminReportsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            const _MonthlyReportHero(),
                            const SizedBox(height: 22),

                            const _SectionHeader(
                              title: 'Quick Actions',
                              subtitle:
                                  'Use these shortcuts to speed up daily admin work.',
                            ),
                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: width >= 900
                                      ? (1180 - 12) / 2
                                      : double.infinity,
                                  child: _QuickActionCard(
                                    title: 'Create Center',
                                    subtitle:
                                        'Add a new WiFi station and start assigning operations.',
                                    icon: Icons.add_business_rounded,
                                    accent: _DashColors.primary,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateCenterScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: width >= 900
                                      ? (1180 - 12) / 2
                                      : double.infinity,
                                  child: const _QuickActionCard(
                                    title: 'More Tools Soon',
                                    subtitle:
                                        'This area is ready for manager creation, comparisons, or assistant tools.',
                                    icon: Icons.auto_awesome_rounded,
                                    accent: _DashColors.blue,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            _SectionHeader(
                              title: 'Active Centers',
                              subtitle:
                                  'Recently created centers with manager assignment details.',
                              actionText: 'Refresh',
                              onTap: () {},
                              trailing: _SmallBadge(
                                label: '${data.totalCenters} centers',
                              ),
                            ),
                            const SizedBox(height: 12),

                            _CentersContainer(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('centers')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 32,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return const _EmptyStateCard(
                                      icon: Icons.error_outline_rounded,
                                      title: 'Failed to load centers',
                                      subtitle: 'Please try again in a moment.',
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const _EmptyStateCard(
                                      icon: Icons.wifi_off_rounded,
                                      title: 'No centers found',
                                      subtitle:
                                          'Create your first center to start managing operations.',
                                    );
                                  }

                                  final docs = snapshot.data!.docs;

                                  return Column(
                                    children: List.generate(docs.length, (
                                      index,
                                    ) {
                                      final doc = docs[index];
                                      final data =
                                          doc.data() as Map<String, dynamic>;

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index == docs.length - 1
                                              ? 0
                                              : 12,
                                        ),
                                        child: _CenterTile(
                                          name:
                                              data['name'] ?? 'Unknown Center',
                                          location:
                                              data['location'] ??
                                              'Unknown Location',
                                          manager:
                                              data['managerName'] ??
                                              'No Manager',
                                          centerId: doc.id,
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DashColors {
  static const pageBg = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const primary = Color(0xFF0B6E63);
  static const primarySoft = Color(0xFFE7F5F2);
  static const primaryDark = Color(0xFF084C44);
  static const blue = Color(0xFF2F6FED);
  static const blueSoft = Color(0xFFEAF1FF);
  static const success = Color(0xFF159A5B);
  static const successSoft = Color(0xFFEAF8F0);
  static const warning = Color(0xFFE28A12);
  static const warningSoft = Color(0xFFFFF3E3);
  static const title = Color(0xFF0F172A);
  static const body = Color(0xFF475569);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE8EEF5);
}

class _TopHeroHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _TopHeroHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DashColors.primaryDark, _DashColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: _DashColors.primary.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: _GlowBlob(size: 120, color: Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -30,
            left: -25,
            child: _GlowBlob(size: 90, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ADMIN PANEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: onRefresh,
                  ),
                  const SizedBox(width: 10),
                  const _CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor centers, compare finances, manage operations, and jump quickly into the tools you use most.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroChip(
                    icon: Icons.wifi_tethering_rounded,
                    label: 'Centers',
                  ),
                  _HeroChip(icon: Icons.analytics_outlined, label: 'Reports'),
                  _HeroChip(
                    icon: Icons.people_outline_rounded,
                    label: 'Managers',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Icon(icon, color: Colors.white),
    );

    if (onTap == null) return button;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: button,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  Color get softColor {
    if (accent == _DashColors.success) return _DashColors.successSoft;
    if (accent == _DashColors.warning) return _DashColors.warningSoft;
    if (accent == _DashColors.blue) return _DashColors.blueSoft;
    return _DashColors.primarySoft;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _DashColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _DashColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _DashColors.title,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _DashColors.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: _DashColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionText,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: subtitle == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _DashColors.title,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: _DashColors.body,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionText != null && actionText!.isNotEmpty) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: _DashColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Text(
              actionText!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;

  const _SmallBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _DashColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: _DashColors.primary,
        ),
      ),
    );
  }
}

class _MonthlyReportHero extends StatelessWidget {
  const _MonthlyReportHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B6E63), Color(0xFF17A673)],
        ),
        boxShadow: [
          BoxShadow(
            color: _DashColors.primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 560;

          final content = [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Finance Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Review revenue, expenses, and overall center comparisons from the admin reports area.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12, height: 12),
            ElevatedButton.icon(
              onPressed: null,
              icon: Icon(Icons.open_in_new_rounded),
              label: Text('Open report'),
            ),
          ];

          if (isTight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Finance Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Review revenue, expenses, and overall center comparisons from the admin reports area.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReportsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _DashColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text(
                    'Open report',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Finance Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Review revenue, expenses, and overall center comparisons from the admin reports area.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminReportsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _DashColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text(
                  'Open report',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _DashColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _DashColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _DashColors.title,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.2,
                    height: 1.45,
                    color: _DashColors.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: _DashColors.title,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _CentersContainer extends StatelessWidget {
  final Widget child;

  const _CentersContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DashColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _DashColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CenterTile extends StatelessWidget {
  final String name;
  final String location;
  final String manager;
  final String centerId;

  const _CenterTile({
    required this.name,
    required this.location,
    required this.manager,
    required this.centerId,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FBFD),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminCenterEditScreen(centerId: centerId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _DashColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _DashColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.wifi_rounded,
                  color: _DashColors.primary,
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: _DashColors.title,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.location_on_outlined,
                          text: location,
                        ),
                        _InfoPill(
                          icon: Icons.person_outline_rounded,
                          text: manager,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _DashColors.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _DashColors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DashColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _DashColors.body),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: _DashColors.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _DashColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: _DashColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _DashColors.title,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: _DashColors.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    Widget placeholder({
      double height = 100,
      double? width,
      BorderRadius? radius,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius ?? BorderRadius.circular(20),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: _DashColors.primary.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: List.generate(4, (_) => placeholder(height: 140)),
              ),
              const SizedBox(height: 20),
              placeholder(height: 130, radius: BorderRadius.circular(26)),
              const SizedBox(height: 20),
              placeholder(height: 88, radius: BorderRadius.circular(24)),
              const SizedBox(height: 12),
              placeholder(height: 88, radius: BorderRadius.circular(24)),
              const SizedBox(height: 20),
              placeholder(height: 280, radius: BorderRadius.circular(26)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _DashColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFD14343),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _DashColors.title,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: _DashColors.body,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DashColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Try again',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
