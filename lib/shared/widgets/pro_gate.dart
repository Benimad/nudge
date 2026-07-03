import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/settings/services/subscription_service.dart';
import '../../core/theme/app_theme.dart';

class ProGate extends StatefulWidget {
  final Widget child;
  final String? featureName;

  const ProGate({
    super.key,
    required this.child,
    this.featureName,
  });

  @override
  State<ProGate> createState() => _ProGateState();
}

class _ProGateState extends State<ProGate> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final isPro = await _subscriptionService.isPro();
    if (mounted) {
      setState(() {
        _isPro = isPro;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    if (_isPro) {
      return widget.child;
    }

    return GestureDetector(
      onTap: () => Get.toNamed('/paywall'),
      child: Stack(
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: 0.5,
              child: widget.child,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.featureName ?? 'Pro feature',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  const Text(
                    'Tap to upgrade',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textVariantColor,
                      fontFamily: 'Quicksand',
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
