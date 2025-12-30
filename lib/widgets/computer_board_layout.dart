import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/ludo_board_painter.dart';
import 'package:ludo/widgets/animated_token.dart';
import '../models/game_model.dart';
import '../logic/game_engine.dart';
import '../blocs/computer/computer_game_bloc.dart';
import '../blocs/game/game_event.dart';

class ComputerBoardLayout extends StatelessWidget {
  final GameModel gameModel;
  final String currentUserId;
  final GameEngine _engine = GameEngine();

  ComputerBoardLayout({
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
              // 1. Board Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: LudoBoardPainter(players: gameModel.players),
                ),
              ),
              // 2. Tokens (Sorted so active turn is on top)
              ..._buildTokens(context, gameModel.tokens, cellSize, tokenSize),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTokens(BuildContext context, Map<String, List<int>> allTokensMap, double cellSize, double tokenSize) {
    List<Map<String, dynamic>> tokenDataList = [];

    allTokensMap.forEach((color, positions) {
      for (int i = 0; i < positions.length; i++) {
        tokenDataList.add({
          'color': color,
          'index': i,
          'pos': positions[i],
        });
      }
    });

    // LAYER FIX: Sort so current player's tokens are drawn LAST (on top)
    final currentPlayerColor = gameModel.players[gameModel.currentTurn]['color'];

    tokenDataList.sort((a, b) {
      if (a['color'] == currentPlayerColor && b['color'] != currentPlayerColor) return 1;
      if (a['color'] != currentPlayerColor && b['color'] == currentPlayerColor) return -1;
      return 0;
    });

    return tokenDataList.map((token) {
      String color = token['color'];
      int i = token['index'];
      int currentPos = token['pos'];

      return AnimatedToken(
        key: ValueKey("comp-$color-$i"),
        colorName: color,
        tokenIndex: i,
        currentPosition: currentPos,
        // Dim if dice not rolled, or if pawn is already finished (99)
        isDimmed: gameModel.diceValue == 0 || currentPos == 99,
        cellSize: cellSize,
        tokenSize: tokenSize,
        onTap: () => _handleTap(context, color, i, currentPos),
      );
    }).toList();
  }

  void _handleTap(BuildContext context, String clickedPawnColor, int index, int currentPos) {
    // 1. Check Ownership
    final myPlayer = gameModel.players.firstWhere(
            (p) => p['id'] == currentUserId,
        orElse: () => {'color': 'Spectator'}
    );
    String myColor = myPlayer['color'];

    // Safety check turn
    final currentPlayer = gameModel.players[gameModel.currentTurn];

    // Must be My Color AND My Turn
    if (clickedPawnColor != myColor || currentPlayer['id'] != currentUserId) return;

    // 2. Check if Finished
    if (currentPos == 99) {
      _showSnack(context, "This pawn has finished!");
      return;
    }

    // 3. Dice check
    if (gameModel.diceValue == 0) {
      _showSnack(context, "Roll the dice first!");
      return;
    }

    // 4. Validate Move logic
    int nextPos = _engine.calculateNextPosition(currentPos, gameModel.diceValue, clickedPawnColor);

    // If nextPos == currentPos, the engine says "Move Impossible"
    if (nextPos == currentPos) {
      // Provide smart feedback
      List<int> gateData = _engine.getHomeEntrance(clickedPawnColor);
      int homeStart = gateData[1];
      int homeEnd = gateData[2];

      // If user is inside the home stretch, calculate needed roll
      if (currentPos >= homeStart && currentPos <= homeEnd) {
        // homeEnd + 1 is the victory step
        int stepsNeeded = (homeEnd - currentPos) + 1;
        _showSnack(context, "You need a $stepsNeeded to win!");
      } else {
        _showSnack(context, "Invalid move!");
      }
      return;
    }

    // 5. Dispatch move
    context.read<ComputerGameBloc>().add(
      MoveToken(
        gameId: gameModel.gameId,
        userId: currentUserId,
        tokenIndex: index,
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(milliseconds: 700))
    );
  }
}