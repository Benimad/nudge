import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps RevenueCat and owns the free-vs-Pro policy.
///
/// Free users get a genuine taste of every headline feature via daily quotas
/// (see [aiMessagesPerDayFree] / [focusSessionsPerDayFree]) rather than a hard
/// wall — they experience the value before being asked to pay. Pro removes the
/// limits and the 5-habit cap.
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Inject real keys at build time:
  //   --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx --dart-define=REVENUECAT_IOS_KEY=appl_xxx
  static const String _apiKeyAndroid =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY', defaultValue: 'goog_demo_key');
  static const String _apiKeyIos =
      String.fromEnvironment('REVENUECAT_IOS_KEY', defaultValue: 'appl_demo_key');
  static const String _proEntitlement = 'pro';

  /// True when a real store key is present for THIS platform, so an
  /// Android-only launch works without an iOS key (and vice versa). In demo
  /// mode we don't pretend to have a billing backend — the paywall explains it
  /// instead of failing.
  static bool get isConfigured {
    final key = Platform.isAndroid ? _apiKeyAndroid : _apiKeyIos;
    return !key.contains('demo');
  }

  // Free-tier allowances.
  static const int aiMessagesPerDayFree = 5;
  static const int focusSessionsPerDayFree = 1;
  static const int freeHabitCap = 5;

  /// Live Pro status. Updated by RevenueCat's customer-info listener so gated
  /// UI unlocks the instant a purchase completes — no app restart.
  static final ValueNotifier<bool> isProNotifier = ValueNotifier<bool>(false);

  static Future<void> init() async {
    if (!isConfigured) {
      debugPrint('ℹ️ RevenueCat in demo mode (no store keys) — purchases disabled');
      return;
    }
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    final apiKey = Platform.isAndroid ? _apiKeyAndroid : _apiKeyIos;
    await Purchases.configure(PurchasesConfiguration(apiKey));

    Purchases.addCustomerInfoUpdateListener((info) {
      isProNotifier.value = info.entitlements.active.containsKey(_proEntitlement);
    });
    try {
      final info = await Purchases.getCustomerInfo();
      isProNotifier.value = info.entitlements.active.containsKey(_proEntitlement);
    } catch (_) {}
  }

  Future<bool> isPro() async {
    if (!isConfigured) return isProNotifier.value;
    try {
      final info = await Purchases.getCustomerInfo();
      final pro = info.entitlements.active.containsKey(_proEntitlement);
      isProNotifier.value = pro;
      return pro;
    } catch (e) {
      debugPrint('Error checking pro status: $e');
      return isProNotifier.value;
    }
  }

  Future<Offerings> getOfferings() async => Purchases.getOfferings();

  Future<bool> purchaseMonthly() => _purchase((o) => o.current?.monthly);
  Future<bool> purchaseAnnual() => _purchase((o) => o.current?.annual);

  Future<bool> _purchase(Package? Function(Offerings) select) async {
    if (!isConfigured) {
      throw Exception('Purchases are not available in this build.');
    }
    final offerings = await Purchases.getOfferings();
    final pkg = select(offerings);
    if (pkg == null) return false;
    await Purchases.purchase(PurchaseParams.package(pkg));
    final info = await Purchases.getCustomerInfo();
    final pro = info.entitlements.active.containsKey(_proEntitlement);
    isProNotifier.value = pro;
    return pro;
  }

  Future<void> restorePurchases() async {
    if (!isConfigured) return;
    final info = await Purchases.restorePurchases();
    isProNotifier.value = info.entitlements.active.containsKey(_proEntitlement);
  }

  Future<CustomerInfo> getCustomerInfo() async => Purchases.getCustomerInfo();

  Future<bool> hasTrialAvailable() async {
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) return false;
      // Only advertise a trial if the store product actually carries one.
      return monthly.storeProduct.introductoryPrice != null;
    } catch (_) {
      return false;
    }
  }

  // ── Daily free-tier quota (per calendar day, resets automatically) ───────────

  Future<bool> _hasQuota(String feature, int perDayFree) async {
    if (await isPro()) return true;
    final prefs = await SharedPreferences.getInstance();
    final key = 'quota_${feature}_${_today()}';
    final used = prefs.getInt(key) ?? 0;
    return used < perDayFree;
  }

  Future<void> _consume(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quota_${feature}_${_today()}';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  Future<int> remaining(String feature, int perDayFree) async {
    if (await isPro()) return 1 << 30;
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt('quota_${feature}_${_today()}') ?? 0;
    return (perDayFree - used).clamp(0, perDayFree);
  }

  Future<bool> canUseAi() => _hasQuota('ai', aiMessagesPerDayFree);
  Future<void> registerAiUse() => _consume('ai');
  Future<bool> canStartFocus() => _hasQuota('focus', focusSessionsPerDayFree);
  Future<void> registerFocusUse() => _consume('focus');

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}
