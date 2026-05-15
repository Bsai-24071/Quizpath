import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../services/friend_match_service.dart';
import '../../services/trivia_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'match_lobby_screen.dart';

class MatchChallengesScreen extends StatefulWidget {
  const MatchChallengesScreen({super.key});

  @override
  State<MatchChallengesScreen> createState() => _MatchChallengesScreenState();
}

class _MatchChallengesScreenState extends State<MatchChallengesScreen> {
  final FriendService _friendService = FriendService();
  final FriendMatchService _matchService = FriendMatchService();
  final Set<String> _processingChallenges = {};

  Future<void> _acceptChallenge(String challengerId, String challengerName, String category) async {
    if (_processingChallenges.contains(challengerId)) {
      print('Already processing this challenge, ignoring...');
      return;
    }
    
    _processingChallenges.add(challengerId);
    
    try {
      print('Accepting $category challenge from $challengerId');

      print('Fetching $category questions for match...');
      final questions = await TriviaService.fetchQuestions(category);
      final matchQuestions = questions.take(10).toList();
      print('Fetched ${matchQuestions.length} questions for match');

      print('Creating match with questions...');
      final matchId = await _matchService.createFriendMatch(
        challengerId,
        _friendService.currentUserId!,
        matchQuestions,
        category,
      );
      print('Match created: $matchId');

      await _friendService.acceptMatchChallenge(challengerId, matchId);
      print('Challenge accepted');

      
      if (mounted) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchLobbyScreen(matchId: matchId),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error accepting challenge: $e');
      print('Stack trace: $stackTrace');
      _processingChallenges.remove(challengerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineChallenge(String challengerId) async {
    try {
      await _friendService.declineMatchChallenge(challengerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Match Challenges'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendService.getMatchChallengesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final challenges = snapshot.data ?? [];
          
          if (challenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports_outlined,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'No pending challenges',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    'Your friends can challenge you to a quiz match!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final username = challenge['username'] ?? 'Unknown';
              final avatarUrl = challenge['avatarUrl'] ?? '';
              final fromUid = challenge['fromUid'] ?? challenge['id'];
              final category = challenge['category'] ?? 'General';
              
              final categoryColor = AppTheme.getCategoryColor(category);
              final categoryIcon = AppTheme.getCategoryIcon(category);
              
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                elevation: AppTheme.elevationMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [

                          UserAvatar(
                            avatarUrl: avatarUrl,
                            username: username,
                            radius: 28,
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.sports_esports_outlined,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'challenged you',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                          vertical: AppTheme.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon, size: 18, color: categoryColor),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: AppTheme.textLight,
                              ),
                              onPressed: () => _acceptChallenge(fromUid, username, category),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                side: const BorderSide(color: AppTheme.errorColor),
                              ),
                              onPressed: () => _declineChallenge(fromUid),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
