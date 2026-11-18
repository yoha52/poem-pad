import 'package:flutter/material.dart';

/// A native vector widget for the app logo.
/// Draws the 6-ray whisker icon with transparent background
/// and natural proportions (1.95:1 aspect ratio).
class AppLogo extends StatelessWidget {
  final Color color;
  final double height;

  const AppLogo({
    super.key,
    required this.color,
    this.height = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 1.95,
      child: CustomPaint(
        painter: _AppLogoPainter(color: color),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  final Color color;

  _AppLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    // Scale canvas from original 800x410 coordinate space to fit `size`
    final scaleX = size.width / 800.0;
    final scaleY = size.height / 410.0;
    canvas.scale(scaleX, scaleY);
    canvas.translate(400.0, 205.0); // center origin (0,0)

    // Right side 3 rays
    _drawRightRaySet(canvas, paint);

    // Left side 3 rays (mirrored)
    canvas.scale(-1.0, -1.0);
    _drawRightRaySet(canvas, paint);

    canvas.restore();
  }

  void _drawRightRaySet(Canvas canvas, Paint paint) {
    // Middle Ray
    final pMiddle = Path();
    pMiddle.moveTo(77.18, 1.18);
    pMiddle.cubicTo(77.18, -6.39, 82.96, -13.40, 90.50, -13.40);
    pMiddle.cubicTo(112.27, -15.37, 338.15, -35.75, 359.91, -37.72);
    pMiddle.cubicTo(381.56, -39.37, 400.44, -22.34, 400.44, -0.69);
    pMiddle.cubicTo(400.44, 20.96, 382.01, 35.80, 360.43, 36.38);
    pMiddle.cubicTo(338.80, 37.03, 98.33, 16.36, 90.70, 15.78);
    pMiddle.cubicTo(83.07, 15.20, 77.18, 8.83, 77.18, 1.18);
    pMiddle.close();
    canvas.drawPath(pMiddle, paint);

    // Top Ray
    final pTop = Path();
    pTop.moveTo(65.29, -52.80);
    pTop.cubicTo(62.21, -59.73, 64.93, -67.85, 71.54, -71.54);
    pTop.cubicTo(90.63, -82.18, 288.76, -192.56, 307.85, -203.20);
    pTop.cubicTo(326.65, -213.72, 351.13, -205.60, 359.92, -185.82);
    pTop.cubicTo(368.71, -166.04, 358.81, -142.90, 338.42, -135.69);
    pTop.cubicTo(318.02, -128.48, 90.79, -47.53, 83.58, -44.96);
    pTop.cubicTo(76.37, -42.39, 68.37, -45.88, 65.29, -52.80);
    pTop.close();
    canvas.drawPath(pTop, paint);

    // Bottom Ray
    final pBottom = Path();
    pBottom.moveTo(65.29, 54.12);
    pBottom.cubicTo(62.21, 61.04, 64.93, 69.17, 71.54, 72.85);
    pBottom.cubicTo(90.63, 83.49, 288.76, 193.88, 307.85, 204.52);
    pBottom.cubicTo(326.65, 215.04, 351.13, 206.92, 359.92, 187.14);
    pBottom.cubicTo(368.71, 167.36, 358.81, 144.22, 338.42, 137.01);
    pBottom.cubicTo(318.02, 129.80, 90.79, 48.84, 83.58, 46.28);
    pBottom.cubicTo(76.37, 43.71, 68.37, 47.20, 65.29, 54.12);
    pBottom.close();
    canvas.drawPath(pBottom, paint);
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
