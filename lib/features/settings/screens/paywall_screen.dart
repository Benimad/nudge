import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  bool _annualSelected = true;
  String _monthlyPrice = '\$6.99';
  String _annualPrice = '\$49.99';
  int? _savingsPercent;
  bool _trialAvailable = false;
  final bool _configured = SubscriptionService.isConfigured;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    if (!_configured) return;
    try {
      final offerings = await _subscriptionService.getOfferings();
      final monthly = offerings.current?.monthly;
      final annual = offerings.current?.annual;
      final trial = await _subscriptionService.hasTrialAvailable();
      if (mounted && monthly != null && annual != null) {
        // Compute the real discount from actual store prices rather than a
        // hardcoded "SAVE 40%".
        int? savings;
        final m = monthly.storeProduct.price;
        final a = annual.storeProduct.price;
        if (m > 0 && a > 0) {
          final pct = (1 - (a / (m * 12))) * 100;
          if (pct > 0) savings = pct.round();
        }
        setState(() {
          _monthlyPrice = monthly.storeProduct.priceString;
          _annualPrice = annual.storeProduct.priceString;
          _savingsPercent = savings;
          _trialAvailable = trial;
        });
      }
    } catch (e) {
      // Keep defaults if RevenueCat fails
    }
  }

  Future<void> _openLegal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Could not open link', url, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _purchase() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final success = _annualSelected
          ? await _subscriptionService.purchaseAnnual()
          : await _subscriptionService.purchaseMonthly();
      if (success && mounted) {
        Get.back(result: true);
        Get.snackbar(
          'Welcome to Nudge Pro',
          'Your subscription is active!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF006C4E),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Purchase failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: context.colors.warningContainer,
          colorText: context.colors.onWarningContainer,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.restorePurchases();
      final isPro = await _subscriptionService.isPro();
      if (isPro && mounted) {
        Get.back(result: true);
        Get.snackbar(
          'Restored',
          'Your previous purchase has been restored.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF006C4E),
          colorText: Colors.white,
        );
      } else if (mounted) {
        Get.snackbar(
          'No purchase found',
          'We couldn\'t find a previous purchase to restore.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Restore failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: context.colors.warningContainer,
          colorText: context.colors.onWarningContainer,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.close, size: 20, color: context.colors.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // App icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF574EB1),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),

              Text(
                'Nudge Pro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  color: context.colors.text,
                ),
              ),
              const SizedBox(height: 32),

              // Benefits
              _buildBenefitRow(context, 'Unlimited habits (free = 5 max)'),
              const SizedBox(height: 16),
              _buildBenefitRow(context, 'AI coach — unlimited conversations'),
              const SizedBox(height: 16),
              _buildBenefitRow(context, 'Body doubling focus rooms'),
              const SizedBox(height: 48),

              // Pricing cards
              Row(
                children: [
                  // Monthly
                  Expanded(
                    child: _buildPricingCard(
                      context: context,
                      plan: 'Monthly',
                      price: _monthlyPrice,
                      period: '/month',
                      isRecommended: !_annualSelected,
                      onTap: () => setState(() => _annualSelected = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Annual (recommended)
                  Expanded(
                    child: _buildPricingCard(
                      context: context,
                      plan: 'Annual',
                      price: _annualPrice,
                      period: '/year',
                      isRecommended: _annualSelected,
                      badge: _savingsPercent != null ? 'SAVE ${_savingsPercent!}%' : 'BEST VALUE',
                      onTap: () => setState(() => _annualSelected = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_configured) ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.colors.outlineVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          !_configured
                              ? 'Coming soon'
                              : _trialAvailable
                                  ? 'Start free trial'
                                  : 'Continue',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !_configured
                    ? 'Subscriptions aren\'t available in this build yet.'
                    : _trialAvailable
                        ? 'Cancel anytime — you\'ll be billed when the trial ends.'
                        : 'Cancel anytime in the store.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textVariant,
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),

              // Legal — required on iOS, good practice everywhere.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openLegal('https://nudgeapp.co/terms'),
                    child: Text('Terms', style: TextStyle(color: context.colors.textVariant, fontSize: 12, fontFamily: 'Inter')),
                  ),
                  Text('·', style: TextStyle(color: context.colors.textVariant)),
                  TextButton(
                    onPressed: () => _openLegal('https://nudgeapp.co/privacy'),
                    child: Text('Privacy', style: TextStyle(color: context.colors.textVariant, fontSize: 12, fontFamily: 'Inter')),
                  ),
                ],
              ),

              // Restore purchase
              TextButton(
                onPressed: _isLoading ? null : _restore,
                child: Text(
                  'Restore purchase',
                  style: TextStyle(
                    color: context.colors.textVariant,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF006C4E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Inter',
            color: context.colors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard({
    required BuildContext context,
    required String plan,
    required String price,
    required String period,
    required bool isRecommended,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? context.colors.primary : context.colors.outlineVariant,
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: isRecommended
              ? [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.colors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            Text(
              plan,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: context.colors.text,
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
