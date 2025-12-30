import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';
import '../game/game_event.dart';
import '../game/game_state.dart';
import '../../services/audio_service.dart'; // Ensure AudioService is imported for sounds

class ComputerGameBloc extends Bloc<GameEvent, GameState> {
  final GameEngine _engine = GameEngine();

  // Internal state tracker
  GameModel _currentGame;

  ComputerGameBloc()
      : _currentGame = GameModel(
    gameId: "OFFLINE",
    status: 'initial',
    currentTurn: 0,
    diceValue: 0,
    diceRolledBy: '',
    winners: [],
    players: [],
    tokens: {
      'Red': [0,0,0,0],
      'Green': [0,0,0,0],
      'Yellow': [0,0,0,0],
      'Blue': [0,0,0,0],
    },
  ),
        super(GameInitial()) {

    on<StartComputerGame>(_onStartComputerGame);
    on<RollDice>(_onRollDice);
    on<MoveToken>(_onMoveToken);
  }

  void _onStartComputerGame(StartComputerGame event, Emitter<GameState> emit) {
    String myColor = event.userColor;

    // 1. Calculate Computer Color (Opposite side)
    List<String> colors = ['Red', 'Green', 'Yellow', 'Blue'];
    int myIndex = colors.indexOf(myColor);
    int compIndex = (myIndex + 2) % 4;
    String compColor = colors[compIndex];

    // 2. Setup Players
    List<Map<String, dynamic>> players = [
      {'id': 'User', 'name': 'You', 'color': myColor, 'isAuto': false},
      {'id': 'Comp1', 'name': 'Computer', 'color': compColor, 'isAuto': true},
    ];

    _currentGame = GameModel(
      gameId: "OFFLINE",
      status: 'playing',
      currentTurn: 0,
      diceValue: 0,
      diceRolledBy: '',
      winners: [],
      players: players,
      tokens: {
        'Red': [0,0,0,0],
        'Green': [0,0,0,0],
        'Yellow': [0,0,0,0],
        'Blue': [0,0,0,0],
      },
    );

    emit(GameLoaded(_currentGame));
  }

  Future<void> _onRollDice(RollDice event, Emitter<GameState> emit) async {
    // STOP if game is finished
    if (_currentGame.status == 'finished') return;

    // Play Sound
    AudioService.playRoll();

    int roll = Random().nextInt(6) + 1;

    _currentGame = _currentGame.copyWith(
        diceValue: roll,
        diceRolledBy: _currentGame.players[_currentGame.currentTurn]['id']
    );
    emit(GameLoaded(_currentGame));

    bool isComputer = _currentGame.players[_currentGame.currentTurn]['isAuto'];

    // Ask Engine for Best Move
    int bestTokenIndex = _engine.pickBestTokenIndex(_currentGame, roll);

    if (bestTokenIndex == -1) {
      // No Move Possible -> Next Turn
      await Future.delayed(const Duration(seconds: 1));
      _nextTurn(emit);
    } else {
      if (isComputer) {
        // Computer moves automatically
        await Future.delayed(const Duration(milliseconds: 1000));
        add(MoveToken(gameId: "OFFLINE", userId: "Comp1", tokenIndex: bestTokenIndex));
      }
      // Human waits for tap input
    }
  }

  void _onMoveToken(MoveToken event, Emitter<GameState> emit) {
    // Capture roll before resetting
    int currentRoll = _currentGame.diceValue;

    String color = _currentGame.players[_currentGame.currentTurn]['color'];
    List<int> tokens = List.from(_currentGame.tokens[color]!);
    int currentPos = tokens[event.tokenIndex];
    int newPos = _engine.calculateNextPosition(currentPos, currentRoll, color);

    tokens[event.tokenIndex] = newPos;
    Map<String, List<int>> allTokens = Map.from(_currentGame.tokens);
    allTokens[color] = tokens;

    // Handle Kill
    allTokens = _engine.checkKill(allTokens, color, newPos);

    // --- WIN CONDITION CHECK ---
    // Check if ALL 4 tokens for this color are at 99
    bool hasWon = allTokens[color]!.every((pos) => pos == 99);

    List<String> currentWinners = List.from(_currentGame.winners);
    if (hasWon && !currentWinners.contains(color)) {
      currentWinners.add(color);
    }

    // --- GAME OVER LOGIC ---
    String newStatus = _currentGame.status;
    if (currentWinners.isNotEmpty) {
      newStatus = 'finished'; // <--- THIS TRIGGERS THE UI DIALOG
    }

    _currentGame = _currentGame.copyWith(
      tokens: allTokens,
      diceValue: 0, // Reset dice
      winners: currentWinners,
      status: newStatus,
    );

    emit(GameLoaded(_currentGame));

    // IF GAME FINISHED: STOP HERE
    if (newStatus == 'finished') {
      return;
    }

    // Normal Turn Logic
    if (currentRoll != 6 && !hasWon) {
      _nextTurn(emit);
    } else {
      // Rolled 6 or Won a pawn: Play again
      if (_currentGame.players[_currentGame.currentTurn]['isAuto']) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) add(const RollDice("OFFLINE"));
        });
      }
    }
  }

  void _nextTurn(Emitter<GameState> emit) {
    if (_currentGame.status == 'finished') return;

    int next = (_currentGame.currentTurn + 1) % _currentGame.players.length;
    _currentGame = _currentGame.copyWith(
      currentTurn: next,
      diceValue: 0,
    );
    emit(GameLoaded(_currentGame));

    // If next player is Computer, auto-roll
    if (_currentGame.players[next]['isAuto']) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) add(const RollDice("OFFLINE"));
      });
    }
  }
}