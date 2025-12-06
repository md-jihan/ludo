import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import 'game_board.dart';

class LobbyScreen extends StatefulWidget {
  final String gameId;
  final String userId;

  const LobbyScreen({super.key, required this.gameId, required this.userId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GameBloc>().add(LoadGame(widget.gameId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded && state.gameModel.status == 'playing') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => GameBoard(gameId: widget.gameId, userId: widget.userId))
          );
        }
      },
      builder: (context, state) {
        if (state is GameLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (state is GameLoaded) {
          final game = state.gameModel;
          return Scaffold(
            // 1. WOOD BACKGROUND
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/wood.png'), fit: BoxFit.cover),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // A. LOBBY HEADER PLANK
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: _woodenBoxDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ROOM ID:", style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                              Text(widget.gameId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3E2723), letterSpacing: 2)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Color(0xFF3E2723), size: 28),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.gameId));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID Copied!")));
                            },
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text("Waiting for players...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                    ),

                    // B. PLAYER LIST (Wooden Slats)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: game.players.length,
                        itemBuilder: (context, index) {
                          final p = game.players[index];
                          bool isMe = p['id'] == widget.userId;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8), // Light wood slat
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF5D4037), width: 1),
                                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 3)]
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColor(p['color']),
                                radius: 20,
                                child: Icon(Icons.person, color: Colors.white.withOpacity(0.8)),
                              ),
                              title: Text(
                                  "${p['name']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3E2723))
                              ),
                              subtitle: Text(
                                  p['color'],
                                  style: TextStyle(color: _getColor(p['color']), fontWeight: FontWeight.bold)
                              ),
                              trailing: isMe
                                  ? const Chip(label: Text("YOU"), backgroundColor: Color(0xFF3E2723), labelStyle: TextStyle(color: Colors.white))
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),

                    // C. START BUTTON
                    if (game.players.isNotEmpty && game.players[0]['id'] == widget.userId)
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: GestureDetector(
                          onTap: game.players.length < 2
                              ? null
                              : () => context.read<GameBloc>().add(StartGame(widget.gameId)),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                                color: game.players.length < 2 ? Colors.grey : const Color(0xFF2E7D32), // Green wood
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white54, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 4)]
                            ),
                            child: Center(
                              child: Text(
                                game.players.length < 2 ? "WAITING FOR PLAYERS..." : "START GAME",
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(30),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                        child: const Text("Waiting for host to start...", style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                      )
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: Text("Error loading lobby")));
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
    if (color == 'Red') return const Color(0xFFC62828);
    if (color == 'Green') return const Color(0xFF2E7D32);
    if (color == 'Yellow') return const Color(0xFFF9A825);
    if (color == 'Blue') return const Color(0xFF1565C0);
    return Colors.grey;
  }
}