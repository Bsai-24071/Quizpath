import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/user_avatar.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendService _friendService = FriendService();

  Future<void> _acceptRequest(String fromUid) async {
    try {
      await _friendService.acceptFriendRequest(fromUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
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

  Future<void> _rejectRequest(String fromUid) async {
    try {
      await _friendService.rejectFriendRequest(fromUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request rejected'),
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
        title: const Text('Friend Requests'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendService.getFriendRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];
          
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'No friend requests',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final username = request['username'] ?? 'Unknown';
              final avatarUrl = request['avatarUrl'] ?? '';
              
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
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'wants to be friends',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        color: AppTheme.successColor,
                        iconSize: 28,
                        tooltip: 'Accept',
                        onPressed: () => _acceptRequest(request['fromUid']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        color: AppTheme.errorColor,
                        iconSize: 28,
                        tooltip: 'Reject',
                        onPressed: () => _rejectRequest(request['fromUid']),
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
