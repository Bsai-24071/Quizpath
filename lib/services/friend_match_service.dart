import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendMatchService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Future<String> createFriendMatch(String player1, String player2, List<Map<String, dynamic>> questions, String category) async {
    try {
      print('FriendMatchService: Creating match for $player1 vs $player2 with ${questions.length} questions in category: $category');
      final matchRef = _database.ref().child('matches').push();
      final matchId = matchRef.key!;
      print('FriendMatchService: Generated match ID: $matchId');
      
      final matchData = {
        'player1': player1,
        'player2': player2,
        'currentQuestion': 0,
        'scores': {'p1': 0, 'p2': 0},
        'status': 'waiting',
        'questions': questions,
        'category': category,
        'createdAt': ServerValue.timestamp,
      };
      
      print('FriendMatchService: Writing match data to database...');
      await matchRef.set(matchData);
      print('FriendMatchService: Match created successfully!');
      
      return matchId;
    } catch (e) {
      print('FriendMatchService ERROR: $e');
      rethrow;
    }
  }

  Future<void> joinMatch(String matchId) async {
    final matchRef = _database.ref().child('matches').child(matchId);
    await matchRef.update({'status': 'active'});
  }

  Future<void> updateAnswer(String matchId, String uid, int answerIndex) async {
    final matchRef = _database.ref().child('matches').child(matchId);
    final playerKey = uid == (await matchRef.child('player1').get()).value ? 'p1' : 'p2';
    await matchRef.child('answers').child(playerKey).set(answerIndex);
  }

  Future<void> updateScores(String matchId, int p1Score, int p2Score) async {
    final matchRef = _database.ref().child('matches').child(matchId);
    await matchRef.child('scores').update({'p1': p1Score, 'p2': p2Score});
  }

  Future<void> nextQuestion(String matchId) async {
    final questionRef = _database.ref().child('matches').child(matchId).child('currentQuestion');
    
    await questionRef.set(ServerValue.increment(1));
  }

  Future<void> finishMatch(String matchId) async {
    final matchRef = _database.ref().child('matches').child(matchId);
    await matchRef.update({'status': 'finished'});
  }

  Stream<DatabaseEvent> getMatchStream(String matchId) {
    return _database.ref().child('matches').child(matchId).onValue;
  }
}
