import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/trivia_service.dart';
import '../../utils/app_theme.dart';
import 'result_screen.dart';

class QuizVsComputer extends StatefulWidget {
  final String category;
  final String difficulty;
  const QuizVsComputer({super.key, required this.category, required this.difficulty});
  @override
  State<QuizVsComputer> createState() => _QuizVsComputerState();
}

class _QuizVsComputerState extends State<QuizVsComputer> {
  bool _loading = true;
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _playerScore = 0;
  int _computerScore = 0;
  int _selected = -1;
  bool _answered = false;
  bool _computerAnsweredFirst = false;
  late Timer _questionTimer;
  Timer? _computerTimer;
  int _timeLeft = 15;
  final Random _rng = Random();
  List<int> _responseTimes = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final qs = await TriviaService.fetchQuestions(widget.category);
      _questions = qs.length >= 10 ? qs.sublist(0, 10) : qs;
      setState(() => _loading = false);
      _startRound();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _startRound() {
    _timeLeft = 15;
    _answered = false;
    _selected = -1;
    _computerAnsweredFirst = false;
    
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        if (!_answered) {
          _handleTimeout();
        }
      }
    });
    _scheduleComputerAnswer();
  }

  void _scheduleComputerAnswer() {
    double correctChance = widget.difficulty == 'Easy'
        ? 0.3
        : widget.difficulty == 'Medium'
            ? 0.6
            : 0.9;
    int delaySeconds = 2 + _rng.nextInt(11);
    _computerTimer?.cancel();
    _computerTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_answered && mounted) {
        final willBeCorrect = _rng.nextDouble() <= correctChance;
        _handleComputerAnswer(willBeCorrect);
      }
    });
  }

  void _handleComputerAnswer(bool isCorrect) {
    if (_answered || !mounted) return;
    
    _questionTimer.cancel();
    _computerTimer?.cancel();
    
    setState(() {
      _computerAnsweredFirst = true;
      _answered = true;
    });
    
    if (isCorrect) {
      setState(() {
        _computerScore += 5;
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _advanceOrFinish();
      }
    });
  }

  void _playerAnswer(int index) {
    if (_answered) return;
    
    _questionTimer.cancel();
    _computerTimer?.cancel();

    _responseTimes.add(15 - _timeLeft);
    
    final correctIndex = _questions[_current]['answer'] as int;
    
    setState(() {
      _selected = index;
      _answered = true;
      _computerAnsweredFirst = false;
    });
    
    if (index == correctIndex) {
      setState(() {
        _playerScore += 5;
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _advanceOrFinish();
      }
    });
  }

  void _handleTimeout() {
    if (_answered || !mounted) return;
    double correctChance = widget.difficulty == 'Easy'
        ? 0.3
        : widget.difficulty == 'Medium'
            ? 0.6
            : 0.9;
    final willBeCorrect = _rng.nextDouble() <= correctChance;
    _handleComputerAnswer(willBeCorrect);
  }

  void _advanceOrFinish() {
    _questionTimer.cancel();
    _computerTimer?.cancel();
    
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
      });
      _startRound();
    } else {

      final avgTime = _responseTimes.isEmpty 
          ? 15.0 
          : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: _playerScore,
            total: _questions.length * 5,
            computerScore: _computerScore,
            category: widget.category,
            avgTime: avgTime.toDouble(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _questionTimer.cancel();
    _computerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Vs Computer — ${widget.difficulty}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spacingLarge),
              Text(
                'Loading questions...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final q = _questions[_current];
    final correctIndex = q['answer'] as int;
    final progress = (_current + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vs Computer — ${widget.difficulty}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.textLight),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          '${_current + 1}/${_questions.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                          ? AppTheme.errorColor.withOpacity(0.1)
                          : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      border: Border.all(
                        color: _timeLeft <= 5 
                            ? AppTheme.errorColor 
                            : AppTheme.dividerColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: _timeLeft <= 5 
                              ? AppTheme.errorColor 
                              : AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          '${_timeLeft}s',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _timeLeft <= 5 
                                ? AppTheme.errorColor 
                                : AppTheme.textPrimary,
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

                    Card(
                      elevation: AppTheme.elevationMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        child: Text(
                          q['question'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),

                    ...List.generate(q['options'].length, (i) {
                      Color? bgColor;
                      Color? textColor;
                      IconData? icon;
                      
                      if (_answered) {
                        if (_computerAnsweredFirst) {

                          if (i == correctIndex) {
                            bgColor = AppTheme.infoColor;
                            textColor = AppTheme.textLight;
                            icon = Icons.smart_toy_outlined;
                          }
                        } else {

                          if (i == correctIndex) {
                            bgColor = AppTheme.successColor;
                            textColor = AppTheme.textLight;
                            icon = Icons.check_circle_outline;
                          } else if (i == _selected) {
                            bgColor = AppTheme.errorColor;
                            textColor = AppTheme.textLight;
                            icon = Icons.cancel_outlined;
                          }
                        }
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                        child: Material(
                          color: bgColor ?? AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          elevation: AppTheme.elevationLow,
                          child: InkWell(
                            onTap: () => _playerAnswer(i),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMedium),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                border: Border.all(
                                  color: bgColor ?? AppTheme.dividerColor,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingSmall),
                                    decoration: BoxDecoration(
                                      color: bgColor != null 
                                          ? Colors.white.withOpacity(0.2)
                                          : AppTheme.primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      String.fromCharCode(65 + i), 
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor ?? AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMedium),
                                  Expanded(
                                    child: Text(
                                      q['options'][i],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textColor ?? AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (icon != null) ...[
                                    const SizedBox(width: AppTheme.spacingSmall),
                                    Icon(icon, color: textColor, size: 24),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: AppTheme.spacingLarge),

                    Card(
                      elevation: AppTheme.elevationMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'You',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_playerScore',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              ':',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'Computer',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_computerScore',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppTheme.infoColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
