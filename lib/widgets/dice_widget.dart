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

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _landController;
  late Animation<double> _xLand, _yLand, _zLand;

  // These variables remember the "Previous" position so rotation is continuous
  double _x = 0;
  double _y = 0;
  double _z = 0;

  bool _isWaitingForServer = false;
  int _lastServerDiceValue = 0;
  final double _size = 60.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _landController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _xLand = AlwaysStoppedAnimation(0);
    _yLand = AlwaysStoppedAnimation(0);
    _zLand = AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _landController.dispose();
    super.dispose();
  }

  void _startVisualSpin() {
    if (!_isWaitingForServer) {
      if(mounted) setState(() => _isWaitingForServer = true);
      _spinController.repeat();
    }
  }

  void _landOn(int targetNumber) {
    _spinController.stop();

    // 1. Determine Target Rotation (Precise Math)
    double tx = 0, ty = 0;
    switch (targetNumber) {
      case 2: ty = -pi / 2; break;
      case 3: ty = pi / 2; break;
      case 4: tx = -pi / 2; break;
      case 5: tx = pi / 2; break;
      case 6: tx = pi; break;
    // Case 1 is 0,0
    }

    // 2. Calculate smooth path from CURRENT spin to TARGET
    double currentSpin = _spinController.value * 2 * pi;

    // Add 4 full spins (4*2pi) to ensure it looks like it's slowing down
    double endX = tx + (8 * pi);
    double endY = ty + (8 * pi);

    if (mounted) {
      setState(() {
        _isWaitingForServer = false;
        // Start from _x + currentSpin (The Previous Position)
        _xLand = Tween<double>(begin: _x + currentSpin, end: endX).animate(CurvedAnimation(parent: _landController, curve: Curves.easeOutBack));
        _yLand = Tween<double>(begin: _y + currentSpin, end: endY).animate(CurvedAnimation(parent: _landController, curve: Curves.easeOutBack));
        _zLand = Tween<double>(begin: _z + currentSpin, end: 0).animate(CurvedAnimation(parent: _landController, curve: Curves.easeOutBack));
      });
    }

    _landController.forward(from: 0).then((_) {
      // Normalize values to keep them manageable for the next roll
      _x = endX % (2 * pi);
      _y = endY % (2 * pi);
      _z = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // A. SERVER SENT ROLL
          if (game.diceValue != 0 && game.diceValue != _lastServerDiceValue) {
            _lastServerDiceValue = game.diceValue;
            _landOn(game.diceValue);
          }

          // B. TURN RESET (The critical fix)
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
          final diceIsReset = game.diceValue == 0;

          // --- FIX: LOGIC RESYNC ---
          // If the server says "Dice is 0" (Reset), we MUST NOT be waiting.
          // This ensures the dice works 100% of the time for the 2nd roll.
          if (diceIsReset && _isWaitingForServer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isWaitingForServer = false;
                  _spinController.stop();
                });
              }
            });
          }

          final canRoll = isMyTurn && diceIsReset && !_isWaitingForServer;

          // Visual Color: White = Active, Grey = Locked
          Color diceColor = canRoll ? Colors.white : Colors.grey[400]!;

          return GestureDetector(
            onTap: () {
              if (canRoll) {
                _startVisualSpin();
                context.read<GameBloc>().add(RollDice(game.gameId));
              } else if (!isMyTurn) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not your turn!")));
              } else if (!diceIsReset) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Move your pawn first!")));
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_spinController, _landController]),
              builder: (context, child) {
                double rx, ry, rz;
                if (_isWaitingForServer) {
                  // WILD SPINNING
                  double val = _spinController.value * 2 * pi;
                  rx = val; ry = val; rz = val;
                } else {
                  // LANDING / RESTING
                  rx = _xLand.value; ry = _yLand.value; rz = _zLand.value;
                }

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rx)..rotateY(ry)..rotateZ(rz),
                  child: Stack(
                    children: [
                      // Pass the dynamic color to faces
                      _face(1, 0, 0, diceColor), _face(6, pi, 0, diceColor),
                      _face(3, 0, -pi/2, diceColor), _face(2, 0, pi/2, diceColor),
                      _face(4, -pi/2, 0, diceColor), _face(5, pi/2, 0, diceColor),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _face(int n, double rx, double ry, Color color) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateX(rx)..rotateY(ry)..translate(0.0, 0.0, _size / 2),
      child: Container(
        width: _size, height: _size,
        decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey[700]!, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)
            ]
        ),
        child: CustomPaint(painter: _DotPainter(n)),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int n;
  _DotPainter(this.n);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.black;
    double r = s.width/9, m = s.width/2, l = s.width/4, R = s.width*0.75;
    List<Offset> d = [];
    if(n%2!=0) d.add(Offset(m,m));
    if(n>1) d.addAll([Offset(l,l), Offset(R,R)]);
    if(n>3) d.addAll([Offset(l,R), Offset(R,l)]);
    if(n==6) d.addAll([Offset(l,m), Offset(R,m)]);
    for(var o in d) c.drawCircle(o, r, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}