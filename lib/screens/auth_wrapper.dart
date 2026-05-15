import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FriendService _friendService = FriendService();
  bool _hasSetOnlineStatus = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) {

          if (!_hasSetOnlineStatus) {
            _hasSetOnlineStatus = true;
            _friendService.setUserOnlineStatus(true);
          }
          return const HomeScreen();
        } else {
          _hasSetOnlineStatus = false;
          return const LoginScreen();
        }
      },
    );
  }
}
