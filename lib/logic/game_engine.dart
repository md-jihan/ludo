import 'dart:math';
import '../models/game_model.dart';

class GameEngine {
  final Random _random = Random();
  final List<int> _safeSpots = [1, 9, 14, 22, 27, 35, 40, 48];

  // --- 1. DEFINE GATES (Where each color turns) ---
  // Returns [GatePosition, HomeStartID, HomeEndID]
  // Made public so UI can use it for "Needed to win" calculations
  List<int> getHomeEntrance(String color) {
    switch (color) {
      case 'Red':    return [51, 53, 57]; // Turn at 51 -> Go to 53..57 -> Win
      case 'Green':  return [12, 58, 62]; // Turn at 12 -> Go to 58..62 -> Win
      case 'Yellow': return [25, 63, 67]; // Turn at 25 -> Go to 63..67 -> Win
      case 'Blue':   return [38, 68, 72]; // Turn at 38 -> Go to 68..72 -> Win
      default:       return [51, 53, 57];
    }
  }

  int calculateNextPosition(int currentPos, int diceValue, String color) {
    // 0. FINISHED CHECK
    // If pawn is already at 99, it never moves again.
    if (currentPos == 99) return 99;

    // A. SPAWN LOGIC
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

    List<int> gateData = getHomeEntrance(color);
    int gatePos = gateData[0];
    int homeStart = gateData[1];
    int homeEnd = gateData[2];

    // B. ALREADY IN HOME PATH? (e.g., Red is at 53)
    if (currentPos >= homeStart && currentPos <= homeEnd) {
      int nextPos = currentPos + diceValue;

      // CHECK VICTORY: You need exact steps to hit "homeEnd + 1" (which represents 99)
      // Example Red: End is 57.
      // If at 57, Roll 1 -> 58 -> Returns 99 (Win).
      // If at 57, Roll 2 -> 59 -> Returns 57 (Overshoot, stay put).

      if (nextPos == homeEnd + 1) {
        return 99; // WIN!
      }

      if (nextPos > homeEnd + 1) {
        return currentPos; // Overshoot (Move invalid, stay put)
      }

      return nextPos;
    }

    // C. CHECK IF ENTERING HOME
    // We calculate distance to the gate.
    int distToGate = -1;

    // Case 1: Simple Forward (e.g., Red at 48, Gate 51)
    if (currentPos <= gatePos) {
      distToGate = gatePos - currentPos;
    }
    // Case 2: Wrap Around (e.g., Green at 50, Gate 12)
    else {
      distToGate = (52 - currentPos) + gatePos;
    }

    // If dice is strictly greater than distance, we cross the gate.
    if (diceValue > distToGate) {
      // Calculate how many steps remain AFTER reaching the gate
      int stepsInHome = diceValue - distToGate - 1;
      int newPos = homeStart + stepsInHome;

      // Check for Victory immediately (e.g. rolled a 6 right at the gate)
      if (newPos == homeEnd + 1) return 99;

      // Check for Overshoot
      if (newPos > homeEnd + 1) return currentPos;

      return newPos;
    }

    // D. NORMAL BOARD MOVE (Loop 52 -> 1)
    int nextPos = currentPos + diceValue;
    if (nextPos > 52) {
      nextPos -= 52;
    }
    return nextPos;
  }

  // --- CHECK KILL ---
  Map<String, List<int>> checkKill(Map<String, List<int>> tokens, String myColor, int newPos) {
    // Safety: Cannot kill in Base, Safe Spots, Home Paths, or Win
    if (newPos == 0 || newPos == 99 || _safeSpots.contains(newPos) || newPos > 52) {
      return tokens;
    }

    Map<String, List<int>> newTokens = Map.from(tokens);
    newTokens = newTokens.map((k, v) => MapEntry(k, List.from(v)));

    newTokens.forEach((color, positions) {
      if (color != myColor) {
        for (int i = 0; i < positions.length; i++) {
          if (positions[i] == newPos) {
            positions[i] = 0; // Kill!
          }
        }
      }
    });
    return newTokens;
  }

  // --- AI BRAIN ---
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
      Map<String, List<int>> afterMove = checkKill(game.tokens, myColor, nextPos);
      if (_countTotalTokens(afterMove) < _countTotalTokens(game.tokens)) score += 100; // Kill
      if (nextPos == 99) score += 50; // Win
      if (currentPos <= 52 && nextPos > 52) score += 30; // Enter Home
      if (_safeSpots.contains(nextPos)) score += 20; // Safe
      if (currentPos == 0 && nextPos != 0) score += 10; // Spawn
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