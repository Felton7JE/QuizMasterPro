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
  final int currentStreak;
  final int coins;
  final int crystals;
  final int energy;
  final int xp;
  final int level;
  final String currentLeague;
  final int eloPoints;
  final DateTime? lastPlayedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? activeBannerId;
  final int? activeTitleId;
  final int? activePhraseId;
  final int? activeAvatarId;
  final int? activeFrameId;
  final int? activeEmoteId;
  final bool isVip;
  final int dailyAiQuizCount;
  final DateTime? lastAiQuizTimestamp;
  final String? referralCode;
  final int referralCount;

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
    this.currentStreak = 0,
    this.coins = 500,
    this.crystals = 100,
    this.energy = 100,
    this.xp = 0,
    this.level = 1,
    this.currentLeague = 'BRONZE',
    this.eloPoints = 0,
    this.lastPlayedDate,
    this.createdAt,
    this.updatedAt,
    this.activeBannerId,
    this.activeTitleId,
    this.activePhraseId,
    this.activeAvatarId,
    this.activeFrameId,
    this.activeEmoteId,
    this.isVip = false,
    this.dailyAiQuizCount = 0,
    this.lastAiQuizTimestamp,
    this.referralCode,
    this.referralCount = 0,
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
      currentStreak: json['currentStreak'] ?? 0,
      coins: json['coins'] ?? 500,
      crystals: json['crystals'] ?? 100,
      energy: json['energy'] ?? 100,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      currentLeague: json['currentLeague'] ?? 'BRONZE',
      eloPoints: json['eloPoints'] ?? 0,
      lastPlayedDate: json['lastPlayedDate'] != null ? DateTime.parse(json['lastPlayedDate']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      activeBannerId: json['activeBannerId'],
      activeTitleId: json['activeTitleId'],
      activePhraseId: json['activePhraseId'],
      activeAvatarId: json['activeAvatarId'],
      activeFrameId: json['activeFrameId'],
      activeEmoteId: json['activeEmoteId'],
      isVip: json['isVip'] ?? false,
      dailyAiQuizCount: json['dailyAiQuizCount'] ?? 0,
      lastAiQuizTimestamp: json['lastAiQuizTimestamp'] != null ? DateTime.tryParse(json['lastAiQuizTimestamp']) : null,
      referralCode: json['referralCode'],
      referralCount: json['referralCount'] ?? 0,
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
      'currentStreak': currentStreak,
      'coins': coins,
      'crystals': crystals,
      'energy': energy,
      'xp': xp,
      'level': level,
      'currentLeague': currentLeague,
      'eloPoints': eloPoints,
      'lastPlayedDate': lastPlayedDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'activeBannerId': activeBannerId,
      'activeTitleId': activeTitleId,
      'activePhraseId': activePhraseId,
      'activeAvatarId': activeAvatarId,
      'activeFrameId': activeFrameId,
      'activeEmoteId': activeEmoteId,
      'isVip': isVip,
      'dailyAiQuizCount': dailyAiQuizCount,
      'lastAiQuizTimestamp': lastAiQuizTimestamp?.toIso8601String(),
      'referralCode': referralCode,
      'referralCount': referralCount,
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
    int? currentStreak,
    int? coins,
    int? crystals,
    int? energy,
    int? xp,
    int? level,
    String? currentLeague,
    int? eloPoints,
    DateTime? lastPlayedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? activeBannerId,
    int? activeTitleId,
    int? activePhraseId,
    int? activeAvatarId,
    int? activeFrameId,
    int? activeEmoteId,
    bool? isVip,
    int? dailyAiQuizCount,
    DateTime? lastAiQuizTimestamp,
    String? referralCode,
    int? referralCount,
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
      currentStreak: currentStreak ?? this.currentStreak,
      coins: coins ?? this.coins,
      crystals: crystals ?? this.crystals,
      energy: energy ?? this.energy,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentLeague: currentLeague ?? this.currentLeague,
      eloPoints: eloPoints ?? this.eloPoints,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeBannerId: activeBannerId ?? this.activeBannerId,
      activeTitleId: activeTitleId ?? this.activeTitleId,
      activePhraseId: activePhraseId ?? this.activePhraseId,
      activeAvatarId: activeAvatarId ?? this.activeAvatarId,
      activeFrameId: activeFrameId ?? this.activeFrameId,
      activeEmoteId: activeEmoteId ?? this.activeEmoteId,
      isVip: isVip ?? this.isVip,
      dailyAiQuizCount: dailyAiQuizCount ?? this.dailyAiQuizCount,
      lastAiQuizTimestamp: lastAiQuizTimestamp ?? this.lastAiQuizTimestamp,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
    );
  }

  UserModel clearEquipment(String type) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      avatar: type == 'AVATAR' ? '' : avatar,
      totalPoints: totalPoints,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      accuracy: accuracy,
      bestStreak: bestStreak,
      currentStreak: currentStreak,
      coins: coins,
      crystals: crystals,
      energy: energy,
      xp: xp,
      level: level,
      currentLeague: currentLeague,
      eloPoints: eloPoints,
      lastPlayedDate: lastPlayedDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      activeBannerId: type == 'BANNER' ? null : activeBannerId,
      activeTitleId: type == 'TITLE' ? null : activeTitleId,
      activePhraseId: type == 'TEXT_PHRASE' ? null : activePhraseId,
      activeAvatarId: type == 'AVATAR' ? null : activeAvatarId,
      activeFrameId: type == 'PROFILE_FRAME' ? null : activeFrameId,
      activeEmoteId: (type == 'EMOTE' || type == 'EMOJI') ? null : activeEmoteId,
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
