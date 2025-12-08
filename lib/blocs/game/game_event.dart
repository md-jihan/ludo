import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object> get props => [];
}

class LoadGame extends GameEvent {
  final String gameId;
  const LoadGame(this.gameId);
}

class RollDice extends GameEvent {
  final String gameId;
  const RollDice(this.gameId);
}

class UpdateGameState extends GameEvent {
  // Used for internal updates or specific moves
}
class MoveToken extends GameEvent {
  final String gameId;
  final String userId;
  final int tokenIndex; // 0, 1, 2, or 3
  const MoveToken({required this.gameId, required this.userId, required this.tokenIndex});
}
class StartGame extends GameEvent { final String gameId; const StartGame(this.gameId); }

// 5. Leave Game (The missing class)
class LeaveGameEvent extends GameEvent {
  final String gameId;
  final String userId;
  const LeaveGameEvent(this.gameId, this.userId);
}

class StartComputerGame extends GameEvent {
  final String userColor;
  const StartComputerGame(this.userColor);
}
