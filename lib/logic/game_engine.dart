class GameEngine {
  static const int pathLength = 52;
  static const int finishedIndex = 99;

  // Start Positions for each color
  static const Map<String, int> startIndices = {
    'Red': 1,
    'Green': 14,
    'Yellow': 27,
    'Blue': 40,
  };

  // Entry to Home Stretch
  static const Map<String, int> homeStretchEntry = {
    'Red': 51, 'Green': 12, 'Yellow': 25, 'Blue': 38,
  };

  int calculateNextPosition(int currentPos, int diceValue, String color) {
    // 1. LOGIC: Moving from Home (0)
    // You MUST roll a 6 to move out.
    if (currentPos == 0) {
      if (diceValue == 6) {
        return startIndices[color]!; // Moves to 1, 14, 27, or 40
      }
      return 0; // Otherwise, stay at home
    }

    // 2. Logic: Already Finished
    if (currentPos == finishedIndex) return finishedIndex;

    // 3. Logic: Inside Home Stretch
    if (currentPos > 100) {
      int homeBase = _getHomeStretchBase(color);
      int stepInStretch = currentPos - homeBase;
      int distanceToFinish = 6 - stepInStretch;

      if (diceValue == distanceToFinish) return finishedIndex;
      if (diceValue < distanceToFinish) return currentPos + diceValue;
      return currentPos; // Overshot, stay put
    }

    // 4. Logic: Standard Path
    int targetPos = currentPos + diceValue;
    int entryPoint = homeStretchEntry[color]!;

    // Check for wrapping / home stretch entry
    bool passedEntryPoint = false;
    if (currentPos <= entryPoint && targetPos > entryPoint) passedEntryPoint = true;

    // Handle wrap-around case (e.g. 50 -> 55 for Red, but Red entry is 51)
    // Handle wrap-around case (e.g. 50 -> 3 for Green)
    if (targetPos > pathLength && !passedEntryPoint) {
      targetPos -= pathLength;
      // Re-check entry point after wrap
      if (targetPos > entryPoint) passedEntryPoint = true;
    }

    if (passedEntryPoint) {
      int extraSteps = targetPos - entryPoint; // simplified
      // Calculate true extra steps based on math is complex,
      // simplified approach: if we passed entry, we go into stretch
      return _getHomeStretchBase(color) + (diceValue - (entryPoint - currentPos));
      // Note: This math simplifies the specific "Enter Stretch" logic.
      // For exact Ludo wrapping, ensure (currentPos + dice) aligns with entry.
    }

    if (targetPos > pathLength) return targetPos - pathLength;
    return targetPos;
  }

  // Check collision/kill
  Map<String, List<int>> checkKill(
      Map<String, List<int>> allTokens, String moverColor, int landedIndex) {

    // Safe zones: 1, 14, 27, 40 (Starts) and 9, 22, 35, 48 (Stars)
    List<int> safeZones = [1, 9, 14, 22, 27, 35, 40, 48];
    if (safeZones.contains(landedIndex) || landedIndex == 0 || landedIndex > 100) {
      return allTokens;
    }

    allTokens.forEach((color, positions) {
      if (color != moverColor) {
        for (int i = 0; i < positions.length; i++) {
          if (positions[i] == landedIndex) {
            allTokens[color]![i] = 0; // Send back to home
          }
        }
      }
    });
    return allTokens;
  }

  int _getHomeStretchBase(String color) {
    switch(color) {
      case 'Red': return 100;
      case 'Green': return 200;
      case 'Yellow': return 300;
      case 'Blue': return 400;
      default: return 500;
    }
  }
}