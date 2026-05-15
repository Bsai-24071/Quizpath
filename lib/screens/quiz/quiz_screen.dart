import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/trivia_service.dart';
import '../../utils/app_theme.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  const QuizScreen({super.key, required this.category});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score = 0;
  int _selected = -1;
  bool _answered = false;
  late Timer _timer;
  int _timeLeft = 15;
  List<int> _responseTimes = [];
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final qs = await TriviaService.fetchQuestions(widget.category);
      setState(() {
        _questions = qs;
        _loading = false;
      });
      _startTimer();
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    _timeLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        _nextQuestion();
      }
    });
  }

  void _check(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
    });

    _responseTimes.add(15 - _timeLeft);
    
    if (i == _questions[_current]['answer']) _score += 5;
    Future.delayed(const Duration(seconds: 1), _nextQuestion);
  }

  void _nextQuestion() {
    _timer.cancel();
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = -1;
        _answered = false;
      });
      _animationController.reset();
      _animationController.forward();
      _startTimer();
    } else {

      final avgTime = _responseTimes.isEmpty 
          ? 15.0 
          : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: _score, 
            total: _questions.length * 5,
            category: widget.category,
            avgTime: avgTime.toDouble(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (!_loading) _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.category),
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
    final progress = (_current + 1) / _questions.length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
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

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      border: Border.all(
                        color: AppTheme.successColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars_outlined,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successColor,
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
                child: FadeTransition(
                  opacity: _progressAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          if (i == q['answer']) {
                            bgColor = AppTheme.successColor;
                            textColor = AppTheme.textLight;
                            icon = Icons.check_circle_outline;
                          } else if (i == _selected) {
                            bgColor = AppTheme.errorColor;
                            textColor = AppTheme.textLight;
                            icon = Icons.cancel_outlined;
                          }
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                          child: Material(
                            color: bgColor ?? AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            elevation: AppTheme.elevationLow,
                            child: InkWell(
                              onTap: () => _check(i),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
