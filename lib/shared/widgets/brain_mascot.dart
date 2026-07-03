import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Friendly smiling-brain mascot, hand-drawn via CustomPainter — no external
/// image assets required. Medium-purple circle with a white brain, happy
/// closed eyes, smile and rays radiating from the top, matching the mockups.
class BrainMascot extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color brainColor;

  const BrainMascot({
    super.key,
    this.size = 128,
    this.backgroundColor = AppTheme.mascotPurple,
    this.brainColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: CustomPaint(painter: _BrainPainter(color: brainColor)),
    );
  }
}

class _BrainPainter extends CustomPainter {
  final Color color;
  _BrainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;

    // Brain occupies the central ~56% of the circle, nudged slightly down so
    // the rays fit above it.
    final w = s * 0.56;
    final h = s * 0.52;
    final left = cx - w / 2;
    final right = cx + w / 2;
    final top = s * 0.28;
    final bottom = top + h;
    final midY = top + h * 0.38;

    final lightPurple = Color.lerp(color, Colors.white, 0.55)!;

    final fill = Paint()
      ..color = const Color(0xFFF3F0FF)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = lightPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Rounded silhouette with a scalloped top edge (brain folds).
    final blob = Path()
      ..moveTo(left, midY)
      ..cubicTo(left, top, cx - w * 0.28, top - h * 0.06, cx - w * 0.16, top + h * 0.05)
      ..cubicTo(cx - w * 0.06, top - h * 0.04, cx + w * 0.06, top - h * 0.04, cx + w * 0.16, top + h * 0.05)
      ..cubicTo(cx + w * 0.28, top - h * 0.06, right, top, right, midY)
      ..cubicTo(right, bottom - h * 0.24, right - w * 0.1, bottom, cx, bottom)
      ..cubicTo(left + w * 0.1, bottom, left, bottom - h * 0.24, left, midY)
      ..close();

    canvas.drawShadow(blob.shift(Offset(0, s * 0.01)), color.withValues(alpha: 0.4), s * 0.02, false);
    canvas.drawPath(blob, fill);
    canvas.drawPath(blob, outline);

    final feature = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;

    // Center seam, upper half only — clear of the face.
    canvas.drawLine(Offset(cx, top + h * 0.04), Offset(cx, midY + h * 0.06), feature);

    // Happy closed eyes — small upward arcs.
    final eyeY = midY + h * 0.2;
    for (final dir in [-1, 1]) {
      final ex = cx + dir * w * 0.2;
      final eye = Path()
        ..moveTo(ex - w * 0.07, eyeY + h * 0.03)
        ..quadraticBezierTo(ex, eyeY - h * 0.06, ex + w * 0.07, eyeY + h * 0.03);
      canvas.drawPath(eye, feature);
    }

    // Smile.
    final smile = Path()
      ..moveTo(cx - w * 0.12, eyeY + h * 0.16)
      ..quadraticBezierTo(cx, eyeY + h * 0.3, cx + w * 0.12, eyeY + h * 0.16);
    canvas.drawPath(smile, feature);

    // Rays/sparks radiating from the sides.
    final ray = Paint()
      ..color = const Color(0xFFF3F0FF)
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;

    // 3 sparks on the left, 3 on the right
    final List<Offset> sparks = [
      // Left side
      Offset(cx - w * 0.45, top + h * 0.1),
      Offset(cx - w * 0.6, top + h * 0.3),
      Offset(cx - w * 0.45, top + h * 0.5),
      // Right side
      Offset(cx + w * 0.45, top + h * 0.1),
      Offset(cx + w * 0.6, top + h * 0.3),
      Offset(cx + w * 0.45, top + h * 0.5),
    ];

    final List<double> sparkAngles = [
      -2.6, -3.14, 2.6, // left side pointing out
      -0.54, 0.0, 0.54, // right side pointing out
    ];

    for (int i = 0; i < sparks.length; i++) {
      final center = sparks[i];
      final dir = Offset.fromDirection(sparkAngles[i]);
      final from = center - dir * (s * 0.03);
      final to = center + dir * (s * 0.03);
      canvas.drawLine(from, to, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainPainter oldDelegate) => oldDelegate.color != color;
}
