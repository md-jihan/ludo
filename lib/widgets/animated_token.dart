import 'dart:async';
import 'package:flutter/material.dart';
import '../logic/path_constants.dart';
import '../services/audio_service.dart';
import 'token_pawn.dart';

class AnimatedToken extends StatefulWidget {
  final String colorName;
  final int tokenIndex;
  final int currentPosition;
  final bool isDimmed;
  final double cellSize;
  final double tokenSize;
  final VoidCallback onTap;

  const AnimatedToken({
    super.key,
    required this.colorName,
    required this.tokenIndex,
    required this.currentPosition,
    required this.isDimmed,
    required this.cellSize,
    required this.tokenSize,
    required this.onTap,
  });

  @override
  State<AnimatedToken> createState() => _AnimatedTokenState();
}

class _AnimatedTokenState extends State<AnimatedToken> with SingleTickerProviderStateMixin {
  late int _visualPosition;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;

  double _left = 0;
  double _top = 0;

  @override
  void initState() {
    super.initState();
    _visualPosition = widget.currentPosition;
    _updateCoordinates(_visualPosition);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(AnimatedToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != oldWidget.currentPosition) {
      _animateToNewPosition(oldWidget.currentPosition, widget.currentPosition);
    } else if (widget.cellSize != oldWidget.cellSize) {
      _updateCoordinates(_visualPosition);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  // --- SHORTCUT DEFINITIONS (Gate -> Home Start) ---
  final Map<int, int> _shortcuts = {
    51: 53, // Red: 51 -> 53
    12: 58, // Green: 12 -> 58
    25: 63, // Yellow: 25 -> 63
    38: 68, // Blue: 38 -> 68
  };

  Future<void> _animateToNewPosition(int start, int end) async {
    // 1. TELEPORT CASES (Spawn, Kill, Win)
    if (start == 0 || end == 0 || end == 99) {
      if (mounted) {
        setState(() {
          _visualPosition = end;
          _updateCoordinates(end);
        });
        if (end == 0) AudioService.playKill();
        else if (end == 99) AudioService.playWin();
        else AudioService.playMove();
        _bounceController.forward(from: 0);
      }
      return;
    }

    // 2. BUILD PATH
    List<int> path = [];
    int current = start;

    // Detect if we are taking a Shortcut (Entering Home)
    // If start is 51 and end is 53, path is just [53].
    // If start is 51 and end is 55, path is [53, 54, 55].
    if (_shortcuts.containsKey(start) && end >= _shortcuts[start]!) {
      current = _shortcuts[start]!; // Jump the gap
      path.add(current);
      // If the dice roll was > 1, continue counting from the home start
    }

    // Continue building path normally
    while (current != end) {
      current++;

      // WRAP AROUND (52 -> 1)
      // Only wrap if we are NOT in the home stretch (>52)
      if (current > 52 && end < 52) {
        current = 1;
      }

      // Special case: If we just walked into a shortcut gate (e.g. arrived at 51)
      // and our destination is inside home (e.g. 54), jump to 53 next.
      if (_shortcuts.containsKey(current - 1) && end >= _shortcuts[current - 1]!) {
        current = _shortcuts[current - 1]!;
      }

      path.add(current);
      if (path.length > 10) break; // Safety
    }

    // 3. ANIMATE
    for (int stepPos in path) {
      if (!mounted) return;
      setState(() {
        _visualPosition = stepPos;
        _updateCoordinates(stepPos);
      });
      _bounceController.forward(from: 0);
      AudioService.playMove();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _updateCoordinates(int pos) {
    double centeringOffset = (widget.cellSize - widget.tokenSize) / 2;
    double l = 0;
    double t = 0;

    if (pos == 99) {
      // WINNER CENTER
      double centerGrid = 7.0 * widget.cellSize;
      // Slight offsets to separate multiple winners
      switch (widget.colorName) {
        case 'Red': l = centerGrid - (widget.cellSize * 0.4); t = centerGrid; break;
        case 'Green': l = centerGrid; t = centerGrid - (widget.cellSize * 0.4); break;
        case 'Yellow': l = centerGrid + (widget.cellSize * 0.4); t = centerGrid; break;
        case 'Blue': l = centerGrid; t = centerGrid + (widget.cellSize * 0.4); break;
      }
      // Add small jitter for multiple tokens of same color
      double jitter = widget.tokenIndex * 5.0;
      l += jitter;

      l += centeringOffset; t += centeringOffset;
    }
    else if (pos == 0) {
      // BASE
      var point = PathConstants.homeBases[widget.colorName]?[widget.tokenIndex];
      if (point != null) {
        l = (point.col * widget.cellSize) + centeringOffset;
        t = (point.row * widget.cellSize) + centeringOffset;
      }
    }
    else {
      // PATH (1-72)
      var point = PathConstants.stepToGrid[pos];
      if (point != null) {
        l = (point.col * widget.cellSize) + centeringOffset;
        t = (point.row * widget.cellSize) + centeringOffset;
      }
    }
    _left = l;
    _top = t;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left,
      top: _top,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SizedBox(
            width: widget.tokenSize,
            height: widget.tokenSize,
            child: TokenPawn(
              colorName: widget.colorName,
              tokenIndex: widget.tokenIndex,
              isDimmed: widget.isDimmed,
              showNumber: true,
            ),
          ),
        ),
      ),
    );
  }
}