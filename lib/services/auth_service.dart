import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Starting signup for $email');

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('AuthService: User created successfully with UID: ${cred.user?.uid}');

      if (cred.user != null) {
        try {
          await cred.user!.updateDisplayName(name);
          print('AuthService: Display name updated to: $name');
        } catch (e) {
          print('AuthService: Failed to update display name: $e');
        }
        
        try {
          await _firestore.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'username': name,
            'email': email,
            'avatarUrl': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=5c6bc0&color=fff&size=200',
            'online': true,
            'lastActive': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('AuthService: Firestore user document created');
        } catch (e) {
          print('AuthService: Failed to create Firestore document: $e');
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('AuthService: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');

      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        default:
          return 'Authentication error: ${e.message}';
      }
    } catch (e) {
      print('AuthService: General exception: $e');
      return 'Unexpected error: $e';
    }
  }

  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Attempting login for $email');
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('AuthService: Login successful for $email');
      
      if (cred.user != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
          
          if (userDoc.exists) {
            await _firestore.collection('users').doc(cred.user!.uid).update({
              'online': true,
              'lastActive': FieldValue.serverTimestamp(),
            });
          } else {
            await _firestore.collection('users').doc(cred.user!.uid).set({
              'uid': cred.user!.uid,
              'username': cred.user!.displayName ?? email.split('@')[0],
              'email': email,
              'avatarUrl': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(cred.user!.displayName ?? email.split('@')[0])}&background=5c6bc0&color=fff&size=200',
              'online': true,
              'lastActive': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });
            print('AuthService: Created missing user document for existing user');
          }
        } catch (e) {
          print('AuthService: Failed to update online status: $e');
        }
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('AuthService: Login error - Code: ${e.code}, Message: ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return 'Login error: ${e.message}';
      }
    } catch (e) {
      print('AuthService: Unexpected error - $e');
      return 'Unexpected error: $e';
    }
  }

  Future<void> signOut() async {
    try {
      if (_auth.currentUser != null) {
        try {
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'online': false,
            'lastActive': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('AuthService: Failed to update online status: $e');
        }
      }
    } catch (e) {
      print('AuthService: Error during signout preparation: $e');
    }
    
    await _auth.signOut();
  }
}
