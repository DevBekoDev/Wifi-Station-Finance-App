import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/app_navigator_key.dart';
import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/utils/constants/app_theme.dart';
import 'services/gemini_finance_assistant_service.dart';
import 'services/firebase_options.dart';
import 'screens/starting_screen.dart';
import 'package:wsfm/services/ai/finance_ai_context_service.dart';
import 'package:wsfm/services/ai/ai_user_session.dart';
import 'utils/ai_assistant_overlay.dart';
import 'utils/ai_voice_controller.dart';
import 'utils/ai_route_observer.dart';
import 'utils/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
static final GeminiFinanceAssistantService geminiService =
    GeminiFinanceAssistantService();
    static final FinanceAiContextService financeContextService =
    FinanceAiContextService();
  static final AiVoiceController aiVoiceController = AiVoiceController();

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

            // Hide AI button on starting/login/signup pages.
            hiddenRoutes: const {
              '/',
              AppRoutes.login,
              AppRoutes.signup,
            },

            connector: AiAssistantConnector(
sendText: (message, history) async {
  String financeContext;

  if (AiUserSession.isAdmin) {
    financeContext =
        await financeContextService.buildAdminFinanceContext();
  } else {
    final centerId = AiUserSession.centerId;

    if (centerId == null || centerId.isEmpty) {
      return 'No center ID found for this manager user.';
    }

    financeContext = await financeContextService.buildAiFinanceContext(
      centerId: centerId,
    );
  }

  return geminiService.ask(
    message: message,
    financeContext: financeContext,
    history: history,
  );
},
  listenToUser: aiVoiceController.listenOnce,
  speakAssistantMessage: aiVoiceController.speak,
),

            child: child ?? const SizedBox.shrink(),
          );
        },

        home: const StartScreen(),
      ),
    );
  }
}