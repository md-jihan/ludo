import 'dart:math';
import '../models/game_model.dart';

class GameEngine {
  final Random _random = Random();

  // Safe Spots (Stars)
  final List<int> _safeSpots = [1, 9, 14, 22, 27, 35, 40, 48];

  int calculateNextPosition(int currentPos, int diceValue, String color) {
    // --- 1. SPAWN LOGIC ---
    if (currentPos == 0) {
      if (diceValue != 6) return 0;
      switch (color) {
        case 'Red': return 1;
        case 'Green': return 14;
        case 'Yellow': return 27;
        case 'Blue': return 40;
        default: return 1;
      }
    }

    // --- 2. DEFINE ZONES ---
    int entrance = 0;
    int homeStart = 0;
    int homeEnd = 0;

    switch (color) {
      case 'Red':    entrance = 51; homeStart = 53; homeEnd = 57; break;
      case 'Green':  entrance = 12; homeStart = 58; homeEnd = 62; break;
      case 'Yellow': entrance = 25; homeStart = 63; homeEnd = 67; break;
      case 'Blue':   entrance = 38; homeStart = 68; homeEnd = 72; break;
    }

    // --- 3. ALREADY IN HOME STRETCH? ---
    // If we are already on the colored path, just move forward
    if (currentPos >= homeStart && currentPos <= homeEnd) {
      int nextPos = currentPos + diceValue;

      if (nextPos > homeEnd) {
        // Check if we hit exactly 99 (Victory)
        // Example: At 57 (last step), need 1 to win.
        // Logic: 57 + 1 = 58 (which is > 57).
        // Distance to win = (homeEnd - currentPos) + 1

        int stepsToWin = (homeEnd - currentPos) + 1;
        if (diceValue == stepsToWin) return 99; // WIN!

        return currentPos; // Overshoot (Stay put)
      }
      return nextPos;
    }

    // --- 4. CHECK IF ENTERING HOME ---
    // Calculate distance to the entrance based on color
    int distToEntrance = -1;

    if (currentPos <= entrance) {
      // Simple case: Forward to entrance (e.g. Current 48, Entrance 51)
      distToEntrance = entrance - currentPos;
    } else {
      // Wrap case: (e.g. Green Current 50, Entrance 12)
      // 50 -> 52 (2 steps) + 1 -> 12 (12 steps) = 14 steps
      distToEntrance = (52 - currentPos) + entrance;
    }

    // If dice is larger than distance, we enter home!
    if (distToEntrance >= 0 && diceValue > distToEntrance) {
      int stepsInHome = diceValue - distToEntrance - 1;
      int newPos = homeStart + stepsInHome;

      // Cap movement if it overshoots the home path immediately
      if (newPos > homeEnd) {
        int stepsToWin = (homeEnd - homeStart) + 1; // 6 steps usually
        if (stepsInHome == stepsToWin) return 99;
        return currentPos; // Overshoot
      }

      return newPos;
    }

    // --- 5. NORMAL BOARD MOVEMENT ---
    int nextPos = currentPos + diceValue;
    if (nextPos > 52) nextPos -= 52;
    return nextPos;
  }

  // Check Kill (Updated to protect Home Paths)
  Map<String, List<int>> checkKill(Map<String, List<int>> tokens, String myColor, int newPos) {
    // Cannot kill in Base(0), Winner(99), Safe Spots, OR Home Paths (>52)
    if (newPos == 0 || newPos == 99 || _safeSpots.contains(newPos) || newPos > 52) {
      return tokens;
    }

    Map<String, List<int>> newTokens = Map.from(tokens);
    newTokens = newTokens.map((k, v) => MapEntry(k, List.from(v)));

    newTokens.forEach((color, positions) {
      if (color != myColor) {
        for (int i = 0; i < positions.length; i++) {
          if (positions[i] == newPos) {
            positions[i] = 0;
          }
        }
      }
    });

    return newTokens;
  }

  // AI Logic (Updated)
  int pickBestTokenIndex(GameModel game, int diceValue) {
    String myColor = game.players[game.currentTurn]['color'];
    List<int> myTokens = game.tokens[myColor]!;

    int bestTokenIndex = -1;
    int bestScore = -100;

    for (int i = 0; i < myTokens.length; i++) {
      int currentPos = myTokens[i];
      int nextPos = calculateNextPosition(currentPos, diceValue, myColor);

      if (nextPos == currentPos) continue;

      int score = 0;

      // A. KILL
      Map<String, List<int>> afterMove = checkKill(game.tokens, myColor, nextPos);
      if (_countTotalTokens(afterMove) < _countTotalTokens(game.tokens)) score += 100;

      // B. WIN (Reach 99)
      if (nextPos == 99) score += 50;

      // C. ENTER HOME (Reach >52)
      if (currentPos <= 52 && nextPos > 52) score += 30;

      // D. SAFE SPOT
      if (_safeSpots.contains(nextPos)) score += 20;

      // E. SPAWN
      if (currentPos == 0 && nextPos != 0) score += 10;

      // F. ADVANCE
      score += 1;
      score += _random.nextInt(5);

      if (score > bestScore) {
        bestScore = score;
        bestTokenIndex = i;
      }
    }

    return bestTokenIndex;
  }

  int _countTotalTokens(Map<String, List<int>> tokens) {
    int count = 0;
    tokens.values.forEach((list) => count += list.where((p) => p > 0 && p < 99).length);
    return count;
  }
}