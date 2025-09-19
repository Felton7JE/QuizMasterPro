import '../models/game_model.dart';
import 'api_service.dart';

/// Serviço alinhado ao GameController do backend (endpoints reais).
class GameService {
  final ApiService _apiService;
  GameService(this._apiService);

  /// GET /api/games/{gameId}/questions?userId=XX
  /// Backend retorna LISTA direta (não um objeto com chave "questions").
  Future<List<QuestionModel>> getGameQuestions(String gameId, String userId) async {
    final list = await _apiService.getList('/api/games/$gameId/questions?userId=$userId');
    return list.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
  }

  Future<QuestionModel> getQuestionByIndex(String gameId, int questionIndex) async {
    final response = await _apiService.get('/api/games/$gameId/questions/$questionIndex');
    return QuestionModel.fromJson(response);
  }

 
  /// GET /api/games/{gameId}/players/{userId}/current-question (questão do jogador)
  Future<QuestionModel> getCurrentQuestionForPlayer(String gameId, String userId) async {
    final response = await _apiService.get('/api/games/$gameId/players/$userId/current-question');
    return QuestionModel.fromJson(response);
  }



 Future<AnswerResponse> submitAnswer(String gameId, AnswerRequest answer) async {
    final body = {
      'userId': answer.userId,
      'selectedAnswer': answer.selectedAnswer,
      'timeToAnswer': answer.timeSpent, // mapeando timeSpent -> timeToAnswer
    };
    final response = await _apiService.post('/api/games/$gameId/answers', body);
    return AnswerResponse.fromJson(response);
  }

  /// GET /api/games/{gameId}/leaderboard/live => lista direta
  Future<List<LeaderboardEntry>> getLiveLeaderboard(String gameId) async {
    final list = await _apiService.getList('/api/games/$gameId/leaderboard/live');
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/games/{gameId}/leaderboard => lista direta
  Future<List<LeaderboardEntry>> getFinalLeaderboard(String gameId) async {
    final list = await _apiService.getList('/api/games/$gameId/leaderboard');
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/games/{gameId}/results -> objeto de resultados (mantemos Map dinâmico)
  Future<Map<String, dynamic>> getGameResults(String gameId) async {
    return await _apiService.get('/api/games/$gameId/results');
  }

  /// GET /api/games/{gameId}/stats -> GameStats
  Future<GameStats> getGameStats(String gameId) async {
    final response = await _apiService.get('/api/games/$gameId/stats');
    return GameStats.fromJson(response);
  }

  /// GET /api/games/{gameId}/players/{userId}/answers => lista direta
  Future<List<AnswerResponse>> getPlayerAnswers(String gameId, String playerId) async {
    final list = await _apiService.getList('/api/games/$gameId/players/$playerId/answers');
    return list.map((a) => AnswerResponse.fromJson(a as Map<String, dynamic>)).toList();
  }

  /// POST /api/games/{gameId}/finish?hostId=XX -> retorna GameResultResponse (Map)
  Future<Map<String, dynamic>> finishGame(String gameId, String hostId) async {
    return await _apiService.post('/api/games/$gameId/finish?hostId=$hostId');
  }

  /// GET /api/games/{gameId}
  Future<GameModel> getGameDetails(String gameId) async {
    final response = await _apiService.get('/api/games/$gameId');
    return GameModel.fromJson(response);
  }

  /// POST /api/games/{gameId}/pause?hostId=XX
  Future<void> pauseGame(String gameId, String hostId) async {
    await _apiService.post('/api/games/$gameId/pause?hostId=$hostId');
  }

  /// POST /api/games/{gameId}/resume?hostId=XX
  Future<void> resumeGame(String gameId, String hostId) async {
    await _apiService.post('/api/games/$gameId/resume?hostId=$hostId');
  }

  /// POST /api/games/{gameId}/next?hostId=XX -> retorna próxima questão
  Future<QuestionModel> nextQuestion(String gameId, String hostId) async {
    final response = await _apiService.post('/api/games/$gameId/next?hostId=$hostId');
    return QuestionModel.fromJson(response);
  }
}
