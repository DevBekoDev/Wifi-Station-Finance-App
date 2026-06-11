import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wsfm/cubits/admin_reports/admin_reports_cubit.dart';
import 'package:wsfm/cubits/admin_reports/admin_reports_state.dart';
import 'package:wsfm/services/admin_report_export_servive.dart';

class _T {
  static const bg = Color(0xFFF4FBF6);
static const surface = Color(0xFFFFFFFF);
static const surface2 = Color(0xFFE8F5EC);
static const border = Color(0xFFD5E8DA);
static const border2 = Color(0xFFBED8C6);

static const emerald = Color(0xFF0B6E63);
static const emeraldD = Color(0xFFE4F4F1);

static const amber = Color(0xFFE28A12);
static const amberD = Color(0xFFFFF1DD);

static const rose = Color(0xFFD85C63);
static const roseD = Color(0xFFFFEBED);

static const blue = Color(0xFF4B7BEC);
static const blueD = Color(0xFFEAF1FF);

static const violet = Color(0xFF8B7CF6);
static const violetD = Color(0xFFF1EEFF);

static const textPrimary = Color.fromARGB(255, 20, 44, 35);
static const textSecondary = Color(0xFF567567);
static const textMuted = Color(0xFF86A093);
}

enum _RecordTypeFilter { all, sales, expenses }

enum _RecordSortMode {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
  centerAZ,
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late final AdminReportsCubit _cubit;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _RecordTypeFilter _recordTypeFilter = _RecordTypeFilter.all;
  _RecordSortMode _sortMode = _RecordSortMode.newest;

  @override
  void initState() {
    super.initState();
    _cubit = AdminReportsCubit()..loadReports();
    _tabController = TabController(length: 2, vsync: this);

    _searchController.addListener(() {
      final value = _searchController.text.trim().toLowerCase();
      if (_searchQuery != value) {
        setState(() => _searchQuery = value);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    _cubit.loadReports();
  }

  Future<void> _exportCsv(AdminReportsLoaded data) async {
    try {
      final file = await AdminReportExportService().exportAdminReportCsv(
        rows: data.records,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Admin report export',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report exported successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export report.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<AdminReportRow> _visibleRecords(List<AdminReportRow> records) {
    final filtered = records.where((row) {
      final isExpense = row.type.toLowerCase().contains('expense');

      bool matchesType;
      switch (_recordTypeFilter) {
        case _RecordTypeFilter.all:
          matchesType = true;
          break;
        case _RecordTypeFilter.sales:
          matchesType = !isExpense;
          break;
        case _RecordTypeFilter.expenses:
          matchesType = isExpense;
          break;
      }

      final q = _searchQuery;
      final matchesSearch = q.isEmpty ||
          row.centerName.toLowerCase().contains(q) ||
          row.itemName.toLowerCase().contains(q) ||
          row.type.toLowerCase().contains(q) ||
          row.description.toLowerCase().contains(q);

      return matchesType && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case _RecordSortMode.newest:
          return b.createdAt.compareTo(a.createdAt);
        case _RecordSortMode.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case _RecordSortMode.highestAmount:
          return b.amount.compareTo(a.amount);
        case _RecordSortMode.lowestAmount:
          return a.amount.compareTo(b.amount);
        case _RecordSortMode.centerAZ:
          return a.centerName.toLowerCase().compareTo(
                b.centerName.toLowerCase(),
              );
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AdminReportsCubit, AdminReportsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _T.bg,
            appBar: _buildAppBar(state),
            body: SafeArea(
              child: _buildBody(state),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AdminReportsState state) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _T.surface,
      foregroundColor: _T.textPrimary,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), _T.emerald],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _T.emerald.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Reports',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: _T.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                'Financial overview',
                style: TextStyle(
                  color: _T.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (state is AdminReportsLoaded)
          _AppBarBtn(
            icon: Icons.ios_share_rounded,
            tooltip: 'Export CSV',
            onPressed: state.records.isEmpty ? null : () => _exportCsv(state),
          ),
        _AppBarBtn(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onPressed: _refresh,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _T.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.border),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), _T.emerald],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _T.emerald.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: _T.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Records'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AdminReportsState state) {
    if (state is AdminReportsInitial || state is AdminReportsLoading) {
      return _buildLoadingState();
    }

    if (state is AdminReportsError) {
      return _buildErrorState(state.message);
    }

    final data = state as AdminReportsLoaded;

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(data),
        _buildRecordsTab(data),
      ],
    );
  }

  Widget _buildOverviewTab(AdminReportsLoaded data) {
    final width = MediaQuery.of(context).size.width;

    final AdminCenterReportItem? topCenter = data.centers.isEmpty
        ? null
        : ([...data.centers]..sort((a, b) => b.profit.compareTo(a.profit))).first;

    final maxSales = data.centers.isEmpty
        ? 0.0
        : data.centers
            .map((e) => e.sales)
            .fold<double>(0, (prev, e) => e > prev ? e : prev);

    return RefreshIndicator(
      color: _T.emerald,
      backgroundColor: _T.surface,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeroCard(data),
          const SizedBox(height: 12),
          _buildPeriodSelector(data),
          if (topCenter != null) ...[
            const SizedBox(height: 12),
            _buildInsightBanner(
              data: data,
              topCenter: topCenter,
            ),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: width >= 700 ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: width >= 700 ? 1.25 : 1.1,
            children: [
              _SummaryCard(
                title: 'Revenue',
                value: _fmt(data.totalSales),
                subtitle: 'Total sales',
                icon: Icons.trending_up_rounded,
                accentColor: _T.emerald,
                accentBg: _T.emeraldD,
              ),
              _SummaryCard(
                title: 'Expenses',
                value: _fmt(data.totalExpenses),
                subtitle: 'Total outgoings',
                icon: Icons.receipt_long_rounded,
                accentColor: _T.amber,
                accentBg: _T.amberD,
              ),
              _SummaryCard(
                title: 'Net Profit',
                value: _fmt(data.totalProfit),
                subtitle: 'Revenue − Expenses',
                icon: data.totalProfit >= 0
                    ? Icons.account_balance_wallet_rounded
                    : Icons.warning_amber_rounded,
                accentColor: data.totalProfit >= 0 ? _T.emerald : _T.rose,
                accentBg: data.totalProfit >= 0 ? _T.emeraldD : _T.roseD,
                valueColor: data.totalProfit >= 0 ? _T.emerald : _T.rose,
              ),
              _SummaryCard(
                title: 'Centers',
                value: data.totalCenters.toString(),
                subtitle: 'Active locations',
                icon: Icons.router_rounded,
                accentColor: _T.violet,
                accentBg: _T.violetD,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionHeader(
            'Center Performance',
            '${data.centers.length} centers',
          ),
          const SizedBox(height: 12),
          if (data.centers.isEmpty)
            _emptyCard('No center data available for this period.')
          else
            ...data.centers.map(
              (center) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CenterCard(
                  center: center,
                  maxSales: maxSales,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CenterEditPlaceholderScreen(
                          centerId: center.centerId,
                          centerName: center.centerName,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AdminReportsLoaded data) {
    final isProfit = data.totalProfit >= 0;
    final margin = data.totalSales > 0
        ? '${((data.totalProfit / data.totalSales) * 100).toStringAsFixed(1)}%'
        : '0.0%';
    final glowColor = isProfit ? _T.emerald : _T.rose;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _T.surface,
        border: Border.all(color: _T.border2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.10),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _periodPill(data.selectedPeriod),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: glowColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: glowColor.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: glowColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfit ? 'Profitable' : 'At a loss',
                            style: TextStyle(
                              color: glowColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  isProfit ? 'Net Profit' : 'Net Loss',
                  style: const TextStyle(
                    color: _T.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _fmt(data.totalProfit),
                  style: TextStyle(
                    color: glowColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 42,
                    height: 1,
                    letterSpacing: -1.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _T.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _T.border),
                  ),
                  child: Row(
                    children: [
                      _HeroStat(
                        label: 'Margin',
                        value: margin,
                        color: _T.textPrimary,
                      ),
                      _vDiv(),
                      _HeroStat(
                        label: 'Sales',
                        value: _fmt(data.totalSales),
                        color: _T.emerald,
                      ),
                      _vDiv(),
                      _HeroStat(
                        label: 'Expenses',
                        value: _fmt(data.totalExpenses),
                        color: _T.amber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDiv() {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: _T.border2,
    );
  }

  Widget _periodPill(AdminReportPeriod period) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _T.surface2,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _T.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 10,
            color: _T.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            _periodLabel(period),
            style: const TextStyle(
              color: _T.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AdminReportsLoaded data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AdminReportPeriod>(
          value: data.selectedPeriod,
          isExpanded: true,
          dropdownColor: _T.surface2,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _T.textMuted,
          ),
          style: const TextStyle(
            color: _T.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(
              value: AdminReportPeriod.all,
              child: Text('📅  All Time'),
            ),
            DropdownMenuItem(
              value: AdminReportPeriod.today,
              child: Text('☀️  Today'),
            ),
            DropdownMenuItem(
              value: AdminReportPeriod.week,
              child: Text('📆  This Week'),
            ),
            DropdownMenuItem(
              value: AdminReportPeriod.month,
              child: Text('🗓️  This Month'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              _cubit.changePeriod(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInsightBanner({
    required AdminReportsLoaded data,
    required AdminCenterReportItem topCenter,
  }) {
    final isProfit = data.totalProfit >= 0;
    final accent = isProfit ? _T.emerald : _T.amber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isProfit
                  ? Icons.auto_graph_rounded
                  : Icons.info_outline_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${topCenter.centerName} leads with ${_fmt(topCenter.profit)} profit.',
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(AdminReportsLoaded data) {
    final rows = _visibleRecords(data.records);

    return Column(
      children: [
        _buildRecordToolbar(
          total: data.records.length,
          visible: rows.length,
        ),
        Expanded(
          child: RefreshIndicator(
            color: _T.emerald,
            backgroundColor: _T.surface,
            onRefresh: _refresh,
            child: rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: _buildEmptyRecords(),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _RecordCard(row: rows[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordToolbar({
    required int total,
    required int visible,
  }) {
    final showingFiltered = _searchQuery.isNotEmpty ||
        _recordTypeFilter != _RecordTypeFilter.all;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(
          bottom: BorderSide(color: _T.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      color: _T.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search center, item, type…',
                      hintStyle: const TextStyle(
                        color: _T.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _T.textMuted,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _T.textMuted,
                                size: 16,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: _T.surface2,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _T.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _T.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _T.emerald,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<_RecordSortMode>(
                tooltip: 'Sort',
                initialValue: _sortMode,
                color: _T.surface2,
                onSelected: (value) => setState(() => _sortMode = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _RecordSortMode.newest,
                    child: Text(
                      'Newest first',
                      style: TextStyle(color: _T.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: _RecordSortMode.oldest,
                    child: Text(
                      'Oldest first',
                      style: TextStyle(color: _T.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: _RecordSortMode.highestAmount,
                    child: Text(
                      'Highest amount',
                      style: TextStyle(color: _T.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: _RecordSortMode.lowestAmount,
                    child: Text(
                      'Lowest amount',
                      style: TextStyle(color: _T.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: _RecordSortMode.centerAZ,
                    child: Text(
                      'Center A–Z',
                      style: TextStyle(color: _T.textPrimary),
                    ),
                  ),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _T.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.border),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _T.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FChip(
                label: 'All',
                selected: _recordTypeFilter == _RecordTypeFilter.all,
                onTap: () {
                  setState(() => _recordTypeFilter = _RecordTypeFilter.all);
                },
              ),
              const SizedBox(width: 8),
              _FChip(
                label: 'Sales',
                selected: _recordTypeFilter == _RecordTypeFilter.sales,
                activeColor: _T.emerald,
                onTap: () {
                  setState(() => _recordTypeFilter = _RecordTypeFilter.sales);
                },
              ),
              const SizedBox(width: 8),
              _FChip(
                label: 'Expenses',
                selected: _recordTypeFilter == _RecordTypeFilter.expenses,
                activeColor: _T.amber,
                onTap: () {
                  setState(() => _recordTypeFilter = _RecordTypeFilter.expenses);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                showingFiltered ? '$visible / $total records' : '$total records',
                style: const TextStyle(
                  color: _T.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _T.surface2,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _T.border),
                ),
                child: Text(
                  _sortLabel(_sortMode),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _T.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _Shimmer(height: 200, radius: 24),
        const SizedBox(height: 12),
        const _Shimmer(height: 52, radius: 16),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: const [
            _Shimmer(height: 120, radius: 20),
            _Shimmer(height: 120, radius: 20),
            _Shimmer(height: 120, radius: 20),
            _Shimmer(height: 120, radius: 20),
          ],
        ),
        const SizedBox(height: 24),
        const _Shimmer(height: 18, radius: 8),
        const SizedBox(height: 12),
        const _Shimmer(height: 120, radius: 20),
        const SizedBox(height: 10),
        const _Shimmer(height: 120, radius: 20),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _T.roseD),
            boxShadow: [
              BoxShadow(
                color: _T.rose.withOpacity(0.10),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _T.roseD,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 26,
                  color: _T.rose,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: _T.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _T.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecords() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _recordTypeFilter != _RecordTypeFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
              ),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.inbox_rounded,
                size: 28,
                color: _T.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters ? 'No matching records' : 'No records yet',
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters.'
                  : 'Records will appear here once data is available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _T.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _recordTypeFilter = _RecordTypeFilter.all;
                    _sortMode = _RecordSortMode.newest;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _T.textSecondary,
                  side: const BorderSide(color: _T.border2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String badge) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _T.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _T.surface2,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _T.border),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              color: _T.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_city_rounded,
            color: _T.textMuted,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _T.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _periodLabel(AdminReportPeriod period) {
    switch (period) {
      case AdminReportPeriod.all:
        return 'All Time';
      case AdminReportPeriod.today:
        return 'Today';
      case AdminReportPeriod.week:
        return 'This Week';
      case AdminReportPeriod.month:
        return 'This Month';
    }
  }

  static String _sortLabel(_RecordSortMode mode) {
    switch (mode) {
      case _RecordSortMode.newest:
        return 'Newest first';
      case _RecordSortMode.oldest:
        return 'Oldest first';
      case _RecordSortMode.highestAmount:
        return 'Highest amount';
      case _RecordSortMode.lowestAmount:
        return 'Lowest amount';
      case _RecordSortMode.centerAZ:
        return 'Center A–Z';
    }
  }

  static String _fmt(double amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();

    final value = abs >= 1000000
        ? '${(abs / 1000000).toStringAsFixed(1)}M'
        : abs >= 1000
            ? '${(abs / 1000).toStringAsFixed(1)}K'
            : abs.toStringAsFixed(0);

    return isNegative ? '-$value' : value;
  }

  static String _fmtDateTime(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy · $hh:$min';
  }
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _AppBarBtn({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _T.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.border),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 17,
            color: onPressed == null ? _T.textMuted : _T.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _T.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;
  final Color? valueColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: valueColor ?? _T.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: _T.textPrimary,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _T.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  final AdminCenterReportItem center;
  final double maxSales;
  final VoidCallback? onTap;

  const _CenterCard({
    required this.center,
    required this.maxSales,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = center.profit >= 0;
    final accent = isProfit ? _T.emerald : _T.rose;
    final salesRatio =
        maxSales > 0 ? (center.sales / maxSales).clamp(0.0, 1.0) : 0.0;
    final expenseRatio = center.sales > 0
        ? (center.expenses / center.sales).clamp(0.0, 1.0)
        : 0.0;
    final margin = center.sales > 0
        ? '${((center.profit / center.sales) * 100).toStringAsFixed(1)}%'
        : '—';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.border),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.5), accent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.centerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _T.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${center.location} · ${center.managerName}',
                            style: const TextStyle(
                              color: _T.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: accent.withOpacity(0.28),
                        ),
                      ),
                      child: Text(
                        '${isProfit ? '+' : '-'}${_AdminReportsScreenState._fmt(center.profit.abs())}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Bar(
                  label: 'Sales',
                  value: _AdminReportsScreenState._fmt(center.sales),
                  progress: salesRatio,
                  color: _T.emerald,
                ),
                const SizedBox(height: 8),
                _Bar(
                  label: 'Expenses',
                  value: _AdminReportsScreenState._fmt(center.expenses),
                  progress: expenseRatio,
                  color: _T.amber,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      '${center.salesCount} sales',
                      fg: _T.emerald,
                      bg: _T.emeraldD,
                    ),
                    _Chip(
                      '${center.expenseCount} exp',
                      fg: _T.amber,
                      bg: _T.amberD,
                    ),
                    _Chip(
                      '$margin margin',
                      fg: _T.blue,
                      bg: _T.blueD,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}

class _CenterEditPlaceholderScreen extends StatelessWidget {
  final String centerId;
  final String centerName;

  const _CenterEditPlaceholderScreen({
    required this.centerId,
    required this.centerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Center'),
        backgroundColor: _T.emerald,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              centerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Center ID: $centerId',
              style: const TextStyle(
                fontSize: 14,
                color: _T.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _T.surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _T.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Edit screen placeholder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'The admin center edit page is not implemented yet. This placeholder will be replaced with the actual editing screen later.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _Bar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _T.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _T.surface2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AdminReportRow row;

  const _RecordCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final isExpense = row.type.toLowerCase().contains('expense');
    final accent = isExpense ? _T.rose : _T.emerald;
    final accentBg = isExpense ? _T.roseD : _T.emeraldD;

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent.withOpacity(0.4), accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          row.itemName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _T.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${isExpense ? '-' : '+'}${_AdminReportsScreenState._fmt(row.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Chip(
                        row.type,
                        fg: accent,
                        bg: accentBg,
                      ),
                      _IChip(
                        icon: Icons.location_on_outlined,
                        label: row.centerName,
                      ),
                      if ((row.quantity ?? 0) > 0)
                        _IChip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Qty ${row.quantity}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: _T.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _AdminReportsScreenState._fmtDateTime(row.createdAt),
                        style: const TextStyle(
                          color: _T.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (row.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _T.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.border),
                      ),
                      child: Text(
                        row.description,
                        style: const TextStyle(
                          color: _T.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _Chip(
    this.label, {
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _IChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _T.surface2,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: _T.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _T.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;

  const _FChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor = _T.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.13) : _T.surface2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.45) : _T.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? activeColor : _T.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double height;
  final double radius;

  const _Shimmer({
    required this.height,
    required this.radius,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [Color(0xFFE7F4EC),
  Color(0xFFD3EBDD),
  Color(0xFFE7F4EC),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;

    const step = 30.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}