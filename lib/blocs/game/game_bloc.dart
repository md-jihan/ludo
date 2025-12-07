import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_event.dart';
import 'game_state.dart';
import '../../services/firebase_service.dart';
import '../../services/audio_service.dart'; // <--- Import AudioService
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final FirebaseService _firebaseService;
  final GameEngine _gameEngine = GameEngine();

  // 1. FIX: Removed AudioService from constructor
  GameBloc({required FirebaseService firebaseService})
      : _firebaseService = firebaseService,
        super(GameInitial()) {

    // 1. Listen to Stream
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
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        // 2. FIX: Static Audio Call
        AudioService.playRoll();

        int diceValue = Random().nextInt(6) + 1;

        await _firebaseService.updateGameState(event.gameId, {
          'diceValue': diceValue,
          'diceRolledBy': game.players[game.currentTurn]['id'],
        });

        // Check if move is possible
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

        // IF NO MOVE POSSIBLE -> Auto Switch Turn
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

    // 5. Move Token
    on<MoveToken>((event, emit) async {
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        if (game.players[game.currentTurn]['id'] != event.userId) return;
        if (game.diceValue == 0) return;

        String color = game.players[game.currentTurn]['color'];
        List<int> tokens = List.from(game.tokens[color]!);
        int currentPos = tokens[event.tokenIndex];

        // Logic
        int newPos = _gameEngine.calculateNextPosition(currentPos, game.diceValue, color);
        if (newPos == currentPos) return;

        // --- 3. FIX: CALCULATE AUDIO LOCALLY ---
        // We simulate the move locally just to play the correct sound immediately
        Map<String, List<int>> tempTokens = Map.from(game.tokens);
        tempTokens[color] = List.from(tokens)..[event.tokenIndex] = newPos;

        String prevTokensStr = tempTokens.toString();
        // Check Kill simulation
        tempTokens = _gameEngine.checkKill(tempTokens, color, newPos);

        if (tempTokens.toString() != prevTokensStr) {
          AudioService.playKill(); // Static Call
        } else if (newPos == 99) {
          AudioService.playWin();  // Static Call
        } else {
          AudioService.playMove(); // Static Call
        }

        // --- 4. FIX: DELEGATE LOGIC TO FIREBASE SERVICE ---
        // We use 'moveToken' because it handles Winning, Rankings, and Turn Switching safely.
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

      // Also check if they already won
      String playerId = game.players[next]['id'];
      bool hasWon = game.winners.contains(playerId);

      if (!hasLeft && !hasWon) return next;
    }
    return currentTurn;
  }
}