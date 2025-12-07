import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // 1. Static Instance (Shared by the whole app)
  static final AudioPlayer _player = AudioPlayer();

  // 2. Sound File Constants (Must match your assets/audio/ folder exactly)
  static const String rollSound = 'audio/dice_roll.mp3';
  static const String moveSound = 'audio/piece_move.mp3';
  static const String killSound = 'audio/kill.mp3';
  static const String winSound = 'audio/win.mp3';

  // 3. Internal Play Method
  static Future<void> _playSound(String path) async {
    try {
      // Stop previous sound to prevent overlap/noise
      if (path != winSound) await _player.stop();

      await _player.play(AssetSource(path));
    } catch (e) {
      debugPrint("🔴 AudioService Error: Could not play $path. Error: $e");
    }
  }

  // 4. Public Methods (Call these from your UI/Bloc)
  static Future<void> playRoll() async => await _playSound(rollSound);
  static Future<void> playMove() async => await _playSound(moveSound);
  static Future<void> playKill() async => await _playSound(killSound);
  static Future<void> playWin() async => await _playSound(winSound);
}