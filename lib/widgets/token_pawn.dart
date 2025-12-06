import 'package:flutter/material.dart';

class TokenPawn extends StatelessWidget {
  final String colorName;
  final int tokenIndex;
  final bool isDimmed;

  const TokenPawn({
    super.key,
    required this.colorName,
    required this.tokenIndex,
    required this.isDimmed,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor = _getColor(colorName);

    // --- UPDATED OPACITY LOGIC ---
    if (isDimmed) {
      // Changed from 0.5 to 0.8 as requested
      baseColor = baseColor.withOpacity(0.8);
    }

    return CustomPaint(
      painter: _PawnPainter(color: baseColor),
      child: Center(
        child: Text(
          "${tokenIndex + 1}",
          style: TextStyle(
            // Adjust text opacity slightly to match the body
            color: Colors.white.withOpacity(isDimmed ? 0.9 : 1.0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'Red': return const Color(0xFFD32F2F);
      case 'Green': return const Color(0xFF388E3C);
      case 'Yellow': return const Color(0xFFFBC02D);
      case 'Blue': return const Color(0xFF1976D2);
      default: return Colors.grey;
    }
  }
}

class _PawnPainter extends CustomPainter {
  final Color color;

  _PawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;

    // Colors for 3D effect
    final Color lighterColor = Color.lerp(color, Colors.white, 0.3)!;
    final Color darkerColor = Color.lerp(color, Colors.black, 0.2)!;
    final Color shadowColor = Colors.black.withOpacity(0.3);

    // 1. Draw Shadow (Oval at the bottom)
    paint.color = shadowColor;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.1, h * 0.85, w * 0.8, h * 0.15),
      paint,
    );
    paint.maskFilter = null; // Reset mask filter

    // 2. Draw Base (Flat oval)
    paint.color = darkerColor;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.75, w * 0.6, h * 0.15),
      paint,
    );

    // 3. Draw Body (Tapered cylinder shape using Path and Linear Gradient)
    final Path bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.4) // Top-left of body
      ..lineTo(w * 0.25, h * 0.8) // Bottom-left of body
      ..quadraticBezierTo(w * 0.5, h * 0.9, w * 0.75, h * 0.8) // Bottom curve
      ..lineTo(w * 0.7, h * 0.4) // Top-right of body
      ..close();

    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [lighterColor, color, darkerColor],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.5));
    canvas.drawPath(bodyPath, paint);
    paint.shader = null; // Reset shader

    // 4. Draw Head (Sphere using Radial Gradient for 3D effect)
    final Rect headRect = Rect.fromLTWH(w * 0.15, 0, w * 0.7, h * 0.6);
    paint.shader = RadialGradient(
      center: const Alignment(-0.4, -0.4), // "Light source" from top-left
      radius: 0.8,
      colors: [Colors.white, lighterColor, color],
      stops: const [0.0, 0.3, 1.0],
    ).createShader(headRect);
    canvas.drawOval(headRect, paint);
    paint.shader = null; // Reset shader

    // 5. Specular highlight
    paint.color = Colors.white.withOpacity(0.6);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.3, h * 0.1, w * 0.2, h * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}