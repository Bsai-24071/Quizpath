import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/friend_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/user_avatar.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  Map<String, dynamic>? _foundUser;
  bool _isLoading = false;
  bool _requestSent = false;

  Future<void> _searchUser() async {
    final searchQuery = _searchController.text.trim();
    
    if (searchQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email or username')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _foundUser = null;
      _requestSent = false;
    });
    
    try {
      print('Searching for: $searchQuery');

      QuerySnapshot querySnapshot;
      
      if (searchQuery.contains('@')) {

        print('Searching by email in Firestore');
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: searchQuery)
            .limit(1)
            .get();
        print('Query completed. Found ${querySnapshot.docs.length} users in Firestore');

        if (querySnapshot.docs.isEmpty) {
          print('User not in Firestore, creating basic profile...');
          
          try {

            final emailUsername = searchQuery.split('@')[0];
            final displayName = emailUsername.substring(0, 1).toUpperCase() + 
                               emailUsername.substring(1);

            final newUserRef = FirebaseFirestore.instance.collection('users').doc();
            await newUserRef.set({
              'uid': newUserRef.id,
              'username': displayName,
              'email': searchQuery,
              'avatarUrl': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=5c6bc0&color=fff&size=200',
              'online': false,
              'lastActive': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'profileCreatedBy': 'friend_search',
            });
            
            print('Created basic profile for user');

            final newUserDoc = await newUserRef.get();
            final userData = newUserDoc.data() as Map<String, dynamic>;
            
            setState(() => _foundUser = {...userData, 'uid': newUserRef.id});
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User found! You can send them a friend request.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          } catch (e) {
            print('Error creating user profile: $e');
            setState(() => _foundUser = null);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating profile: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }
      } else {

        print('Searching by username');
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: searchQuery)
            .limit(1)
            .get();
        print('Query completed. Found ${querySnapshot.docs.length} users');
      }

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        final userUid = userDoc.id;
        
        print('Found user: ${userData['username']} (${userData['email']})');

        if (userUid == _friendService.currentUserId) {
          setState(() => _foundUser = null);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You cannot add yourself as a friend'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        setState(() => _foundUser = {...userData, 'uid': userUid});
      } else {
        print('No user found');
        setState(() => _foundUser = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                searchQuery.contains('@') 
                    ? 'No user found with this email in the system.'
                    : 'No user found with this username',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendRequest() async {
    if (_foundUser == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _friendService.sendFriendRequest(_foundUser!['uid']);
      setState(() => _requestSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
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
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingLarge),
            AppTextField(
              controller: _searchController,
              label: 'Friend Email or Username',
              hint: 'Enter email or username',
              prefixIcon: Icons.person_search_outlined,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textLight),
                      )
                    : const Icon(Icons.search),
                label: const Text('Search User'),
                onPressed: _isLoading ? null : _searchUser,
              ),
            ),
            if (_foundUser != null) ...[
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
                      UserAvatar(
                        avatarUrl: _foundUser!['avatarUrl'],
                        username: _foundUser!['username'] ?? 'Unknown',
                        radius: 50,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        _foundUser!['username'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        _foundUser!['email'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _requestSent
                              ? const Icon(Icons.check_circle_outline)
                              : const Icon(Icons.person_add_outlined),
                          label: Text(
                            _requestSent ? 'Request Sent!' : 'Send Friend Request',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _requestSent ? AppTheme.successColor : AppTheme.primaryColor,
                          ),
                          onPressed: _requestSent || _isLoading ? null : _sendRequest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
