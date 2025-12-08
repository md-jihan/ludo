import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AudioService {
  // 1. GLOBAL SETTING
  static bool isSoundOn = true;

  // Two players: One for SFX, one for Dice (to prevent cutting each other off)
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _dicePlayer = AudioPlayer();

  // File Paths
  static const String _rollFile = 'audio/dice_roll.mp3';
  static const String _moveFile = 'audio/piece_move.mp3';
  static const String _killFile = 'audio/kill.mp3';
  static const String _winFile = 'audio/win.mp3';

  // --- TOGGLE METHOD ---
  static void toggleSound() {
    isSoundOn = !isSoundOn;
    debugPrint("🔊 Sound Toggled: $isSoundOn"); // Check your console for this!

    if (!isSoundOn) {
      // If turning off, stop all currently playing sounds immediately
      _sfxPlayer.stop();
      _dicePlayer.stop();
    }
  }

  // --- INTERNAL: GENERIC SFX ---
  static Future<void> _playSfx(String file) async {
    // A. Check if Sound is allowed
    if (!isSoundOn) return;

    try {
      // B. Low Latency Logic (Don't stop previous unless it's Win)
      if (file == _winFile) {
        await _sfxPlayer.stop();
      }

      Source source = kIsWeb ? UrlSource('./assets/$file') : AssetSource(file);

      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(source);
    } catch (e) {
      debugPrint("🔴 SFX Error: $e");
    }
  }

  // --- INTERNAL: DICE SOUND ---
  static Future<void> playRoll() async {
    // A. Check if Sound is allowed
    if (!isSoundOn) return;

    try {
      // B. Stop previous roll to prevent echo
      await _dicePlayer.stop();

      Source source = kIsWeb ? UrlSource('./assets/$_rollFile') : AssetSource(_rollFile);

      await _dicePlayer.setVolume(1.0);
      await _dicePlayer.play(source);
    } catch (e) {
      debugPrint("🔴 Dice Audio Error: $e");
    }
  }

  // --- PUBLIC METHODS ---
  static Future<void> playMove() async => await _playSfx(_moveFile);
  static Future<void> playKill() async => await _playSfx(_killFile);
  static Future<void> playWin() async => await _playSfx(_winFile);
}