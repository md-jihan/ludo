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
    // Initialize exactly at current position to avoid "flying" on load
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

    // Only animate if position CHANGED
    if (widget.currentPosition != oldWidget.currentPosition) {
      _animateToNewPosition(oldWidget.currentPosition, widget.currentPosition);
    }
    // Handle Board Resize
    else if (widget.cellSize != oldWidget.cellSize) {
      _updateCoordinates(_visualPosition);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _animateToNewPosition(int start, int end) async {
    // --- FIX IS HERE ---

    // Case 1: Spawning (0 -> Start) OR Killing (Pos -> 0)
    // We do NOT want to walk the steps between 0 and 14.
    // We want to jump directly.
    if (start == 0 || end == 0) {
      if (mounted) {
        setState(() {
          _visualPosition = end;
          _updateCoordinates(end);
        });

        // Optional: Play a sound for spawning/killing
        if (end != 0) AudioService.playMove();
        else AudioService.playKill();

        // Little visual pop
        _bounceController.forward(from: 0);
      }
      return;
    }

    // Case 2: Normal Walking (e.g., 14 -> 16)
    int steps = end - start;

    // Sanity check: If steps are too large (glitch), don't walk
    if (steps < 0 || steps > 6) {
      setState(() {
        _visualPosition = end;
        _updateCoordinates(end);
      });
      return;
    }

    // Walk step-by-step
    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;

      int nextStep = start + i;

      setState(() {
        _visualPosition = nextStep;
        _updateCoordinates(nextStep);
      });

      _bounceController.forward(from: 0); // Visual Pop
      AudioService.playMove(); // Sound

      await Future.delayed(const Duration(milliseconds: 250)); // Walk Speed
    }
  }

  void _updateCoordinates(int pos) {
    double centeringOffset = (widget.cellSize - widget.tokenSize) / 2;
    double l = 0;
    double t = 0;

    if (pos == 99) {
      // Winner Center
      double centerGrid = 7.0 * widget.cellSize;
      switch (widget.colorName) {
        case 'Red': l = centerGrid - (widget.cellSize * 0.6); t = centerGrid; break;
        case 'Green': l = centerGrid; t = centerGrid - (widget.cellSize * 0.6); break;
        case 'Yellow': l = centerGrid + (widget.cellSize * 0.6); t = centerGrid; break;
        case 'Blue': l = centerGrid; t = centerGrid + (widget.cellSize * 0.6); break;
      }
      double jitter = widget.tokenIndex * (widget.tokenSize * 0.2);
      if (widget.colorName == 'Red' || widget.colorName == 'Yellow') t += jitter - (widget.tokenSize * 0.3);
      if (widget.colorName == 'Green' || widget.colorName == 'Blue') l += jitter - (widget.tokenSize * 0.3);
      l += centeringOffset; t += centeringOffset;
    }
    else if (pos == 0) {
      // Home Base
      var point = PathConstants.homeBases[widget.colorName]?[widget.tokenIndex];
      if (point != null) {
        l = (point.col * widget.cellSize) + centeringOffset;
        t = (point.row * widget.cellSize) + centeringOffset;
      }
    }
    else {
      // Path (Grid 1-52)
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