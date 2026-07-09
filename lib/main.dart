import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/app_settings.dart';
import 'core/services/firebase_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/firestore_service.dart';
import 'features/settings/services/subscription_service.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/goals_screen.dart';
import 'features/onboarding/screens/reminder_setup_screen.dart';
import 'features/ai_coach/controllers/chat_controller.dart';
import 'features/habits/controllers/home_controller.dart';
import 'features/habits/screens/home_screen.dart';
import 'features/body_doubling/controllers/body_doubling_controller.dart';
import 'features/paralysis_mode/screens/paralysis_mode_screen.dart';
import 'features/body_doubling/screens/body_doubling_screen.dart';
import 'features/ai_coach/screens/ai_coach_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/paywall_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Accessibility prefs are needed for the very first frame.
  await AppSettings.instance.load();

  // Critical-path only: Firebase (identity) + local database. Everything else
  // is kicked off after the first frame so a cold start on poor network never
  // hangs on a network round-trip.
  final firebaseInitialized = await FirebaseService.initialize();
  if (firebaseInitialized) {
    try {
      if (AuthService().currentUser == null) {
        await AuthService().signInAnonymously();
      }
    } catch (e) {
      debugPrint('⚠️ Anonymous sign-in error: $e');
    }
  } else {
    debugPrint('⚠️ App running without Firebase - some features may be limited');
  }

  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('❌ Database init error: $e');
  }

  Get.put(HomeController(), permanent: true);
  Get.put(ChatController(), permanent: true);
  Get.put(BodyDoublingController(), permanent: true);

  runApp(const NudgeApp());

  // Deferred, non-blocking initialization.
  unawaited(_initDeferred(firebaseInitialized));
}

Future<void> _initDeferred(bool firebaseInitialized) async {
  try {
    await SubscriptionService.init();
  } catch (e) {
    debugPrint('⚠️ RevenueCat init error: $e');
  }
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('⚠️ Notification init error: $e');
  }
  try {
    await AnalyticsService.init();
  } catch (e) {
    debugPrint('⚠️ Analytics init error: $e');
  }

  // Cloud → local restore: if a signed-in user has an empty local database
  // (e.g. fresh install), pull their habits and history back. Non-destructive.
  if (firebaseInitialized) {
    try {
      final user = AuthService().currentUser;
      if (user != null && !user.isAnonymous) {
        final home = Get.find<HomeController>();
        if (home.habits.isEmpty) {
          final restored = await FirestoreService().restoreFromCloud();
          if (restored > 0) await home.refreshData();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Cloud restore skipped: $e');
    }
  }
}

class NudgeApp extends StatefulWidget {
  const NudgeApp({super.key});

  @override
  State<NudgeApp> createState() => _NudgeAppState();
}

class _NudgeAppState extends State<NudgeApp> {
  final _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _applyMotion();
    _settings.reduceMotion.addListener(_applyMotion);
  }

  @override
  void dispose() {
    _settings.reduceMotion.removeListener(_applyMotion);
    super.dispose();
  }

  /// Reduce-motion is a global concern for flutter_animate (which drives most
  /// of the app's animation), so we collapse its default duration to zero.
  void _applyMotion() {
    Animate.defaultDuration =
        _settings.reduceMotion.value ? Duration.zero : const Duration(milliseconds: 300);
  }

  void _registerActivity() {
    try {
      Get.find<HomeController>().resetParalysisTimer();
    } catch (_) {}
  }

  ThemeData _highContrastLight() => AppTheme.lightTheme.copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3B2CA0),
          secondary: Color(0xFF00563B),
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.highContrast,
      builder: (context, highContrast, _) {
        return ValueListenableBuilder<double>(
          valueListenable: _settings.extraTextScale,
          builder: (context, extraScale, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _settings.reduceMotion,
              builder: (context, reduceMotion, _) {
                return GetMaterialApp(
                  title: 'Nudge',
                  debugShowCheckedModeBanner: false,
                  theme: highContrast ? _highContrastLight() : AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ThemeMode.system,
                  navigatorKey: Get.key,
                  initialRoute: '/splash',
                  defaultTransition: Transition.cupertino,
                  transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 320),
                  builder: (context, child) {
                    // Compose OUR extra scale on top of the OS setting instead of
                    // replacing it, so a low-vision user's system font size still
                    // counts.
                    final osFactor = MediaQuery.textScalerOf(context).scale(100) / 100;
                    return Listener(
                      onPointerDown: (_) => _registerActivity(),
                      onPointerMove: (_) => _registerActivity(),
                      behavior: HitTestBehavior.translucent,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(osFactor * extraScale),
                          disableAnimations: reduceMotion,
                        ),
                        child: child!,
                      ),
                    );
                  },
                  getPages: [
                    GetPage(name: '/', page: () => const WelcomeScreen()),
                    GetPage(
                      name: '/splash',
                      page: () => const SplashScreen(),
                      transition: Transition.fadeIn,
                      transitionDuration: const Duration(milliseconds: 350),
                    ),
                    GetPage(name: '/onboarding/welcome', page: () => const WelcomeScreen()),
                    GetPage(name: '/onboarding/goals', page: () => const GoalsScreen()),
                    GetPage(name: '/onboarding/reminders', page: () => const ReminderSetupScreen()),
                    GetPage(name: '/home', page: () => const HomeScreen()),
                    GetPage(name: '/paralysis-mode', page: () => const ParalysisModeScreen()),
                    GetPage(name: '/body-doubling', page: () => const BodyDoublingScreen()),
                    GetPage(name: '/ai-coach', page: () => const AiCoachScreen()),
                    GetPage(name: '/stats', page: () => const StatsScreen()),
                    GetPage(name: '/settings', page: () => const SettingsScreen()),
                    GetPage(name: '/paywall', page: () => const PaywallScreen()),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
