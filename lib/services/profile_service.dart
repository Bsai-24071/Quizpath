import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String> uploadProfileImage(Uint8List bytes) async {
    if (currentUserId == null) throw Exception('No user logged in');

    try {
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _firestore.collection('users').doc(currentUserId).set({
        'avatarUrl': base64Image,
      }, SetOptions(merge: true));

      return base64Image;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String?> getProfileImageUrl() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data()?['avatarUrl'] as String?;
    } catch (e) {
      print('Error getting profile image: $e');
      return null;
    }
  }
}
