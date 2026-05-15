import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/friend_match_service.dart';
import '../../utils/app_theme.dart';
import 'friend_match_result_screen.dart';

class FriendMatchScreen extends StatefulWidget {
  final String matchId;
  const FriendMatchScreen({super.key, required this.matchId});

  @override
  State<FriendMatchScreen> createState() => _FriendMatchScreenState();
}

class _FriendMatchScreenState extends State<FriendMatchScreen> {
  final FriendMatchService _matchService = FriendMatchService();
  List<Map<String, dynamic>> _questions = [];
  Map<dynamic, dynamic>? _matchData;
  int _selected = -1;
  bool _answered = false;
  Timer? _timer;
  int _timeLeft = 10;
  int _myScore = 0;
  int _friendScore = 0;
  String? _myPlayerId;
  String? _friendPlayerId;
  bool _bothAnswered = false;
  int? _lastQuestionNumber;
  bool _isAdvancing = false;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _listenToMatch();
  }

  void _listenToMatch() {
    _matchService.getMatchStream(widget.matchId).listen((event) {
      if (!mounted) return;
      
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      
      final currentQuestion = data['currentQuestion'] as int? ?? 0;
      final status = data['status'] as String? ?? 'active';

      final player1 = data['player1'] as String;
      final currentUid = _matchService.currentUserId;
      final myPlayerId = currentUid == player1 ? 'p1' : 'p2';

      if (status == 'finished') {
        print('[$myPlayerId] Match status is FINISHED! Navigating to results...');
        _timer?.cancel();
        _advanceTimer?.cancel();

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FriendMatchResultScreen(
                  matchId: widget.matchId,
                ),
              ),
            );
          }
        });
        return;
      }

      if (_lastQuestionNumber != null && currentQuestion != _lastQuestionNumber) {
        print('[$myPlayerId] Question changed from $_lastQuestionNumber to $currentQuestion - resetting state');
        _advanceTimer?.cancel();
        _advanceTimer = null;
        _isAdvancing = false;
        setState(() {
          _selected = -1;
          _answered = false;
          _bothAnswered = false;
        });
        _startTimer();
      }
      _lastQuestionNumber = currentQuestion;
      
      setState(() {
        _matchData = data;

        _myPlayerId = myPlayerId;
        _friendPlayerId = myPlayerId == 'p1' ? 'p2' : 'p1';

        final scores = data['scores'] as Map<dynamic, dynamic>?;
        if (scores != null) {
          _myScore = scores[_myPlayerId] ?? 0;
          _friendScore = scores[_friendPlayerId] ?? 0;
        }

        final answers = data['answers'] as Map<dynamic, dynamic>?;
        if (answers != null) {
          final p1Answered = answers['p1'] != null;
          final p2Answered = answers['p2'] != null;
          final wasBothAnswered = _bothAnswered;
          _bothAnswered = p1Answered && p2Answered;

          if (_bothAnswered && !wasBothAnswered && !_isAdvancing && _advanceTimer == null) {
            print('[$_myPlayerId] Both players answered Q$currentQuestion!');
            _timer?.cancel();

            if (_myPlayerId == 'p1') {
              print('[$_myPlayerId] I am P1, scheduling advancement in 2 seconds...');
              _advanceTimer = Timer(const Duration(seconds: 2), () {
                if (mounted && !_isAdvancing) {
                  _goToNextQuestion();
                }
              });
            } else {
              print('[$_myPlayerId] I am P2, waiting for P1 to advance...');
            }
          }
        }
      });
    });
  }

  Future<void> _loadQuestions() async {
    try {

      final snapshot = await FirebaseDatabase.instance.ref()
        .child('matches').child(widget.matchId).child('questions').get();
      
      if (snapshot.exists && mounted) {
        final questionsData = snapshot.value as List<dynamic>;
        setState(() {
          _questions = questionsData.map((q) => Map<String, dynamic>.from(q as Map)).toList();
        });
        print('Loaded ${_questions.length} questions from database');
        _startTimer();
      } else {
        print('No questions found in database for match ${widget.matchId}');
      }
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      
      if (_timeLeft > 0 && !_answered) {
        setState(() => _timeLeft--);
      } else if (_timeLeft == 0 && !_answered) {
        _answer(-1);
      }
    });
  }

  Future<void> _answer(int index) async {
    if (_answered) return;
    
    setState(() {
      _selected = index;
      _answered = true;
    });
    
    _timer?.cancel();

    final currentQ = _matchData?['currentQuestion'] ?? 0;
    if (currentQ < _questions.length) {
      final correctAnswer = _questions[currentQ]['answer'] as int;
      final isCorrect = index == correctAnswer;
      
      if (isCorrect) {

        final newMyScore = _myScore + 1;
        print('Correct answer! My score: $_myScore -> $newMyScore (I am $_myPlayerId)');

        if (_myPlayerId == 'p1') {
          await _matchService.updateScores(widget.matchId, newMyScore, _friendScore);
        } else {
          await _matchService.updateScores(widget.matchId, _friendScore, newMyScore);
        }
      }
    }

    await _matchService.updateAnswer(widget.matchId, _matchService.currentUserId, index);
  }

  Future<void> _goToNextQuestion() async {

    if (_isAdvancing) {
      print('[$_myPlayerId] Already advancing, skipping duplicate call');
      return;
    }
    
    _isAdvancing = true;
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _timer?.cancel();
    
    final currentQ = _matchData?['currentQuestion'] ?? 0;
    print('[$_myPlayerId] Attempting to advance from question $currentQ');
    
    if (currentQ >= 9) {

      print('[$_myPlayerId] Match finished! Setting status to finished...');
      await _matchService.finishMatch(widget.matchId);

    } else {
      try {

        await FirebaseDatabase.instance
            .ref()
            .child('matches')
            .child(widget.matchId)
            .child('answers')
            .remove();
        
        print('[$_myPlayerId] Cleared answers for Q$currentQ');

        await _matchService.nextQuestion(widget.matchId);
        
        print('[$_myPlayerId] Called nextQuestion for Q$currentQ');
      } catch (e) {
        print('[$_myPlayerId] Error advancing question: $e');
        _isAdvancing = false;
      }

    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty || _matchData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQ = _matchData!['currentQuestion'] ?? 0;
    
    if (currentQ >= _questions.length) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: Text('Loading next question...')),
      );
    }
    
    final q = _questions[currentQ];
    final answers = _matchData!['answers'] as Map<dynamic, dynamic>?;
    final friendAnswered = answers?[_friendPlayerId] != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('VS Friend'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (currentQ + 1) / 10,
            backgroundColor: AppTheme.backgroundColor.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
        ),
      ),
      body: Column(
        children: [

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '${currentQ + 1}/10',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: _timeLeft <= 5 
                        ? AppTheme.errorColor 
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: _timeLeft <= 5 ? AppTheme.textLight : AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '$_timeLeft s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft <= 5 ? AppTheme.textLight : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    border: Border.all(
                      color: AppTheme.successColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'You',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '$_myScore',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    border: Border.all(
                      color: AppTheme.infoColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Friend',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '$_friendScore',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (friendAnswered)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        border: Border.all(
                          color: AppTheme.successColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Text(
                            'Friend has answered!',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (friendAnswered) const SizedBox(height: AppTheme.spacingLarge),

                  Card(
                    elevation: AppTheme.elevationLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLarge),
                      child: Text(
                        q['question'],
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLarge),

                  ...List.generate(
                    (q['options'] as List).length,
                    (i) {
                      Color borderColor = AppTheme.textSecondary.withValues(alpha: 0.3);
                      Color bgColor = AppTheme.cardBackground;
                      Color textColor = AppTheme.textPrimary;
                      Icon? icon;
                      
                      if (_answered) {
                        if (i == q['answer']) {
                          bgColor = AppTheme.successColor;
                          borderColor = AppTheme.successColor;
                          textColor = AppTheme.textLight;
                          icon = const Icon(Icons.check_circle, color: AppTheme.textLight);
                        } else if (i == _selected) {
                          bgColor = AppTheme.errorColor;
                          borderColor = AppTheme.errorColor;
                          textColor = AppTheme.textLight;
                          icon = const Icon(Icons.cancel, color: AppTheme.textLight);
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            onTap: _answered ? null : () => _answer(i),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingMedium),
                              child: Row(
                                children: [

                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _answered && (i == q['answer'] || i == _selected)
                                          ? AppTheme.textLight.withValues(alpha: 0.3)
                                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: TextStyle(
                                        color: _answered && (i == q['answer'] || i == _selected)
                                            ? AppTheme.textLight
                                            : AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMedium),
                                  Expanded(
                                    child: Text(
                                      q['options'][i],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (icon != null) ...[
                                    const SizedBox(width: AppTheme.spacingSmall),
                                    icon,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
