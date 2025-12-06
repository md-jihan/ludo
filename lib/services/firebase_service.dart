import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create Game (Now accepts playerName)
  Future<String> createGame(String userId, String playerName) async {
    String gameId = const Uuid().v4().substring(0, 6).toUpperCase();

    await _db.collection('games').doc(gameId).set({
      'status': 'waiting',
      'currentTurn': 0,
      'diceValue': 0,
      'diceRolledBy': '',
      'players': [
        {
          'id': userId,
          'color': 'Red',
          'name': playerName, // <--- SAVING NAME
          'isAuto': false
        }
      ],
      'tokens': {
        'Red': [0, 0, 0, 0],
        'Green': [0, 0, 0, 0],
        'Yellow': [0, 0, 0, 0],
        'Blue': [0, 0, 0, 0]
      }
    });
    return gameId;
  }

  // 2. Join Game (Now accepts playerName)
  Future<void> joinGame(String gameId, String userId, String playerName) async {
    DocumentSnapshot doc = await _db.collection('games').doc(gameId).get();

    if (!doc.exists) throw Exception("Game not found");

    List players = doc['players'];

    // Check if already joined
    bool alreadyJoined = players.any((p) => p['id'] == userId);
    if (alreadyJoined) return;

    if (players.length >= 4) throw Exception("Game is full");

    List<String> colors = ['Red', 'Green', 'Yellow', 'Blue'];
    String nextColor = colors[players.length];

    await _db.collection('games').doc(gameId).update({
      'players': FieldValue.arrayUnion([
        {
          'id': userId,
          'color': nextColor,
          'name': playerName, // <--- SAVING NAME
          'isAuto': false
        }
      ])
    });
  }

  // ... (Keep streamGame and updateGameState as they were) ...
  Stream<GameModel> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) {
      return GameModel.fromJson(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> updateGameState(String gameId, Map<String, dynamic> data) async {
    await _db.collection('games').doc(gameId).update(data);
  }
}