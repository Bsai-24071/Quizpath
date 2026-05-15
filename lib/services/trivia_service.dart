import 'dart:convert';
import 'package:http/http.dart' as http;

class TriviaService {
  static const Map<String, int> _categoryIds = {
    'General': 9,
    'History': 23,
    'Science': 17,
    'Math': 19,
    'Computers': 18,
  };

  static Future<List<Map<String, dynamic>>> fetchQuestions(String category) async {
    final id = _categoryIds[category] ?? 9;
    final url =
        'https://opentdb.com/api.php?amount=10&category=$id&type=multiple&encode=url3986';
    
    int attempts = 0;
    Exception? lastError;
    
    while (attempts < 3) {
      attempts++;
      try {
        print('Fetching questions from API (attempt $attempts/3)...');
        
        final res = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('API request timeout');
          },
        );
        
        print('API response status: ${res.statusCode}');
        
        if (res.statusCode != 200) {
          throw Exception('Failed to load questions: HTTP ${res.statusCode}');
        }
        
        final data = jsonDecode(res.body);
        
        if (data['response_code'] != 0) {
          throw Exception('API error: response_code=${data['response_code']}');
        }
        
        final results = (data['results'] as List)
            .map<Map<String, dynamic>>((q) {
              final options = List<String>.from(q['incorrect_answers']
                  .map((e) => Uri.decodeComponent(e)));
              options.add(Uri.decodeComponent(q['correct_answer']));
              options.shuffle();
              return {
                'question': Uri.decodeComponent(q['question']),
                'options': options,
                'answer': options.indexOf(Uri.decodeComponent(q['correct_answer'])),
              };
            })
            .toList();
        
        print('Successfully loaded ${results.length} questions');
        return results;
        
      } catch (e) {
        lastError = e as Exception;
        print('Error fetching questions (attempt $attempts/3): $e');
        
        if (attempts < 3) {
          print('Retrying in ${attempts} seconds...');
          await Future.delayed(Duration(seconds: attempts));
        }
      }
    }
    
    throw lastError ?? Exception('Failed to load questions after 3 attempts');
  }
}
