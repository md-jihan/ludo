class TokenModel {
  final int id;         // 0, 1, 2, 3 (each player has 4 tokens)
  final int position;   // -1 = home base, 0-51 = main path, 100+ = home stretch
  final String color;   // 'Red', 'Green', 'Yellow', 'Blue'
  final bool isSafe;    // True if on a Star

  TokenModel({
    required this.id,
    required this.position,
    required this.color,
    this.isSafe = false,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'color': color,
      'isSafe': isSafe,
    };
  }

  // Create from Firebase Map
  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      id: json['id'] ?? 0,
      position: json['position'] ?? -1,
      color: json['color'] ?? '',
      isSafe: json['isSafe'] ?? false,
    );
  }

  TokenModel copyWith({int? position, bool? isSafe}) {
    return TokenModel(
      id: id,
      color: color,
      position: position ?? this.position,
      isSafe: isSafe ?? this.isSafe,
    );
  }
}