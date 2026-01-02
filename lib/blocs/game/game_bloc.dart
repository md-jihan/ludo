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

  // Track moves waiting for server confirmation
  final Map<String, Map<int, int>> _pendingMoves = {};

  GameBloc({required FirebaseService firebaseService})
      : _firebaseService = firebaseService,
        super(GameInitial()) {

    on<LoadGame>((event, emit) async {
      await emit.forEach(
        _firebaseService.streamGame(event.gameId),
        onData: (GameModel incomingGame) {
          Map<String, List<int>> correctedTokens = Map.from(incomingGame.tokens);
          correctedTokens = correctedTokens.map((k, v) => MapEntry(k, List.from(v)));

          // Check Pending Moves (Anti-Glitch)
          List<String> usersToCheck = _pendingMoves.keys.toList();
          for (String userId in usersToCheck) {
            var player = incomingGame.players.firstWhere((p) => p['id'] == userId, orElse: () => {});
            if (player.isEmpty) continue;

            String color = player['color'];
            if (!correctedTokens.containsKey(color)) continue;

            Map<int, int> userMoves = _pendingMoves[userId]!;
            List<int> completedTokens = [];

            userMoves.forEach((tokenIdx, targetPos) {
              int serverPos = correctedTokens[color]![tokenIdx];
              if (serverPos == targetPos) {
                completedTokens.add(tokenIdx);
              } else {
                correctedTokens[color]![tokenIdx] = targetPos; // Force optimistic
              }
            });

            for (int t in completedTokens) userMoves.remove(t);
            if (userMoves.isEmpty) _pendingMoves.remove(userId);
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
        // Prevent rolling if game is finished
        if (game.status == 'finished') return;

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

        // IF NO MOVES POSSIBLE
        if (!canMove) {
          await Future.delayed(const Duration(seconds: 1));
          int nextTurn = _getNextValidTurn(game, game.currentTurn);

          // --- FIX START: OPTIMISTIC UPDATE ---
          // Immediately switch local state to "Next Turn".
          // This ensures UI disables the dice instantly, preventing a "3rd roll" glitch
          // while waiting for the server to reply.
          emit(GameLoaded(game.copyWith(
            diceValue: 0,
            currentTurn: nextTurn,
          )));
          // --- FIX END ---

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

        // 1. Pending Move
        if (!_pendingMoves.containsKey(event.userId)) {
          _pendingMoves[event.userId] = {};
        }
        _pendingMoves[event.userId]![event.tokenIndex] = newPos;

        // 2. Optimistic Update
        Map<String, List<int>> allTokens = Map.from(game.tokens);
        allTokens = allTokens.map((k, v) => MapEntry(k, List.from(v)));
        allTokens[color]![event.tokenIndex] = newPos;

        allTokens = _gameEngine.checkKill(allTokens, color, newPos);

        // --- WIN LOGIC ---
        bool hasWon = allTokens[color]!.every((pos) => pos == 99);
        List<String> currentWinners = List.from(game.winners);

        if (hasWon && !currentWinners.contains(event.userId)) {
          currentWinners.add(event.userId);
        }

        // --- CHECK GAME FINISH ---
        String newStatus = game.status;
        if (currentWinners.length >= game.players.length - 1 && game.players.length > 1) {
          newStatus = 'finished';
        }

        int nextTurn = game.currentTurn;
        if (newStatus != 'finished' && game.diceValue != 6 && !hasWon) {
          nextTurn = _getNextValidTurn(game, game.currentTurn);
        }

        emit(GameLoaded(game.copyWith(
          tokens: allTokens,
          diceValue: 0,
          currentTurn: nextTurn,
          winners: currentWinners,
          status: newStatus,
        )));

        if (_didKillOccur(game.tokens, allTokens)) {
          AudioService.playKill();
        } else if (hasWon) {
          AudioService.playWin();
        } else {
          AudioService.playMove();
        }

        // 3. Send to Server
        await _firebaseService.moveToken(event.gameId, event.userId, event.tokenIndex, newPos);

        // Ensure Turn/Status/Dice reset is synced
        await _firebaseService.updateGameState(event.gameId, {
          'diceValue': 0, // Reset dice on server immediately
          'currentTurn': nextTurn,
          'status': newStatus,
          if (hasWon) 'winners': currentWinners,
        });
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