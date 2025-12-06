import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- REQUIRED for Clipboard
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
              MaterialPageRoute(
                  builder: (_) => GameBoard(
                      gameId: widget.gameId,
                      userId: widget.userId
                  )
              )
          );
        }
      },
      builder: (context, state) {
        if (state is GameLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (state is GameLoaded) {
          final game = state.gameModel;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Text("Lobby: ${widget.gameId}"),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: "Copy Game ID",
                    onPressed: () {
                      // --- COPY LOGIC ---
                      Clipboard.setData(ClipboardData(text: widget.gameId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Game ID copied to clipboard!")),
                      );
                    },
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                // ... (Rest of your Lobby UI code remains the same) ...
                Expanded(
                  child: ListView.builder(
                    itemCount: game.players.length,
                    itemBuilder: (context, index) {
                      final p = game.players[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: _getColor(p['color'])),
                        title: Text("${p['name']} (${p['color']})"),
                        subtitle: Text(p['id'] == widget.userId ? "(You)" : ""),
                      );
                    },
                  ),
                ),
                // ... (Start Button Code) ...
                if (game.players.isNotEmpty && game.players[0]['id'] == widget.userId)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: game.players.length < 2
                          ? null
                          : () => context.read<GameBloc>().add(StartGame(widget.gameId)),
                      child: Text(game.players.length < 2 ? "WAITING..." : "START GAME"),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Waiting for host..."),
                  )
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: Text("Error loading lobby")));
      },
    );
  }

  Color _getColor(String color) {
    if (color == 'Red') return Colors.red;
    if (color == 'Green') return Colors.green;
    if (color == 'Yellow') return Colors.amber;
    if (color == 'Blue') return Colors.blue;
    return Colors.grey;
  }
}