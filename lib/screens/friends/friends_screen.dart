import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/friend_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'match_challenges_screen.dart';
import 'match_lobby_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendService _friendService = FriendService();
  StreamSubscription? _challengeSubscription;
  final Set<String> _processedMatches = {};

  @override
  void initState() {
    super.initState();
    _cleanupOldChallenges();
    _listenForAcceptedChallenges();
  }

  @override
  void dispose() {
    _challengeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cleanupOldChallenges() async {

    await _friendService.cleanupAllAcceptedChallenges();
  }

  void _showCategoryDialog(String friendUid, String username, String avatarUrl) {
    final categories = [
      {'name': 'General', 'icon': Icons.quiz_outlined, 'color': AppTheme.generalColor},
      {'name': 'History', 'icon': Icons.history_edu_outlined, 'color': AppTheme.historyColor},
      {'name': 'Science', 'icon': Icons.science_outlined, 'color': AppTheme.scienceColor},
      {'name': 'Math', 'icon': Icons.calculate_outlined, 'color': AppTheme.mathColor},
      {'name': 'Computers', 'icon': Icons.computer_outlined, 'color': AppTheme.computersColor},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        title: Row(
          children: [
            UserAvatar(
              avatarUrl: avatarUrl,
              username: username,
              radius: 20,
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Text(
                'Challenge $username',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a category:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ...categories.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
              child: Material(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  onTap: () async {
                    Navigator.pop(context);
                    await _sendChallengeWithCategory(
                      friendUid,
                      username,
                      category['name'] as String,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          color: category['color'] as Color,
                          size: AppTheme.iconSizeLarge,
                        ),
                        const SizedBox(width: AppTheme.spacingMedium),
                        Text(
                          category['name'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChallengeWithCategory(
    String friendUid,
    String username,
    String category,
  ) async {
    try {
      await _friendService.sendMatchChallenge(friendUid, category);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$category challenge sent to $username!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _listenForAcceptedChallenges() {
    print('Started listening for accepted challenges');
    _challengeSubscription = _friendService.getSentChallengesStream().listen((challenges) async {
      print('Received challenge update: ${challenges.length} accepted challenges');
      if (challenges.isNotEmpty && mounted) {
        final acceptedChallenge = challenges.first;
        final matchId = acceptedChallenge['matchId'] as String?;
        final targetUid = acceptedChallenge['targetUid'] as String?;
        
        print('Accepted challenge found! matchId: $matchId, targetUid: $targetUid');

        if (matchId != null && !_processedMatches.contains(matchId)) {
          _processedMatches.add(matchId);
          
          if (targetUid != null && mounted) {

            _challengeSubscription?.pause();

            print('Cleaning up accepted challenge');
            try {
              await _friendService.cancelSentChallenge(targetUid);
            } catch (e) {
              print('Error cleaning up challenge: $e');
            }

            print('Navigating to match lobby: $matchId');
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchLobbyScreen(matchId: matchId),
                ),
              ).then((_) {

                _challengeSubscription?.resume();
              });
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friendService.getMatchChallengesStream(),
            builder: (context, snapshot) {
              final challengeCount = snapshot.data?.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sports_esports),
                    tooltip: 'Match Challenges',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MatchChallengesScreen(),
                        ),
                      );
                    },
                  ),
                  if (challengeCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$challengeCount',
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Friend',
            onPressed: () => Navigator.pushNamed(context, '/add_friend'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Friend Requests',
            onPressed: () => Navigator.pushNamed(context, '/friend_requests'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendService.getFriendsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data ?? <Map<String, dynamic>>[];
          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'No friends yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    'Add some friends to start playing!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add Friend'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/add_friend'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final friendUid = (friend['friendUid'] ?? '') as String;
              final username = (friend['username'] ?? 'Unknown') as String;
              final avatarUrl = (friend['avatarUrl'] ?? '') as String;
              final isOnline = (friend['online'] ?? false) as bool;

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                elevation: AppTheme.elevationLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                            avatarUrl: avatarUrl,
                            username: username,
                            radius: 28,
                          ),

                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.cardBackground,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppTheme.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isOnline ? Icons.circle : Icons.circle_outlined,
                                  size: 12,
                                  color: isOnline ? AppTheme.successColor : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? 'Online' : 'Offline',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isOnline ? AppTheme.successColor : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      FutureBuilder<bool>(
                        future: _friendService.hasPendingChallenge(friendUid),
                        builder: (context, snapshot) {
                          final hasPending = snapshot.data ?? false;
                          
                          if (hasPending) {

                            return ElevatedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningColor,
                                foregroundColor: AppTheme.textLight,
                              ),
                              onPressed: friendUid.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await _friendService.cancelSentChallenge(friendUid);
                                        if (mounted) {
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Challenge cancelled'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to cancel: $e'),
                                              backgroundColor: AppTheme.errorColor,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            );
                          }

                          return ElevatedButton.icon(
                            icon: const Icon(Icons.sports_esports_outlined, size: 18),
                            label: const Text('Challenge'),
                            onPressed: friendUid.isEmpty
                                ? null
                                : () => _showCategoryDialog(friendUid, username, avatarUrl),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_friend'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Friend'),
      ),
    );
  }
}
