import './room_model.dart';

enum GameStatus {
  WAITING('WAITING'),
  IN_PROGRESS('IN_PROGRESS'),
  FINISHED('FINISHED');

  const GameStatus(this.value);
  final String value;

  static GameStatus fromString(String value) {
    return GameStatus.values.firstWhere((e) => e.value == value);
  }
}

class GameModel {
  final String id;
  final String roomId;
  final String roomCode;
  final GameMode gameMode;
  final Difficulty difficulty;
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final GameStatus status;

  GameModel({
    required this.id,
    required this.roomId,
    required this.roomCode,
    required this.gameMode,
    required this.difficulty,
    required this.questions,
    required this.currentQuestionIndex,
    required this.startedAt,
    this.finishedAt,
    required this.status,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'].toString(),
      roomId: json['roomId'].toString(),
      roomCode: json['roomCode'],
      gameMode: GameMode.fromString(json['gameMode']),
      difficulty: Difficulty.fromString(json['difficulty']),
      questions: (json['questions'] as List?)?.map((q) => QuestionModel.fromJson(q)).toList() ?? [],
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      startedAt: DateTime.parse(json['startedAt']),
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt']) : null,
      status: GameStatus.fromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'roomCode': roomCode,
      'gameMode': gameMode.value,
      'difficulty': difficulty.value,
      'questions': questions.map((q) => q.toJson()).toList(),
      'currentQuestionIndex': currentQuestionIndex,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'status': status.value,
    };
  }
}

class QuestionModel {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String category;
  final Difficulty difficulty;
  final String? explanation;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.difficulty,
    this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Backend envia 'questionText', fallback para 'question' e 'text'
    final questionText = json['questionText'] ?? json['question'] ?? json['text'] ?? '';
    // Backend envia category como objeto {id, name, displayName}, extrair o nome
    final rawCategory = json['category'];
    final categoryStr = (rawCategory is Map)
        ? (rawCategory['name'] ?? rawCategory['displayName'] ?? '')
        : (rawCategory?.toString() ?? '');

    return QuestionModel(
      id: json['id'],
      question: questionText,
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      category: categoryStr,
      difficulty: Difficulty.fromString(json['difficulty'] ?? 'MEDIUM'),
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'category': category,
      'difficulty': difficulty.value,
      'explanation': explanation,
    };
  }
}

class AnswerRequest {
  final String userId;
  final int questionId;
  final int selectedAnswer;
  final int timeSpent;

  AnswerRequest({
    required this.userId,
    required this.questionId,
    required this.selectedAnswer,
    required this.timeSpent,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'questionId': questionId,
      'selectedAnswer': selectedAnswer,
      'timeSpent': timeSpent,
    };
  }
}

class AnswerResponse {
  final String id;
  final String userId;
  final int questionId;
  final int selectedAnswer;
  final bool isCorrect;
  final int timeSpent;
  final int points;
  final DateTime answeredAt;
  final int? correctAnswer;
  final String? explanation;
  final int? totalPoints;

  AnswerResponse({
    this.id = '0',
    this.userId = '0',
    required this.questionId,
    this.selectedAnswer = 0,
    required this.isCorrect,
    this.timeSpent = 0,
    required this.points,
    DateTime? answeredAt,
    this.correctAnswer,
    this.explanation,
    this.totalPoints,
  }) : answeredAt = answeredAt ?? DateTime.now();

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    int? parsedCorrectAnswer;
    if (json['correctAnswer'] is num) {
      parsedCorrectAnswer = (json['correctAnswer'] as num).toInt();
    } else if (json['correctAnswer'] != null) {
      parsedCorrectAnswer = int.tryParse(json['correctAnswer'].toString());
    }

    return AnswerResponse(
      id: json['id']?.toString() ?? '0',
      userId: json['userId']?.toString() ?? json['playerId']?.toString() ?? '0',
      questionId: (json['questionId'] as num?)?.toInt() ?? 0,
      selectedAnswer: (json['selectedAnswer'] as num?)?.toInt() ?? 0,
      isCorrect: json['isCorrect'] ?? false,
      timeSpent: (json['timeSpent'] ?? json['timeToAnswer'] as num?)?.toInt() ?? 0,
      points: (json['points'] ?? json['pointsEarned'] as num?)?.toInt() ?? 0,
      answeredAt: json['answeredAt'] != null ? DateTime.parse(json['answeredAt']) : null,
      correctAnswer: parsedCorrectAnswer,
      explanation: json['explanation'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'questionId': questionId,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'points': points,
      'answeredAt': answeredAt.toIso8601String(),
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (totalPoints != null) 'totalPoints': totalPoints,
    };
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String fullName;
  final String? avatar;
  final TeamColor? team;
  final int score;
  final int correctAnswers;
  final int totalAnswers;
  final double averageTime;
  final int position;
  final int coinsEarned;
  final int xpEarned;
  final int? activeBannerId;
  final int? activePhraseId;
  final int? activeAvatarId;
  final int? activeFrameId;
  final bool isVip;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatar,
    this.team,
    required this.score,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.averageTime,
    required this.position,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.activeBannerId,
    this.activePhraseId,
    this.activeAvatarId,
    this.activeFrameId,
    this.isVip = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    double avgTime = 0.0;
    if (json['totalTime'] != null && json['totalQuestions'] != null && json['totalQuestions'] > 0) {
      avgTime = (json['totalTime'] as num).toDouble() / 1000.0 / (json['totalQuestions'] as num).toDouble();
    } else if (json['averageTime'] != null) {
      avgTime = (json['averageTime'] as num).toDouble();
    }

    return LeaderboardEntry(
      userId: json['userId'].toString(),
      username: json['username'] ?? 'Unknown',
      fullName: json['fullName'] ?? json['username'] ?? 'Unknown',
      avatar: json['avatar'],
      team: json['team'] != null ? TeamColor.fromString(json['team']) : null,
      score: json['totalPoints'] ?? json['score'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalAnswers: json['totalQuestions'] ?? json['totalAnswers'] ?? 0,
      averageTime: avgTime,
      position: json['position'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      activeBannerId: json['activeBannerId'],
      activePhraseId: json['activePhraseId'],
      activeAvatarId: json['activeAvatarId'],
      activeFrameId: json['activeFrameId'],
      isVip: json['isVip'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
      'team': team?.value,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalAnswers': totalAnswers,
      'averageTime': averageTime,
      'position': position,
      'coinsEarned': coinsEarned,
      'xpEarned': xpEarned,
      'activeBannerId': activeBannerId,
      'activePhraseId': activePhraseId,
      'activeAvatarId': activeAvatarId,
      'activeFrameId': activeFrameId,
      'isVip': isVip,
    };
  }
}

class GameStats {
  final String gameId;
  final int totalQuestions;
  final int totalPlayers;
  final int totalTeams;
  final Duration averageQuestionTime;
  final Map<String, int> categoryStats;
  final Map<String, dynamic> teamStats;

  GameStats({
    required this.gameId,
    required this.totalQuestions,
    required this.totalPlayers,
    required this.totalTeams,
    required this.averageQuestionTime,
    required this.categoryStats,
    required this.teamStats,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      gameId: json['gameId'].toString(),
      totalQuestions: json['totalQuestions'],
      totalPlayers: json['totalPlayers'],
      totalTeams: json['totalTeams'],
      averageQuestionTime: Duration(milliseconds: json['averageQuestionTime']),
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
      teamStats: Map<String, dynamic>.from(json['teamStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'totalQuestions': totalQuestions,
      'totalPlayers': totalPlayers,
      'totalTeams': totalTeams,
      'averageQuestionTime': averageQuestionTime.inMilliseconds,
      'categoryStats': categoryStats,
      'teamStats': teamStats,
    };
  }
}
