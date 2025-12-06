import 'package:flutter/material.dart';

class TokenPawn extends StatelessWidget {
  final String colorName;
  final int tokenIndex;
  final bool isDimmed;

  const TokenPawn({
    super.key,
    required this.colorName,
    required this.tokenIndex,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColor(),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          if (!isDimmed)
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
        ],
      ),
      child: Center(
        child: Text(
          "${tokenIndex + 1}", // Show 1, 2, 3, 4 on the pawn
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getColor() {
    Color base;
    switch (colorName) {
      case 'Red': base = const Color(0xFFD32F2F); break; // Darker Red
      case 'Green': base = const Color(0xFF388E3C); break;
      case 'Yellow': base = const Color(0xFFFBC02D); break;
      case 'Blue': base = const Color(0xFF1976D2); break;
      default: base = Colors.grey;
    }
    return isDimmed ? base.withOpacity(0.3) : base;
  }
}