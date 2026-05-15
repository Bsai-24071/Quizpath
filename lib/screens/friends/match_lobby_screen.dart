import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/friend_match_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'friend_match_screen.dart';

class MatchLobbyScreen extends StatefulWidget {
  final String matchId;
  const MatchLobbyScreen({super.key, required this.matchId});

  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  final FriendMatchService _matchService = FriendMatchService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<dynamic, dynamic>? _matchData;
  Map<String, String> _playerNames = {};
  Map<String, String> _playerAvatars = {};
  bool _isLoading = true;
  bool _hasJoined = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _matchService.getMatchStream(widget.matchId).listen((event) {
      if (mounted && !_hasNavigated) {
        final matchData = event.snapshot.value as Map<dynamic, dynamic>?;
        print('Match stream update: $matchData');
        
        setState(() {
          _matchData = matchData;

          if (_isLoading && matchData != null) {
            _isLoading = false;
          }
        });

        if (matchData != null && !_hasJoined && matchData['status'] == 'waiting') {
          _hasJoined = true;
          final currentUid = _matchService.currentUserId;
          print('Auto-joining match for user: $currentUid');
          _matchService.joinMatch(widget.matchId);
        }

        if (matchData?['status'] == 'active' && !_hasNavigated) {
          _hasNavigated = true;
          print('✅ Match is ACTIVE! Navigating to game screen NOW...');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendMatchScreen(matchId: widget.matchId),
                ),
              );
            }
          });
        }
      }
    });

    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      print('Loading player names for match: ${widget.matchId}');

      final matchSnapshot = await _matchService
          .getMatchStream(widget.matchId)
          .first
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('Timeout loading match data');
              throw TimeoutException('Match data load timeout');
            },
          );
      
      final matchData = matchSnapshot.snapshot.value as Map<dynamic, dynamic>?;
      
      if (matchData == null) {
        print('Match data is null, using placeholder names');
        return;
      }
      
      print('Match data loaded: $matchData');
      final player1Uid = matchData['player1'] as String?;
      final player2Uid = matchData['player2'] as String?;
      
      if (player1Uid == null || player2Uid == null) {
        print('Player UIDs are null');
        return;
      }
      
      print('Fetching player names for $player1Uid and $player2Uid');

      try {
        final player1Doc = await _firestore
            .collection('users')
            .doc(player1Uid)
            .get()
            .timeout(const Duration(seconds: 3));
        final player2Doc = await _firestore
            .collection('users')
            .doc(player2Uid)
            .get()
            .timeout(const Duration(seconds: 3));
        
        if (!mounted) return;
        
        setState(() {
          _playerNames = {
            player1Uid: player1Doc.data()?['username'] ?? 'Player 1',
            player2Uid: player2Doc.data()?['username'] ?? 'Player 2',
          };
          _playerAvatars = {
            player1Uid: player1Doc.data()?['avatarUrl'] ?? '',
            player2Uid: player2Doc.data()?['avatarUrl'] ?? '',
          };
        });
        
        print('Player names loaded: $_playerNames');
      } catch (e) {
        print('Error loading player names: $e (continuing anyway)');
      }
    } catch (e) {
      print('Error in _loadPlayerData: $e (continuing anyway)');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _matchData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Match Lobby'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _matchData!['status'];
    final player1Uid = _matchData!['player1'] as String;
    final player2Uid = _matchData!['player2'] as String;
    final isCreator = player1Uid == _matchService.currentUserId;
    final bothPlayersReady = status == 'active';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Match Lobby'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports_outlined,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerCard(
                      _playerNames[player1Uid] ?? 'Player 1',
                      _playerAvatars[player1Uid] ?? '',
                      true,
                    ),
                    Text(
                      'VS',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    _buildPlayerCard(
                      _playerNames[player2Uid] ?? 'Player 2',
                      _playerAvatars[player2Uid] ?? '',
                      bothPlayersReady,
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingXLarge),
                
                if (!bothPlayersReady)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Text(
                        'Waiting for ${_playerNames[player2Uid] ?? 'friend'} to join...',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 60,
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Text(
                        'Both players ready!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),
                      if (isCreator)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FriendMatchScreen(matchId: widget.matchId),
                                ),
                              );
                            },
                            child: const Text('Start Match'),
                          ),
                        )
                      else
                        Text(
                          'Waiting for host to start...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(String name, String avatarUrl, bool isReady) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isReady ? AppTheme.primaryColor : AppTheme.textSecondary,
              width: 3,
            ),
          ),
          child: UserAvatar(
            avatarUrl: avatarUrl,
            username: name,
            radius: 40,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isReady ? AppTheme.successColor : AppTheme.warningColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Text(
            isReady ? 'Ready' : 'Waiting...',
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
