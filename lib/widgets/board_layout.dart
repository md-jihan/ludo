import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_model.dart';
import '../logic/path_constants.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import 'token_pawn.dart';
import 'ludo_board_painter.dart' hide Point; // Import the new painter

class BoardLayout extends StatelessWidget {
  final GameModel gameModel;
  final String currentUserId;

  const BoardLayout({
    super.key,
    required this.gameModel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. Calculate the Square Board Size based on the screen width
        // We take the width, minus padding (if you added any in parent),
        // but ensure it doesn't overflow height.
        double boardSize = constraints.maxWidth;

        // 2. Define Cell Size (Exact Grid Math)
        double cellSize = boardSize / 15.0;

        // 3. Define Token Size (Slightly smaller than cell to look nice)
        double tokenSize = cellSize * 0.7; // 70% of the square

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              // A. THE VISUAL BOARD (Code Generated, No Image)
              Positioned.fill(
                child: CustomPaint(
                  painter: LudoBoardPainter(), // Uses the responsive code we just wrote
                ),
              ),

              // B. THE TOKENS (Mapped to the exact same grid)
              ..._buildTokens(context, gameModel.tokens, cellSize, tokenSize),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTokens(BuildContext context, Map<String, List<int>> allTokens, double cellSize, double tokenSize) {
    List<Widget> widgets = [];

    // Calculate offset to center the token in the cell
    double centeringOffset = (cellSize - tokenSize) / 2;

    allTokens.forEach((color, positions) {
      for (int i = 0; i < positions.length; i++) {
        int pathIndex = positions[i];
        Point? gridPoint;

        // --- POSITION LOGIC ---
        if (pathIndex == 0) {
          // Home Base Logic (0, 1, 2, 3 specific spots)
          // Note: In LudoBoardPainter, we drew circles at offsets like (col + 1.5).
          // We must match that logic here.
          gridPoint = PathConstants.homeBases[color]![i];

          // SPECIAL ADJUSTMENT FOR HOME:
          // The painter drew circles centered at e.g., (2.5, 2.5).
          // The gridPoint is (2, 2).
          // So we need to position the token at (2 * cell) + (0.5 * cell) - (token/2)
          // Or simply: (2 * cell) + cell/2 - token/2

          double left = (gridPoint.col * cellSize) + (cellSize / 2) + (cellSize * 0.0) - (tokenSize / 2);
          double top = (gridPoint.row * cellSize) + (cellSize / 2) + (cellSize * 0.0) - (tokenSize / 2);

          // Wait, logic check: homeBases in PathConstants are (2,2), (2,3)...
          // In Painter: Offset((col + 1.5) * cellSize...
          // If Red is col=0, row=0. Circles are at 1.5, 1.5
          // My PathConstants say Red Base points are (2,2).
          // 0 + 1.5 = 1.5. Grid Point 2 is... 2.0.
          // Ah, we need to sync perfectly.
          // Let's use the exact center of the grid cell provided by PathConstants.

          left = (gridPoint.col * cellSize) + centeringOffset;
          top = (gridPoint.row * cellSize) + centeringOffset;

          // Wait! PathConstants.homeBases: Red=[(2,2)...].
          // Painter Red Base is at 0,0 (6x6).
          // Inside Red Base, circles are at roughly grid cells (2,2), (2,3), (3,2), (3,3).
          // Yes! So using standard grid centering is correct.

        } else {
          // Standard Path Logic
          gridPoint = PathConstants.stepToGrid[pathIndex];
        }

        if (gridPoint != null) {
          double left = (gridPoint.col * cellSize) + centeringOffset;
          double top = (gridPoint.row * cellSize) + centeringOffset;

          widgets.add(
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onTap: () {
                  context.read<GameBloc>().add(
                    MoveToken(
                      gameId: gameModel.gameId,
                      userId: currentUserId,
                      tokenIndex: i,
                    ),
                  );
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
}

