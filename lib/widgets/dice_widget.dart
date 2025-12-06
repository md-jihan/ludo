import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';

class DiceWidget extends StatelessWidget {
  final String myPlayerId;

  const DiceWidget({super.key, required this.myPlayerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // 1. Identify whose turn it is
          final currentPlayer = game.players[game.currentTurn];
          final String turnColorName = currentPlayer['color'];
          final Color turnColor = _getColor(turnColorName);

          // 2. Check if it is MY turn
          bool isMyTurn = currentPlayer['id'] == myPlayerId;

          return GestureDetector(
            // Only allow tap if it's my turn AND dice hasn't been rolled yet (value is 0)
            onTap: isMyTurn && game.diceValue == 0
                ? () {
              context.read<GameBloc>().add(RollDice(game.gameId));
            }
                : null,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white, // Keep background white for contrast
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  // 3. Border color matches the player's turn color
                  color: isMyTurn ? turnColor : Colors.grey,
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Center(
                child: game.diceValue == 0
                    ? Icon(Icons.casino, size: 40, color: isMyTurn ? turnColor : Colors.grey)
                    : Text(
                  "${game.diceValue}",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    // 4. Text color matches the player's turn color
                    color: turnColor,
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'Red': return Colors.red[700]!;
      case 'Green': return Colors.green[700]!;
      case 'Yellow': return Colors.amber[700]!;
      case 'Blue': return Colors.blue[700]!;
      default: return Colors.black;
    }
  }
}