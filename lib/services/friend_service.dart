import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> sendFriendRequest(String targetUid) async {
    final myUid = currentUserId;
    if (myUid == null) throw Exception('Not signed in');
    
    final myUserDoc = await _firestore.collection('users').doc(myUid).get();
    if (!myUserDoc.exists) throw Exception('Your profile not found');

    final myUserData = myUserDoc.data()!;
    final requestData = {
      'fromUid': myUid,
      'username': myUserData['username'] ?? '',
      'avatarUrl': myUserData['avatarUrl'] ?? '',
    };

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('friendRequests')
        .doc(myUid)
        .set(requestData);
  }

  Future<void> cancelFriendRequest(String targetUid) async {
    final myUid = currentUserId;
    if (myUid == null) return;
    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('friendRequests')
        .doc(myUid)
        .delete();
  }

  Future<void> sendMatchChallenge(String targetUid, String category) async {
    final myUid = currentUserId;
    if (myUid == null) throw Exception('Not signed in');
    
    final existingChallenge = await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('matchChallenges')
        .doc(myUid)
        .get();
    
    if (existingChallenge.exists) {
      final status = existingChallenge.data()?['status'];
      if (status == 'pending') {
        await _firestore
            .collection('users')
            .doc(targetUid)
            .collection('matchChallenges')
            .doc(myUid)
            .delete();
      }
    }
    
    final myUserDoc = await _firestore.collection('users').doc(myUid).get();
    if (!myUserDoc.exists) throw Exception('Your profile not found');

    final myUserData = myUserDoc.data()!;
    final challengeData = {
      'fromUid': myUid,
      'username': myUserData['username'] ?? 'Someone',
      'avatarUrl': myUserData['avatarUrl'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'category': category,
    };

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('matchChallenges')
        .doc(myUid)
        .set(challengeData);
  }

  Stream<List<Map<String, dynamic>>> getMatchChallengesStream() {
    final myUid = currentUserId;
    if (myUid == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(myUid)
        .collection('matchChallenges')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          final now = DateTime.now();
          final validChallenges = <Map<String, dynamic>>[];
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final timestamp = data['timestamp'] as Timestamp?;
            
            if (timestamp != null) {
              final challengeTime = timestamp.toDate();
              final ageInSeconds = now.difference(challengeTime).inSeconds;
              
              if (ageInSeconds > 30) {
                await doc.reference.delete();
                continue;
              }
            }
            
            validChallenges.add({...data, 'id': doc.id});
          }
          
          return validChallenges;
        });
  }

  Stream<List<Map<String, dynamic>>> getSentChallengesStream() async* {
    final myUid = currentUserId;
    if (myUid == null) {
      yield [];
      return;
    }
    
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .get();
    
    if (friendsSnapshot.docs.isEmpty) {
      yield [];
      return;
    }
    
    final controller = StreamController<List<Map<String, dynamic>>>();
    final subscriptions = <StreamSubscription>[];
    
    for (var friendDoc in friendsSnapshot.docs) {
      final friendUid = friendDoc.data()['friendUid'] as String?;
      if (friendUid == null) continue;
      
      final subscription = _firestore
          .collection('users')
          .doc(friendUid)
          .collection('matchChallenges')
          .doc(myUid)
          .snapshots()
          .listen((challengeDoc) async {
        if (challengeDoc.exists) {
          final data = challengeDoc.data();
          if (data?['status'] == 'accepted' && data?['matchId'] != null) {
            final acceptedAt = data?['acceptedAt'] as Timestamp?;
            if (acceptedAt != null) {
              final acceptedTime = acceptedAt.toDate();
              final ageInSeconds = DateTime.now().difference(acceptedTime).inSeconds;
              
              if (ageInSeconds <= 30) {
                print('Real-time detection: Challenge accepted by $friendUid for match ${data!['matchId']}');
                controller.add([{
                  ...data,
                  'id': challengeDoc.id,
                  'targetUid': friendUid,
                }]);
              }
            }
          }
        }
      });
      
      subscriptions.add(subscription);
    }
    
    await for (final challenges in controller.stream) {
      yield challenges;
    }
    
    for (var sub in subscriptions) {
      await sub.cancel();
    }
    await controller.close();
  }

  Future<void> acceptMatchChallenge(String challengerId, String matchId) async {
    final myUid = currentUserId;
    if (myUid == null) throw Exception('Not signed in');

    await _firestore
        .collection('users')
        .doc(myUid)
        .collection('matchChallenges')
        .doc(challengerId)
        .update({
          'status': 'accepted',
          'matchId': matchId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> declineMatchChallenge(String challengerId) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await _firestore
        .collection('users')
        .doc(myUid)
        .collection('matchChallenges')
        .doc(challengerId)
        .delete();
  }

  Future<void> cancelSentChallenge(String targetUid) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('matchChallenges')
        .doc(myUid)
        .delete();
  }

  Future<bool> hasPendingChallenge(String targetUid) async {
    final myUid = currentUserId;
    if (myUid == null) return false;

    final challengeDoc = await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('matchChallenges')
        .doc(myUid)
        .get();

    if (!challengeDoc.exists) return false;
    
    final status = challengeDoc.data()?['status'];
    return status == 'pending';
  }

  Future<void> cleanupAllAcceptedChallenges() async {
    final myUid = currentUserId;
    if (myUid == null) return;

    print('Cleaning up old challenges...');
    
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .get();
    
    for (var friendDoc in friendsSnapshot.docs) {
      final friendUid = friendDoc.data()['friendUid'] as String?;
      if (friendUid == null) continue;
      
      try {
        final challengeDoc = await _firestore
            .collection('users')
            .doc(friendUid)
            .collection('matchChallenges')
            .doc(myUid)
            .get();
        
        if (challengeDoc.exists) {
          final status = challengeDoc.data()?['status'];
          if (status == 'accepted') {
            await challengeDoc.reference.delete();
            print('Deleted old accepted challenge from $friendUid');
          }
        }
      } catch (e) {
        print('Error cleaning challenge from $friendUid: $e');
      }
    }
  }

  Future<void> acceptFriendRequest(String senderUid) async {
    final myUid = currentUserId;
    if (myUid == null) throw Exception('Not signed in');

    final requestDoc = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friendRequests')
        .doc(senderUid)
        .get();

    if (!requestDoc.exists) return;

    final requestData = requestDoc.data()!;
    final friendData = {
      'friendUid': senderUid,
      'username': requestData['username'] ?? '',
      'avatarUrl': requestData['avatarUrl'] ?? '',
    };

    await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(senderUid)
        .set(friendData);

    final currentUserDoc = await _firestore.collection('users').doc(myUid).get();
    final currentUserData = currentUserDoc.data() ?? {};
    final reverseFriendData = {
      'friendUid': myUid,
      'username': currentUserData['username'] ?? '',
      'avatarUrl': currentUserData['avatarUrl'] ?? '',
    };

    await _firestore
        .collection('users')
        .doc(senderUid)
        .collection('friends')
        .doc(myUid)
        .set(reverseFriendData);

    await rejectFriendRequest(senderUid);
  }

  Future<void> rejectFriendRequest(String senderUid) async {
    final myUid = currentUserId;
    if (myUid == null) return;
    await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friendRequests')
        .doc(senderUid)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final myUid = currentUserId;
    if (myUid == null) return Stream.value(<Map<String, dynamic>>[]);
    
    final outputController = StreamController<List<Map<String, dynamic>>>.broadcast();
    StreamSubscription? friendsSubscription;
    List<StreamSubscription>? statusSubscriptions;
    
    friendsSubscription = _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .snapshots()
        .listen((friendsSnapshot) {
          if (statusSubscriptions != null) {
            for (var sub in statusSubscriptions!) {
              sub.cancel();
            }
          }
          
          if (friendsSnapshot.docs.isEmpty) {
            outputController.add(<Map<String, dynamic>>[]);
            return;
          }
          
          final friendsOrder = <String>[];
          final friendsData = <String, Map<String, dynamic>>{};
          
          for (var doc in friendsSnapshot.docs) {
            final data = doc.data();
            final friendUid = data['friendUid'] ?? doc.id;
            friendsOrder.add(friendUid);
            friendsData[friendUid] = {
              'friendUid': friendUid,
              'username': data['username'] ?? 'Unknown',
              'avatarUrl': data['avatarUrl'] ?? '',
              'online': false,
            };
          }
          
          void emitOrderedList() {
            final orderedList = friendsOrder
                .map((uid) => friendsData[uid]!)
                .toList();
            outputController.add(orderedList);
          }
          
          statusSubscriptions = friendsSnapshot.docs.map((doc) {
            final data = doc.data();
            final friendUid = data['friendUid'] ?? doc.id;
            
            return _firestore
                .collection('users')
                .doc(friendUid)
                .snapshots()
                .listen((friendDoc) {
                  if (!friendDoc.exists) return;
                  
                  final friendUserData = friendDoc.data() ?? {};
                  
                  friendsData[friendUid] = {
                    'friendUid': friendUid,
                    'username': data['username'] ?? friendUserData['username'] ?? 'Unknown',
                    'avatarUrl': data['avatarUrl'] ?? friendUserData['avatarUrl'] ?? '',
                    'online': friendUserData['online'] ?? false,
                  };
                  
                  emitOrderedList();
                });
          }).toList();
        });
    
    outputController.onCancel = () {
      friendsSubscription?.cancel();
      if (statusSubscriptions != null) {
        for (var sub in statusSubscriptions!) {
          sub.cancel();
        }
      }
    };
    
    return outputController.stream;
  }

  Stream<List<Map<String, dynamic>>> getFriendRequestsStream() {
    final myUid = currentUserId;
    if (myUid == null) return Stream.value(<Map<String, dynamic>>[]);
    return _firestore
        .collection('users')
        .doc(myUid)
        .collection('friendRequests')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'fromUid': data['fromUid'] ?? doc.id,
                'username': data['username'] ?? '',
                'avatarUrl': data['avatarUrl'] ?? '',
              };
            }).toList());
  }

  Future<void> setUserOnlineStatus(bool isOnline) async {
    final myUid = currentUserId;
    if (myUid == null) return;
    await _firestore.collection('users').doc(myUid).update({
      'online': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getOnlineFriends() {
    final myUid = currentUserId;
    if (myUid == null) return Stream.value(<Map<String, dynamic>>[]);
    return _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((d) => (d['online'] ?? false) == true)
            .map((d) => Map<String, dynamic>.from(d))
            .toList());
  }
}
