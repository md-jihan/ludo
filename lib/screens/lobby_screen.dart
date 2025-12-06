import 'package:flutter/material.dart';
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
    // Start listening to the specific game ID
    context.read<GameBloc>().add(LoadGame(widget.gameId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          // If status changes to 'playing', navigate to board [cite: 14]
          if (state.gameModel.status == 'playing') {
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
        }
      },
      builder: (context, state) {
        if (state is GameLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (state is GameLoaded) {
          final game = state.gameModel;
          return Scaffold(
            appBar: AppBar(title: Text("Lobby: ${widget.gameId}")),
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Waiting for players...", style: TextStyle(fontSize: 18)),
                ),
                // List of Joined Players
                Expanded(
                  child: ListView.builder(
                    itemCount: game.players.length,
                    itemBuilder: (context, index) {
                      final p = game.players[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: _getColor(p['color'])),
                        title: Text("Player ${index + 1} (${p['color']})"),
                        subtitle: Text(p['id'] == widget.userId ? "(You)" : ""),
                      );
                    },
                  ),
                ),
                // Start Button (Only for Host/Player 1)
                // Inside LobbyScreen build method...

// Start Button (Only for Host/Player 1)
                // Inside the build method...

// Start Button (Only for Host/Player 1)
                if (game.players.isNotEmpty && game.players[0]['id'] == widget.userId)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey[400], // Visual feedback for disabled
                      ),
                      // Logic: If players < 2, Button is Disabled (null). If >= 2, Enabled.
                      onPressed: game.players.length < 2
                          ? null
                          : () {
                        context.read<GameBloc>().add(StartGame(widget.gameId));
                      },
                      child: Text(
                        game.players.length < 2 ? "WAITING FOR PLAYERS..." : "START GAME",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: Text("Error loading lobby")));
      },
    );
  }

  Color _getColor(String color) {
    switch(color) {
      case 'Red': return Colors.red;
      case 'Green': return Colors.green;
      case 'Yellow': return Colors.amber;
      case 'Blue': return Colors.blue;
      default: return Colors.grey;
    }
  }
}