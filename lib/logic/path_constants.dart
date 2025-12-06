// A simple class to hold Grid Coordinates (Row, Column)
// 0,0 is Top-Left. 14,14 is Bottom-Right.
class Point {
  final int row;
  final int col;
  const Point(this.row, this.col);
}

class PathConstants {
  // ===========================================================================
  // 1. THE MAIN OUTER PATH (Steps 1 - 52)
  // ===========================================================================
  // This maps the linear game logic index to the visual grid coordinate.
  // The path moves clockwise around the board.
  static const Map<int, Point> stepToGrid = {
    // --- RED ARM (Bottom part, moving right) ---
    1: Point(6, 1), // Red Start (Colored cell)
    2: Point(6, 2),
    3: Point(6, 3),
    4: Point(6, 4),
    5: Point(6, 5),

    // --- Turning UP towards Green ---
    6: Point(5, 6),
    7: Point(4, 6),
    8: Point(3, 6), // Star
    9: Point(2, 6),
    10: Point(1, 6),
    11: Point(0, 6),

    // --- Top Turn (Middle columns) ---
    12: Point(0, 7),
    13: Point(0, 8),

    // --- GREEN ARM (Top part, moving down) ---
    14: Point(1, 8), // Green Start (Colored cell)
    15: Point(2, 8),
    16: Point(3, 8),
    17: Point(4, 8),
    18: Point(5, 8),

    // --- Turning RIGHT towards Yellow ---
    19: Point(6, 9),
    20: Point(6, 10),
    21: Point(6, 11), // Star
    22: Point(6, 12),
    23: Point(6, 13),
    24: Point(6, 14),

    // --- Right Turn (Middle rows) ---
    25: Point(7, 14),
    26: Point(8, 14),

    // --- YELLOW ARM (Top part, moving left) ---
    27: Point(8, 13), // Yellow Start (Colored cell)
    28: Point(8, 12),
    29: Point(8, 11),
    30: Point(8, 10),
    31: Point(8, 9),

    // --- Turning DOWN towards Blue ---
    32: Point(9, 8),
    33: Point(10, 8),
    34: Point(11, 8), // Star
    35: Point(12, 8),
    36: Point(13, 8),
    37: Point(14, 8),

    // --- Bottom Turn (Middle columns) ---
    38: Point(14, 7),
    39: Point(14, 6),

    // --- BLUE ARM (Bottom part, moving up) ---
    40: Point(13, 6), // Blue Start (Colored cell)
    41: Point(12, 6),
    42: Point(11, 6),
    43: Point(10, 6),
    44: Point(9, 6),

    // --- Turning LEFT towards Red ---
    45: Point(8, 5),
    46: Point(8, 4),
    47: Point(8, 3), // Star
    48: Point(8, 2),
    49: Point(8, 1),
    50: Point(8, 0),

    // --- Left Turn (Back to start of loop) ---
    51: Point(7, 0),
    52: Point(6, 0),
    // Next step is 1: Point(6,1), completing the loop.

    // =========================================================================
    // 2. HOME STRETCHES (Victory Paths)
    // =========================================================================
    // The 5 colored squares leading into the center.

    // Red Victory Path (Row 7, moving right)
    101: Point(7, 1),
    102: Point(7, 2),
    103: Point(7, 3),
    104: Point(7, 4),
    105: Point(7, 5),

    // Green Victory Path (Col 7, moving down)
    201: Point(1, 7),
    202: Point(2, 7),
    203: Point(3, 7),
    204: Point(4, 7),
    205: Point(5, 7),

    // Yellow Victory Path (Row 7, moving left)
    301: Point(7, 13),
    302: Point(7, 12),
    303: Point(7, 11),
    304: Point(7, 10),
    305: Point(7, 9),

    // Blue Victory Path (Col 7, moving up)
    401: Point(13, 7),
    402: Point(12, 7),
    403: Point(11, 7),
    404: Point(10, 7),
    405: Point(9, 7),

    // =========================================================================
    // 3. THE CENTER (Winner Spot)
    // =========================================================================
    99: Point(7, 7),
  };

  // ===========================================================================
  // 4. HOME BASES (Starting Positions)
  // ===========================================================================
  // The 4 specific circles inside each player's colored base.
  static const Map<String, List<Point>> homeBases = {
    'Red':    [Point(2, 2), Point(2, 3), Point(3, 2), Point(3, 3)],
    'Green':  [Point(2, 11), Point(2, 12), Point(3, 11), Point(3, 12)],
    'Yellow': [Point(11, 11), Point(11, 12), Point(12, 11), Point(12, 12)],
    'Blue':   [Point(11, 2), Point(11, 3), Point(12, 2), Point(12, 3)],
  };
}