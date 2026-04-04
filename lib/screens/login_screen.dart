import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/cubits/auth/auth_state.dart';
import 'package:wsfm/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _hidePassword = true;
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() {
    debugPrint("Login button tapped");

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    debugPrint("Email entered: $email");
    debugPrint("Password length: ${password.length}");

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Please enter email and password.";
      });
      debugPrint("Validation failed: empty email or password");
      return;
    }

    setState(() {
      errorMessage = null;
    });

    try {
      debugPrint("Calling AuthCubit.loginWithEmail");
      context.read<AuthCubit>().loginWithEmail(email, password);
      debugPrint("AuthCubit.loginWithEmail called");
    } catch (e) {
      debugPrint("onPressed error: $e");
      setState(() {
        errorMessage = "Unexpected error: $e";
      });
    }
  }

  void _handleGoogleLogin() {
    debugPrint("Google button tapped");

    setState(() {
      errorMessage = null;
    });

    try {
      context.read<AuthCubit>().loginWithGoogle();
      debugPrint("AuthCubit.loginWithGoogle called");
    } catch (e) {
      debugPrint("Google button error: $e");
      setState(() {
        errorMessage = "Google login error: $e";
      });
    }
  }

  void _handleForgotPassword() {
    debugPrint("Forgot password tapped");

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
        debugPrint("Bloc state changed: ${state.runtimeType}");

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
          debugPrint("AuthError message: ${state.message}");
          setState(() {
            errorMessage = state.message;
          });
        }

        if (state is AuthSuccess) {
          debugPrint("AuthSuccess role: ${state.role}, centerId: ${state.centerId}");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE0F2F1),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipPath(
                      clipper: HeaderClipper(),
                      child: Container(
                        height: 260,
                        width: double.infinity,
                        color: const Color(0xFF00695C),
                      ),
                    ),
                    const Positioned(
                      left: 25,
                      top: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello!",
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Welcome to WiFi Station Finance Manager",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: passwordController,
                        obscureText: _hidePassword,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _handleEmailLogin(),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : _handleForgotPassword,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Color(0xFF00695C)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleEmailLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                            disabledBackgroundColor: const Color(0xFF00695C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Or login with"),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SocialIcon(Icons.facebook),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: isLoading ? null : _handleGoogleLogin,
                            child: const SocialIcon(Icons.g_mobiledata),
                          ),
                          const SizedBox(width: 20),
                          const SocialIcon(Icons.apple),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don’t have an account? "),
                          GestureDetector(
                            onTap: () {
                              debugPrint("Create account tapped");
                            },
                            child: const Text(
                              "Create",
                              style: TextStyle(
                                color: Color(0xFF00695C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class SocialIcon extends StatelessWidget {
  final IconData icon;

  const SocialIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00695C),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF00695C),
        size: 24,
      ),
    );
  }
}