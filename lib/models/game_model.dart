import 'package:equatable/equatable.dart';

class GameModel extends Equatable {
  final String gameId;
  final String status; // 'waiting', 'playing', 'finished' [cite: 117]
  final int currentTurn; // 0=Red, 1=Green, 2=Yellow, 3=Blue [cite: 118]
  final int diceValue;
  final String diceRolledBy;
  final List<Map<String, dynamic>> players; // <--- This data changes when joining
  final Map<String, List<int>> tokens; // "Red": [0,0,0,0] [cite: 136]

  const GameModel({
    required this.gameId,
    required this.status,
    required this.currentTurn,
    required this.diceValue,
    required this.diceRolledBy,
    required this.players,
    required this.tokens,
  });

  // Factory to create from Firestore Snapshot
  factory GameModel.fromJson(Map<String, dynamic> json, String id) {
    return GameModel(
      gameId: id,
      status: json['status'] ?? 'waiting',
      currentTurn: json['currentTurn'] ?? 0,
      diceValue: json['diceValue'] ?? 0,
      diceRolledBy: json['diceRolledBy'] ?? '',
      players: List<Map<String, dynamic>>.from(json['players'] ?? []),
      tokens: Map<String, List<int>>.from(
        (json['tokens'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<int>.from(v)),
        ),
      ),
    );
  }

  // To save back to Firestore
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'currentTurn': currentTurn,
      'diceValue': diceValue,
      'diceRolledBy': diceRolledBy,
      'players': players,
      'tokens': tokens,
    };
  }

  // --- THE FIX IS HERE ---
  @override
  List<Object?> get props => [
    gameId,
    status,
    currentTurn,
    diceValue,
    tokens,
    players // <--- ADD THIS!
  ];
}