import 'package:flutter/material.dart';
import '../services/audio_service.dart'; // Import to control sound globally

class GameSettingsPanel extends StatefulWidget {
  final bool isOpen;
  final double topOpen;
  final double topClosed;

  const GameSettingsPanel({
    super.key,
    required this.isOpen,
    this.topOpen = 80,     // Default position when open
    this.topClosed = -150, // Default position when hidden
  });

  @override
  State<GameSettingsPanel> createState() => _GameSettingsPanelState();
}

class _GameSettingsPanelState extends State<GameSettingsPanel> {
  // 1. Initialize State from Global Service
  bool _isSoundOn = AudioService.isSoundOn;

  // 2. Internal Toggle Method
  void _toggleSound(bool value) {
    setState(() {
      _isSoundOn = value;
      // Update Global Service
      AudioService.isSoundOn = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: widget.isOpen ? widget.topOpen : widget.topClosed,
      left: 20,
      right: 20,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD7CCC8), // Wood theme
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF5D4037), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                    _isSoundOn ? Icons.volume_up : Icons.volume_off,
                    color: const Color(0xFF3E2723),
                    size: 30
                ),
                const SizedBox(width: 15),
                const Text(
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
              value: _isSoundOn,
              // ON COLORS (Green)
              activeThumbColor: const Color(0xFF2E7D32),
              activeTrackColor: const Color(0xFFA5D6A7),
              // OFF COLORS (Brown)
              inactiveThumbColor: const Color(0xFF5D4037),
              inactiveTrackColor: const Color(0xFFBCAAA4),

              // 3. Use Internal Method
              onChanged: _toggleSound,
            ),
          ],
        ),
      ),
    );
  }
}