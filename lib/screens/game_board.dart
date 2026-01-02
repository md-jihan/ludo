import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/game_settings_panel.dart';

import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../models/game_model.dart';
import '../widgets/board_layout.dart';
import '../widgets/dice_widget.dart';
import '../services/audio_service.dart'; // IMPORT THIS

class GameBoard extends StatefulWidget {
  final String gameId;
  final String userId;

  const GameBoard({super.key, required this.gameId, required this.userId});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final Set<String> _notifiedLeftPlayers = {};
  final Set<String> _notifiedWinners = {};
  bool _celebrationShown = false;

  // --- NEW: SETTINGS STATE ---
  bool _isSettingsOpen = false;
  bool _isSoundOn = AudioService.isSoundOn;

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
    });
  }

  void _toggleSound(bool value) {
    setState(() {
      _isSoundOn = value;
      AudioService.isSoundOn = value; // Update Global Service
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;
          final players = game.players;

          // A. Player Left SnackBar
          for (var p in players) {
            bool hasLeft = p['hasLeft'] ?? false;
            String pid = p['id'];
            if (hasLeft && !_notifiedLeftPlayers.contains(pid)) {
              _notifiedLeftPlayers.add(pid);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p['name']} left!"), backgroundColor: Colors.orange));
            }
          }

          // B. MINI DIALOG
          for (String winnerId in game.winners) {
            if (!_notifiedWinners.contains(winnerId)) {
              _notifiedWinners.add(winnerId);
              if (winnerId != widget.userId) {
                final winner = players.firstWhere((p) => p['id'] == winnerId, orElse: () => {'name': 'Unknown'});
                _showMiniWinNotification(winner['name']);
              }
            }
          }

          // C. MY WIN/LOSS DIALOG
          if (!_celebrationShown) {
            if (game.winners.contains(widget.userId)) {
              _celebrationShown = true;
              int rank = game.winners.indexOf(widget.userId) + 1;
              _showCelebrationDialog(rank, false, players.length);
            }
            else if (game.status == 'finished') {
              _celebrationShown = true;
              _showCelebrationDialog(0, true, players.length);
            }
          }

          // D. Game Over
          int activePlayers = players.where((p) => p['hasLeft'] != true).length;
          if (players.length > 1 && activePlayers < 2 && game.status != 'finished') {
            _showGameOverDialog();
          }
        }
      },
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;
          final currentPlayer = game.players[game.currentTurn];
          final String turnColor = currentPlayer['color'];
          final String turnName = currentPlayer['name'] ?? turnColor;

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/wood.png'),
                  fit: BoxFit.cover,
                  opacity: 1,
                ),
              ),
              child: SafeArea(
                // --- CHANGE 1: WRAP IN STACK ---
                child: Stack(
                  children: [
                    // --- LAYER 1: GAME UI ---
                    Column(
                      children: [
                        // App Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          decoration: _woodenBoxDecoration(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Ludo", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),

                              // Right Side Buttons
                              Row(
                                children: [
                                  // SETTINGS ICON
                                  GestureDetector(
                                    onTap: _toggleSettings,
                                    child: const Icon(Icons.settings, color: Color(0xFF8D6E63), size: 30),
                                  ),
                                  const SizedBox(width: 15),
                                  // EXIT ICON
                                  IconButton(
                                    icon: const Icon(Icons.exit_to_app, color: Color(0xFF8D6E63), size: 30),
                                    onPressed: () => _showLeaveConfirmDialog(game),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        // Status
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.all(10),
                          decoration: _woodenBoxDecoration(),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 18, color: Color(0xFF3E2723), fontFamily: 'Courier', fontWeight: FontWeight.bold),
                                children: [
                                  const TextSpan(text: "Waiting for "),
                                  TextSpan(
                                    text: "$turnName's",
                                    style: TextStyle(color: _getColor(turnColor), fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                  const TextSpan(text: " move"),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Board
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.15), blurRadius: 15, spreadRadius: 2)],
                              ),
                              child: BoardLayout(gameModel: game, currentUserId: widget.userId),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Controls
                        Container(
                          height: 140,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: const Color(0xFF3E2723).withValues(alpha:0.8),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                              border: const Border(top: BorderSide(color: Color(0xFF8D6E63), width: 4))
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: _woodenBoxDecoration(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("You are:", style: TextStyle(color: Color(0xFF3E2723), fontSize: 12)),
                                    Text(_getMyColor(game, widget.userId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3E2723))),
                                  ],
                                ),
                              ),

                              // DICE
                              Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(20)
                                  ),
                                  child: DiceWidget(
                                    value: game.diceValue,
                                    isMyTurn: game.players[game.currentTurn]['id'] == widget.userId,
                                    onRoll: () {
                                      context.read<GameBloc>().add(RollDice(game.gameId));
                                    },
                                  )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // --- LAYER 2: SLIDING SETTINGS PANEL ---
                    GameSettingsPanel(
                      isOpen: _isSettingsOpen,
                      isSoundOn: _isSoundOn,
                      onToggleSound: _toggleSound,
                    ),
                    // --- LAYER 3: CLICK OUTSIDE TO CLOSE ---
                    if (_isSettingsOpen)
                      Positioned.fill(
                        top: 160, // Start below the panel
                        child: GestureDetector(
                          onTap: _toggleSettings,
                          behavior: HitTestBehavior.translucent,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  // --- HELPERS ---
  BoxDecoration _woodenBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFD7CCC8),
      image: const DecorationImage(image: AssetImage('assets/wood.png'), fit: BoxFit.cover, opacity: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF5D4037), width: 2),
      boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 4)],
    );
  }

  String _getMyColor(GameModel game, String userId) {
    final me = game.players.firstWhere((p) => p['id'] == userId, orElse: () => {'color': 'Spectator'});
    return me['color'];
  }

  Color _getColor(String colorName) {
    if (colorName == 'Red') return const Color(0xFFC62828);
    if (colorName == 'Green') return const Color(0xFF2E7D32);
    if (colorName == 'Yellow') return const Color(0xFFF9A825);
    if (colorName == 'Blue') return const Color(0xFF1565C0);
    return Colors.black;
  }

  // --- DIALOGS (Keep your existing ones) ---
  void _showMiniWinNotification(String winnerName) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });

        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 80),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)]
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.black),
                  const SizedBox(width: 10),
                  Text("$winnerName Won!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCelebrationDialog(int rank, bool isLoser, int totalPlayers) {
    String title = isLoser ? "😢 YOU LOST 😢" : "🏆 WINNER 🏆";
    String message = isLoser ? "Better luck next time!" : "You finished rank #$rank!";
    Color color = isLoser ? Colors.red : Colors.amber;
    bool canStay = (totalPlayers > 2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF5D4037), width: 3)),
        title: Center(child: Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLoser ? Icons.sentiment_very_dissatisfied : Icons.emoji_events, size: 70, color: color),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
            if (canStay && !isLoser)
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text("(Others are still playing. You can watch!)", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              )
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  context.read<GameBloc>().add(LeaveGameEvent(widget.gameId, widget.userId));
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("EXIT GAME", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              if (canStay)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E2723)),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("WATCH", style: TextStyle(color: Colors.white)),
                ),
            ],
          )
        ],
      ),
    );
  }

  void _showLeaveConfirmDialog(GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        title: const Text("Leave Game?"),
        content: const Text("You will be removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<GameBloc>().add(LeaveGameEvent(widget.gameId, widget.userId));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("Everyone else has left!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}