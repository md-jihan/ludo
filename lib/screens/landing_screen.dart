import 'package:flutter/material.dart';
import 'home_menu.dart'; // Import your existing Create/Join screen

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. GLOBAL WOOD BACKGROUND
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wood.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2. BIG GAME TITLE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                  margin: const EdgeInsets.only(bottom: 60),
                  decoration: _woodenBoxDecoration(),
                  child: const Text(
                    "LUDO KING",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3E2723), // Dark Brown
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: Colors.white54, offset: Offset(1, 1), blurRadius: 0)
                      ],
                    ),
                  ),
                ),

                // 3. "PLAY WITH COMPUTER" BUTTON
                _buildWoodenButton(
                  context,
                  label: "WITH COMPUTER",
                  icon: Icons.computer,
                  color: const Color(0xFFEF6C00), // Orange Tint
                  onTap: () {
                    // Logic for AI Mode goes here later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Computer Mode Coming Soon!")),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // 4. "PLAY WITH FRIEND" BUTTON (Goes to Online Menu)
                _buildWoodenButton(
                  context,
                  label: "WITH FRIEND",
                  icon: Icons.people,
                  color: const Color(0xFF1565C0), // Blue Tint
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeMenu()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- BUTTON WIDGET ---
  Widget _buildWoodenButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 80, // Bigger buttons for main menu
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          image: const DecorationImage(
            image: AssetImage('assets/wood.jpg'),
            fit: BoxFit.cover,
            opacity: 0.2, // Texture overlay
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black54, offset: Offset(4, 6), blurRadius: 8)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DECORATION HELPER ---
  BoxDecoration _woodenBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFD7CCC8),
      image: const DecorationImage(
        image: AssetImage('assets/wood.jpg'),
        fit: BoxFit.cover,
        opacity: 0.5,
      ),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFF5D4037), width: 4),
      boxShadow: const [
        BoxShadow(color: Colors.black54, offset: Offset(4, 6), blurRadius: 6)
      ],
    );
  }
}