import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Check this path carefully:
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_state.dart';
import '../widgets/board_layout.dart';
import '../widgets/dice_widget.dart';
class GameBoard extends StatelessWidget {
  final String gameId;
  final String userId;

  const GameBoard({super.key, required this.gameId, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Note: GameBloc is already initialized in Lobby, but we keep listening
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ludo"),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      backgroundColor: Colors.white, // Or a wood texture
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state is GameLoaded) {
            final game = state.gameModel;
// 1. Get current player data
            final currentPlayer = game.players[game.currentTurn];
            final String turnColor = currentPlayer['color'];
            final String turnName = currentPlayer['name'] ?? turnColor; // Fallback to Color if name missing

            return Column(
              children: [
                // Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  color: Colors.white,
                  width: double.infinity,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 22, color: Colors.black),
                        children: [
                          const TextSpan(text: "Waiting for "),
                          TextSpan(
                            text: "$turnName's", // <--- SHOWS NAME HERE
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getColor(turnColor), // Name is colored by their team color
                              fontSize: 24,
                            ),
                          ),
                          const TextSpan(text: " move"),
                        ],
                      ),
                    ),
                  ),
                ),
                // 2. Board
                Expanded(
                  child: Center(
                    child: BoardLayout(
                        gameModel: game,
                        currentUserId: userId
                    ),
                  ),
                ),
                // 3. Controls Area
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(20),
                  color: Colors.grey[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Player Info
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("You are:"),
                          Chip(label: Text(_getMyColor(game, userId))),
                        ],
                      ),

                      // The Dice
                      DiceWidget(myPlayerId: userId), // [cite: 129]
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  String _getMyColor(game, userId) {
    final me = game.players.firstWhere((p) => p['id'] == userId, orElse: () => {'color': 'Spectator'});
    return me['color'];
  }

  Color _getColor(String colorName) {
    if (colorName == 'Red') return Colors.red;
    if (colorName == 'Green') return Colors.green;
    if (colorName == 'Yellow') return Colors.amber;
    if (colorName == 'Blue') return Colors.blue;
    return Colors.black;
  }
}