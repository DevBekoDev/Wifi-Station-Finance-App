import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/screens/login_screen.dart';
import 'package:wsfm/screens/manager_activation_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const Color dark1 = Color(0xFF051F20);
  static const Color dark2 = Color(0xFF0B2B26);
  static const Color dark3 = Color(0xFF163832);
  static const Color dark4 = Color(0xFF235347);
  static const Color mint = Color(0xFF8EB69B);
  static const Color lightMint = Color(0xFFDAF1DE);
  static const Color bodyBg = Color(0xFFF7FBF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightMint,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWebLike = width >= 900;
            final isTablet = width >= 600 && width < 900;

            final contentMaxWidth = isWebLike ? 1200.0 : 700.0;
            final heroHeight = isWebLike ? 320.0 : 280.0;
            final topPadding = isWebLike ? 28.0 : 20.0;
            final headerRadius = isWebLike ? 42.0 : 32.0;
            final panelRadius = isWebLike ? 38.0 : 30.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.all(isWebLike ? 24 : 14),
                  child: isWebLike
                      ? _DesktopStartLayout(
                          heroHeight: heroHeight,
                          headerRadius: headerRadius,
                          panelRadius: panelRadius,
                          topPadding: topPadding,
                        )
                      : _MobileStartLayout(
                          heroHeight: heroHeight,
                          headerRadius: headerRadius,
                          panelRadius: panelRadius,
                          topPadding: topPadding,
                          isTablet: isTablet,
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

class _DesktopStartLayout extends StatelessWidget {
  final double heroHeight;
  final double headerRadius;
  final double panelRadius;
  final double topPadding;

  const _DesktopStartLayout({
    required this.heroHeight,
    required this.headerRadius,
    required this.panelRadius,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: _HeroPanel(
            height: heroHeight,
            radius: headerRadius,
            topPadding: topPadding,
            large: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 10,
          child: _ActionPanel(
            radius: panelRadius,
            crossAxisCount: 2,
            childAspectRatio: 1.18,
            showFooterIcon: true,
          ),
        ),
      ],
    );
  }
}

class _MobileStartLayout extends StatelessWidget {
  final double heroHeight;
  final double headerRadius;
  final double panelRadius;
  final double topPadding;
  final bool isTablet;

  const _MobileStartLayout({
    required this.heroHeight,
    required this.headerRadius,
    required this.panelRadius,
    required this.topPadding,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroPanel(
          height: heroHeight,
          radius: headerRadius,
          topPadding: topPadding,
          large: isTablet,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _ActionPanel(
            radius: panelRadius,
            crossAxisCount: 2,
            childAspectRatio: isTablet ? 1.15 : 0.96,
            showFooterIcon: true,
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final double height;
  final double radius;
  final double topPadding;
  final bool large;

  const _HeroPanel({
    required this.height,
    required this.radius,
    required this.topPadding,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StartScreen.dark1,
            StartScreen.dark2,
            StartScreen.dark3,
            StartScreen.dark4,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -10,
            child: Container(
              width: large ? 180 : 120,
              height: large ? 180 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: topPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // children: [
                
                
                
              //   Icon(
              //     Icons.menu_rounded,
              //     color: Colors.white.withOpacity(0.9),
              //     size: large ? 24 : 20,
              //   ),
              // ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: large ? 140 : 112,
                  height: large ? 140 : 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(large ? 36 : 28),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_rounded,
                    color: Colors.white,
                    size: large ? 66 : 54,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'WSFM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: large ? 42 : 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: large ? 140 : 100,
                  height: 5,
                  decoration: BoxDecoration(
                    color: StartScreen.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                // Text(
                //   'WiFi Station Finance Manager',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: large ? 16 : 14,
                //     color: Colors.white.withOpacity(0.76),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final double radius;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool showFooterIcon;

  const _ActionPanel({
    required this.radius,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.showFooterIcon,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _StartActionData(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Admin Login',
        subtitle: 'Sign in as admin',
        bgColor: const Color(0xFFFFF8E8),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => AuthCubit(),
                child: const LoginScreen(),
              ),
            ),
          );
        },
      ),
      _StartActionData(
        icon: Icons.storefront_rounded,
        title: 'Manager Login',
        subtitle: 'Sign in as manager',
        bgColor: const Color(0xFFFFF8E8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => AuthCubit(),
                child: const LoginScreen(),
              ),
            ),
          );
        },
      ),
      _StartActionData(
        icon: Icons.lock_open_rounded,
        title: 'Activate Manager',
        subtitle: 'Create your account',
        bgColor: const Color(0xFFEAF7F0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManagerActivationScreen(),
            ),
          );
        },
      ),
      _StartActionData(
        icon: Icons.info_outline_rounded,
        title: 'About App',
        subtitle: 'Quick information',
        bgColor: const Color(0xFFF5F7FB),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('About WSFM'),
              content: const Text(
                'WSFM helps admins and managers manage WiFi station finances, centers, sales, expenses, and reports.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 238, 255, 240),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: actions.length,
                physics: const ClampingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final item = actions[index];
                  return _ResponsiveActionCard(data: item);
                },
              ),
            ),
            if (showFooterIcon) ...[
              const SizedBox(height: 12),
              // Container(
              //   width: 66,
              //   height: 66,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     color: Color.fromARGB(255, 238, 255, 240),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.08),
              //         blurRadius: 16,
              //         offset: const Offset(0, 8),
              //       ),
              //     ],
              //   ),
              //   child: const Icon(
              //     Icons.sync_rounded,
              //     size: 30,
              //     color: StartScreen.dark4,
              //   ),
              // ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bgColor;
  final VoidCallback onTap;

  const _StartActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.onTap,
  });
}

class _ResponsiveActionCard extends StatelessWidget {
  final _StartActionData data;

  const _ResponsiveActionCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(255, 238, 255, 240),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.09),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: data.bgColor,
                  child: Icon(
                    data.icon,
                    color: StartScreen.dark4,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1E36),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.42),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}