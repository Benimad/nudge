import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class BreathingCircle extends StatefulWidget {
  final VoidCallback onComplete;

  const BreathingCircle({super.key, required this.onComplete});

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with TickerProviderStateMixin {
  late AnimationController _inhaleController;
  late AnimationController _holdInController;
  late AnimationController _exhaleController;
  late AnimationController _holdOutController;

  int _phase = 0; // 0=inhale, 1=hold, 2=exhale, 3=hold
  int _cyclesCompleted = 0;
  final int _targetCycles = 3;

  static const Duration _phaseDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _inhaleController = AnimationController(
      vsync: this,
      duration: _phaseDuration,
    );
    _holdInController = AnimationController(
      vsync: this,
      duration: _phaseDuration,
    );
    _exhaleController = AnimationController(
      vsync: this,
      duration: _phaseDuration,
    );
    _holdOutController = AnimationController(
      vsync: this,
      duration: _phaseDuration,
    );

    _startSequence();
  }

  void _startSequence() {
    if (_cyclesCompleted >= _targetCycles) {
      widget.onComplete();
      return;
    }
    setState(() => _phase = 0);
    _inhaleController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() => _phase = 1);
      _holdInController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        setState(() => _phase = 2);
        _exhaleController.forward(from: 0.0).then((_) {
          if (!mounted) return;
          setState(() => _phase = 3);
          _holdOutController.forward(from: 0.0).then((_) {
            if (!mounted) return;
            _cyclesCompleted++;
            _startSequence();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _inhaleController.dispose();
    _holdInController.dispose();
    _exhaleController.dispose();
    _holdOutController.dispose();
    super.dispose();
  }

  double get _scale {
    switch (_phase) {
      case 0:
        return 0.6 + (_inhaleController.value * 0.4);
      case 1:
        return 1.0;
      case 2:
        return 1.0 - (_exhaleController.value * 0.4);
      case 3:
        return 0.6;
      default:
        return 0.6;
    }
  }

  String get _label {
    switch (_phase) {
      case 0:
        return 'Breathe in...';
      case 1:
        return 'Hold...';
      case 2:
        return 'Breathe out...';
      case 3:
        return 'Hold...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _inhaleController,
            _holdInController,
            _exhaleController,
            _holdOutController,
          ]),
          builder: (context, child) {
            return Container(
              width: 200 * _scale,
              height: 200 * _scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        Text(
          'Cycle ${_cyclesCompleted + 1} of $_targetCycles',
          style: const TextStyle(color: AppTheme.textVariantColor),
        ).animate().fadeIn(),
      ],
    );
  }
}
