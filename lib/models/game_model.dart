import 'room_model.dart';

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
    return QuestionModel(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      category: json['category'],
      difficulty: Difficulty.fromString(json['difficulty']),
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

  AnswerResponse({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeSpent,
    required this.points,
    required this.answeredAt,
  });

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      questionId: json['questionId'],
      selectedAnswer: json['selectedAnswer'],
      isCorrect: json['isCorrect'],
      timeSpent: json['timeSpent'],
      points: json['points'],
      answeredAt: DateTime.parse(json['answeredAt']),
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
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'].toString(),
      username: json['username'],
      fullName: json['fullName'],
      avatar: json['avatar'],
      team: json['team'] != null ? TeamColor.fromString(json['team']) : null,
      score: json['score'],
      correctAnswers: json['correctAnswers'],
      totalAnswers: json['totalAnswers'],
      averageTime: (json['averageTime'] ?? 0).toDouble(),
      position: json['position'],
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
