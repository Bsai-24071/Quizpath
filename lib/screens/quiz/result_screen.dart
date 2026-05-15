import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../home_screen.dart';
import '../../features/aptitude/aptitude_service.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final int? computerScore;
  final String? category;
  final double? avgTime;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.computerScore,
    this.category,
    this.avgTime,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AptitudeService _aptitudeService = AptitudeService();
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _recordMatchHistory();
  }

  Future<void> _recordMatchHistory() async {
    if (_recorded) {
      print('Already recorded, skipping...');
      return;
    }
    
    if (widget.category == null) {
      print('⚠️ Category is null, cannot record match history');
      return;
    }
    
    try {
      final uid = _aptitudeService.currentUserId;
      print('📊 Recording match to history:');
      print('  - User: $uid');
      print('  - Category: ${widget.category}');
      print('  - Score: ${widget.score}');
      print('  - Correct: ${widget.score ~/ 5}');
      print('  - Total: ${widget.total ~/ 5}');
      print('  - AvgTime: ${widget.avgTime ?? 15.0}');
      
      await _aptitudeService.recordMatchToHistory(
        uid: uid,
        category: widget.category!,
        correct: widget.score ~/ 5,
        total: widget.total ~/ 5,
        avgTime: widget.avgTime ?? 15.0,
      );
      
      setState(() => _recorded = true);
      print('✅ Match recorded successfully to history: ${widget.category}');
    } catch (e, stackTrace) {
      print('❌ Error recording match: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVsComputer = widget.computerScore != null;
    String resultText = '';
    Color resultColor = AppTheme.primaryColor;
    IconData resultIcon = Icons.emoji_events_outlined;

    if (isVsComputer) {
      if (widget.score > widget.computerScore!) {
        resultText = 'You Win!';
        resultColor = AppTheme.successColor;
        resultIcon = Icons.emoji_events;
      } else if (widget.score < widget.computerScore!) {
        resultText = 'Computer Wins!';
        resultColor = AppTheme.errorColor;
        resultIcon = Icons.smart_toy_outlined;
      } else {
        resultText = 'It\'s a Tie!';
        resultColor = AppTheme.warningColor;
        resultIcon = Icons.handshake_outlined;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isVsComputer) ...[

                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      resultIcon,
                      size: 80,
                      color: resultColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    resultText,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),

                  Card(
                    elevation: AppTheme.elevationMedium,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLarge),
                      child: Column(
                        children: [
                          _buildScoreRow('Your Score', widget.score, AppTheme.primaryColor, context),
                          const SizedBox(height: AppTheme.spacingMedium),
                          const Divider(),
                          const SizedBox(height: AppTheme.spacingMedium),
                          _buildScoreRow('Computer Score', widget.computerScore!, AppTheme.textSecondary, context),
                        ],
                      ),
                    ),
                  ),
                ] else ...[

                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'Quiz Complete!',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),
                  Card(
                    elevation: AppTheme.elevationMedium,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLarge),
                      child: Column(
                        children: [
                          Text(
                            'Your Score',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),
                          Text(
                            '${widget.score} / ${widget.total}',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          Text(
                            '${((widget.score / widget.total) * 100).toStringAsFixed(0)}% Correct',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Back to Menu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color color, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '$score',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
