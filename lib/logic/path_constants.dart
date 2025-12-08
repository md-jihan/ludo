class PathConstants {
  // Step -> Grid Coordinate (row, col)
  // Grid is 0..14 (15x15)
  static const Map<int, Point> stepToGrid = {
    // --- RED PATH (1 - 13) ---
    1: Point(6, 1), 2: Point(6, 2), 3: Point(6, 3), 4: Point(6, 4), 5: Point(6, 5),
    6: Point(5, 6), 7: Point(4, 6), 8: Point(3, 6), 9: Point(2, 6), 10: Point(1, 6), 11: Point(0, 6),
    12: Point(0, 7), 13: Point(0, 8),

    // --- GREEN PATH (14 - 26) ---
    14: Point(1, 8), 15: Point(2, 8), 16: Point(3, 8), 17: Point(4, 8), 18: Point(5, 8),
    19: Point(6, 9), 20: Point(6, 10), 21: Point(6, 11), 22: Point(6, 12), 23: Point(6, 13), 24: Point(6, 14),
    25: Point(7, 14), 26: Point(8, 14),

    // --- YELLOW PATH (27 - 39) ---
    27: Point(8, 13), 28: Point(8, 12), 29: Point(8, 11), 30: Point(8, 10), 31: Point(8, 9),
    32: Point(9, 8), 33: Point(10, 8), 34: Point(11, 8), 35: Point(12, 8), 36: Point(13, 8), 37: Point(14, 8),
    38: Point(14, 7), 39: Point(14, 6),

    // --- BLUE PATH (40 - 52) ---
    40: Point(13, 6), 41: Point(12, 6), 42: Point(11, 6), 43: Point(10, 6), 44: Point(9, 6),
    45: Point(8, 5), 46: Point(8, 4), 47: Point(8, 3), 48: Point(8, 2), 49: Point(8, 1), 50: Point(8, 0),
    51: Point(7, 0), 52: Point(6, 0),

    // --- HOME PATHS (Safe Zones inside) ---
    // These were missing!

    // RED HOME (53 - 57)
    53: Point(7, 1), 54: Point(7, 2), 55: Point(7, 3), 56: Point(7, 4), 57: Point(7, 5),

    // GREEN HOME (58 - 62)
    58: Point(1, 7), 59: Point(2, 7), 60: Point(3, 7), 61: Point(4, 7), 62: Point(5, 7),

    // YELLOW HOME (63 - 67)
    63: Point(7, 13), 64: Point(7, 12), 65: Point(7, 11), 66: Point(7, 10), 67: Point(7, 9),

    // BLUE HOME (68 - 72)
    68: Point(13, 7), 69: Point(12, 7), 70: Point(11, 7), 71: Point(10, 7), 72: Point(9, 7),
  };

  static const Map<String, List<Point>> homeBases = {
    'Red': [Point(2, 2), Point(2, 3), Point(3, 2), Point(3, 3)],
    'Green': [Point(2, 11), Point(2, 12), Point(3, 11), Point(3, 12)],
    'Yellow': [Point(11, 11), Point(11, 12), Point(12, 11), Point(12, 12)],
    'Blue': [Point(11, 2), Point(11, 3), Point(12, 2), Point(12, 3)],
  };
}

class Point {
  final int row;
  final int col;
  const Point(this.row, this.col);
}