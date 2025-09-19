import 'room_model.dart';

// Modelo independente para questões por categoria
class QuestionData {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswer; // índice (0..n)
  final String category; // ex: MATH
  final Difficulty difficulty;
  final String? explanation;
  final int order; // ordem dentro da categoria

  QuestionData({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.difficulty,
    required this.order,
    this.explanation,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    // ignore: avoid_print
    print('🟡 DEBUG QuestionData: fromJson chamado com: $json');
    
    try {
      final question = QuestionData(
        id: json['id'],
        question: json['question'] ?? json['text'] ?? '',
        options: List<String>.from(json['options'] ?? const []),
        correctAnswer: json['correctAnswer'] ?? json['correct_index'] ?? 0,
        category: json['category'] ?? '',
        difficulty: Difficulty.fromString(json['difficulty'] ?? 'MEDIUM'),
        order: json['order'] ?? json['orderIndex'] ?? 0,
        explanation: json['explanation'],
      );
      
      // ignore: avoid_print
      print('🟡 DEBUG QuestionData: Questão criada com sucesso - id: ${question.id}');
      
      return question;
    } catch (e) {
      // ignore: avoid_print
      print('❌ ERRO QuestionData: Erro ao criar questão - $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'category': category,
        'difficulty': difficulty.value,
        'order': order,
        'explanation': explanation,
      };
}
