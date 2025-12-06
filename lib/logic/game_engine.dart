class GameEngine {
  static const int pathLength = 52;
  static const int finishedIndex = 99; // <--- The Safe Spot

  // Entry points to the Home Stretch
  static const Map<String, int> homeStretchEntry = {
    'Red': 51, 'Green': 12, 'Yellow': 25, 'Blue': 38,
  };

  int calculateNextPosition(int currentPos, int diceValue, String color) {
    // 1. HOME RULE: Needs 6 to start
    if (currentPos == 0) {
      return diceValue == 6 ? _getStart(color) : 0;
    }

    // 2. FINISH RULE: If already finished, NEVER move again.
    if (currentPos == finishedIndex) return finishedIndex;

    // 3. HOME STRETCH RULE (Prevent going out)
    if (currentPos > 100) {
      int homeBase = _getHomeStretchBase(color);
      int stepInStretch = currentPos - homeBase; // e.g. 1 (first box)
      int distanceToFinish = 6 - stepInStretch; // Steps needed to reach center

      if (diceValue <= distanceToFinish) {
        if (diceValue == distanceToFinish) return finishedIndex; // Exact roll -> Win
        return currentPos + diceValue; // Move forward
      }

      // IF DICE IS TOO HIGH (e.g. need 2, rolled 5) -> DO NOTHING.
      // This prevents the pawn from "going out" or bouncing weirdly.
      return currentPos;
    }

    // 4. Standard Movement (Same as before)
    int targetPos = currentPos + diceValue;
    int entryPoint = homeStretchEntry[color]!;
    bool passedEntryPoint = false;

    if (currentPos <= entryPoint && targetPos > entryPoint) passedEntryPoint = true;

    // Handle wrap around (52 -> 1)
    if (targetPos > pathLength && !passedEntryPoint) {
      targetPos -= pathLength;
      if (targetPos > entryPoint) passedEntryPoint = true;
    }

    if (passedEntryPoint) {
      // Calculate steps taken INTO the colored path
      int extraSteps = diceValue - (entryPoint - currentPos);
      return _getHomeStretchBase(color) + extraSteps;
    }

    if (targetPos > pathLength) return targetPos - pathLength;
    return targetPos;
  }

  // ... (Keep checkKill and helper methods same as before) ...

  Map<String, List<int>> checkKill(Map<String, List<int>> allTokens, String moverColor, int landedIndex) {
    // Cannot kill if finished (99) or at home (0) or in safe zones
    List<int> safeZones = [1, 9, 14, 22, 27, 35, 40, 48];
    if (safeZones.contains(landedIndex) || landedIndex == 0 || landedIndex > 100 || landedIndex == 99) {
      return allTokens;
    }

    allTokens.forEach((color, positions) {
      if (color != moverColor) {
        for (int i = 0; i < positions.length; i++) {
          if (positions[i] == landedIndex) {
            allTokens[color]![i] = 0; // Kill!
          }
        }
      }
    });
    return allTokens;
  }

  int _getStart(String color) {
    switch(color) {
      case 'Red': return 1;
      case 'Green': return 14;
      case 'Yellow': return 27;
      case 'Blue': return 40;
      default: return 1;
    }
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