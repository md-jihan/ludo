import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_event.dart';
import 'game_state.dart';
import '../../services/firebase_service.dart';
import '../../services/audio_service.dart'; // Ensure this import exists
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final FirebaseService _firebaseService;
  final AudioService _audioService; // <--- 1. Store the service
  final GameEngine _gameEngine = GameEngine();

  // <--- 2. Fix Constructor to initialize _audioService
  GameBloc(this._firebaseService, this._audioService) : super(GameInitial()) {

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

    // 3. Roll Dice
    on<RollDice>((event, emit) async {
      // <--- 3. Play Roll Sound
      _audioService.playRoll();

      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        // Generate Random (1-6)
        int diceValue = Random().nextInt(6) + 1;

        // Update result immediately
        await _firebaseService.updateGameState(event.gameId, {
          'diceValue': diceValue,
          'diceRolledBy': game.players[game.currentTurn]['id'],
        });

        // CHECK: Can I move anything?
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

          int nextTurn = (game.currentTurn + 1) % game.players.length;

          await _firebaseService.updateGameState(event.gameId, {
            'currentTurn': nextTurn,
            'diceValue': 0,
          });
        }
      }
    });

    // 4. Move Token
    on<MoveToken>((event, emit) async {
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        if (game.players[game.currentTurn]['id'] != event.userId) return;
        if (game.diceValue == 0) return;

        String color = game.players[game.currentTurn]['color'];
        List<int> tokens = List.from(game.tokens[color]!);
        int currentPos = tokens[event.tokenIndex];

        // A. Calculate Move
        int newPos = _gameEngine.calculateNextPosition(currentPos, game.diceValue, color);

        if (newPos == currentPos) return;

        // B. Apply Move locally first
        tokens[event.tokenIndex] = newPos;
        Map<String, List<int>> allTokens = Map.from(game.tokens);

        // Ensure we create deep copies of the lists to compare accurately
        allTokens = allTokens.map((k, v) => MapEntry(k, List.from(v)));
        allTokens[color] = tokens;

        // <--- 4. Sound Logic Preparation
        int enemiesBefore = _countEnemiesOnBoard(allTokens, color);

        // C. Check Kills
        allTokens = _gameEngine.checkKill(allTokens, color, newPos);

        // <--- 5. Play Correct Sound
        int enemiesAfter = _countEnemiesOnBoard(allTokens, color);

        if (enemiesAfter < enemiesBefore) {
          _audioService.playKill(); // Enemy count dropped -> Kill happened
        } else if (newPos == 99) { // Assuming 99 is winning index
          _audioService.playWin();
        } else {
          _audioService.playMove();
        }

        // D. Turn Logic
        int nextTurn = game.currentTurn;
        if (game.diceValue != 6) {
          nextTurn = (game.currentTurn + 1) % game.players.length;
        }

        // E. Save to Firebase
        await _firebaseService.updateGameState(event.gameId, {
          'tokens': allTokens,
          'currentTurn': nextTurn,
          'diceValue': 0,
        });
      }
    });
  }

  // <--- 6. Helper Method for Kill Detection
  int _countEnemiesOnBoard(Map<String, List<int>> tokens, String myColor) {
    int count = 0;
    tokens.forEach((key, positions) {
      if (key != myColor) {
        // Count active tokens (Not at Home 0, Not Finished 99)
        count += positions.where((pos) => pos > 0 && pos < 99).length;
      }
    });
    return count;
  }
}