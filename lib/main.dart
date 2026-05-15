import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/friends/add_friend_screen.dart';
import 'screens/friends/friend_requests_screen.dart';
import 'services/friend_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase already initialized: $e');
  }
  runApp(const QuizPathApp());
}

class QuizPathApp extends StatefulWidget {
  const QuizPathApp({super.key});

  @override
  State<QuizPathApp> createState() => _QuizPathAppState();
}

class _QuizPathAppState extends State<QuizPathApp> with WidgetsBindingObserver {
  final FriendService _friendService = FriendService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _friendService.setUserOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _friendService.setUserOnlineStatus(false);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizPath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/friends': (context) => const FriendsScreen(),
        '/add_friend': (context) => const AddFriendScreen(),
        '/friend_requests': (context) => const FriendRequestsScreen(),
      },
    );
  }
}
