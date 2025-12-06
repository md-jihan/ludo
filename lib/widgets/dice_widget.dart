import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';

class DiceWidget extends StatefulWidget {
  final String myPlayerId;

  const DiceWidget({super.key, required this.myPlayerId});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  int _displayValue = 1; // Value shown WHILE rolling
  bool _isAnimating = false;
  Timer? _rollTimer;
  int _lastServerDiceValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Spin 360 degrees (2 * pi) multiple times
    _rotationAnimation = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    // bounce effect (shrink then grow)
    _scaleAnimation = SequenceAnimationBuilder<double>()
        .addAnim(begin: 1.0, end: 0.8, duration: const Duration(milliseconds: 200), curve: Curves.easeIn)
        .addAnim(begin: 0.8, end: 1.2, duration: const Duration(milliseconds: 400), curve: Curves.easeOut)
        .addAnim(begin: 1.2, end: 1.0, duration: const Duration(milliseconds: 200), curve: Curves.elasticOut)
        .build(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _rollTimer?.cancel();
    super.dispose();
  }

  void _runRollAnimation(int finalValue) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    _controller.forward(from: 0).then((_) {
      // Animation Finished
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _displayValue = finalValue;
        });
      }
    });

    // While animating, rapidly change the number displayed
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_controller.isCompleted) {
        timer.cancel();
      } else {
        setState(() {
          // Show random values while spinning
          _displayValue = Random().nextInt(6) + 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // Detect if dice value CHANGED in Firebase (someone rolled)
          if (game.diceValue != 0 && game.diceValue != _lastServerDiceValue) {
            _lastServerDiceValue = game.diceValue;

            // If *I* rolled, the button press started animation.
            // If *someone else* rolled, we need to trigger animation now.
            if (game.diceRolledBy != widget.myPlayerId) {
              _runRollAnimation(game.diceValue);
            } else {
              // Ensure we land on the correct final value
              // (The local animation might still be spinning random numbers)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _rollTimer?.cancel();
                setState(() => _displayValue = game.diceValue);
              });
            }
          }

          // If turn reset to 0, reset our display too (optional)
          if (game.diceValue == 0) {
            _lastServerDiceValue = 0;
          }
        }
      },
      child: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state is! GameLoaded) return const SizedBox();

          final game = state.gameModel;
          final isMyTurn = game.players[game.currentTurn]['id'] == widget.myPlayerId;
          final canRoll = isMyTurn && game.diceValue == 0; // Only roll if dice is 0 (reset)

          return GestureDetector(
            onTap: () {
              if (canRoll && !_isAnimating) {
                // 1. Start Visual Animation immediately
                _runRollAnimation(0); // 0 means "don't stop on specific number yet"

                // 2. Tell Server to Calculate Logic
                context.read<GameBloc>().add(RollDice(game.gameId));
              }
            },
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: CustomPaint(
                      painter: _DicePainter(
                        number: _isAnimating ? _displayValue : (game.diceValue == 0 ? _displayValue : game.diceValue),
                        color: canRoll ? Colors.white : Colors.grey[300]!, // Dim if disabled
                      ),
                      size: const Size(60, 60),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- 3D PAINTER CLASS ---
class _DicePainter extends CustomPainter {
  final int number;
  final Color color;

  _DicePainter({required this.number, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint();

    // 1. Draw Shadow (to give it depth)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, w, h),
          const Radius.circular(12)
      ),
      Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 2. Draw Main Box (The Dice)
    paint.color = color;
    final RRect box = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(12));
    canvas.drawRRect(box, paint);

    // 3. Draw "3D" Edge Highlight (Top/Left light)
    final Paint highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.5);
    canvas.drawPath(
        Path()..moveTo(0, h)..lineTo(0, 0)..lineTo(w, 0),
        highlight
    );

    // 4. Draw "3D" Edge Shadow (Bottom/Right dark)
    final Paint shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withOpacity(0.1);
    canvas.drawPath(
        Path()..moveTo(0, h)..lineTo(w, h)..lineTo(w, 0),
        shadow
    );

    // 5. Draw Dots
    _drawDots(canvas, size);
  }

  void _drawDots(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()..color = Colors.black;
    final double r = size.width / 10; // Dot radius
    final double c = size.width / 2; // Center
    final double l = size.width / 4; // Left/Top
    final double m = size.width * 0.75; // Right/Bottom

    final List<Offset> dots = [];

    switch (number) {
      case 1: dots.add(Offset(c, c)); break;
      case 2: dots.addAll([Offset(l, l), Offset(m, m)]); break;
      case 3: dots.addAll([Offset(l, l), Offset(c, c), Offset(m, m)]); break;
      case 4: dots.addAll([Offset(l, l), Offset(m, l), Offset(l, m), Offset(m, m)]); break;
      case 5: dots.addAll([Offset(l, l), Offset(m, l), Offset(c, c), Offset(l, m), Offset(m, m)]); break;
      case 6: dots.addAll([Offset(l, l), Offset(m, l), Offset(l, c), Offset(m, c), Offset(l, m), Offset(m, m)]); break;
      default: dots.add(Offset(c, c)); // Fallback
    }

    // Draw dots with slight indentation effect
    for (var dot in dots) {
      // Inner shadow for hole look
      canvas.drawCircle(dot, r, dotPaint);
      canvas.drawCircle(dot, r * 0.8, Paint()..color = const Color(0xFF212121)); // Darker center
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) => oldDelegate.number != number || oldDelegate.color != color;
}

// Simple sequence animation helper
class SequenceAnimationBuilder<T> {
  // (Simplified implementation for readability)
  Animation<double> build(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(controller);
  }
  // Ignore the addAnim method in this simplified snippet to fit one file, using standard TweenSequence above.
  SequenceAnimationBuilder addAnim({required double begin, required double end, required Duration duration, required Curve curve}) { return this; }
}