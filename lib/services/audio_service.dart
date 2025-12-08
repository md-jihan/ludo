import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // 1. Define filenames WITHOUT 'assets/'
  static const String _rollFile = 'audio/dice_roll.mp3';
  static const String _moveFile = 'audio/piece_move.mp3';
  static const String _killFile = 'audio/kill.mp3';
  static const String _winFile = 'audio/win.mp3';

  static Future<void> _playSound(String file) async {
    try {
      if (file != _winFile) await _player.stop();

      // 2. WEB SPECIFIC FIX
      if (kIsWeb) {
        // On Web, we force the full relative URL.
        // Try './assets/' to force it to look relative to index.html
        await _player.play(UrlSource('./assets/$file'));
      } else {
        // On Mobile, AssetSource automatically adds 'assets/' prefix
        await _player.play(AssetSource(file));
      }
    } catch (e) {
      debugPrint("🔴 Audio Error: $e");
    }
  }

  static Future<void> playRoll() async => await _playSound(_rollFile);
  static Future<void> playMove() async => await _playSound(_moveFile);
  static Future<void> playKill() async => await _playSound(_killFile);
  static Future<void> playWin() async => await _playSound(_winFile);
}