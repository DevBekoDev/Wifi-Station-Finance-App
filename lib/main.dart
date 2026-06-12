import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/utils/constants/app_theme.dart';

import 'services/firebase_options.dart';
import 'screens/starting_screen.dart';

// Change these imports if your dashboard files are in another folder
import 'screens/admin_dashboard_screen.dart';
import 'screens/manager_dashboard_screen.dart';

import 'services/ai/ai_user_session.dart';
import 'services/ai/direct_gemini_finance_assistant_service.dart';
import 'services/ai/finance_ai_context_service.dart';

import 'utils/ai_assistant_overlay.dart';
import 'utils/ai_voice_controller.dart';
import 'utils/ai_route_observer.dart';
import 'utils/app_routes.dart';
import 'utils/app_navigator_key.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final AiVoiceController aiVoiceController = AiVoiceController();

  static final FinanceAiContextService financeContextService =
      FinanceAiContextService();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static final DirectGeminiFinanceAssistantService geminiService =
      DirectGeminiFinanceAssistantService(
    apiKey: geminiApiKey,
  );

  static int aiMaxTokensForQuestion(String message) {
    final text = message.toLowerCase();

    final asksEachCenter = text.contains('each center') ||
        text.contains('every center') ||
        text.contains('per center') ||
        text.contains('center by center') ||
        text.contains('each centre') ||
        text.contains('every centre');

    if (asksEachCenter) {
      return 1400;
    }

    final asksAnalysis = text.contains('why') ||
        text.contains('improve') ||
        text.contains('advice') ||
        text.contains('analyze') ||
        text.contains('analyse') ||
        text.contains('recommend') ||
        text.contains('problem') ||
        text.contains('low') ||
        text.contains('reduce') ||
        text.contains('increase');

    if (asksAnalysis) {
      return 900;
    }

    final asksReport = text.contains('report') ||
        text.contains('summary') ||
        text.contains('details') ||
        text.contains('data');

    if (asksReport) {
      return 700;
    }

    final asksSimpleNumber = text.contains('total') ||
        text.contains('profit') ||
        text.contains('sales') ||
        text.contains('expenses') ||
        text.contains('cards');

    if (asksSimpleNumber) {
      return 300;
    }

    return 450;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'wsfm',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        navigatorObservers: [
          aiRouteObserver,
        ],
        builder: (context, child) {
  return AiAssistantOverlay(
    currentRouteListenable: currentRouteName,
    hiddenRoutes: const {
      AppRoutes.login,
      AppRoutes.signup,
    },
    connector: AiAssistantConnector(
      sendText: (message, history) async {
        final directAnswer =
            await financeContextService.tryAnswerDirectly(
          question: message,
          isAdmin: AiUserSession.isAdmin,
          managerCenterId: AiUserSession.centerId,
        );

        if (directAnswer != null) {
          return directAnswer;
        }

        String financeContext;

        if (AiUserSession.isAdmin) {
          financeContext =
              await financeContextService.buildSmartAdminFinanceContext(
            question: message,
          );
        } else {
          final centerId = AiUserSession.centerId;

          if (centerId == null || centerId.isEmpty) {
            return 'No center ID found for this manager user.';
          }

          financeContext = await financeContextService
              .buildSmartManagerFinanceContext(
            question: message,
            managerCenterId: centerId,
          );
        }

        return geminiService.ask(
          message: message,
          financeContext: financeContext,
          history: history,
          maxOutputTokens: aiMaxTokensForQuestion(message),
        );
      },
      listenToUser: aiVoiceController.listenOnce,
      speakAssistantMessage: aiVoiceController.speak,
    ),
    child: child ?? const SizedBox.shrink(),
  );
},
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<_SessionUserData> _loadUserData(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const _SessionUserData.invalid(
          'User account data was not found. Please contact the admin.',
        );
      }

      final data = doc.data()!;

      final role = (data['role'] ?? '').toString().trim().toLowerCase();

      final centerId = (data['centerId'] ??
              data['centerID'] ??
              data['center_id'] ??
              data['assignedCenterId'] ??
              '')
          .toString()
          .trim();

      if (role == 'admin') {
 AiUserSession.setUser(
  userRole: 'admin',
  userCenterId: null,
);
        return const _SessionUserData.admin();
      }

      if (role == 'manager') {
        if (centerId.isEmpty) {
          return const _SessionUserData.invalid(
            'No center ID found for this manager user.',
          );
        }

       AiUserSession.setUser(
  userRole: 'manager',
  userCenterId: centerId,
);

        return _SessionUserData.manager(centerId);
      }

      return _SessionUserData.invalid(
        'Unknown user role: $role',
      );
    } catch (e) {
      return _SessionUserData.invalid(
        'Failed to load user session: $e',
      );
    }
  }

  void _clearAiSession() {
    AiUserSession.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SessionLoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          _clearAiSession();
          return const StartScreen();
        }

        return FutureBuilder<_SessionUserData>(
          future: _loadUserData(user),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _SessionLoadingScreen();
            }

            final sessionData = userSnapshot.data;

            if (sessionData == null || sessionData.type == _SessionType.invalid) {
              return _SessionProblemScreen(
                message: sessionData?.message ??
                    'Could not restore the saved login session.',
              );
            }

            if (sessionData.type == _SessionType.admin) {
              return const AdminDashboardScreen();
            }

            if (sessionData.type == _SessionType.manager) {
              return ManagerDashboardScreen(
                centerId: sessionData.centerId,
              );
            }

            return const StartScreen();
          },
        );
      },
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SessionProblemScreen extends StatelessWidget {
  final String message;

  const _SessionProblemScreen({
    required this.message,
  });

  Future<void> _logout() async {
  AiUserSession.clear();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SessionType {
  admin,
  manager,
  invalid,
}

class _SessionUserData {
  final _SessionType type;
  final String centerId;
  final String? message;

  const _SessionUserData._({
    required this.type,
    this.centerId = '',
    this.message,
  });

  const _SessionUserData.admin()
      : this._(
          type: _SessionType.admin,
        );

  const _SessionUserData.manager(String centerId)
      : this._(
          type: _SessionType.manager,
          centerId: centerId,
        );

  const _SessionUserData.invalid(String message)
      : this._(
          type: _SessionType.invalid,
          message: message,
        );
}