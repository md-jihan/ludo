import 'package:flutter/material.dart';

class BoardCell extends StatelessWidget {
  final Color color;
  final bool isSafeSpot;
  final Widget? child;

  const BoardCell({
    super.key,
    this.color = Colors.white,
    this.isSafeSpot = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: Stack(
        children: [
          if (isSafeSpot)
            const Center(child: Icon(Icons.star_border, color: Colors.black26, size: 12)),
          if (child != null) Center(child: child),
        ],
      ),
    );
  }
}