import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // --- FIX: DO NOT start with 'assets/' ---
  // The player automatically adds 'assets/', so we just list the folder inside it.
  static const String rollSound = 'audio/dice_roll.mp3';
  static const String moveSound = 'audio/piece_move.mp3';
  static const String killSound = 'audio/kill.mp3';
  static const String winSound = 'audio/win.mp3';

  Future<void> _playSound(String path) async {
    try {
      debugPrint("🔊 AudioService: Playing $path");
      await _player.stop(); // Stop previous sound
      await _player.play(AssetSource(path));
    } catch (e) {
      debugPrint("🔴 AudioService Error: Could not play $path. Error: $e");
    }
  }

  Future<void> playRoll() async => await _playSound(rollSound);
  Future<void> playMove() async => await _playSound(moveSound);
  Future<void> playKill() async => await _playSound(killSound);
  Future<void> playWin() async => await _playSound(winSound);
}