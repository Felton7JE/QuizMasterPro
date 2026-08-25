class SeasonReward {
  final int id;
  final int levelRequired;
  final String freeRewardType;
  final String? freeRewardValue;
  final String? premiumRewardType;
  final String? premiumRewardValue;
  final String? freeRewardImageUrl;
  final String? premiumRewardImageUrl;
  final bool isBossLevel;
  final String? bossName;
  final String? bossImageUrl;

  SeasonReward({
    required this.id,
    required this.levelRequired,
    required this.freeRewardType,
    this.freeRewardValue,
    this.premiumRewardType,
    this.premiumRewardValue,
    this.freeRewardImageUrl,
    this.premiumRewardImageUrl,
    this.isBossLevel = false,
    this.bossName,
    this.bossImageUrl,
  });

  factory SeasonReward.fromJson(Map<String, dynamic> json) {
    return SeasonReward(
      id: json['id'] ?? 0,
      levelRequired: json['levelRequired'] ?? 1,
      freeRewardType: json['freeRewardType'] ?? 'COIN',
      freeRewardValue: json['freeRewardValue'],
      premiumRewardType: json['premiumRewardType'],
      premiumRewardValue: json['premiumRewardValue'],
      freeRewardImageUrl: json['freeRewardImageUrl'],
      premiumRewardImageUrl: json['premiumRewardImageUrl'],
      isBossLevel: json['bossLevel'] ?? json['isBossLevel'] ?? false,
      bossName: json['bossName'],
      bossImageUrl: json['bossImageUrl'],
    );
  }
}

class SeasonResponse {
  final int seasonId;
  final String name;
  final String description;
  final int currentLevel;
  final int seasonPoints;
  final bool isPremium;
  final int? exclusiveCategoryId;
  final List<SeasonReward> rewards;
  final int lastClaimedFreeLevel;
  final int lastClaimedPremiumLevel;
  final String? bannerUrl;
  final String? mapBackgroundUrl;
  final String? lockedNodeIconUrl;
  final String? currentNodeIconUrl;
  final String? completedNodeIconUrl;

  SeasonResponse({
    required this.seasonId,
    required this.name,
    required this.description,
    required this.currentLevel,
    required this.seasonPoints,
    required this.isPremium,
    this.exclusiveCategoryId,
    required this.rewards,
    required this.lastClaimedFreeLevel,
    required this.lastClaimedPremiumLevel,
    this.bannerUrl,
    this.mapBackgroundUrl,
    this.lockedNodeIconUrl,
    this.currentNodeIconUrl,
    this.completedNodeIconUrl,
  });

  factory SeasonResponse.fromJson(Map<String, dynamic> json) {
    var rawRewards = json['rewards'] as List? ?? [];
    List<SeasonReward> parsedRewards =
        rawRewards.map((r) => SeasonReward.fromJson(r)).toList();

    return SeasonResponse(
      seasonId: json['seasonId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      currentLevel: json['currentLevel'] ?? 1,
      seasonPoints: json['seasonPoints'] ?? 0,
      isPremium: json['premium'] ?? false,
      exclusiveCategoryId: json['exclusiveCategoryId'],
      rewards: parsedRewards,
      lastClaimedFreeLevel: json['lastClaimedFreeLevel'] ?? 0,
      lastClaimedPremiumLevel: json['lastClaimedPremiumLevel'] ?? 0,
      bannerUrl: json['bannerUrl'],
      mapBackgroundUrl: json['mapBackgroundUrl'],
      lockedNodeIconUrl: json['lockedNodeIconUrl'],
      currentNodeIconUrl: json['currentNodeIconUrl'],
      completedNodeIconUrl: json['completedNodeIconUrl'],
    );
  }
}
