class TitleModel {
  final int id;
  final String name;
  final String description;
  final String conditionType;
  final int conditionValue;

  TitleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionType,
    required this.conditionValue,
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) {
    return TitleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      conditionType: json['conditionType'] as String,
      conditionValue: json['conditionValue'] as int,
    );
  }
}
