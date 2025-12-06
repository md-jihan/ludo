import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/ludo_board_painter.dart' hide Point; // Hide Point to avoid conflict
import 'package:ludo/widgets/token_pawn.dart';
import '../models/game_model.dart';
import '../logic/path_constants.dart';
import '../logic/game_engine.dart'; // <--- 1. Import Engine
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';

class BoardLayout extends StatelessWidget {
  final GameModel gameModel;
  final String currentUserId;
  final GameEngine _engine = GameEngine(); // <--- 2. Create Engine Instance

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
              // A. THE VISUAL BOARD
              Positioned.fill(
                child: CustomPaint(
                  painter: LudoBoardPainter(players: gameModel.players),
                ),
              ),

              // B. THE TOKENS
              ..._buildTokens(context, gameModel.tokens, cellSize, tokenSize),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTokens(BuildContext context, Map<String, List<int>> allTokens, double cellSize, double tokenSize) {
    List<Widget> widgets = [];
    double centeringOffset = (cellSize - tokenSize) / 2;

    allTokens.forEach((color, positions) {
      for (int i = 0; i < positions.length; i++) {
        int currentPos = positions[i];
        Point? gridPoint;

        // 1. Determine Position
        if (currentPos == 0) {
          gridPoint = PathConstants.homeBases[color]![i];
        } else {
          gridPoint = PathConstants.stepToGrid[currentPos];
        }

        if (gridPoint != null) {
          double left = (gridPoint.col * cellSize) + centeringOffset;
          double top = (gridPoint.row * cellSize) + centeringOffset;

          // Inside _buildTokens method, replace the existing Positioned widget with this:

          // Inside _buildTokens method...

          widgets.add(
            // CHANGED: Use Positioned (No Animation) instead of AnimatedPositioned
            Positioned(
              left: left,
              top: top,

              child: GestureDetector(
                onTap: () {
                  _handleTap(context, color, i, currentPos);
                },
                child: SizedBox(
                  width: tokenSize,
                  height: tokenSize,
                  child: TokenPawn(
                    colorName: color,
                    tokenIndex: i,
                    isDimmed: gameModel.diceValue == 0,
                  ),
                ),
              ),
            ),
          );
        }
      }
    });
    return widgets;
  }

  // <--- 4. THE LOGIC HANDLER
  void _handleTap(BuildContext context, String clickedPawnColor, int index, int currentPos) {

    // A. IDENTIFY MY COLOR (The Local Player)
    final myPlayer = gameModel.players.firstWhere(
            (p) => p['id'] == currentUserId,
        orElse: () => {'color': 'Spectator'}
    );
    String myColor = myPlayer['color'];

    // B. STRICT OWNERSHIP CHECK
    // If I click a pawn that isn't mine, stop immediately with a message.
    if (clickedPawnColor != myColor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are $myColor! You can't move $clickedPawnColor."),
          backgroundColor: Colors.black87,
          duration: const Duration(milliseconds: 700),
        ),
      );
      return;
    }

    // C. TURN CHECK
    final currentPlayer = gameModel.players[gameModel.currentTurn];
    if (currentPlayer['id'] != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Wait for your turn!"),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 500)
        ),
      );
      return;
    }

    // D. DICE CHECK
    if (gameModel.diceValue == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Roll the dice first!"), duration: Duration(milliseconds: 500)),
      );
      return;
    }

    // E. VALIDATE MOVE (Game Engine Rules)
    int nextPos = _engine.calculateNextPosition(currentPos, gameModel.diceValue, clickedPawnColor);

    // If position doesn't change, the move is invalid based on rules
    if (nextPos == currentPos) {
      if (currentPos == 0 && gameModel.diceValue != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You need a 6 to move out of home!"), duration: Duration(milliseconds: 700)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid move!"), duration: Duration(milliseconds: 500)),
        );
      }
      return;
    }

    // F. SEND MOVE EVENT (Only if everything above passed)
    context.read<GameBloc>().add(
      MoveToken(
        gameId: gameModel.gameId,
        userId: currentUserId,
        tokenIndex: index,
      ),
    );
  }
}