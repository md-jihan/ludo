import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_event.dart';
import 'game_state.dart';
import '../../services/firebase_service.dart';
import '../../services/audio_service.dart';
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final FirebaseService _firebaseService;
  final GameEngine _gameEngine = GameEngine();

  GameBloc({required FirebaseService firebaseService})
      : _firebaseService = firebaseService,
        super(GameInitial()) {

    // 1. Load Game (Stream)
    on<LoadGame>((event, emit) async {
      await emit.forEach(
        _firebaseService.streamGame(event.gameId),
        onData: (GameModel game) => GameLoaded(game),
        onError: (_, __) => const GameError(),
      );
    });

    // 2. Start Game
    on<StartGame>((event, emit) async {
      await _firebaseService.updateGameState(event.gameId, {'status': 'playing'});
    });

    // 3. Leave Game
    on<LeaveGameEvent>((event, emit) async {
      await _firebaseService.leaveGame(event.gameId, event.userId);
    });

    // 4. Roll Dice
    on<RollDice>((event, emit) async {
      // Audio is handled in UI widget for immediate feedback
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        int diceValue = Random().nextInt(6) + 1;

        // Optimistic Update? No, for dice we usually wait for server to prevent cheating conflicts,
        // but since we have the animation in UI, the delay is hidden there.
        await _firebaseService.updateGameState(event.gameId, {
          'diceValue': diceValue,
          'diceRolledBy': game.players[game.currentTurn]['id'],
        });

        // Auto-skip logic if no move possible
        String color = game.players[game.currentTurn]['color'];
        List<int> myTokens = game.tokens[color]!;
        bool canMove = false;

        for (int pos in myTokens) {
          int nextPos = _gameEngine.calculateNextPosition(pos, diceValue, color);
          if (nextPos != pos) {
            canMove = true;
            break;
          }
        }

        if (!canMove) {
          await Future.delayed(const Duration(seconds: 1));
          int nextTurn = _getNextValidTurn(game, game.currentTurn);
          await _firebaseService.updateGameState(event.gameId, {
            'currentTurn': nextTurn,
            'diceValue': 0,
          });
        }
      }
    });

    // 5. MOVE TOKEN (OPTIMISTIC UPDATE FIX)
    on<MoveToken>((event, emit) async {
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        // Validation
        if (game.players[game.currentTurn]['id'] != event.userId) return;
        if (game.diceValue == 0) return;

        String color = game.players[game.currentTurn]['color'];
        List<int> tokens = List.from(game.tokens[color]!);
        int currentPos = tokens[event.tokenIndex];

        // Logic
        int newPos = _gameEngine.calculateNextPosition(currentPos, game.diceValue, color);
        if (newPos == currentPos) return;

        // --- STEP A: CALCULATE NEW STATE LOCALLY ---
        // We create the "Future State" right now
        Map<String, List<int>> allTokens = Map.from(game.tokens);
        // Deep copy the list so we don't mutate the old state
        allTokens = allTokens.map((k, v) => MapEntry(k, List.from(v)));

        // Update Position
        allTokens[color]![event.tokenIndex] = newPos;

        // Check Kill (Simulated)
        allTokens = _gameEngine.checkKill(allTokens, color, newPos);

        // Check Win (Simulated)
        bool hasWon = allTokens[color]!.every((pos) => pos == 99);
        List<String> currentWinners = List.from(game.winners);
        if (hasWon && !currentWinners.contains(event.userId)) {
          currentWinners.add(event.userId);
        }

        // Calculate Next Turn (Simulated)
        int nextTurn = game.currentTurn;
        if (game.diceValue != 6 && !hasWon) {
          nextTurn = _getNextValidTurn(game, game.currentTurn);
        }

        // --- STEP B: EMIT STATE IMMEDIATELY (OPTIMISTIC) ---
        // The UI will update instantly, Pawn starts walking instantly.
        emit(GameLoaded(game.copyWith(
          tokens: allTokens,
          diceValue: 0, // Reset dice visually so they can't click again
          currentTurn: nextTurn,
          winners: currentWinners,
        )));

        // --- STEP C: SOUNDS ---
        // Play sound immediately
        String prevTokensStr = game.tokens.toString(); // Compare against OLD state
        if (allTokens.toString() != prevTokensStr && allTokens[color]![event.tokenIndex] == newPos) {
          // We do a rough check. If it was a kill, the map string changed drastically.
          // Actually, AnimatedToken plays 'playMove'. We only need 'playKill' or 'playWin'.
          // Since AnimatedToken handles the walking sound, let's just handle Win/Kill.

          // If we suspect a kill (enemy count changed), play kill sound
          if (_didKillOccur(game.tokens, allTokens)) {
            AudioService.playKill();
          } else if (hasWon) {
            AudioService.playWin();
          }
        }

        // --- STEP D: SEND TO SERVER ---
        // We send the request. When Firebase responds, the Stream will update again.
        // Since we already updated the UI to the same result, the user sees no change (smooth).
        await _firebaseService.moveToken(event.gameId, event.userId, event.tokenIndex, newPos);
      }
    });
  }

  // --- Helper Methods ---
  int _getNextValidTurn(GameModel game, int currentTurn) {
    int next = currentTurn;
    for (int i = 0; i < game.players.length; i++) {
      next = (next + 1) % game.players.length;
      bool hasLeft = game.players[next]['hasLeft'] ?? false;
      String playerId = game.players[next]['id'];
      bool hasWon = game.winners.contains(playerId);

      if (!hasLeft && !hasWon) return next;
    }
    return currentTurn;
  }

  // Simple helper to detect if total tokens on board decreased (Kill happened)
  bool _didKillOccur(Map<String, List<int>> oldTokens, Map<String, List<int>> newTokens) {
    int countOld = 0;
    int countNew = 0;

    oldTokens.forEach((k, v) => countOld += v.where((p) => p > 0 && p < 99).length);
    newTokens.forEach((k, v) => countNew += v.where((p) => p > 0 && p < 99).length);

    // If fewer tokens are on the board path now, someone got sent to 0 (Home).
    return countNew < countOld;
  }
}