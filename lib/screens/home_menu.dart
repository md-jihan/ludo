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
      body: Container(
        // 1. WOOD BACKGROUND
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wood.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2. APP TITLE (Burnt Wood Look)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: _woodenBoxDecoration(),
                  child: const Text(
                    "LUDO KING",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3E2723), // Dark Brown
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.white54, offset: Offset(1, 1), blurRadius: 0)
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // 3. CREATE GAME BUTTON
                _buildWoodenButton(
                  context,
                  label: "CREATE NEW GAME",
                  icon: Icons.add_circle,
                  color: const Color(0xFF4CAF50), // Green tint
                  onTap: () => _showCreateGameDialog(context, userId),
                ),

                const SizedBox(height: 20),

                // 4. JOIN GAME BUTTON
                _buildWoodenButton(
                  context,
                  label: "JOIN GAME",
                  icon: Icons.login,
                  color: const Color(0xFF2196F3), // Blue tint
                  onTap: () => _showJoinGameDialog(context, userId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: WOODEN BUTTON ---
  Widget _buildWoodenButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9), // Tinted wood
          image: const DecorationImage(
            image: AssetImage('assets/wood.png'),
            fit: BoxFit.cover,
            opacity: 0.2, // Show texture through color
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 5)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: WOODEN DECORATION ---
  BoxDecoration _woodenBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFD7CCC8),
      image: const DecorationImage(
        image: AssetImage('assets/wood.png'),
        fit: BoxFit.cover,
        opacity: 0.5,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF5D4037), width: 3),
      boxShadow: const [
        BoxShadow(color: Colors.black45, offset: Offset(3, 5), blurRadius: 6)
      ],
    );
  }

  // --- DIALOGS (Keep your existing logic, just styling update optional) ---
  void _showCreateGameDialog(BuildContext context, String userId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8), // Wood color bg
        title: const Text("Create Game", style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Enter Your Name", filled: true, fillColor: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String name = nameController.text.trim();
              if (name.isEmpty) name = "Player 1";
              try {
                final gameId = await context.read<FirebaseService>().createGame(userId, name);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyScreen(gameId: gameId, userId: userId)));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("CREATE", style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showJoinGameDialog(BuildContext context, String userId) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        title: const Text("Join Game", style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: const InputDecoration(labelText: "Game ID", filled: true, fillColor: Colors.white54),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Your Name", filled: true, fillColor: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String gameId = idController.text.trim();
              String name = nameController.text.trim();
              if (gameId.length < 6) return;
              if (name.isEmpty) name = "Player 2";
              try {
                await context.read<FirebaseService>().joinGame(gameId, userId, name);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyScreen(gameId: gameId, userId: userId)));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("JOIN", style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}