import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class DiceWidget extends StatefulWidget {
  final int value;           // Dice Value (1-6)
  final bool isMyTurn;       // Can I click it?
  final VoidCallback onRoll; // Tap callback

  const DiceWidget({
    super.key,
    required this.value,
    required this.isMyTurn,
    required this.onRoll,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _animTimer;
  int _displayValue = 1; // Number to show during animation
  bool _isRolling = false;
  DateTime? _rollStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Initialize display with current value or 1
    _displayValue = widget.value > 0 ? widget.value : 1;
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // CASE 1: Dice rolled (0 -> 5)
    if (widget.value != 0 && oldWidget.value == 0) {
      if (_isRolling) {
        // A. I clicked it (Manual Roll) -> Stop smoothly
        _stopRollingAnim(widget.value);
      } else {
        // B. Computer/Opponent rolled (Auto Roll) -> Trigger animation
        _triggerAutoRoll(widget.value);
      }
    }

    // CASE 2: Dice Reset (5 -> 0)
    if (widget.value == 0 && oldWidget.value != 0) {
      if (_isRolling) {
        _stopRollingAnim(_displayValue);
      }
    }
  }

  // --- MANUAL ROLL (Tap) ---
  void _startRollingAnim() {
    if (_isRolling) return;

    AudioService.playRoll();
    _rollStartTime = DateTime.now();

    setState(() {
      _isRolling = true;
    });

    _controller.repeat(); // Start Spinning

    // Flip numbers rapidly
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) setState(() => _displayValue = Random().nextInt(6) + 1);
    });

    // Call Parent Logic
    widget.onRoll();
  }

  // --- AUTO ROLL (Computer/Opponent) ---
  void _triggerAutoRoll(int targetValue) async {
    // 1. Start Visuals
    setState(() {
      _isRolling = true;
    });
    _controller.repeat();

    // Play sound if not already triggered by Bloc (Optional, safer to have it here)
    // Note: If your Bloc plays sound too, remove this line to avoid double echo.
    // AudioService.playRoll();

    // 2. Flip numbers
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) setState(() => _displayValue = Random().nextInt(6) + 1);
    });

    // 3. Wait 0.5 seconds (Simulate rolling time)
    await Future.delayed(const Duration(milliseconds: 500));

    // 4. Stop on Target
    if (mounted) {
      _animTimer?.cancel();
      _controller.stop();
      _controller.value = 0;
      setState(() {
        _isRolling = false;
        _displayValue = targetValue;
      });
    }
  }

  Future<void> _stopRollingAnim(int finalValue) async {
    // Force minimum duration for manual rolls
    if (_rollStartTime != null) {
      final int minDuration = 500;
      final int elapsed = DateTime.now().difference(_rollStartTime!).inMilliseconds;
      if (elapsed < minDuration) {
        await Future.delayed(Duration(milliseconds: minDuration - elapsed));
      }
    }

    _animTimer?.cancel();

    if (mounted) {
      _controller.stop();
      _controller.value = 0;

      setState(() {
        _isRolling = false;
        _displayValue = finalValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Allow click only if it's My Turn
    final bool canRoll = widget.isMyTurn && widget.value == 0 && !_isRolling;

    // UI Styling
    final Color boxColor = canRoll ? Colors.white : Colors.grey[300]!;
    final Color dotColor = canRoll ? Colors.black : Colors.grey[600]!;

    return GestureDetector(
      onTap: () {
        if (!widget.isMyTurn) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not your turn!")));
          return;
        }
        if (widget.value != 0) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Move your pawn first!")));
          return;
        }

        if (canRoll) {
          _startRollingAnim();
        }
      },
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(2, 2))],
          ),
          child: CustomPaint(
            // Use _displayValue (Animation) or widget.value (Static)
            painter: _DotPainter(_isRolling ? _displayValue : (widget.value == 0 ? _displayValue : widget.value), dotColor),
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int number;
  final Color color;
  _DotPainter(this.number, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    double r = size.width / 10;
    double c = size.width / 2;
    double l = size.width / 4;
    double m = size.width * 0.75;
    List<Offset> dots = [];
    switch (number) {
      case 1: dots = [Offset(c, c)]; break;
      case 2: dots = [Offset(l, l), Offset(m, m)]; break;
      case 3: dots = [Offset(l, l), Offset(c, c), Offset(m, m)]; break;
      case 4: dots = [Offset(l, l), Offset(m, l), Offset(l, m), Offset(m, m)]; break;
      case 5: dots = [Offset(l, l), Offset(m, l), Offset(c, c), Offset(l, m), Offset(m, m)]; break;
      case 6: dots = [Offset(l, l), Offset(m, l), Offset(l, c), Offset(m, c), Offset(l, m), Offset(m, m)]; break;
      default: dots = [Offset(c, c)]; // Fallback
    }
    for (var d in dots) canvas.drawCircle(d, r, paint);
  }
  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) => oldDelegate.number != number || oldDelegate.color != color;
}