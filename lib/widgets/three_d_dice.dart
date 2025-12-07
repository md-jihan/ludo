import 'dart:math';
import 'package:flutter/material.dart';

class ThreeDimensionalDice extends StatefulWidget {
  final int value;          // The number to land on (1-6)
  final VoidCallback? onRoll; // Tap action
  final bool disabled;      // Is it clickable?
  final double size;        // Size of the cube

  const ThreeDimensionalDice({
    super.key,
    required this.value,
    this.onRoll,
    this.disabled = false,
    this.size = 60.0,
  });

  @override
  State<ThreeDimensionalDice> createState() => _ThreeDimensionalDiceState();
}

class _ThreeDimensionalDiceState extends State<ThreeDimensionalDice> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // These hold the "Landing" animations
  late Animation<double> _xAnim;
  late Animation<double> _yAnim;
  late Animation<double> _zAnim;

  // These hold the "Resting" angles (Where the dice stopped last)
  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;

  // State Flag
  bool _isWildSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations to 0
    _xAnim = AlwaysStoppedAnimation(0);
    _yAnim = AlwaysStoppedAnimation(0);
    _zAnim = AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ThreeDimensionalDice oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. New Number Arrived (e.g. 0 -> 5)
    if (widget.value != 0 && widget.value != oldWidget.value) {
      _landOn(widget.value);
    }

    // 2. Reset Arrived (e.g. 5 -> 0)
    // FORCE RESET: If the game says dice is 0, we must be ready to roll.
    if (widget.value == 0) {
      if (_isWildSpinning || _controller.isAnimating) {
        setState(() {
          _isWildSpinning = false;
          _controller.stop();
        });
      }
    }
  }

  // --- ACTION: START SPINNING ---
  void _startSpinning() {
    if (widget.disabled || _isWildSpinning) return;

    // Notify Parent
    widget.onRoll?.call();

    // Start Visuals
    setState(() {
      _isWildSpinning = true;
    });
    _controller.repeat();
  }

  // --- ACTION: LAND ON NUMBER ---
  void _landOn(int targetNumber) {
    // 1. Stop the wild loop
    _controller.stop();

    // 2. Calculate Target Rotation
    double targetX = 0;
    double targetY = 0;

    switch (targetNumber) {
      case 1: targetX = 0; targetY = 0; break;          // Front
      case 2: targetX = 0; targetY = -pi / 2; break;    // Right
      case 3: targetX = 0; targetY = pi / 2; break;     // Left
      case 4: targetX = -pi / 2; targetY = 0; break;    // Top
      case 5: targetX = pi / 2; targetY = 0; break;     // Bottom
      case 6: targetX = pi; targetY = 0; break;         // Back
    }

    // 3. Smooth Transition Math
    // We grab the controller value to ensure we start rotating from "Right Now"
    double currentRot = _controller.value * 2 * pi;
    double extraSpins = 4 * pi; // Add spins for effect

    // Calculate End Angles based on LAST Resting Position + Current Spin
    double endX = _lastX + targetX + extraSpins + currentRot;
    double endY = _lastY + targetY + extraSpins + currentRot;
    double endZ = _lastZ + (2 * pi);

    setState(() {
      _isWildSpinning = false; // Turn off wild mode

      // Create Tweens to animate from (Where we are) -> (Where we want to be)
      _xAnim = Tween<double>(begin: _lastX + currentRot, end: endX)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
      _yAnim = Tween<double>(begin: _lastY + currentRot, end: endY)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
      _zAnim = Tween<double>(begin: _lastZ, end: endZ)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    });

    // 4. Run Animation
    _controller.forward(from: 0).then((_) {
      // 5. Update Resting Position (Normalize to keep numbers small)
      setState(() {
        _lastX = endX % (2 * pi);
        _lastY = endY % (2 * pi);
        _lastZ = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Ensures clicks are captured
      onTap: _startSpinning,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double rx, ry, rz;

          if (_isWildSpinning) {
            // MODE 1: WILD SPIN
            double val = _controller.value * 2 * pi;
            rx = _lastX + val;
            ry = _lastY + val;
            rz = _lastZ + val;
          } else {
            // MODE 2: LANDING / RESTING
            // If animating, use Tween. If stopped, use _lastX/Y/Z.
            rx = _controller.isAnimating ? _xAnim.value : _lastX;
            ry = _controller.isAnimating ? _yAnim.value : _lastY;
            rz = _controller.isAnimating ? _zAnim.value : _lastZ;
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D Perspective
              ..rotateX(rx)
              ..rotateY(ry)
              ..rotateZ(rz),
            child: Stack(
              children: [
                _face(1, Matrix4.identity()..translate(0.0, 0.0, widget.size/2)),
                _face(6, Matrix4.identity()..rotateY(pi)..translate(0.0, 0.0, widget.size/2)),
                _face(3, Matrix4.identity()..rotateY(-pi/2)..translate(0.0, 0.0, widget.size/2)),
                _face(2, Matrix4.identity()..rotateY(pi/2)..translate(0.0, 0.0, widget.size/2)),
                _face(4, Matrix4.identity()..rotateX(-pi/2)..translate(0.0, 0.0, widget.size/2)),
                _face(5, Matrix4.identity()..rotateX(pi/2)..translate(0.0, 0.0, widget.size/2)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _face(int n, Matrix4 transform) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
            color: widget.disabled ? Colors.grey[300] : Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]
        ),
        child: CustomPaint(
          painter: _DotPainter(n, widget.disabled ? Colors.grey : Colors.black),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int n;
  final Color c;
  _DotPainter(this.n, this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = c;
    double r = size.width/10, center = size.width/2, l = size.width/4, R = size.width*0.75;
    List<Offset> d = [];
    if(n%2!=0) d.add(Offset(center,center));
    if(n>1) d.addAll([Offset(l,l), Offset(R,R)]);
    if(n>3) d.addAll([Offset(l,R), Offset(R,l)]);
    if(n==6) d.addAll([Offset(l,center), Offset(R,center)]);
    for(var o in d) canvas.drawCircle(o, r, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}