import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/sales/sales_cubit.dart';
import 'package:wsfm/cubits/sales/sales_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sales Screen - Full Fixed Version
// Drop-in replacement for sales_screen.dart.
// Fixes Dismissible delete crash by NEVER returning true from confirmDismiss.
// Firestore stream removes deleted items naturally after delete succeeds.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Theme Constants ─────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF00897B);
const _kPrimaryDark = Color(0xFF00695C);
const _kPrimaryLight = Color(0xFF26A69A);
const _kPrimarySoft = Color(0xFFE0F2F1);

const _kBackground = Color(0xFFF4F7FA);
const _kSurface = Colors.white;
const _kSurfaceSoft = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE7EDF2);

const _kTextPrimary = Color(0xFF0D1B2A);
const _kTextSecondary = Color(0xFF667085);
const _kTextMuted = Color(0xFF98A2B3);

const _kDanger = Color(0xFFE53935);
const _kWarning = Color(0xFFFFA726);
const _kSuccess = Color(0xFF12B76A);
const _kEdit = Color(0xFF1976D2);

const _kShadow = Color(0x12000000);

const _kPagePadding = 16.0;
const _kCardRadius = 22.0;

// Change this to '$' if you do not use Turkish Lira.
const _kCurrency = '₺';

// ─── Packages ────────────────────────────────────────────────────────────────

const _kPackages = <_PackageOption>[
  _PackageOption(
    name: '1 GB',
    price: 25,
    icon: Icons.wifi_rounded,
    badge: 'Basic',
  ),
  _PackageOption(
    name: '2 GB',
    price: 35,
    icon: Icons.data_usage_rounded,
    badge: 'Value',
  ),
  _PackageOption(
    name: '5 GB',
    price: 60,
    icon: Icons.sd_storage_rounded,
    badge: 'Popular',
  ),
  _PackageOption(
    name: '10 GB',
    price: 100,
    icon: Icons.flash_on_rounded,
    badge: 'Fast',
  ),
  _PackageOption(
    name: 'Unlimited',
    price: 150,
    icon: Icons.all_inclusive_rounded,
    badge: 'Best',
  ),
  _PackageOption(
    name: 'Night Pack',
    price: 40,
    icon: Icons.nights_stay_rounded,
    badge: 'Night',
  ),
];

// ─── Entry Point ─────────────────────────────────────────────────────────────

class SalesScreen extends StatelessWidget {
  final String centerId;

  const SalesScreen({
    super.key,
    required this.centerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesCubit()..loadSales(centerId),
      child: _SalesView(centerId: centerId),
    );
  }
}

// ─── Main View ───────────────────────────────────────────────────────────────

class _SalesView extends StatefulWidget {
  final String centerId;

  const _SalesView({
    required this.centerId,
  });

  @override
  State<_SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<_SalesView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _SaleSort _sort = _SaleSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesCubit, SalesState>(
      listener: _listenToMessages,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _kBackground,
          appBar: _buildAppBar(context, state),
          body: SafeArea(
            child: Stack(
              children: [
                if (state.isLoading)
                  const _LoadingState()
                else
                  _buildBody(context, state),
                if (state.isSaving) const _TopSavingBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _listenToMessages(BuildContext context, SalesState state) {
    final messenger = ScaffoldMessenger.of(context);

    if (state.errorMessage != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          _buildSnackBar(
            state.errorMessage!,
            isError: true,
          ),
        );

      context.read<SalesCubit>().clearMessages();
    }

    if (state.successMessage != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(_buildSnackBar(state.successMessage!));

      context.read<SalesCubit>().clearMessages();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SalesState state) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _kBackground,
      foregroundColor: _kTextPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 16,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.45,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Record package sales quickly',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton.filledTonal(
          tooltip: 'Refresh',
          onPressed: state.isLoading || state.isSaving ? null : _refreshSales,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SalesState state) {
    final filteredSales = _filterAndSortSales(state.recentSales);
    final bestPackage = _bestPackageName(state.recentSales);
    final averageSale = state.recentSales.isEmpty
        ? 0.0
        : state.totalSalesAmount / state.recentSales.length;

    return RefreshIndicator(
      color: _kPrimary,
      backgroundColor: _kSurface,
      onRefresh: () async => _refreshSales(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          _kPagePadding,
          8,
          _kPagePadding,
          32,
        ),
        children: [
          _HeroCard(
            totalAmount: state.totalSalesAmount,
            totalCards: state.totalQuantity,
            recentCount: state.recentSales.length,
            averageSale: averageSale,
            bestPackage: bestPackage,
          ),
          const SizedBox(height: 20),
          _QuickInsightsRow(
            cards: [
              _InsightData(
                label: 'Avg. Sale',
                value: _money(averageSale),
                icon: Icons.trending_up_rounded,
              ),
              _InsightData(
                label: 'Top Pack',
                value: bestPackage ?? '—',
                icon: Icons.workspace_premium_rounded,
              ),
              _InsightData(
                label: 'Records',
                value: state.recentSales.length.toString(),
                icon: Icons.receipt_long_rounded,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Choose Package',
            subtitle: 'Tap a card, choose quantity, then confirm.',
            trailing: state.isSaving
                ? const _MiniStatusPill(
                    text: 'Saving...',
                    icon: Icons.cloud_upload_rounded,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: state.isSaving,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: state.isSaving ? 0.62 : 1,
              child: _PackageGrid(
                packages: _kPackages,
                onSelect: (item) {
                  HapticFeedback.lightImpact();
                  _showQuantitySheet(
                    context: context,
                    item: item,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent Sales',
            subtitle: state.recentSales.isEmpty
                ? 'No records yet.'
                : '${filteredSales.length} shown from ${state.recentSales.length} records',
          ),
          const SizedBox(height: 12),
          _SalesToolbar(
            controller: _searchController,
            query: _searchQuery,
            sort: _sort,
            onQueryChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            onSortChanged: (sort) {
              HapticFeedback.selectionClick();
              setState(() => _sort = sort);
            },
          ),
          const SizedBox(height: 12),
          _SalesList(
            sales: filteredSales,
            allSalesCount: state.recentSales.length,
            isSaving: state.isSaving,
            hasActiveFilter: _searchQuery.isNotEmpty,
            onDelete: (sale) => _deleteSale(context, sale),
            onEdit: (sale) => _showEditSaleSheet(
              context: context,
              sale: sale,
            ),
            onClearFilter: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ],
      ),
    );
  }

  void _refreshSales() {
    HapticFeedback.selectionClick();
    context.read<SalesCubit>().loadSales(widget.centerId);
  }

  List<SaleHistoryItem> _filterAndSortSales(List<SaleHistoryItem> sales) {
    final query = _searchQuery.toLowerCase();

    final filtered = sales.where((sale) {
      if (query.isEmpty) return true;

      final packageName = sale.packageName.toLowerCase();
      final quantity = sale.quantity.toString();
      final amount = sale.totalAmount.toStringAsFixed(0);

      return packageName.contains(query) ||
          quantity.contains(query) ||
          amount.contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _SaleSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case _SaleSort.highest:
          return b.totalAmount.compareTo(a.totalAmount);
        case _SaleSort.quantity:
          return b.quantity.compareTo(a.quantity);
      }
    });

    return filtered;
  }

  String? _bestPackageName(List<SaleHistoryItem> sales) {
    if (sales.isEmpty) return null;

    final totals = <String, int>{};

    for (final sale in sales) {
      totals[sale.packageName] = (totals[sale.packageName] ?? 0) + sale.quantity;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.first.key;
  }

  void _showQuantitySheet({
    required BuildContext context,
    required _PackageOption item,
  }) {
    final salesCubit = context.read<SalesCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _QuantitySheet(
          item: item,
          centerId: widget.centerId,
          salesCubit: salesCubit,
        );
      },
    );
  }

  void _showEditSaleSheet({
    required BuildContext context,
    required SaleHistoryItem sale,
  }) {
    final salesCubit = context.read<SalesCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditSaleSheet(
          sale: sale,
          centerId: widget.centerId,
          salesCubit: salesCubit,
        );
      },
    );
  }

  void _deleteSale(BuildContext context, SaleHistoryItem sale) {
    if (sale.id.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          _buildSnackBar(
            'Cannot delete this sale because sale ID is empty.',
            isError: true,
          ),
        );
      return;
    }

    HapticFeedback.mediumImpact();

    context.read<SalesCubit>().deleteSale(
          centerId: widget.centerId,
          saleId: sale.id,
        );
  }
}

// ─── Hero Card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double totalAmount;
  final int totalCards;
  final int recentCount;
  final double averageSale;
  final String? bestPackage;

  const _HeroCard({
    required this.totalAmount,
    required this.totalCards,
    required this.recentCount,
    required this.averageSale,
    required this.bestPackage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF004D43),
            Color(0xFF00796B),
            Color(0xFF00A7B7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3000695C),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const _HeroDecoration(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _HeroIcon(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Package Sales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.25,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Live sales overview',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _WhitePill(text: '$recentCount recent'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Total Revenue',
                      value: _money(totalAmount),
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 58,
                    color: Colors.white.withOpacity(0.22),
                  ),
                  Expanded(
                    child: _HeroStat(
                      label: 'Cards Sold',
                      value: totalCards.toString(),
                      icon: Icons.confirmation_number_rounded,
                      alignment: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GlassMiniChip(
                    icon: Icons.trending_up_rounded,
                    text: 'Avg ${_money(averageSale)}',
                  ),
                  _GlassMiniChip(
                    icon: Icons.star_rounded,
                    text: 'Top ${bestPackage ?? '—'}',
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

class _HeroDecoration extends StatelessWidget {
  const _HeroDecoration();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -38,
              child: _HeroCircle(size: 130, opacity: 0.08),
            ),
            Positioned(
              right: 38,
              bottom: -48,
              child: _HeroCircle(size: 112, opacity: 0.06),
            ),
            Positioned(
              left: -52,
              bottom: -64,
              child: _HeroCircle(size: 120, opacity: 0.045),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeroCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final CrossAxisAlignment alignment;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: alignment == CrossAxisAlignment.end
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.82),
              size: 16,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.76),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            value,
            textAlign: alignment == CrossAxisAlignment.end
                ? TextAlign.end
                : TextAlign.start,
            style: const TextStyle(
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String text;

  const _WhitePill({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassMiniChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GlassMiniChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.88)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Insights ─────────────────────────────────────────────────────────

class _QuickInsightsRow extends StatelessWidget {
  final List<_InsightData> cards;

  const _QuickInsightsRow({
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              for (final card in cards) ...[
                _InsightCard(data: card),
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: _InsightCard(data: cards[i])),
              if (i != cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightData data;

  const _InsightCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: _kShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: _kPrimaryDark, size: 20),
          const SizedBox(height: 9),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _kTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  final String label;
  final String value;
  final IconData icon;

  const _InsightData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _kTextPrimary,
                  letterSpacing: -0.45,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _MiniStatusPill({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _kPrimarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: _kPrimaryDark,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _kPrimaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Package Grid ────────────────────────────────────────────────────────────

class _PackageGrid extends StatelessWidget {
  final List<_PackageOption> packages;
  final ValueChanged<_PackageOption> onSelect;

  const _PackageGrid({
    required this.packages,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 900
            ? 4
            : width >= 620
                ? 3
                : 2;

        final aspectRatio = width >= 900
            ? 1.38
            : width >= 620
                ? 1.24
                : width >= 400
                    ? 1.06
                    : 0.94;

        return GridView.builder(
          itemCount: packages.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = packages[index];

            return _PackageCard(
              item: item,
              onTap: () => onSelect(item),
            );
          },
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  final _PackageOption item;
  final VoidCallback onTap;

  const _PackageCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFeatured = item.badge.toLowerCase() == 'popular' ||
        item.badge.toLowerCase() == 'best';

    return Semantics(
      button: true,
      label: '${item.name}, ${_money(item.price)} per card',
      child: Material(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kCardRadius),
          splashColor: _kPrimarySoft,
          highlightColor: _kPrimarySoft.withOpacity(0.55),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(
                color: isFeatured ? _kWarning.withOpacity(0.55) : _kBorder,
                width: isFeatured ? 1.2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: _kShadow,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SoftIconBox(
                      icon: item.icon,
                      size: 44,
                    ),
                    const Spacer(),
                    _PackageBadge(text: item.badge),
                  ],
                ),
                const Spacer(),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _kTextPrimary,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      _money(item.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _kPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/ card',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text(
                      'Tap to sell',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kTextMuted,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _kTextMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageBadge extends StatelessWidget {
  final String text;

  const _PackageBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = text.toLowerCase() == 'popular' ||
        text.toLowerCase() == 'best';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isPopular ? _kWarning.withOpacity(0.16) : _kPrimarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isPopular ? const Color(0xFFB85B00) : _kPrimaryDark,
        ),
      ),
    );
  }
}

class _SoftIconBox extends StatelessWidget {
  final IconData icon;
  final double size;

  const _SoftIconBox({
    required this.icon,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kPrimarySoft,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(
        icon,
        color: _kPrimaryDark,
        size: size * 0.5,
      ),
    );
  }
}

// ─── Sales Toolbar ───────────────────────────────────────────────────────────

class _SalesToolbar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final _SaleSort sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_SaleSort> onSortChanged;

  const _SalesToolbar({
    required this.controller,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onClear,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search package, quantity, amount...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: _kSurfaceSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SortChip(
                text: 'Newest',
                icon: Icons.schedule_rounded,
                selected: sort == _SaleSort.newest,
                onTap: () => onSortChanged(_SaleSort.newest),
              ),
              const SizedBox(width: 8),
              _SortChip(
                text: 'Highest',
                icon: Icons.payments_rounded,
                selected: sort == _SaleSort.highest,
                onTap: () => onSortChanged(_SaleSort.highest),
              ),
              const SizedBox(width: 8),
              _SortChip(
                text: 'Qty',
                icon: Icons.confirmation_number_rounded,
                selected: sort == _SaleSort.quantity,
                onTap: () => onSortChanged(_SaleSort.quantity),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.text,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? _kPrimarySoft : _kSurfaceSoft,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _kPrimaryLight.withOpacity(0.35) : _kBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? _kPrimaryDark : _kTextSecondary,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: selected ? _kPrimaryDark : _kTextSecondary,
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

// ─── Sales List ──────────────────────────────────────────────────────────────

class _SalesList extends StatelessWidget {
  final List<SaleHistoryItem> sales;
  final int allSalesCount;
  final bool isSaving;
  final bool hasActiveFilter;
  final ValueChanged<SaleHistoryItem> onDelete;
  final ValueChanged<SaleHistoryItem> onEdit;
  final VoidCallback onClearFilter;

  const _SalesList({
    required this.sales,
    required this.allSalesCount,
    required this.isSaving,
    required this.hasActiveFilter,
    required this.onDelete,
    required this.onClearFilter,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (allSalesCount == 0) {
      return const _EmptySalesState();
    }

    if (sales.isEmpty && hasActiveFilter) {
      return _NoSearchResultsState(onClear: onClearFilter);
    }

    return Column(
      children: [
        for (final sale in sales)
          _SaleHistoryCard(
            sale: sale,
            isSaving: isSaving,
            onDelete: onDelete,
            onEdit: onEdit,
          ),
      ],
    );
  }
}

class _EmptySalesState extends StatelessWidget {
  const _EmptySalesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 36,
        horizontal: 22,
      ),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kPrimarySoft,
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _kPrimaryDark,
              size: 33,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No sales yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a package above and confirm the quantity to create the first sale record.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoSearchResultsState({
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: _kTextMuted,
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'No matching sales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try another package name, amount, or quantity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Clear filter'),
          ),
        ],
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  final SaleHistoryItem sale;
  final bool isSaving;
  final ValueChanged<SaleHistoryItem> onDelete;
  final ValueChanged<SaleHistoryItem> onEdit;

  const _SaleHistoryCard({
    required this.sale,
    required this.isSaving,
    required this.onDelete,
    required this.onEdit,
  });

  Future<bool> _confirmDelete(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete sale?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Remove ${sale.packageName} × ${sale.quantity} from sales records?',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _kDanger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
              ),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String get _safeDismissKey {
    if (sale.id.trim().isNotEmpty) {
      return 'sale_${sale.id}';
    }

    return 'sale_${sale.packageName}_${sale.createdAt.microsecondsSinceEpoch}_${sale.quantity}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(_safeDismissKey),
      resizeDuration: null,
      direction: isSaving ? DismissDirection.none : DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kEdit.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.edit_rounded,
          color: _kEdit,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kDanger.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: _kDanger,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit(sale);
          return false;
        }

        final shouldDelete = await _confirmDelete(context);

        if (shouldDelete) {
          onDelete(sale);
        }

        // Do not return true here.
        // Returning true removes the Dismissible immediately while Firestore may
        // still return the same item for a moment, which can crash the app.
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(
              color: _kShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const _SoftIconBox(
              icon: Icons.receipt_long_rounded,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sale.quantity} × ${_money(sale.packagePrice)} · ${_relativeTime(sale.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _money(sale.totalAmount),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: _kPrimaryDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SaleCardAction(
                        icon: Icons.edit_rounded,
                        label: 'edit',
                        color: _kEdit,
                        onTap: isSaving ? null : () => onEdit(sale),
                      ),
                      const SizedBox(width: 6),
                      _SaleCardAction(
                        icon: Icons.delete_outline_rounded,
                        label: 'delete',
                        color: _kTextMuted,
                        onTap: isSaving
                            ? null
                            : () async {
                                final shouldDelete =
                                    await _confirmDelete(context);

                                if (shouldDelete) {
                                  onDelete(sale);
                                }
                              },
                      ),
                    ],
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

class _SaleCardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SaleCardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quantity Bottom Sheet ───────────────────────────────────────────────────

class _QuantitySheet extends StatefulWidget {
  final _PackageOption item;
  final String centerId;
  final SalesCubit salesCubit;

  const _QuantitySheet({
    required this.item,
    required this.centerId,
    required this.salesCubit,
  });

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  int _quantity = 1;
  bool _touched = false;

  bool get _hasValidQuantity => _quantity >= 1 && _quantity <= 999;

  double get _total => widget.item.price * (_hasValidQuantity ? _quantity : 0);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _clampQuantity(int value) {
    if (value < 1) return 1;
    if (value > 999) return 999;
    return value;
  }

  void _setQuantity(int value) {
    final next = _clampQuantity(value);

    setState(() {
      _quantity = next;
      _touched = true;
    });

    _controller.text = next.toString();
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    HapticFeedback.selectionClick();
  }

  void _handleQuantityText(String value) {
    final parsed = int.tryParse(value);

    setState(() {
      _touched = true;

      if (parsed == null) {
        _quantity = 0;
      } else {
        _quantity = parsed > 999 ? 999 : parsed;
      }
    });

    if (parsed != null && parsed > 999) {
      _controller.text = '999';
      _controller.selection = const TextSelection.collapsed(offset: 3);
    }
  }

  void _confirmSale() {
    final parsed = int.tryParse(_controller.text.trim());

    if (parsed == null || parsed < 1) {
      setState(() {
        _quantity = 0;
        _touched = true;
      });

      HapticFeedback.heavyImpact();
      return;
    }

    final finalQuantity = _clampQuantity(parsed);

    Navigator.pop(context);

    widget.salesCubit.addSale(
      centerId: widget.centerId,
      packageName: widget.item.name,
      packagePrice: widget.item.price,
      quantity: finalQuantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BottomSheetHandle(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _SoftIconBox(
                      icon: widget.item.icon,
                      size: 54,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _kTextPrimary,
                              letterSpacing: -0.55,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_money(widget.item.price)} per card',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kTextSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PackageBadge(text: widget.item.badge),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _setQuantity(_quantity - 1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: _kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _kSurface,
                          hintText: '1',
                          errorText: _touched && !_hasValidQuantity
                              ? 'Enter 1 - 999'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: _kBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: _kBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: _kPrimary,
                              width: 1.6,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: _kDanger),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: _kDanger,
                              width: 1.4,
                            ),
                          ),
                        ),
                        onTap: () {
                          _controller.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _controller.text.length,
                          );
                        },
                        onChanged: _handleQuantityText,
                        onSubmitted: (_) => _confirmSale(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: () => _setQuantity(_quantity + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _QuickQuantityChips(
                  selectedQuantity: _quantity,
                  onSelected: _setQuantity,
                ),
                const SizedBox(height: 18),
                _TotalPreview(
                  quantity: _quantity,
                  total: _total,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _hasValidQuantity ? _confirmSale : null,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text('Confirm ${_money(_total)} Sale'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimaryDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kTextMuted.withOpacity(0.25),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
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

class _EditSaleSheet extends StatefulWidget {
  final SaleHistoryItem sale;
  final String centerId;
  final SalesCubit salesCubit;

  const _EditSaleSheet({
    required this.sale,
    required this.centerId,
    required this.salesCubit,
  });

  @override
  State<_EditSaleSheet> createState() => _EditSaleSheetState();
}

class _EditSaleSheetState extends State<_EditSaleSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  late int _quantity;
  bool _touched = false;

  bool get _hasValidQuantity => _quantity >= 1 && _quantity <= 999;

  bool get _hasChanged => _quantity != widget.sale.quantity;

  double get _total =>
      widget.sale.packagePrice * (_hasValidQuantity ? _quantity : 0);

  @override
  void initState() {
    super.initState();
    _quantity = widget.sale.quantity;
    _controller = TextEditingController(text: _quantity.toString());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _clampQuantity(int value) {
    if (value < 1) return 1;
    if (value > 999) return 999;
    return value;
  }

  void _setQuantity(int value) {
    final next = _clampQuantity(value);

    setState(() {
      _quantity = next;
      _touched = true;
    });

    _controller.text = next.toString();
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    HapticFeedback.selectionClick();
  }

  void _handleQuantityText(String value) {
    final parsed = int.tryParse(value);

    setState(() {
      _touched = true;

      if (parsed == null) {
        _quantity = 0;
      } else {
        _quantity = parsed > 999 ? 999 : parsed;
      }
    });

    if (parsed != null && parsed > 999) {
      _controller.text = '999';
      _controller.selection = const TextSelection.collapsed(offset: 3);
    }
  }

  void _confirmEdit() {
    final parsed = int.tryParse(_controller.text.trim());

    if (parsed == null || parsed < 1) {
      setState(() {
        _quantity = 0;
        _touched = true;
      });

      HapticFeedback.heavyImpact();
      return;
    }

    final finalQuantity = _clampQuantity(parsed);

    Navigator.pop(context);

    widget.salesCubit.editSale(
      centerId: widget.centerId,
      saleId: widget.sale.id,
      quantity: finalQuantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BottomSheetHandle(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const _SoftIconBox(
                      icon: Icons.edit_rounded,
                      size: 54,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit ${widget.sale.packageName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _kTextPrimary,
                              letterSpacing: -0.55,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_money(widget.sale.packagePrice)} per card',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kTextSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _kEdit.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _kEdit,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'New Quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _setQuantity(_quantity - 1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: _kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _kSurface,
                          hintText: '1',
                          errorText: _touched && !_hasValidQuantity
                              ? 'Enter 1 - 999'
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: _kBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: _kBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: _kEdit,
                              width: 1.6,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: _kDanger),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: _kDanger,
                              width: 1.4,
                            ),
                          ),
                        ),
                        onTap: () {
                          _controller.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _controller.text.length,
                          );
                        },
                        onChanged: _handleQuantityText,
                        onSubmitted: (_) {
                          if (_hasValidQuantity && _hasChanged) {
                            _confirmEdit();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: () => _setQuantity(_quantity + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _QuickQuantityChips(
                  selectedQuantity: _quantity,
                  onSelected: _setQuantity,
                ),
                const SizedBox(height: 18),
                _TotalPreview(
                  quantity: _quantity,
                  total: _total,
                ),
                if (!_hasChanged) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Change quantity to update this sale',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _hasValidQuantity && _hasChanged ? _confirmEdit : null,
                    icon: const Icon(Icons.save_rounded),
                    label: Text('Update to ${_money(_total)}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kEdit,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kTextMuted.withOpacity(0.25),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
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

class _QuickQuantityChips extends StatelessWidget {
  final int selectedQuantity;
  final ValueChanged<int> onSelected;

  const _QuickQuantityChips({
    required this.selectedQuantity,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const quantities = [1, 2, 5, 10, 20, 50];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final quantity in quantities)
          ChoiceChip(
            label: Text('×$quantity'),
            selected: selectedQuantity == quantity,
            selectedColor: _kPrimarySoft,
            backgroundColor: _kSurface,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w900,
              color:
                  selectedQuantity == quantity ? _kPrimaryDark : _kTextSecondary,
            ),
            side: BorderSide(
              color: selectedQuantity == quantity
                  ? _kPrimaryLight.withOpacity(0.4)
                  : _kBorder,
            ),
            onSelected: (_) => onSelected(quantity),
          ),
      ],
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _TotalPreview extends StatelessWidget {
  final int quantity;
  final double total;

  const _TotalPreview({
    required this.quantity,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final safeQuantity = quantity < 0 ? 0 : quantity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kPrimarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: _kPrimaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$safeQuantity card${safeQuantity == 1 ? '' : 's'} selected',
              style: const TextStyle(
                fontSize: 13,
                color: _kTextSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _money(total),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: _kPrimaryDark,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading & Saving States ─────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: const [
        _SkeletonBox(height: 178, radius: 30),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 86, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 86, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 86, radius: 18)),
          ],
        ),
        SizedBox(height: 28),
        _SkeletonBox(height: 22, width: 160, radius: 12),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 150, radius: 22)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonBox(height: 150, radius: 22)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 150, radius: 22)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonBox(height: 150, radius: 22)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const _SkeletonBox({
    required this.height,
    this.width,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _kBorder),
      ),
    );
  }
}

class _TopSavingBar extends StatelessWidget {
  const _TopSavingBar();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(
        minHeight: 3,
        color: _kPrimary,
        backgroundColor: _kPrimarySoft,
      ),
    );
  }
}

// ─── Quantity Button ─────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPrimaryDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

SnackBar _buildSnackBar(
  String message, {
  bool isError = false,
}) {
  return SnackBar(
    content: Row(
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: isError ? _kDanger : _kSuccess,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
  );
}

String _money(num value) {
  return '$_kCurrency${value.toStringAsFixed(0)}';
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inSeconds < 30) return 'Just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

// ─── Local Models ────────────────────────────────────────────────────────────

class _PackageOption {
  final String name;
  final double price;
  final IconData icon;
  final String badge;

  const _PackageOption({
    required this.name,
    required this.price,
    required this.icon,
    required this.badge,
  });
}

enum _SaleSort {
  newest,
  highest,
  quantity,
}
