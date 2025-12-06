import 'package:equatable/equatable.dart';
import '../../models/game_model.dart';

abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final GameModel gameModel;
  const GameLoaded(this.gameModel);
  @override
  List<Object> get props => [gameModel];
}

class GameError extends GameState {
  final String message;
  const GameError({this.message = "An error occurred"});
}