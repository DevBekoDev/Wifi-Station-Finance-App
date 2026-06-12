import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/cubits/auth/auth_state.dart';
import 'package:wsfm/screens/admin_dashboard_screen.dart';
import 'package:wsfm/screens/manager_dashboard_screen.dart';
import 'package:wsfm/utils/app_routes.dart';
import 'package:wsfm/services/ai/ai_user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool _hidePassword = true;
  String? errorMessage;
  bool isLoading = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Please enter your email and password.";
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    try {
      context.read<AuthCubit>().loginWithEmail(email, password);
    } catch (e) {
      setState(() {
        errorMessage = "Unexpected error: $e";
      });
    }
  }

  void _handleGoogleLogin() {
    setState(() {
      errorMessage = null;
    });

    try {
      context.read<AuthCubit>().loginWithGoogle();
    } catch (e) {
      setState(() {
        errorMessage = "Google login error: $e";
      });
    }
  }

  void _handleForgotPassword() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage = "Enter your email first.";
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    context.read<AuthCubit>().resetPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            isLoading = true;
            errorMessage = null;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }

        if (state is AuthError) {
          setState(() {
            errorMessage = state.message;
          });
        }
if (state is AuthSuccess) {
  AiUserSession.setUser(
  userRole: state.role,
  userCenterId: state.centerId,
);
  if (state.role == 'admin') {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(
          name: AppRoutes.adminDashboard,
        ),
        builder: (_) => const AdminDashboardScreen(),
      ),
      (route) => false,
    );
  } else if (state.role == 'manager') {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(
          name: AppRoutes.managerDashboard,
        ),
        builder: (_) => ManagerDashboardScreen(
          centerId: state.centerId ?? '',
        ),
      ),
      (route) => false,
    );
  }
}
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _AppColors.bgTop,
                _AppColors.bgBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 470),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _TopHeroSection(),
                                  const SizedBox(height: 22),
                                  _LoginCard(
                                    emailController: emailController,
                                    passwordController: passwordController,
                                    emailFocusNode: emailFocusNode,
                                    passwordFocusNode: passwordFocusNode,
                                    hidePassword: _hidePassword,
                                    errorMessage: errorMessage,
                                    isLoading: isLoading,
                                    onTogglePassword: () {
                                      setState(() {
                                        _hidePassword = !_hidePassword;
                                      });
                                    },
                                    onLogin: isLoading ? null : _handleEmailLogin,
                                    onGoogle:
                                        isLoading ? null : _handleGoogleLogin,
                                    onForgot:
                                        isLoading ? null : _handleForgotPassword,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AppColors {
  static const Color bgTop = Color(0xFF062A2A);
  static const Color bgBottom = Color(0xFFEAF6F2);

  static const Color primary = Color(0xFF0D5C63);
  static const Color primaryDark = Color(0xFF083D40);
  static const Color accent = Color(0xFF42A58A);

  static const Color card = Colors.white;
  static const Color inputFill = Color(0xFFF4F7F6);
  static const Color inputBorder = Color(0xFFE3ECE8);

  static const Color textDark = Color(0xFF18302B);
  static const Color textMid = Color(0xFF5F746E);
  static const Color textLight = Color(0xFFEDF6F3);

  static const Color errorBg = Color(0xFFFFF2F1);
  static const Color errorBorder = Color(0xFFF3C9C5);
  static const Color errorText = Color(0xFFB33A32);
}

class _TopHeroSection extends StatelessWidget {
  const _TopHeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _AppColors.primaryDark,
            _AppColors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -35,
            right: -20,
            child: _GlowCircle(
              size: 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -45,
            left: -15,
            child: _GlowCircle(
              size: 100,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "WSFM",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "Welcome back",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Sign in to manage stations, track sales, and review financial performance in one place.",
                style: TextStyle(
                  color: _AppColors.textLight.withOpacity(0.86),
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _MiniInfoChip(
                    icon: Icons.bar_chart_rounded,
                    text: "Reports",
                  ),
                  _MiniInfoChip(
                    icon: Icons.apartment_rounded,
                    text: "Centers",
                  ),
                  _MiniInfoChip(
                    icon: Icons.payments_outlined,
                    text: "Sales",
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
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

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool hidePassword;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback? onLogin;
  final VoidCallback? onGoogle;
  final VoidCallback? onForgot;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.hidePassword,
    required this.errorMessage,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onGoogle,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Login",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter your account details below.",
            style: TextStyle(
              fontSize: 13.5,
              color: _AppColors.textMid,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          const _InputLabel("Email address"),
          const SizedBox(height: 8),
          _ModernTextField(
            controller: emailController,
            focusNode: emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hintText: "you@example.com",
            prefixIcon: Icons.email_outlined,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(passwordFocusNode);
            },
          ),
          const SizedBox(height: 16),
          const _InputLabel("Password"),
          const SizedBox(height: 8),
          _ModernTextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            obscureText: hidePassword,
            textInputAction: TextInputAction.done,
            hintText: "Enter your password",
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _AppColors.textMid,
              ),
            ),
            onSubmitted: (_) => onLogin?.call(),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgot,
              style: TextButton.styleFrom(
                foregroundColor: _AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            _ErrorMessageBox(message: errorMessage!),
            const SizedBox(height: 14),
          ],
          _PrimaryButton(
            text: "Login",
            isLoading: isLoading,
            onTap: onLogin,
          ),
          const SizedBox(height: 18),
          const _DividerText(),
          const SizedBox(height: 18),
          _GoogleButton(
            onTap: onGoogle,
            isLoading: isLoading,
          ),
          const SizedBox(height: 20),
          Center(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  color: _AppColors.textMid,
                ),
                children: [
                  TextSpan(text: "Need a manager account? "),
                  TextSpan(
                    text: "Contact admin",
                    style: TextStyle(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;

  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _AppColors.textDark,
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _ModernTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: false,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: _AppColors.textDark,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _AppColors.textMid,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: _AppColors.textMid,
          size: 20,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: _AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _AppColors.inputBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ErrorMessageBox extends StatelessWidget {
  final String message;

  const _ErrorMessageBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _AppColors.errorText,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _AppColors.errorText,
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
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.text,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              _AppColors.primaryDark,
              _AppColors.primary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _AppColors.primary.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.login_rounded, size: 18),
                    SizedBox(width: 10),
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withOpacity(0.08),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "or continue with",
            style: TextStyle(
              color: _AppColors.textMid,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _GoogleButton({
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF9FCFB),
          foregroundColor: _AppColors.textDark,
          side: const BorderSide(
            color: _AppColors.inputBorder,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFFEAF4EC),
              child: Icon(
                Icons.g_mobiledata,
                size: 22,
                color: _AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              "Continue with Google",
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}