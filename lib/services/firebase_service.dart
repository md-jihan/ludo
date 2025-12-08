import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create Game
  Future<String> createGame(String userId, String playerName) async {
    String gameId = const Uuid().v4().substring(0, 6).toUpperCase();

    await _db.collection('games').doc(gameId).set({
      'status': 'waiting',
      'currentTurn': 0,
      'diceValue': 0,
      'diceRolledBy': '',
      'winners': [],
      'players': [
        {
          'id': userId,
          'color': 'Red',
          'name': playerName,
          'isAuto': false,
          'hasLeft': false
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

  // 2. Join Game
  Future<void> joinGame(String gameId, String userId, String playerName) async {
    DocumentSnapshot doc = await _db.collection('games').doc(gameId).get();
    if (!doc.exists) throw Exception("Game not found");

    List players = doc['players'];
    if (players.any((p) => p['id'] == userId)) return;
    if (players.length >= 4) throw Exception("Game is full");

    List<String> colors = ['Red', 'Green', 'Yellow', 'Blue'];
    String nextColor = colors[players.length];

    await _db.collection('games').doc(gameId).update({
      'players': FieldValue.arrayUnion([
        { 'id': userId, 'color': nextColor, 'name': playerName, 'isAuto': false, 'hasLeft': false }
      ])
    });
  }

  // 3. Move Token (With KILL Logic)
  Future<void> moveToken(String gameId, String userId, int tokenIndex, int newValue) async {
    DocumentReference gameRef = _db.collection('games').doc(gameId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(gameRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      List players = List.from(data['players']);
      Map<String, dynamic> tokens = Map.from(data['tokens']);
      List<String> winners = List<String>.from(data['winners'] ?? []);
      String status = data['status'];
      int currentTurn = data['currentTurn'];
      int diceValue = data['diceValue'];

      // A. Identify Player
      String playerColor = players.firstWhere((p) => p['id'] == userId)['color'];

      // --- KILL LOGIC START ---
      // Before moving, check if we land on someone (unless it's a Star/Safe spot)
      // For simplicity, we assume hitting an enemy anywhere (except 0 or 99) kills them.
      List<int> safeSpots = [1, 9, 14, 22, 27, 35, 40, 48];
      if (newValue != 0 && newValue != 99 && !safeSpots.contains(newValue)) {
        tokens.forEach((otherColor, positions) {
          if (otherColor != playerColor) {
            List<int> enemyTokens = List<int>.from(positions);
            bool killed = false;

            for (int i = 0; i < enemyTokens.length; i++) {
              // If enemy is at the same spot
              if (enemyTokens[i] == newValue) {
                enemyTokens[i] = 0; // SEND HOME!
                killed = true;
              }
            }
            // Update enemy tokens in map if modified
            if (killed) tokens[otherColor] = enemyTokens;
          }
        });
      }
      // --- KILL LOGIC END ---

      // B. Move My Token
      List<int> playerTokens = List<int>.from(tokens[playerColor]);
      playerTokens[tokenIndex] = newValue;
      tokens[playerColor] = playerTokens;

      // C. Check Win
      bool hasFinished = playerTokens.every((pos) => pos == 99);
      if (hasFinished && !winners.contains(userId)) {
        winners.add(userId);
      }

      // D. Check Game Over (Active players vs Winners)
      int activePlayersCount = players.where((p) => p['hasLeft'] != true).length;

      // If 2 players total, game ends when 1 wins.
      // If >2 players, game ends when (Players - 1) win.
      if (winners.length >= activePlayersCount - 1) {
        status = 'finished';
      }

      // E. Calculate Next Turn
      if (status != 'finished') {
        bool extraTurn = (diceValue == 6 && !hasFinished);

        if (!extraTurn) {
          int nextIndex = currentTurn;
          int attempts = 0;
          do {
            nextIndex = (nextIndex + 1) % players.length;
            String nextPlayerId = players[nextIndex]['id'];
            bool hasLeft = players[nextIndex]['hasLeft'] ?? false;
            bool alreadyWon = winners.contains(nextPlayerId);

            if (!hasLeft && !alreadyWon) {
              currentTurn = nextIndex;
              break;
            }
            attempts++;
          } while (attempts < players.length);
        }
      }

      transaction.update(gameRef, {
        'tokens': tokens,
        'winners': winners,
        'status': status,
        'currentTurn': currentTurn,
        'diceValue': 0,
      });
    });
  }

  // ... (Stream, Update, Leave methods remain same) ...
  Stream<GameModel> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) {
      if (!snapshot.exists) throw Exception("Game deleted");
      return GameModel.fromJson(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> updateGameState(String gameId, Map<String, dynamic> data) async {
    await _db.collection('games').doc(gameId).update(data);
  }

  Future<void> leaveGame(String gameId, String userId) async {
    // (Same as previous leaveGame code)
    DocumentReference docRef = _db.collection('games').doc(gameId);
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List players = List.from(data['players']);
      Map<String, dynamic> tokens = Map.from(data['tokens']);
      int currentTurn = data['currentTurn'];

      int playerIndex = players.indexWhere((p) => p['id'] == userId);
      if (playerIndex == -1) return;
      players[playerIndex]['hasLeft'] = true;
      String color = players[playerIndex]['color'];
      tokens[color] = [0, 0, 0, 0];

      if (currentTurn == playerIndex) {
        int nextTurn = currentTurn;
        for (int i = 0; i < players.length; i++) {
          nextTurn = (nextTurn + 1) % players.length;
          if (players[nextTurn]['hasLeft'] != true) {
            currentTurn = nextTurn;
            break;
          }
        }
      }
      transaction.update(docRef, {
        'players': players,
        'tokens': tokens,
        'currentTurn': currentTurn,
        'diceValue': 0,
      });
    });
  }
}