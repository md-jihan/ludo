import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create Game [cite: 86, 171]
  Future<String> createGame(String userId) async {
    String gameId = const Uuid().v4().substring(0, 6).toUpperCase();

    await _db.collection('games').doc(gameId).set({
      'status': 'waiting',
      'currentTurn': 0,
      'diceValue': 0,
      'diceRolledBy': '',
      'players': [
        {'id': userId, 'color': 'Red', 'isAuto': false} // [cite: 124]
      ],
      'tokens': {
        'Red': [0, 0, 0, 0],
        'Green': [0, 0, 0, 0],
        'Yellow': [0, 0, 0, 0],
        'Blue': [0, 0, 0, 0]
      } // [cite: 136-140]
    });
    return gameId;
  }

  // 2. Stream Game Data [cite: 88, 179]
  Stream<GameModel> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) {
      return GameModel.fromJson(snapshot.data()!, snapshot.id);
    });
  }

  // 3. Update Game State (Move Token / Roll Dice) [cite: 89, 177]
  Future<void> updateGameState(String gameId, Map<String, dynamic> data) async {
    await _db.collection('games').doc(gameId).update(data);
  }
  // Inside FirebaseService class...

  Future<void> joinGame(String gameId, String userId) async {
    // 1. Get the current game data
    DocumentSnapshot doc = await _db.collection('games').doc(gameId).get();

    if (!doc.exists) throw Exception("Game not found");

    List players = doc['players'];

    // 2. Avoid duplicates: Check if user is already in the game
    bool alreadyJoined = players.any((p) => p['id'] == userId);
    if (alreadyJoined) return;

    // 3. Assign Color based on arrival order
    // Player 1 = Red (already there), Player 2 = Green, 3 = Yellow, 4 = Blue
    List<String> colors = ['Red', 'Green', 'Yellow', 'Blue'];
    String nextColor = colors[players.length];

    // 4. Update Firestore
    await _db.collection('games').doc(gameId).update({
      'players': FieldValue.arrayUnion([
        {'id': userId, 'color': nextColor, 'isAuto': false}
      ])
    });
  }
}