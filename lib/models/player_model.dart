import 'token_model.dart';

class PlayerModel {
  final String id;         // Firebase User ID
  final String name;
  final String color;      // Assigned color
  final List<TokenModel> tokens;

  PlayerModel({
    required this.id,
    required this.name,
    required this.color,
    required this.tokens,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'tokens': tokens.map((t) => t.toJson()).toList(),
    };
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    var list = json['tokens'] as List;
    List<TokenModel> tokenList = list.map((i) => TokenModel.fromJson(i)).toList();

    return PlayerModel(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      tokens: tokenList,
    );
  }
}