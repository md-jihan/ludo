import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/dice_widget.dart';
import '../blocs/computer/computer_game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../widgets/computer_board_layout.dart';
import '../services/audio_service.dart';

class ComputerGameBoard extends StatelessWidget {
  final String userColor;

  const ComputerGameBoard({super.key, required this.userColor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ComputerGameBloc()..add(StartComputerGame(userColor)),
      child: Scaffold(
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
  bool _isSettingsOpen = false;

  // --- FIX 1: SYNC LOGIC CORRECTLY ---
  // If 'isMuted' is FALSE, then Sound is ON (true).
  bool _isSoundOn = AudioService.isSoundOn;

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
    });
  }

  void _toggleSound(bool value) {
    setState(() {
      _isSoundOn = value;
      // --- FIX 2: UPDATE SERVICE ---
      // If Switch is ON (true), Muted is OFF (false).
      AudioService.isSoundOn = value;
    });
  }

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

          if (game.players.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentPlayer = game.players[game.currentTurn];
          final String turnName = currentPlayer['name'];
          final String turnColor = currentPlayer['color'];
          final bool isHumanTurn = currentPlayer['isAuto'] == false;

          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // A. TOP APP BAR
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
                          GestureDetector(
                            onTap: _toggleSettings,
                            child: const Icon(Icons.settings, color: Color(0xFF8D6E63), size: 28),
                          ),
                        ],
                      ),
                    ),

                    // B. STATUS
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

                    // C. BOARD
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                                ],
                              ),
                              child: ComputerBoardLayout(
                                gameModel: game,
                                currentUserId: "User",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

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
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DiceWidget(
                              value: game.diceValue,
                              isMyTurn: isHumanTurn && game.status != 'finished',
                              onRoll: () {
                                context.read<ComputerGameBloc>().add(const RollDice("OFFLINE"));
                              },
                            ),
                          ),
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

                // SLIDING SETTINGS
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: _isSettingsOpen ? 70 : -150,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7CCC8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF5D4037), width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.volume_up, color: Color(0xFF3E2723), size: 30),
                            SizedBox(width: 15),
                            Text(
                              "Sound",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isSoundOn, // Linked to the correct logic
                          // COLORS
                          activeColor: const Color(0xFF2E7D32),       // Green (ON)
                          activeTrackColor: const Color(0xFFA5D6A7),
                          inactiveThumbColor: const Color(0xFF5D4037), // Brown (OFF)
                          inactiveTrackColor: const Color(0xFFBCAAA4),
                          onChanged: _toggleSound,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isSettingsOpen)
                  Positioned.fill(
                    top: 150,
                    child: GestureDetector(
                      onTap: _toggleSettings,
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
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