import 'dart:convert';

class CustomStudyQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String hint;
  final String topic;
  final String difficulty;

  const CustomStudyQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.hint = 'Revise os conceitos fundamentais do material.',
    this.topic = 'Geral',
    this.difficulty = 'MÉDIO',
  });

  factory CustomStudyQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return CustomStudyQuestion(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      questionText: json['questionText'] as String? ?? json['question'] as String? ?? '',
      options: rawOptions,
      correctAnswer: (json['correctAnswer'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? 'Sem explicação detalhada disponível.',
      hint: json['hint'] as String? ?? 'Preste atenção aos conceitos fundamentais do texto.',
      topic: json['topic'] as String? ?? 'Geral',
      difficulty: json['difficulty'] as String? ?? 'MÉDIO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'hint': hint,
      'topic': topic,
      'difficulty': difficulty,
    };
  }
}

class StudyFlashcard {
  final String id;
  final String front;
  final String back;
  final String topic;
  final bool isMastered;

  const StudyFlashcard({
    required this.id,
    required this.front,
    required this.back,
    this.topic = 'Geral',
    this.isMastered = false,
  });

  StudyFlashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? topic,
    bool? isMastered,
  }) {
    return StudyFlashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      topic: topic ?? this.topic,
      isMastered: isMastered ?? this.isMastered,
    );
  }

  factory StudyFlashcard.fromJson(Map<String, dynamic> json) {
    return StudyFlashcard(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      topic: json['topic'] as String? ?? 'Geral',
      isMastered: json['isMastered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'topic': topic,
      'isMastered': isMastered,
    };
  }
}

class CustomStudyQuiz {
  final String id;
  final String title;
  final String description;
  final String sourceType; // 'PDF', 'TEXT', 'TOPIC'
  final String? sourceFileName;
  final DateTime createdAt;
  final int questionCount;
  final int crystalsCost;
  final List<CustomStudyQuestion> questions;
  final List<StudyFlashcard> flashcards;
  final List<String> summaryBullets;
  final int? bestScore;
  final bool isShared;
  final String? shareCode;

  const CustomStudyQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.sourceType,
    this.sourceFileName,
    required this.createdAt,
    required this.questionCount,
    this.crystalsCost = 5,
    required this.questions,
    this.flashcards = const [],
    this.summaryBullets = const [],
    this.bestScore,
    this.isShared = false,
    this.shareCode,
  });

  CustomStudyQuiz copyWith({
    String? id,
    String? title,
    String? description,
    String? sourceType,
    String? sourceFileName,
    DateTime? createdAt,
    int? questionCount,
    int? crystalsCost,
    List<CustomStudyQuestion>? questions,
    List<StudyFlashcard>? flashcards,
    List<String>? summaryBullets,
    int? bestScore,
    bool? isShared,
    String? shareCode,
  }) {
    return CustomStudyQuiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      createdAt: createdAt ?? this.createdAt,
      questionCount: questionCount ?? this.questionCount,
      crystalsCost: crystalsCost ?? this.crystalsCost,
      questions: questions ?? this.questions,
      flashcards: flashcards ?? this.flashcards,
      summaryBullets: summaryBullets ?? this.summaryBullets,
      bestScore: bestScore ?? this.bestScore,
      isShared: isShared ?? this.isShared,
      shareCode: shareCode ?? this.shareCode,
    );
  }

  factory CustomStudyQuiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final rawFlashcards = json['flashcards'] as List<dynamic>? ?? [];
    final rawBullets = json['summaryBullets'] as List<dynamic>? ?? [];

    return CustomStudyQuiz(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Quiz de Estudo',
      description: json['description'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'TEXT',
      sourceFileName: json['sourceFileName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? rawQuestions.length,
      crystalsCost: (json['crystalsCost'] as num?)?.toInt() ?? 5,
      questions: rawQuestions
          .map((q) => CustomStudyQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      flashcards: rawFlashcards
          .map((f) => StudyFlashcard.fromJson(f as Map<String, dynamic>))
          .toList(),
      summaryBullets: rawBullets.map((b) => b.toString()).toList(),
      bestScore: (json['bestScore'] as num?)?.toInt(),
      isShared: json['isShared'] as bool? ?? false,
      shareCode: json['shareCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sourceType': sourceType,
      'sourceFileName': sourceFileName,
      'createdAt': createdAt.toIso8601String(),
      'questionCount': questionCount,
      'crystalsCost': crystalsCost,
      'questions': questions.map((q) => q.toJson()).toList(),
      'flashcards': flashcards.map((f) => f.toJson()).toList(),
      'summaryBullets': summaryBullets,
      'bestScore': bestScore,
      'isShared': isShared,
      'shareCode': shareCode,
    };
  }

  static String encodeList(List<CustomStudyQuiz> quizzes) {
    return jsonEncode(quizzes.map((q) => q.toJson()).toList());
  }

  static List<CustomStudyQuiz> decodeList(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((item) => CustomStudyQuiz.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class UniqueKey {
  static int _counter = 0;
  @override
  String toString() => 'q_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
