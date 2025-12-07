import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class DiceWidget extends StatefulWidget {
  final int value;           // Current Dice Value (from Server or Computer)
  final bool isMyTurn;       // Is it my turn to roll?
  final VoidCallback onRoll; // Function to trigger the roll

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
  int _displayValue = 1; // Number shown during animation
  bool _isRolling = false;
  DateTime? _rollStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- WATCH FOR CHANGES (This connects Logic to UI) ---
  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. New Value Arrived (0 -> 5): Stop Animation & Show Result
    if (widget.value != 0 && widget.value != oldWidget.value) {
      _stopRollingAnim(widget.value);
    }

    // 2. Reset (5 -> 0): Reset State
    if (widget.value == 0 && oldWidget.value != 0) {
      if (_isRolling) {
        _stopRollingAnim(_displayValue);
      }
    }
  }

  void _startRollingAnim() {
    if (_isRolling) return;

    AudioService.playRoll();
    _rollStartTime = DateTime.now();

    setState(() {
      _isRolling = true;
    });

    _controller.repeat();

    // Fast random flipping
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) setState(() => _displayValue = Random().nextInt(6) + 1);
    });

    // Trigger the actual Logic
    widget.onRoll();
  }

  Future<void> _stopRollingAnim(int finalValue) async {
    // Ensure animation plays for at least 0.5 seconds
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
    final bool canRoll = widget.isMyTurn && widget.value == 0 && !_isRolling;
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
            painter: _DotPainter(_displayValue, dotColor),
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
      default: dots = [Offset(c, c)];
    }
    for (var d in dots) canvas.drawCircle(d, r, paint);
  }
  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) => oldDelegate.number != number || oldDelegate.color != color;
}