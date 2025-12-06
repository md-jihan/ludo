import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import 'lobby_screen.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter

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
    // Generate a temporary user ID for this session
    final String userId = const Uuid().v4();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("FLUTTER LUDO",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),

            // CREATE GAME BUTTON
            ElevatedButton(
              onPressed: () async {
                // Call Firebase to create room [cite: 68]
                final gameId = await context.read<FirebaseService>().createGame(userId);
                if (context.mounted) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LobbyScreen(gameId: gameId, userId: userId))
                  );
                }
              },
              child: const Text("Create New Game"),
            ),

            const SizedBox(height: 20),

            // JOIN GAME BUTTON
            ElevatedButton(
              onPressed: () {
                _showJoinDialog(context, userId);
              },
              child: const Text("Join Game"),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, String userId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Game ID"),
        content: TextField(
          controller: controller,

          // 1. Force Keyboard to show Uppercase
          textCapitalization: TextCapitalization.characters,

          // 2. Force Input Logic to convert to Uppercase
          inputFormatters: [
            UpperCaseTextFormatter(),
            FilteringTextInputFormatter.allow(RegExp("[A-Z0-9]")), // Optional: Only allow Letters/Numbers
          ],

          decoration: const InputDecoration(
            hintText: "e.g. 831E7F",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String gameId = controller.text.trim(); // It's already uppercase now

              if (gameId.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid Game ID"))
                );
                return;
              }

              try {
                await context.read<FirebaseService>().joinGame(gameId, userId);

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LobbyScreen(gameId: gameId, userId: userId)
                      )
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error joining: $e"))
                );
              }
            },
            child: const Text("JOIN"),
          )
        ],
      ),
    );
  }
}