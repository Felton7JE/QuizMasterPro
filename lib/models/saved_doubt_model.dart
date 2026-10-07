class SavedDoubt {
  final int id;
  final String questionText;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String topic;
  final String difficulty;
  final DateTime createdAt;

  SavedDoubt({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.topic,
    required this.difficulty,
    required this.createdAt,
  });

  factory SavedDoubt.fromJson(Map<String, dynamic> json) {
    return SavedDoubt(
      id: json['id'] ?? 0,
      questionText: json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
      topic: json['topic'] ?? 'Geral',
      difficulty: json['difficulty'] ?? 'MEDIO',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
