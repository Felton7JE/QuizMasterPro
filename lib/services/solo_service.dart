import './api_service.dart';

class SoloLevelDto {
  final int levelNumber;
  final String categoryName;
  final String categoryDisplayName;
  final String difficulty;
  final bool unlocked;
  final bool completed;
  final int starsCount;
  final int highScore;
  final bool isBossLevel;
  final String? bossName;
  final String? bossAvatar;
  final int bossLivesRemaining;
  final int requiredStarsToUnlock;

  SoloLevelDto({
    required this.levelNumber,
    required this.categoryName,
    required this.categoryDisplayName,
    required this.difficulty,
    required this.unlocked,
    required this.completed,
    required this.starsCount,
    required this.highScore,
    required this.isBossLevel,
    this.bossName,
    this.bossAvatar,
    required this.bossLivesRemaining,
    required this.requiredStarsToUnlock,
  });

  factory SoloLevelDto.fromJson(Map<String, dynamic> json) {
    return SoloLevelDto(
      levelNumber: json['levelNumber'] ?? 1,
      categoryName: json['categoryName'] ?? '',
      categoryDisplayName: json['categoryDisplayName'] ?? '',
      difficulty: json['difficulty'] ?? 'EASY',
      unlocked: json['unlocked'] ?? false,
      completed: json['completed'] ?? false,
      starsCount: json['starsCount'] ?? 0,
      highScore: json['highScore'] ?? 0,
      isBossLevel: json['isBossLevel'] ?? false,
      bossName: json['bossName'],
      bossAvatar: json['bossAvatar'],
      bossLivesRemaining: json['bossLivesRemaining'] ?? 3,
      requiredStarsToUnlock: json['requiredStarsToUnlock'] ?? 0,
    );
  }
}

class SoloMapResponse {
  final int userId;
  final int currentUnlockedLevel;
  final int totalStars;
  final int currentEnergy;
  final int secondsUntilNextEnergy;
  final List<SoloLevelDto> levels;

  SoloMapResponse({
    required this.userId,
    required this.currentUnlockedLevel,
    required this.totalStars,
    required this.currentEnergy,
    required this.secondsUntilNextEnergy,
    required this.levels,
  });

  factory SoloMapResponse.fromJson(Map<String, dynamic> json) {
    var rawLevels = json['levels'] as List? ?? [];
    List<SoloLevelDto> parsedLevels =
        rawLevels.map((l) => SoloLevelDto.fromJson(l)).toList();

    return SoloMapResponse(
      userId: json['userId'] ?? 0,
      currentUnlockedLevel: json['currentUnlockedLevel'] ?? 1,
      totalStars: json['totalStars'] ?? 0,
      currentEnergy: json['currentEnergy'] ?? 5,
      secondsUntilNextEnergy: json['secondsUntilNextEnergy'] ?? 0,
      levels: parsedLevels,
    );
  }
}

class SoloStartLevelResponse {
  final int levelNumber;
  final String categoryName;
  final String difficulty;
  final bool isBossLevel;
  final String botName;
  final String botAvatar;
  final double botAccuracyRate;
  final int botMinDelayMs;
  final int botMaxDelayMs;
  final String? bossTaunt;
  final List<dynamic> questions;

  SoloStartLevelResponse({
    required this.levelNumber,
    required this.categoryName,
    required this.difficulty,
    required this.isBossLevel,
    required this.botName,
    required this.botAvatar,
    required this.botAccuracyRate,
    required this.botMinDelayMs,
    required this.botMaxDelayMs,
    this.bossTaunt,
    required this.questions,
  });

  factory SoloStartLevelResponse.fromJson(Map<String, dynamic> json) {
    return SoloStartLevelResponse(
      levelNumber: json['levelNumber'] ?? 1,
      categoryName: json['categoryName'] ?? '',
      difficulty: json['difficulty'] ?? 'EASY',
      isBossLevel: json['isBossLevel'] ?? false,
      botName: json['botName'] ?? 'BOT Oponente',
      botAvatar: json['botAvatar'] ?? 'bot_avatar_1',
      botAccuracyRate: (json['botAccuracyRate'] as num?)?.toDouble() ?? 0.7,
      botMinDelayMs: json['botMinDelayMs'] ?? 3000,
      botMaxDelayMs: json['botMaxDelayMs'] ?? 7000,
      bossTaunt: json['bossTaunt'],
      questions: json['questions'] as List? ?? [],
    );
  }
}

class SoloFinishLevelResponse {
  final bool victory;
  final int levelNumber;
  final int starsEarned;
  final int playerScore;
  final int botScore;
  final int xpEarned;
  final int coinsEarned;
  final bool isBossLevel;
  final int bossLivesRemaining;
  final bool checkpointReverted;
  final int newCurrentLevel;
  final String message;

  SoloFinishLevelResponse({
    required this.victory,
    required this.levelNumber,
    required this.starsEarned,
    required this.playerScore,
    required this.botScore,
    required this.xpEarned,
    required this.coinsEarned,
    required this.isBossLevel,
    required this.bossLivesRemaining,
    required this.checkpointReverted,
    required this.newCurrentLevel,
    required this.message,
  });

  factory SoloFinishLevelResponse.fromJson(Map<String, dynamic> json) {
    return SoloFinishLevelResponse(
      victory: json['victory'] ?? false,
      levelNumber: json['levelNumber'] ?? 1,
      starsEarned: json['starsEarned'] ?? 0,
      playerScore: json['playerScore'] ?? 0,
      botScore: json['botScore'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      isBossLevel: json['isBossLevel'] ?? false,
      bossLivesRemaining: json['bossLivesRemaining'] ?? 3,
      checkpointReverted: json['checkpointReverted'] ?? false,
      newCurrentLevel: json['newCurrentLevel'] ?? 1,
      message: json['message'] ?? '',
    );
  }
}

class SoloService {
  final ApiService _api;

  SoloService(this._api);

  Future<SoloMapResponse> getMapProgress(int userId) async {
    final res = await _api.get('/api/solo/map/$userId');
    return SoloMapResponse.fromJson(res);
  }

  Future<SoloStartLevelResponse> startLevel(int userId, int levelNumber) async {
    final res = await _api.get('/api/solo/level/$levelNumber/start?userId=$userId');
    return SoloStartLevelResponse.fromJson(res);
  }

  Future<SoloFinishLevelResponse> finishLevel({
    required int userId,
    required int levelNumber,
    required int playerScore,
    required int botScore,
    required int correctCount,
    required int totalQuestions,
    required List<Map<String, dynamic>> answeredQuestions,
  }) async {
    final requestBody = {
      'userId': userId,
      'levelNumber': levelNumber,
      'playerScore': playerScore,
      'botScore': botScore,
      'correctCount': correctCount,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
    };

    final res = await _api.post('/api/solo/level/finish', requestBody);
    return SoloFinishLevelResponse.fromJson(res);
  }

  Future<List<dynamic>> getFreeModeQuestions(List<int> seenIds, int limit) async {
    final res = await _api.postList(
      '/api/solo/free-mode/questions?limit=$limit',
      seenIds,
    );
    return res;
  }

  Future<Map<String, dynamic>> submitFreeModeScore(int userId, String gameMode, int score, int streak) async {
    final requestBody = {
      'gameMode': gameMode,
      'score': score,
      'streak': streak,
    };
    final res = await _api.post('/api/solo/free-mode/score?userId=$userId', requestBody);
    return res;
  }

  Future<List<dynamic>> getFreeModeLeaderboard(String gameMode) async {
    final res = await _api.getList('/api/solo/free-mode/leaderboard/$gameMode');
    return res;
  }

  Future<String> getCorrectAnswerText(int questionId) async {
    final res = await _api.get('/api/solo/question/$questionId/answer');
    return res['correctAnswerText'] as String;
  }
}
