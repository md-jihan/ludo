import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';
import '../../services/audio_service.dart'; // <--- Ensure AudioService is imported
import '../game/game_event.dart';
import '../game/game_state.dart';

class ComputerGameBloc extends Bloc<GameEvent, GameState> {
  final GameEngine _engine = GameEngine();
  final String humanId = "HUMAN_PLAYER";
  final String botId = "COMPUTER_BOT";

  ComputerGameBloc() : super(GameInitial()) {
    on<StartComputerGame>(_onStartComputerGame);
    on<RollDice>(_onRollDice);
    on<MoveToken>(_onMoveToken);
  }

  // 1. START GAME
  void _onStartComputerGame(StartComputerGame event, Emitter<GameState> emit) {
    String userColor = event.userColor;
    String botColor;

    switch (userColor) {
      case 'Red': botColor = 'Yellow'; break;
      case 'Green': botColor = 'Blue'; break;
      case 'Yellow': botColor = 'Red'; break;
      case 'Blue': botColor = 'Green'; break;
      default: botColor = 'Yellow';
    }

    Map<String, List<int>> tokens = {
      'Red': [0, 0, 0, 0],
      'Green': [0, 0, 0, 0],
      'Yellow': [0, 0, 0, 0],
      'Blue': [0, 0, 0, 0],
    };

    List<Map<String, dynamic>> players = [
      {'id': humanId, 'name': 'You', 'color': userColor, 'type': 'human'},
      {'id': botId, 'name': 'Computer', 'color': botColor, 'type': 'bot'},
    ];

    // Initialize Game Model
    final game = GameModel(
      gameId: "OFFLINE",
      status: "playing",
      currentTurn: 0,
      diceValue: 0,
      diceRolledBy: "",
      tokens: tokens,
      players: players,
      winners: [],
    );

    emit(GameLoaded(game));
  }

  // 2. ROLL DICE
  Future<void> _onRollDice(RollDice event, Emitter<GameState> emit) async {
    if (state is! GameLoaded) return;

    // --- DEFINING 'game' HERE IS CRITICAL ---
    final currentState = state as GameLoaded;
    var game = currentState.gameModel;

    if (game.status == 'finished') return;

    // BOT SOUND CHECK
    if (game.players[game.currentTurn]['type'] == 'bot') {
      AudioService.playRoll();
    }

    // Generate Roll
    int roll = Random().nextInt(6) + 1;

    // Update State
    game = game.copyWith(
      diceValue: roll,
      diceRolledBy: game.players[game.currentTurn]['id'],
    );
    emit(GameLoaded(game));

    // Check Logic
    String color = game.players[game.currentTurn]['color'];
    bool canMove = _canAnyTokenMove(game.tokens[color]!, roll, color);

    if (!canMove) {
      await Future.delayed(const Duration(seconds: 1));
      add(MoveToken(gameId: "OFFLINE", userId: "AUTO", tokenIndex: -1));
    } else if (game.players[game.currentTurn]['type'] == 'bot') {
      await Future.delayed(const Duration(milliseconds: 1500));
      int bestTokenIndex = _findBestBotMove(game, roll);
      add(MoveToken(gameId: "OFFLINE", userId: botId, tokenIndex: bestTokenIndex));
    }
  }

  // 3. MOVE TOKEN
  Future<void> _onMoveToken(MoveToken event, Emitter<GameState> emit) async {
    if (state is! GameLoaded) return;

    // --- DEFINING 'game' HERE IS CRITICAL ---
    final currentState = state as GameLoaded;
    var game = currentState.gameModel;

    // Handle Skip Turn
    if (event.tokenIndex == -1) {
      int nextTurn = (game.currentTurn + 1) % game.players.length;
      game = game.copyWith(diceValue: 0, currentTurn: nextTurn);
      emit(GameLoaded(game));
      _checkBotTurn(game);
      return;
    }

    // Calculate Logic
    String color = game.players[game.currentTurn]['color'];
    List<int> tokens = List.from(game.tokens[color]!);
    int currentPos = tokens[event.tokenIndex];
    int newPos = _engine.calculateNextPosition(currentPos, game.diceValue, color);

    if (newPos == currentPos) return;

    // Apply Move
    tokens[event.tokenIndex] = newPos;
    Map<String, List<int>> allTokens = Map.from(game.tokens);
    allTokens[color] = tokens;

    // Kill Check & Sound
    String prevTokensStr = allTokens.toString();
    allTokens = _engine.checkKill(allTokens, color, newPos);

    if (allTokens.toString() != prevTokensStr) {
      AudioService.playKill();
    } else {
      AudioService.playMove();
    }

    // Win Check
    bool hasWon = tokens.every((pos) => pos == 99);
    List<String> currentWinners = List.from(game.winners);

    if (hasWon) {
      AudioService.playWin();

      String playerId = game.players[game.currentTurn]['id'];
      if (!currentWinners.contains(playerId)) {
        currentWinners.add(playerId);
      }

      // End Game
      game = game.copyWith(
        tokens: allTokens,
        diceValue: 0,
        status: 'finished',
        winners: currentWinners,
      );
      emit(GameLoaded(game));
      return;
    }

    // Next Turn Calculation
    int nextTurn = game.currentTurn;
    if (game.diceValue != 6) {
      nextTurn = (game.currentTurn + 1) % game.players.length;
    }

    // Update State
    game = game.copyWith(
      tokens: allTokens,
      diceValue: 0,
      currentTurn: nextTurn,
      winners: currentWinners,
    );

    emit(GameLoaded(game));
    _checkBotTurn(game);
  }

  void _checkBotTurn(GameModel game) {
    if (game.status == 'finished') return;
    if (game.players[game.currentTurn]['type'] == 'bot') {
      Future.delayed(const Duration(seconds: 1), () {
        add(RollDice("OFFLINE"));
      });
    }
  }

  // --- HELPERS ---
  bool _canAnyTokenMove(List<int> tokens, int dice, String color) {
    for (int pos in tokens) {
      if (_engine.calculateNextPosition(pos, dice, color) != pos) return true;
    }
    return false;
  }

  int _findBestBotMove(GameModel game, int dice) {
    String color = game.players[game.currentTurn]['color'];
    List<int> tokens = game.tokens[color]!;

    // Priority: Kill
    for(int i=0; i<4; i++) {
      int next = _engine.calculateNextPosition(tokens[i], dice, color);
      Map<String, List<int>> tempTokens = Map.from(game.tokens);
      tempTokens[color] = List.from(tokens)..[i] = next;
      if (_engine.checkKill(tempTokens, color, next).toString() != tempTokens.toString()) return i;
    }

    // Priority: Home
    for (int i = 0; i < 4; i++) {
      if (tokens[i] == 0 && dice == 6) return i;
    }

    // Priority: Any Move
    for(int i=0; i<4; i++) {
      if (_engine.calculateNextPosition(tokens[i], dice, color) != tokens[i]) return i;
    }
    return 0;
  }
}