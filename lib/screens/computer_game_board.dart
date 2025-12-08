import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/dice_widget.dart';
import '../blocs/computer/computer_game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../widgets/computer_board_layout.dart';

class ComputerGameBoard extends StatelessWidget {
  final String userColor;

  const ComputerGameBoard({super.key, required this.userColor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ComputerGameBloc()..add(StartComputerGame(userColor)),
      child: Scaffold(
        // 1. GLOBAL WOOD BACKGROUND
        body: Container(
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
      barrierDismissible: false, // Must click button
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8), // Wood Color
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
                backgroundColor: const Color(0xFF3E2723), // Dark Wood
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.pop(ctx); // Close Dialog
                Navigator.pop(context); // Go back to Landing Screen
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
      // 1. LISTEN FOR GAME OVER
      listener: (context, state) {
        if (state is GameLoaded) {
          if (state.gameModel.status == 'finished') {
            // Determine who won
            final game = state.gameModel;
            final humanPlayer = game.players.firstWhere((p) => p['type'] == 'human');
            final String humanColor = humanPlayer['color'];

            // Check if Human's tokens are all 99
            final bool userWon = game.tokens[humanColor]!.every((t) => t == 99);

            _showGameEndDialog(context, userWon);
          }
        }
      },
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;
          final currentPlayer = game.players[game.currentTurn];
          final String turnName = currentPlayer['name'];
          final String turnColor = currentPlayer['color'];
          final bool isHumanTurn = currentPlayer['type'] == 'human';

          return SafeArea(
            child: Column(
              children: [
                // A. APP BAR
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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

                // B. STATUS PLANK
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

                const Spacer(),

                // C. THE BOARD
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                        ],
                      ),
                      child: ComputerBoardLayout(
                        gameModel: game,
                        currentUserId: "HUMAN_PLAYER",
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // D. CONTROLS
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

                        // USE THE UNIVERSAL DICE WIDGET HERE
                        child: DiceWidget(
                          value: game.diceValue, // 1. Pass the value from Computer Bloc
                          isMyTurn: isHumanTurn && game.status != 'finished', // 2. Check turn
                          onRoll: () {
                            // 3. Trigger Computer Event
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

// --- LOCAL DICE WIDGET ---

// --- 2D LOCAL DICE WIDGET ---
class LocalDiceWidget extends StatelessWidget {
  final int value;
  final bool isMyTurn;
  final VoidCallback onRoll;

  const LocalDiceWidget({
    super.key,
    required this.value,
    required this.isMyTurn,
    required this.onRoll
  });

  @override
  Widget build(BuildContext context) {
    // Logic: Enable roll only if it's my turn AND dice is reset (0)
    bool canRoll = isMyTurn && value == 0;

    // Visuals: White if active, Grey if disabled
    Color boxColor = canRoll ? Colors.white : Colors.grey[400]!;
    Color borderColor = canRoll ? Colors.black : Colors.grey[700]!;

    return GestureDetector(
      onTap: canRoll ? onRoll : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(2,2)
            )
          ],
        ),
        child: Center(
          child: value == 0
              ? (canRoll
              ? const Text(
              "ROLL",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          )
              : const Icon(Icons.hourglass_bottom, color: Colors.black54))
              : CustomPaint(
            size: const Size(50, 50),
            painter: _DotPainter(value),
          ),
        ),
      ),
    );
  }
}

// --- PAINTER FOR 2D DOTS ---
class _DotPainter extends CustomPainter {
  final int n;
  _DotPainter(this.n);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.black;
    double r = s.width / 9;   // Dot radius
    double m = s.width / 2;   // Middle
    double l = s.width / 4;   // Left/Top
    double R = s.width * 0.75; // Right/Bottom

    List<Offset> d = [];

    if (n % 2 != 0) d.add(Offset(m, m)); // Center dot for 1, 3, 5
    if (n > 1) d.addAll([Offset(l, l), Offset(R, R)]); // Diagonal
    if (n > 3) d.addAll([Offset(l, R), Offset(R, l)]); // Other diagonal
    if (n == 6) d.addAll([Offset(l, m), Offset(R, m)]); // Middle sides

    for (var o in d) c.drawCircle(o, r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}