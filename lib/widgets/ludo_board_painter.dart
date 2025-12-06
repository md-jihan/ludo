import 'package:flutter/material.dart';

class LudoBoardPainter extends CustomPainter {
  // --- COLOR PALETTE ---
  final Color redColor = const Color(0xFFE53935);
  final Color greenColor = const Color(0xFF43A047);
  final Color yellowColor = const Color(0xFFFDD835);
  final Color blueColor = const Color(0xFF1E88E5);
  final Color borderColor = const Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15.0;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = borderColor;

    // 1. White Background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Draw Bases
    _drawBase(canvas, 0, 0, redColor, cellSize);      // Red (Top-Left)
    _drawBase(canvas, 9, 0, greenColor, cellSize);    // Green (Top-Right)
    _drawBase(canvas, 9, 9, yellowColor, cellSize);   // Yellow (Bottom-Right)
    _drawBase(canvas, 0, 9, blueColor, cellSize);     // Blue (Bottom-Left)

    // 3. Grid & Center
    _drawGridTracks(canvas, cellSize, strokePaint, paint);
    _drawCenter(canvas, size, cellSize);
  }

  void _drawBase(Canvas canvas, int col, int row, Color color, double cellSize) {
    final Paint paint = Paint()..style = PaintingStyle.fill..color = color;

    // A. Colored 6x6 Box
    canvas.drawRect(
      Rect.fromLTWH(col * cellSize, row * cellSize, 6 * cellSize, 6 * cellSize),
      paint,
    );

    // B. White 4x4 Inner Box ("Anti-color" background for pawns)
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * cellSize, (row + 1) * cellSize, 4 * cellSize, 4 * cellSize),
      paint,
    );

    // C. Token Circles (FIXED POSITIONING)
    // We position them at relative grid cells 2 and 3.
    // Center of cell 2 is 2.5. Center of cell 3 is 3.5.
    paint.color = color.withOpacity(0.2); // Faint circle to indicate spot

    List<Offset> offsets = [
      Offset((col + 2.5) * cellSize, (row + 2.5) * cellSize), // Top-Left of inner 2x2
      Offset((col + 2.5) * cellSize, (row + 3.5) * cellSize), // Bottom-Left
      Offset((col + 3.5) * cellSize, (row + 2.5) * cellSize), // Top-Right
      Offset((col + 3.5) * cellSize, (row + 3.5) * cellSize), // Bottom-Right
    ];

    for (var offset in offsets) {
      // Draw colored ring
      canvas.drawCircle(offset, cellSize * 0.4, Paint()..style=PaintingStyle.stroke..color=color..strokeWidth=2);
    }
  }

  void _drawGridTracks(Canvas canvas, double cellSize, Paint strokePaint, Paint fillPaint) {
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        bool isBase = (row < 6 && col < 6) || (row < 6 && col >= 9) ||
            (row >= 9 && col < 6) || (row >= 9 && col >= 9);
        bool isCenter = (row >= 6 && row <= 8 && col >= 6 && col <= 8);

        if (!isBase && !isCenter) {
          canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize), strokePaint);

          // Colored Cells
          if (row == 6 && col == 1) _fill(canvas, col, row, cellSize, redColor);    // Red Start
          if (row == 1 && col == 8) _fill(canvas, col, row, cellSize, greenColor);  // Green Start
          if (row == 8 && col == 13) _fill(canvas, col, row, cellSize, yellowColor);// Yellow Start
          if (row == 13 && col == 6) _fill(canvas, col, row, cellSize, blueColor);  // Blue Start

          // Home Stretches
          if (row == 7 && col > 0 && col < 6) _fill(canvas, col, row, cellSize, redColor);
          if (col == 7 && row > 0 && row < 6) _fill(canvas, col, row, cellSize, greenColor);
          if (row == 7 && col > 8 && col < 14) _fill(canvas, col, row, cellSize, yellowColor);
          if (col == 7 && row > 8 && row < 14) _fill(canvas, col, row, cellSize, blueColor);

          // Star Icons
          if ([const Point(6,1), const Point(2,6), const Point(1,8), const Point(6,12),
            const Point(8,13), const Point(12,8), const Point(13,6), const Point(8,2)]
              .contains(Point(row, col))) {
            _drawStar(canvas, col, row, cellSize);
          }
        }
      }
    }
  }

  void _fill(Canvas canvas, int col, int row, double cellSize, Color color) {
    canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        Paint()..style = PaintingStyle.fill..color = color);
    canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        Paint()..style = PaintingStyle.stroke..strokeWidth=1..color = Colors.black);
  }

  void _drawStar(Canvas canvas, int col, int row, double cellSize) {
    final textPainter = TextPainter(
      text: TextSpan(text: String.fromCharCode(Icons.star.codePoint),
          style: TextStyle(fontSize: cellSize * 0.8, fontFamily: Icons.star.fontFamily, color: Colors.black38)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((col * cellSize) + (cellSize - textPainter.width) / 2, (row * cellSize) + (cellSize - textPainter.height) / 2));
  }

  void _drawCenter(Canvas canvas, Size size, double cellSize) {
    double cx = size.width / 2, cy = size.height / 2;
    double half = (3 * cellSize) / 2;
    Paint paint = Paint()..style = PaintingStyle.fill;

    canvas.drawPath(Path()..moveTo(cx - half, cy - half)..lineTo(cx, cy)..lineTo(cx - half, cy + half)..close(), paint..color = redColor);
    canvas.drawPath(Path()..moveTo(cx - half, cy - half)..lineTo(cx, cy)..lineTo(cx + half, cy - half)..close(), paint..color = greenColor);
    canvas.drawPath(Path()..moveTo(cx + half, cy - half)..lineTo(cx, cy)..lineTo(cx + half, cy + half)..close(), paint..color = yellowColor);
    canvas.drawPath(Path()..moveTo(cx - half, cy + half)..lineTo(cx, cy)..lineTo(cx + half, cy + half)..close(), paint..color = blueColor);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// Helper for simple point check
class Point { final int r, c; const Point(this.r, this.c); @override bool operator ==(Object o) => o is Point && o.r==r && o.c==c; @override int get hashCode => Object.hash(r,c); }