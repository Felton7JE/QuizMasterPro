class FriendModel {
  final int id;
  final String username;
  final String? avatar;
  final int level;
  final String currentLeague;
  final bool isOnline;
  final int? friendshipId;

  FriendModel({
    required this.id,
    required this.username,
    this.avatar,
    required this.level,
    required this.currentLeague,
    required this.isOnline,
    this.friendshipId,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as int,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      level: json['level'] as int? ?? 1,
      currentLeague: json['currentLeague'] as String? ?? 'BRONZE',
      isOnline: json['isOnline'] == true || json['online'] == true, // Handle different boolean keys just in case
      friendshipId: json['friendshipId'] as int?,
    );
  }

  FriendModel copyWith({
    int? id,
    String? username,
    String? avatar,
    int? level,
    String? currentLeague,
    bool? isOnline,
    int? friendshipId,
  }) {
    return FriendModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      currentLeague: currentLeague ?? this.currentLeague,
      isOnline: isOnline ?? this.isOnline,
      friendshipId: friendshipId ?? this.friendshipId,
    );
  }
}
