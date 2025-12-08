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

  // FIX: Memory to track moves that are waiting for server confirmation
  // Format: { 'UserId': { TokenIndex: TargetPosition } }
  final Map<String, Map<int, int>> _pendingMoves = {};

  GameBloc({required FirebaseService firebaseService})
      : _firebaseService = firebaseService,
        super(GameInitial()) {

    // 1. Load Game (Stream with Anti-Glitch Protection)
    on<LoadGame>((event, emit) async {
      await emit.forEach(
        _firebaseService.streamGame(event.gameId),
        onData: (GameModel incomingGame) {
          // Create a modifiable copy of the tokens
          Map<String, List<int>> correctedTokens = Map.from(incomingGame.tokens);
          correctedTokens = correctedTokens.map((k, v) => MapEntry(k, List.from(v)));

          // CHECK PENDING MOVES
          List<String> usersToCheck = _pendingMoves.keys.toList();

          for (String userId in usersToCheck) {
            // Find player color
            var player = incomingGame.players.firstWhere((p) => p['id'] == userId, orElse: () => {});
            if (player.isEmpty) continue;

            String color = player['color'];
            if (!correctedTokens.containsKey(color)) continue;

            Map<int, int> userMoves = _pendingMoves[userId]!;
            List<int> completedTokens = [];

            userMoves.forEach((tokenIdx, targetPos) {
              int serverPos = correctedTokens[color]![tokenIdx];

              if (serverPos == targetPos) {
                // SUCCESS: Server has caught up!
                completedTokens.add(tokenIdx);
              } else {
                // LAG: Server is sending old data (e.g. 0).
                // We ignore the server and FORCE our local optimistic value (e.g. 1).
                correctedTokens[color]![tokenIdx] = targetPos;
              }
            });

            // Cleanup finished moves
            for (int t in completedTokens) {
              userMoves.remove(t);
            }
            if (userMoves.isEmpty) {
              _pendingMoves.remove(userId);
            }
          }

          return GameLoaded(incomingGame.copyWith(tokens: correctedTokens));
        },
        onError: (_, __) => const GameError(),
      );
    });

    on<StartGame>((event, emit) async {
      await _firebaseService.updateGameState(event.gameId, {'status': 'playing'});
    });

    on<LeaveGameEvent>((event, emit) async {
      await _firebaseService.leaveGame(event.gameId, event.userId);
    });

    on<RollDice>((event, emit) async {
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        int diceValue = Random().nextInt(6) + 1;

        await _firebaseService.updateGameState(event.gameId, {
          'diceValue': diceValue,
          'diceRolledBy': game.players[game.currentTurn]['id'],
        });

        // Auto-skip Logic
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

    on<MoveToken>((event, emit) async {
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        if (game.players[game.currentTurn]['id'] != event.userId) return;
        if (game.diceValue == 0) return;

        String color = game.players[game.currentTurn]['color'];
        List<int> tokens = List.from(game.tokens[color]!);
        int currentPos = tokens[event.tokenIndex];

        int newPos = _gameEngine.calculateNextPosition(currentPos, game.diceValue, color);
        if (newPos == currentPos) return;

        // --- 1. REGISTER PENDING MOVE (Anti-Glitch) ---
        if (!_pendingMoves.containsKey(event.userId)) {
          _pendingMoves[event.userId] = {};
        }
        _pendingMoves[event.userId]![event.tokenIndex] = newPos;

        // --- 2. OPTIMISTIC UPDATE ---
        Map<String, List<int>> allTokens = Map.from(game.tokens);
        allTokens = allTokens.map((k, v) => MapEntry(k, List.from(v)));
        allTokens[color]![event.tokenIndex] = newPos;

        allTokens = _gameEngine.checkKill(allTokens, color, newPos);

        bool hasWon = allTokens[color]!.every((pos) => pos == 99);
        List<String> currentWinners = List.from(game.winners);
        if (hasWon && !currentWinners.contains(event.userId)) {
          currentWinners.add(event.userId);
        }

        int nextTurn = game.currentTurn;
        if (game.diceValue != 6 && !hasWon) {
          nextTurn = _getNextValidTurn(game, game.currentTurn);
        }

        emit(GameLoaded(game.copyWith(
          tokens: allTokens,
          diceValue: 0,
          currentTurn: nextTurn,
          winners: currentWinners,
        )));

        if (_didKillOccur(game.tokens, allTokens)) {
          AudioService.playKill();
        } else if (hasWon) {
          AudioService.playWin();
        }

        // --- 3. SEND TO SERVER ---
        await _firebaseService.moveToken(event.gameId, event.userId, event.tokenIndex, newPos);
      }
    });
  }

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

  bool _didKillOccur(Map<String, List<int>> oldTokens, Map<String, List<int>> newTokens) {
    int countOld = 0;
    int countNew = 0;
    oldTokens.forEach((k, v) => countOld += v.where((p) => p > 0 && p < 99).length);
    newTokens.forEach((k, v) => countNew += v.where((p) => p > 0 && p < 99).length);
    return countNew < countOld;
  }
}