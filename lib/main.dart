import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'utils/app_navigator_key.dart';
import 'package:wsfm/cubits/auth/auth_cubit.dart';
import 'package:wsfm/utils/constants/app_theme.dart';

import 'services/firebase_options.dart';
import 'screens/starting_screen.dart';

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
              sendText: (message) async {
                // AI TEAM CONNECTS HERE LATER.
                // Example:
                // return await GeminiService.askFinanceAssistant(message);

                await Future.delayed(const Duration(milliseconds: 700));

                return 'AI placeholder answer for: "$message". '
                    'Later this will be connected to Gemini and Firebase finance data.';
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