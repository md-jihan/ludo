import 'package:flutter/material.dart';
import '../logic/path_constants.dart';

class LudoBoardPainter extends CustomPainter {
  final List<Map<String, dynamic>> players;

  LudoBoardPainter({required this.players});

  // --- VINTAGE COLOR PALETTE ---
  // Deep, worn-out paint look
  final Color redColor = const Color(0xFFC62828);    // Vintage Red
  final Color greenColor = const Color(0xFF2E7D32);  // Vintage Green
  final Color yellowColor = const Color(0xFFF9A825); // Mustard Yellow
  final Color blueColor = const Color(0xFF1565C0);   // Vintage Blue

  // Grid Lines: Dark Brown (burnt wood look) instead of black
  final Color borderColor = const Color(0xFF3E2723);

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15.0;

    // Fill Paint (Applied with Multiply mode to blend with wood)
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Stroke Paint (The carved lines)
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 // Slightly thicker for "carved" look
      ..color = borderColor;

    // 1. DO NOT draw a white background.
    // We want the parent widget's wood image to show through!

    // 2. Draw Bases
    _drawBase(canvas, 0, 0, redColor, "Red", cellSize);
    _drawBase(canvas, 9, 0, greenColor, "Green", cellSize);
    _drawBase(canvas, 9, 9, yellowColor, "Yellow", cellSize);
    _drawBase(canvas, 0, 9, blueColor, "Blue", cellSize);

    // 3. Draw Grid Tracks
    _drawGridTracks(canvas, cellSize, strokePaint, paint);

    // 4. Draw Center
    _drawCenter(canvas, size, cellSize);

    // 5. Draw Outer Border (The frame)
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..style=PaintingStyle.stroke..strokeWidth=4..color=borderColor
    );
  }

  void _drawBase(Canvas canvas, int col, int row, Color color, String colorName, double cellSize) {
    // A. Colored Base (Use opacity to let wood grain show through)
    final Paint paint = Paint()..style = PaintingStyle.fill..color = color.withOpacity(0.85);

    canvas.drawRect(
      Rect.fromLTWH(col * cellSize, row * cellSize, 6 * cellSize, 6 * cellSize),
      paint,
    );

    // B. Inner Box (Lighter Wood look - simulate scraped paint)
    // We use a transparent white overlay to lighten the wood underneath
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * cellSize, (row + 1) * cellSize, 4 * cellSize, 4 * cellSize),
      Paint()..color = Colors.white.withOpacity(0.2),
    );

    // Draw Border around inner box
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * cellSize, (row + 1) * cellSize, 4 * cellSize, 4 * cellSize),
      Paint()..style=PaintingStyle.stroke..color=borderColor..strokeWidth=1,
    );

    // C. Token Circles (Carved slots)
    // Draw dark circle (hole) then colored rim
    List<Offset> offsets = [
      Offset((col + 2.5) * cellSize, (row + 2.5) * cellSize),
      Offset((col + 2.5) * cellSize, (row + 3.5) * cellSize),
      Offset((col + 3.5) * cellSize, (row + 2.5) * cellSize),
      Offset((col + 3.5) * cellSize, (row + 3.5) * cellSize),
    ];

    for (var offset in offsets) {
      // The "Hole" (Shadow)
      canvas.drawCircle(offset, cellSize * 0.35, Paint()..color = Colors.black.withOpacity(0.3));
      // The Ring
      canvas.drawCircle(offset, cellSize * 0.4, Paint()..style=PaintingStyle.stroke..color=borderColor.withOpacity(0.6)..strokeWidth=1);
    }

    // D. Player Name (Burnt Wood Text Effect)
    final player = players.firstWhere((p) => p['color'] == colorName, orElse: () => {});
    if (player.isNotEmpty) {
      String name = player['name'] ?? "Player";
      bool hasLeft = player['hasLeft'] ?? false;

      final textSpan = TextSpan(
        text: name + (hasLeft ? " (Left)" : ""),
        style: TextStyle(
          color: hasLeft ? Colors.black38 : const Color(0xFF3E2723), // Dark Brown text
          fontSize: cellSize * 0.5,
          fontWeight: FontWeight.w900,
          fontFamily: "Courier", // Monospace looks more like stamped wood
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 6 * cellSize);

      textPainter.paint(canvas, Offset(
        (col * cellSize) + (3 * cellSize) - (textPainter.width / 2),
        (row * cellSize) + (0.2 * cellSize),
      ));
    }
  }

  void _drawGridTracks(Canvas canvas, double cellSize, Paint strokePaint, Paint fillPaint) {
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        bool isBase = (row < 6 && col < 6) || (row < 6 && col >= 9) ||
            (row >= 9 && col < 6) || (row >= 9 && col >= 9);
        bool isCenter = (row >= 6 && row <= 8 && col >= 6 && col <= 8);

        if (!isBase && !isCenter) {
          // 1. Draw Cell Border (Carved line)
          canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize), strokePaint);

          // 2. Determine Color (Vintage)
          Color? cellColor;
          if (row == 6 && col == 1) cellColor = redColor;
          else if (row == 1 && col == 8) cellColor = greenColor;
          else if (row == 8 && col == 13) cellColor = yellowColor;
          else if (row == 13 && col == 6) cellColor = blueColor;
          else if (row == 7 && col > 0 && col < 6) cellColor = redColor;
          else if (col == 7 && row > 0 && row < 6) cellColor = greenColor;
          else if (row == 7 && col > 8 && col < 14) cellColor = yellowColor;
          else if (col == 7 && row > 8 && row < 14) cellColor = blueColor;

          if (cellColor != null) {
            // Apply color with opacity (Painted Wood effect)
            canvas.drawRect(
                Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
                Paint()..color = cellColor.withOpacity(0.85)
            );
          }

          // 3. Draw Stars (Dark burnt stamp)
          if ([const Point(6,1), const Point(2,6), const Point(1,8), const Point(6,12),
            const Point(8,13), const Point(12,8), const Point(13,6), const Point(8,2)]
              .contains(Point(row, col))) {
            _drawStar(canvas, col, row, cellSize);
          }
        }
      }
    }
  }

  void _drawStar(Canvas canvas, int col, int row, double cellSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.star.codePoint),
        style: TextStyle(
            fontSize: cellSize * 0.7,
            fontFamily: Icons.star.fontFamily,
            color: const Color(0xFF3E2723).withOpacity(0.6) // Burnt wood star
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
        canvas,
        Offset((col * cellSize) + (cellSize - textPainter.width) / 2, (row * cellSize) + (cellSize - textPainter.height) / 2)
    );
  }

  void _drawCenter(Canvas canvas, Size size, double cellSize) {
    // Draw the triangles with Vintage Colors
    double cx = size.width / 2, cy = size.height / 2;
    double half = (3 * cellSize) / 2;
    Paint paint = Paint()..style = PaintingStyle.fill;

    // Use .withOpacity(0.85) for all to keep the texture visible
    canvas.drawPath(Path()..moveTo(cx - half, cy - half)..lineTo(cx, cy)..lineTo(cx - half, cy + half)..close(), paint..color = redColor.withOpacity(0.85));
    canvas.drawPath(Path()..moveTo(cx - half, cy - half)..lineTo(cx, cy)..lineTo(cx + half, cy - half)..close(), paint..color = greenColor.withOpacity(0.85));
    canvas.drawPath(Path()..moveTo(cx + half, cy - half)..lineTo(cx, cy)..lineTo(cx + half, cy + half)..close(), paint..color = yellowColor.withOpacity(0.85));
    canvas.drawPath(Path()..moveTo(cx - half, cy + half)..lineTo(cx, cy)..lineTo(cx + half, cy + half)..close(), paint..color = blueColor.withOpacity(0.85));

    // Draw "Home" Text in center
    final textPainter = TextPainter(
        text: const TextSpan(
            text: "HOME",
            style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold, fontSize: 12)
        ),
        textDirection: TextDirection.ltr
    )..layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width/2, cy - textPainter.height/2));
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter oldDelegate) => true;
}
// Helper for simple point check (Ensure this is in your logic file or here)
class Point { final int r, c; const Point(this.r, this.c); @override bool operator ==(Object o) => o is Point && o.r==r && o.c==c; @override int get hashCode => Object.hash(r,c); }