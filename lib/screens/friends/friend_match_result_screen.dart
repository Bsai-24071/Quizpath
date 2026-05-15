import 'package:flutter/material.dart';
import '../../services/friend_match_service.dart';
import '../../utils/app_theme.dart';
import '../../features/aptitude/aptitude_service.dart';
import '../home_screen.dart';

class FriendMatchResultScreen extends StatefulWidget {
  final String matchId;
  const FriendMatchResultScreen({super.key, required this.matchId});

  @override
  State<FriendMatchResultScreen> createState() => _FriendMatchResultScreenState();
}

class _FriendMatchResultScreenState extends State<FriendMatchResultScreen> {
  final FriendMatchService _matchService = FriendMatchService();
  final AptitudeService _aptitudeService = AptitudeService();
  Map<dynamic, dynamic>? _matchData;
  int _myScore = 0;
  int _friendScore = 0;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _matchService.getMatchStream(widget.matchId).listen((event) {
      if (mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final player1 = data['player1'] as String;
          final currentUid = _matchService.currentUserId;
          final myPlayerId = currentUid == player1 ? 'p1' : 'p2';
          final friendPlayerId = currentUid == player1 ? 'p2' : 'p1';
          
          final scores = data['scores'] as Map<dynamic, dynamic>?;
          
          setState(() {
            _matchData = data;
            _myScore = scores?[myPlayerId] ?? 0;
            _friendScore = scores?[friendPlayerId] ?? 0;
          });
          
          if (!_recorded && _matchData != null) {
            _recordMatchHistory();
          }
        }
      }
    });
  }

  Future<void> _recordMatchHistory() async {
    if (_recorded) return;
    
    final category = _matchData?['category'] as String?;
    if (category == null) {
      print('⚠️ Category is null in friend match, cannot record history');
      return;
    }
    
    try {
      final uid = _aptitudeService.currentUserId;
      print('📊 Recording friend match to history:');
      print('  - User: $uid');
      print('  - Category: $category');
      print('  - Score: $_myScore out of 10');
      
      await _aptitudeService.recordMatchToHistory(
        uid: uid,
        category: category,
        correct: _myScore,
        total: 10,
        avgTime: 10.0,
      );
      
      setState(() => _recorded = true);
      print('✅ Friend match recorded successfully to history: $category');
    } catch (e, stackTrace) {
      print('❌ Error recording friend match: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_matchData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isWinner = _myScore > _friendScore;
    final isTie = _myScore == _friendScore;
    final accuracy = _myScore * 10;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Match Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                decoration: BoxDecoration(
                  color: (isTie ? AppTheme.warningColor : (isWinner ? AppTheme.successColor : AppTheme.errorColor)).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTie ? Icons.handshake_outlined : (isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied_outlined),
                  size: 80,
                  color: isTie ? AppTheme.warningColor : (isWinner ? AppTheme.successColor : AppTheme.errorColor),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLarge),
              
              Text(
                isTie ? 'It\'s a Tie!' : (isWinner ? 'You Won!' : 'You Lost!'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: isTie ? AppTheme.warningColor : (isWinner ? AppTheme.successColor : AppTheme.errorColor),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Your Score',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                '$_myScore',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            ':',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                'Friend Score',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                '$_friendScore',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      const Divider(),
                      const SizedBox(height: AppTheme.spacingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Text(
                            'Your Accuracy: ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '$accuracy%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXLarge),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Home'),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
