import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import 'lobby_screen.dart';

// Helper for Uppercase Game ID
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = const Uuid().v4();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("FLUTTER LUDO", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),

            // CREATE GAME BUTTON
            ElevatedButton(
              onPressed: () {
                _showCreateGameDialog(context, userId); // <--- New Dialog
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              child: const Text("Create New Game", style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // JOIN GAME BUTTON
            ElevatedButton(
              onPressed: () {
                _showJoinGameDialog(context, userId); // <--- Updated Dialog
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              child: const Text("Join Game", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Dialog for CREATING a game ---
  void _showCreateGameDialog(BuildContext context, String userId) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Game"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Enter Your Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String name = nameController.text.trim();
              if (name.isEmpty) name = "Player 1"; // Default

              try {
                // Call Create with Name
                final gameId = await context.read<FirebaseService>().createGame(userId, name);

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LobbyScreen(gameId: gameId, userId: userId)
                  ));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("CREATE"),
          )
        ],
      ),
    );
  }

  // --- 2. Dialog for JOINING a game ---
  void _showJoinGameDialog(BuildContext context, String userId) {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Game"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Game ID Input
            TextField(
              controller: idController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: const InputDecoration(
                labelText: "Game ID (e.g. 8A3B12)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            // Player Name Input
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Your Name",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String gameId = idController.text.trim();
              String name = nameController.text.trim();

              if (gameId.length < 6) return;
              if (name.isEmpty) name = "Player 2"; // Default

              try {
                // Call Join with Name
                await context.read<FirebaseService>().joinGame(gameId, userId, name);

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LobbyScreen(gameId: gameId, userId: userId)
                  ));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("JOIN"),
          )
        ],
      ),
    );
  }
}