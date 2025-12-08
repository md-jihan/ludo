import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/dice_widget.dart';
import '../blocs/computer/computer_game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../widgets/computer_board_layout.dart';

class ComputerGameBoard extends StatelessWidget {
  final String userColor; // e.g. "Blue"

  const ComputerGameBoard({super.key, required this.userColor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Initialize Bloc and Start Game immediately
      create: (context) => ComputerGameBloc()..add(StartComputerGame(userColor)),
      child: Scaffold(
        body: Container(
          // 1. GLOBAL WOOD BACKGROUND
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wood.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const ComputerView(),
        ),
      ),
    );
  }
}

class ComputerView extends StatefulWidget {
  const ComputerView({super.key});

  @override
  State<ComputerView> createState() => _ComputerViewState();
}

class _ComputerViewState extends State<ComputerView> {

  // --- WIN/LOSS DIALOG ---
  void _showGameEndDialog(BuildContext context, bool userWon) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5D4037), width: 4),
        ),
        title: Center(
          child: Text(
            userWon ? "🏆 YOU WON! 🏆" : "💀 YOU LOST 💀",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: userWon ? Colors.green[800] : Colors.red[900],
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              userWon ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
              size: 80,
              color: userWon ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              userWon
                  ? "Congratulations! You beat the computer!"
                  : "Better luck next time!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E2723),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("EXIT GAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ComputerGameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          if (state.gameModel.status == 'finished') {
            final game = state.gameModel;
            final humanPlayer = game.players.firstWhere((p) => p['id'] == 'User', orElse: () => {});
            if (humanPlayer.isEmpty) return;

            final String humanColor = humanPlayer['color'];
            final bool userWon = game.winners.contains(humanColor);
            _showGameEndDialog(context, userWon);
          }
        }
      },
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // Safety Check: Ensure players exist
          if (game.players.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentPlayer = game.players[game.currentTurn];
          final String turnName = currentPlayer['name'];
          final String turnColor = currentPlayer['color'];
          // Check if "isAuto" is false (meaning Human)
          final bool isHumanTurn = currentPlayer['isAuto'] == false;

          return SafeArea(
            child: Column(
              children: [
                // --- A. TOP APP BAR ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: _woodenBoxDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF3E2723), size: 28),
                          ),
                          const SizedBox(width: 15),
                          const Text(
                            "Vs Computer",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                          ),
                        ],
                      ),
                      const Icon(Icons.settings, color: Color(0xFF8D6E63), size: 28),
                    ],
                  ),
                ),

                // --- B. STATUS PLANK (Turn Message) ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(10),
                  decoration: _woodenBoxDecoration(),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 18, color: Color(0xFF3E2723), fontFamily: 'Courier', fontWeight: FontWeight.bold),
                        children: [
                          const TextSpan(text: "Turn: "),
                          TextSpan(
                            text: "$turnName ($turnColor)",
                            style: TextStyle(
                              color: _getColor(turnColor),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- C. THE BOARD (Use Expanded to fix layout issues) ---
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AspectRatio(
                        aspectRatio: 1.0, // Force square shape
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                            ],
                          ),
                          child: ComputerBoardLayout(
                            gameModel: game,
                            currentUserId: "User", // Matches Bloc ID
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- D. BOTTOM CONTROLS ---
                Container(
                  height: 140,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723).withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    border: const Border(top: BorderSide(color: Color(0xFF8D6E63), width: 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Player Info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: _woodenBoxDecoration(),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: Color(0xFF3E2723)),
                            Text("You", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                          ],
                        ),
                      ),

                      // DICE
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // UNIVERSAL DICE WIDGET
                        child: DiceWidget(
                          value: game.diceValue,
                          isMyTurn: isHumanTurn && game.status != 'finished',
                          onRoll: () {
                            context.read<ComputerGameBloc>().add(const RollDice("OFFLINE"));
                          },
                        ),
                      ),

                      // Computer Info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: _woodenBoxDecoration(),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.computer, color: Color(0xFF3E2723)),
                            Text("Bot", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // --- HELPERS ---
  BoxDecoration _woodenBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFD7CCC8),
      image: const DecorationImage(
        image: AssetImage('assets/wood.png'),
        fit: BoxFit.cover,
        opacity: 0.5,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF5D4037), width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 4)
      ],
    );
  }

  Color _getColor(String color) {
    switch (color) {
      case 'Red': return const Color(0xFFC62828);
      case 'Green': return const Color(0xFF2E7D32);
      case 'Yellow': return const Color(0xFFF9A825);
      case 'Blue': return const Color(0xFF1565C0);
      default: return Colors.black;
    }
  }
}