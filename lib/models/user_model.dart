class UserModel {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatar;
  final int totalPoints;
  final int gamesPlayed;
  final int gamesWon;
  final double accuracy;
  final int bestStreak;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatar,
    required this.totalPoints,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.accuracy,
    required this.bestStreak,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      avatar: json['avatar'],
      totalPoints: json['totalPoints'] ?? 0,
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      bestStreak: json['bestStreak'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatar': avatar,
      'totalPoints': totalPoints,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'accuracy': accuracy,
      'bestStreak': bestStreak,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? avatar,
    int? totalPoints,
    int? gamesPlayed,
    int? gamesWon,
    double? accuracy,
    int? bestStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      totalPoints: totalPoints ?? this.totalPoints,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      accuracy: accuracy ?? this.accuracy,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CreateUserRequest {
  final String username;
  final String email;
  final String? fullName;
  final String? avatar;

  CreateUserRequest({
    required this.username,
    required this.email,
    this.fullName,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatar': avatar,
    };
  }
}
