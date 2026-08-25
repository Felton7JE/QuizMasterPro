class MissionModel {
  final int id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final int rewardCoins;
  final bool isCompleted;
  final bool rewardClaimed;
  final String type;
  final int? rewardItemId;
  final String? rewardItemType;
  final String? rewardItemName;
  final String? rewardItemValue;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.rewardCoins,
    required this.isCompleted,
    required this.rewardClaimed,
    required this.type,
    this.rewardItemId,
    this.rewardItemType,
    this.rewardItemName,
    this.rewardItemValue,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetValue: json['targetValue'],
      currentValue: json['currentValue'],
      rewardCoins: json['rewardCoins'],
      isCompleted: json['isCompleted'],
      rewardClaimed: json['rewardClaimed'],
      type: json['type'] ?? 'DAILY',
      rewardItemId: json['rewardItemId'],
      rewardItemType: json['rewardItemType'],
      rewardItemName: json['rewardItemName'],
      rewardItemValue: json['rewardItemValue'],
    );
  }
}
