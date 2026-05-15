import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'aptitude_model.dart';

class AptitudeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Future<List<Map<String, dynamic>>> fetchUserMatchHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('matchHistory')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'category': data['category'] ?? 'General',
          'correct': data['correct'] ?? 0,
          'total': data['total'] ?? 0,
          'avgTime': (data['avgTime'] ?? 0.0).toDouble(),
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching match history: $e');
      return [];
    }
  }

  List<String> _getRecommendedFields(String category) {
    switch (category.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return ['Engineering', 'Data Science', 'Finance', 'Research'];
      
      case 'history':
        return ['Civil Services', 'Law', 'Teaching', 'Archaeology'];
      
      case 'politics':
      case 'political science':
        return ['International Relations', 'Governance', 'Journalism', 'Diplomacy'];
      
      case 'science':
      case 'biology':
      case 'physics':
      case 'chemistry':
        return ['Medicine', 'Research', 'Biotechnology', 'Environmental Science'];
      
      case 'programming':
      case 'computers':
      case 'computer science':
        return ['Software Engineering', 'AI/ML', 'Cybersecurity', 'Data Analytics'];
      
      case 'religion':
      case 'islamic studies':
        return ['Islamic Studies', 'Teaching', 'Religious Affairs', 'Social Work'];
      
      case 'geography':
        return ['Urban Planning', 'Environmental Science', 'GIS Specialist', 'Tourism'];
      
      case 'literature':
      case 'english':
        return ['Writing', 'Journalism', 'Teaching', 'Publishing'];
      
      case 'economics':
        return ['Business', 'Finance', 'Policy Making', 'Banking'];
      
      default:
        return ['Generalist Roles', 'Administration', 'Management', 'Teaching'];
    }
  }

  Future<List<AptitudeResult>> calculateAptitude(String uid) async {
    try {
      print('Calculating aptitude for user: $uid');
      
      final matchHistory = await fetchUserMatchHistory(uid);
      
      if (matchHistory.isEmpty) {
        print('No match history found');
        return [];
      }

      print('Found ${matchHistory.length} matches in history');

      Map<String, List<Map<String, dynamic>>> categoryMap = {};
      
      for (var match in matchHistory) {
        final category = match['category'] as String;
        if (!categoryMap.containsKey(category)) {
          categoryMap[category] = [];
        }
        categoryMap[category]!.add(match);
      }

      print('Categories found: ${categoryMap.keys.join(", ")}');

      List<AptitudeResult> results = [];
      
      for (var entry in categoryMap.entries) {
        final category = entry.key;
        final matches = entry.value;
        
        int totalCorrect = 0;
        int totalQuestions = 0;
        double totalTime = 0;
        
        for (var match in matches) {
          totalCorrect += match['correct'] as int;
          totalQuestions += match['total'] as int;
          totalTime += match['avgTime'] as double;
        }
        
        final accuracy = totalQuestions > 0 
            ? (totalCorrect / totalQuestions * 100) 
            : 0.0;
        
        final avgTime = matches.isNotEmpty 
            ? totalTime / matches.length 
            : 0.0;
        
        final result = AptitudeResult(
          category: category,
          accuracy: accuracy,
          questionsAttempted: totalQuestions,
          averageTime: avgTime,
          recommendedFields: _getRecommendedFields(category),
        );
        
        results.add(result);
        
        print('$category: ${accuracy.toStringAsFixed(1)}% accuracy, $totalQuestions questions');
      }

      results.sort((a, b) => b.accuracy.compareTo(a.accuracy));

      for (var result in results) {
        await saveAptitudeResult(uid, result);
      }

      print('Aptitude calculation complete. ${results.length} categories analyzed.');
      
      return results;
    } catch (e) {
      print('Error calculating aptitude: $e');
      return [];
    }
  }

  Future<void> saveAptitudeResult(String uid, AptitudeResult result) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('aptitude')
          .doc(result.category)
          .set(result.toMap());
      
      print('Saved aptitude for ${result.category}');
    } catch (e) {
      print('Error saving aptitude result: $e');
    }
  }

  Future<List<AptitudeResult>> fetchAptitudeResults(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('aptitude')
          .get();

      final results = snapshot.docs.map((doc) {
        return AptitudeResult.fromMap(doc.data());
      }).toList();

      results.sort((a, b) => b.accuracy.compareTo(a.accuracy));

      return results;
    } catch (e) {
      print('Error fetching aptitude results: $e');
      return [];
    }
  }

  Future<void> recordMatchToHistory({
    required String uid,
    required String category,
    required int correct,
    required int total,
    required double avgTime,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('matchHistory')
          .add({
        'category': category,
        'correct': correct,
        'total': total,
        'avgTime': avgTime,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('Recorded match to history: $category ($correct/$total)');
    } catch (e) {
      print('Error recording match to history: $e');
    }
  }

  Future<String?> getStrongestCategory(String uid) async {
    final results = await fetchAptitudeResults(uid);
    if (results.isEmpty) return null;
    return results.first.category;
  }

  Future<String?> getWeakestCategory(String uid) async {
    final results = await fetchAptitudeResults(uid);
    if (results.isEmpty) return null;
    return results.last.category;
  }

  Future<double> getOverallAccuracy(String uid) async {
    final results = await fetchAptitudeResults(uid);
    if (results.isEmpty) return 0.0;
    
    double totalAccuracy = 0;
    for (var result in results) {
      totalAccuracy += result.accuracy;
    }
    
    return totalAccuracy / results.length;
  }
}
