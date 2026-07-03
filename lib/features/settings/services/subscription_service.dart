import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // TODO: Add your RevenueCat API keys from https://app.revenuecat.com/
  // Get keys from: Settings > API Keys > Public app-specific API keys
  static const String _apiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: 'goog_demo_key', // Demo mode - replace with real key
  );
  static const String _apiKeyIos = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: 'appl_demo_key', // Demo mode - replace with real key
  );
  static const String _proEntitlement = 'pro';

  static Future<void> init() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    final apiKey = Platform.isAndroid ? _apiKeyAndroid : _apiKeyIos;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_proEntitlement);
    } catch (e) {
      debugPrint('Error checking pro status: $e');
      return false;
    }
  }

  Future<bool> purchaseMonthly() async {
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly != null) {
        await Purchases.purchase(
          PurchaseParams.package(monthly),
        );
        final info = await Purchases.getCustomerInfo();
        return info.entitlements.active.containsKey(_proEntitlement);
      }
      return false;
    } catch (e) {
      debugPrint('Monthly purchase failed: $e');
      return false;
    }
  }

  Future<bool> purchaseAnnual() async {
    try {
      final offerings = await Purchases.getOfferings();
      final annual = offerings.current?.annual;
      if (annual != null) {
        await Purchases.purchase(
          PurchaseParams.package(annual),
        );
        final info = await Purchases.getCustomerInfo();
        return info.entitlements.active.containsKey(_proEntitlement);
      }
      return false;
    } catch (e) {
      debugPrint('Annual purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Restore failed: $e');
      rethrow;
    }
  }

  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  Future<bool> hasTrialAvailable() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.monthly != null;
    } catch (e) {
      return false;
    }
  }
}
