class FriendModel {
  final String uid;
  final String username;
  final String avatarUrl;

  FriendModel({
    required this.uid,
    required this.username,
    required this.avatarUrl,
  });

  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'avatarUrl': avatarUrl,
    };
  }
}
