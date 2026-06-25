import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/screens/login_screen.dart';
import 'package:wsfm/screens/manager_activation_screen.dart';
import 'package:wsfm/utils/app_routes.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF051F20);
  static const bg2 = Color(0xFF0B2B26);
  static const bg3 = Color(0xFF163832);
  static const accent = Color(0xFF235347);
  static const mint = Color(0xFF8EB69B);
  static const mintLight = Color(0xFFDAF1DE);
  static const surface = Color(0xFFF7FBF8);
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1B2B26);
  static const textMid = Color(0xFF4A6358);
  static const textMuted = Color(0xFF8FA99E);
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeHero;
  late final Animation<Offset> _slideHero;
  late final Animation<double> _fadePanel;
  late final Animation<Offset> _slidePanel;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeHero = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _slideHero = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _fadePanel = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _slidePanel = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(
          name: AppRoutes.login,
        ),
        builder: (_) => BlocProvider(
          create: (_) => AuthCubit(),
          child: const LoginScreen(),
        ),
      ),
    );
  }

  void _openManagerActivation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(
          name: '/manager-activation',
        ),
        builder: (_) => const ManagerActivationScreen(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('About WSFM'),
        content: const Text(
          'WSFM helps admins and managers manage WiFi station finances, centers, sales, expenses, and reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isWide = w >= 900;
            final isTablet = w >= 600 && w < 900;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1200 : 700,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isWide ? 24 : 16),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 11,
                              child: FadeTransition(
                                opacity: _fadeHero,
                                child: SlideTransition(
                                  position: _slideHero,
                                  child: const _HeroPanel(large: true),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 10,
                              child: FadeTransition(
                                opacity: _fadePanel,
                                child: SlideTransition(
                                  position: _slidePanel,
                                  child: _ActionPanel(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.15,
                                    onAdminTap: _openLogin,
                                    onManagerTap: _openLogin,
                                    onActivateTap: _openManagerActivation,
                                    onAboutTap: _showAboutDialog,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            FadeTransition(
                              opacity: _fadeHero,
                              child: SlideTransition(
                                position: _slideHero,
                                child: _HeroPanel(large: isTablet),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: FadeTransition(
                                opacity: _fadePanel,
                                child: SlideTransition(
                                  position: _slidePanel,
                                  child: _ActionPanel(
                                    crossAxisCount: 2,
                                    childAspectRatio: isTablet ? 1.12 : 0.98,
                                    onAdminTap: _openLogin,
                                    onManagerTap: _openLogin,
                                    onActivateTap: _openManagerActivation,
                                    onAboutTap: _showAboutDialog,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Hero Panel ───────────────────────────────────────────────────────────────
class _HeroPanel extends StatelessWidget {
  final bool large;

  const _HeroPanel({
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 60.0 : 48.0;
    final titleSize = large ? 38.0 : 30.0;
    final containerSize = large ? 130.0 : 104.0;
    final panelHeight = large ? 310.0 : 268.0;

    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 36 : 28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.bg, _C.bg2, _C.bg3],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _C.bg.withOpacity(0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _Ring(
              size: large ? 200 : 150,
              opacity: 0.06,
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: _Ring(
              size: large ? 130 : 90,
              opacity: 0.04,
            ),
          ),
          const Positioned(
            top: 20,
            left: 20,
            child: _StatusBadge(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(large ? 34 : 26),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: _C.mint.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_rounded,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'WSFM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'WiFi Station Finance Manager',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: large ? 13 : 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: large ? 48 : 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _C.mint,
                    borderRadius: BorderRadius.circular(10),
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

class _Ring extends StatelessWidget {
  final double size;
  final double opacity;

  const _Ring({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 1,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _C.mint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: _C.mint.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _C.mint,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'v2.0 · WSFM',
            style: TextStyle(
              color: _C.mint,
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Panel ─────────────────────────────────────────────────────────────
class _ActionPanel extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final void Function(BuildContext context) onAdminTap;
  final void Function(BuildContext context) onManagerTap;
  final void Function(BuildContext context) onActivateTap;
  final void Function(BuildContext context) onAboutTap;

  const _ActionPanel({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.onAdminTap,
    required this.onManagerTap,
    required this.onActivateTap,
    required this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.shield_rounded,
        label: 'Admin',
        description: 'Sign in as admin',
        tag: 'Full access',
        iconBg: const Color(0xFFEAF3DE),
        iconColor: const Color(0xFF3B6D11),
        tagBg: const Color(0xFFEAF3DE),
        tagColor: const Color(0xFF3B6D11),
        onTap: onAdminTap,
      ),
      _ActionItem(
        icon: Icons.storefront_rounded,
        label: 'Manager',
        description: 'Sign in as manager',
        tag: 'Branch access',
        iconBg: const Color(0xFFE6F1FB),
        iconColor: const Color(0xFF185FA5),
        tagBg: const Color(0xFFE6F1FB),
        tagColor: const Color(0xFF185FA5),
        onTap: onManagerTap,
      ),
      _ActionItem(
        icon: Icons.person_add_rounded,
        label: 'Activate',
        description: 'Create your account',
        tag: 'New manager',
        iconBg: const Color(0xFFFAEEDA),
        iconColor: const Color(0xFF854F0B),
        tagBg: const Color(0xFFFAEEDA),
        tagColor: const Color(0xFF854F0B),
        onTap: onActivateTap,
      ),
      _ActionItem(
        icon: Icons.info_outline_rounded,
        label: 'About',
        description: 'App information',
        tag: null,
        iconBg: const Color(0xFFF1EFE8),
        iconColor: const Color(0xFF5F5E5A),
        tagBg: Colors.transparent,
        tagColor: Colors.transparent,
        onTap: onAboutTap,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 14),
              child: Text(
                'QUICK ACCESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _C.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, i) {
                  return _ActionCard(
                    item: actions[i],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────
class _ActionItem {
  final IconData icon;
  final String label;
  final String description;
  final String? tag;
  final Color iconBg;
  final Color iconColor;
  final Color tagBg;
  final Color tagColor;
  final void Function(BuildContext context) onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.tag,
    required this.iconBg,
    required this.iconColor,
    required this.tagBg,
    required this.tagColor,
    required this.onTap,
  });
}

class _ActionCard extends StatefulWidget {
  final _ActionItem item;

  const _ActionCard({
    required this.item,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });

        widget.item.onTap(context);
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xFFF2F6F3)
                : const Color(0xFFF7FBF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.black.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.item.iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.item.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: _C.textMuted,
                  height: 1.3,
                ),
              ),
              if (widget.item.tag != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.item.tagBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    widget.item.tag!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.item.tagColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}