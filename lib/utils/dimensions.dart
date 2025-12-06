import 'package:flutter/material.dart';

class Dimensions {
  static double getBoardSize(BuildContext context) {
    // The board should be a square, taking up most of the width but with some padding
    return MediaQuery.of(context).size.width * 0.95;
  }

  static double getCellSize(BuildContext context) {
    // The Ludo board is a 15x15 grid
    return getBoardSize(context) / 15;
  }
}