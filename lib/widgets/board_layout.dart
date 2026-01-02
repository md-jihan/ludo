import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ludo_board_painter.dart';
import 'animated_token.dart';
import '../models/game_model.dart';
import '../logic/game_engine.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';

class BoardLayout extends StatelessWidget {
  final GameModel gameModel;
  final String currentUserId;
  final GameEngine _engine = GameEngine();

  BoardLayout({
    super.key,
    required this.gameModel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double boardSize = constraints.maxWidth;
        double cellSize = boardSize / 15.0;
        double tokenSize = cellSize * 0.9;

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: LudoBoardPainter(players: gameModel.players),
                ),
              ),
              // --- FIX: USE SORTED TOKENS METHOD ---
              ..._buildSortedTokens(context, gameModel.tokens, cellSize, tokenSize),
            ],
          ),
        );
      },
    );
  }

  // --- NEW METHOD: Sorts tokens so Active Player is on TOP ---
  List<Widget> _buildSortedTokens(BuildContext context, Map<String, List<int>> allTokens, double cellSize, double tokenSize) {
    List<Map<String, dynamic>> tokenDataList = [];

    // 1. Flatten tokens into a list
    allTokens.forEach((color, positions) {
      for (int i = 0; i < positions.length; i++) {
        tokenDataList.add({
          'color': color,
          'index': i,
          'pos': positions[i],
        });
      }
    });

    // 2. Identify Active Player Color
    String currentTurnColor = '';
    if (gameModel.players.isNotEmpty) {
      currentTurnColor = gameModel.players[gameModel.currentTurn]['color'];
    }

    // 3. SORT: Active Player's tokens go to the END (Top of Stack)
    tokenDataList.sort((a, b) {
      bool aIsCurrent = (a['color'] == currentTurnColor);
      bool bIsCurrent = (b['color'] == currentTurnColor);

      if (aIsCurrent && !bIsCurrent) return 1; // A is active -> Draw A Last
      if (!aIsCurrent && bIsCurrent) return -1; // B is active -> Draw B Last
      return 0;
    });

    // 4. Create Widgets
    return tokenDataList.map((data) {
      return _buildSingleToken(context, data['color'], data['index'], data['pos'], cellSize, tokenSize);
    }).toList();
  }

  Widget _buildSingleToken(BuildContext context, String color, int i, int currentPos, double cellSize, double tokenSize) {
    return AnimatedToken(
      key: ValueKey("$color-$i"),
      colorName: color,
      tokenIndex: i,
      currentPosition: currentPos,
      isDimmed: gameModel.diceValue == 0 || currentPos == 99,
      cellSize: cellSize,
      tokenSize: tokenSize,
      onTap: () => _handleTap(context, color, i, currentPos),
    );
  }

  void _handleTap(BuildContext context, String clickedPawnColor, int index, int currentPos) {
    // 1. Check Ownership
    final myPlayer = gameModel.players.firstWhere(
            (p) => p['id'] == currentUserId,
        orElse: () => {'color': 'Spectator'}
    );
    String myColor = myPlayer['color'];
    if (clickedPawnColor != myColor) return;

    // 2. Check Dice
    if (gameModel.diceValue == 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Roll the dice first!"), duration: Duration(milliseconds: 500)));
      return;
    }

    // 3. Check Turn
    final currentPlayer = gameModel.players[gameModel.currentTurn];
    if (currentPlayer['id'] != currentUserId) return;

    // 4. Validate Move
    int nextPos = _engine.calculateNextPosition(currentPos, gameModel.diceValue, clickedPawnColor);
    if (nextPos == currentPos) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Invalid move!"),
              duration: Duration(milliseconds: 500)
          )
      );
      return;
    }

    // 5. Send Move
    context.read<GameBloc>().add(
      MoveToken(
        gameId: gameModel.gameId,
        userId: currentUserId,
        tokenIndex: index,
      ),
    );
  }
}