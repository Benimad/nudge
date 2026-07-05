import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/analytics_service.dart';
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

  // Initialize Firebase
  final firebaseInitialized = await FirebaseService.initialize();
  if (!firebaseInitialized) {
    debugPrint('⚠️ App running without Firebase - some features may be limited');
  } else {
    // Every user needs a Firebase identity for Firestore sync to have
    // somewhere to write, whether or not they ever tap "Sign in with Google".
    try {
      if (AuthService().currentUser == null) {
        await AuthService().signInAnonymously();
      }
    } catch (e) {
      debugPrint('⚠️ Anonymous sign-in error: $e');
    }
  }

  // Initialize Database
  try {
    await DatabaseHelper.instance.database;
    debugPrint('✅ Database initialized');
  } catch (e) {
    debugPrint('❌ Database init error: $e');
  }

  // Initialize RevenueCat
  try {
    await SubscriptionService.init();
    debugPrint('✅ RevenueCat initialized');
  } catch (e) {
    debugPrint('⚠️ RevenueCat init error: $e');
  }

  // Initialize Notifications
  try {
    await NotificationService().init();
    debugPrint('✅ Notifications initialized');
  } catch (e) {
    debugPrint('⚠️ Notification init error: $e');
  }

  // Initialize Analytics (no-op unless POSTHOG_API_KEY is dart-defined)
  try {
    await AnalyticsService.init();
  } catch (e) {
    debugPrint('⚠️ Analytics init error: $e');
  }

  // Initialize controllers globally so IndexedStack children can find them,
  // and so a running focus-session timer survives navigating away from it.
  Get.put(HomeController(), permanent: true);
  Get.put(ChatController(), permanent: true);
  Get.put(BodyDoublingController(), permanent: true);

  runApp(const NudgeApp());
}

class NudgeApp extends StatefulWidget {
  const NudgeApp({super.key});

  @override
  State<NudgeApp> createState() => _NudgeAppState();
}

class _NudgeAppState extends State<NudgeApp> {
  double _textScale = 1.0;
  bool _reduceAnimations = false;
  bool _highContrast = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _registerActivity() {
    try {
      Get.find<HomeController>().resetParalysisTimer();
    } catch (_) {
      // HomeController isn't registered yet (very first frame) — ignore.
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _textScale = (prefs.getBool('large_text') ?? false) ? 1.2 : 1.0;
        _reduceAnimations = prefs.getBool('sensory_safe_ui') ?? false;
        _highContrast = prefs.getBool('high_contrast') ?? false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Settings load in a few frames; show a blank brand-colored surface that
      // matches the splash background so launch reads as one continuous scene
      // instead of a white flash + spinner.
      final dark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: dark ? AppColors.dark.background : AppColors.light.background,
        ),
      );
    }

    final theme = _highContrast ? AppTheme.lightTheme.copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0000FF),
        secondary: Color(0xFF008000),
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.white,
    ) : AppTheme.lightTheme;

    return GetMaterialApp(
      title: 'Nudge',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: Get.key,
      initialRoute: '/splash',
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 320),
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) => _registerActivity(),
          onPointerMove: (_) => _registerActivity(),
          behavior: HitTestBehavior.translucent,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_textScale),
              disableAnimations: _reduceAnimations,
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
          // The splash fades itself out, so the route underneath just fades in.
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
  }
}
