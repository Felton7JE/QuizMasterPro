import '../models/game_model.dart';
import 'api_service.dart';

class GameService {
  final ApiService _apiService;

  GameService(this._apiService);

  Future<List<QuestionModel>> getGameQuestions(String gameId, String userId) async {
    final response = await _apiService.get('/api/games/$gameId/questions?userId=$userId');
    return (response['questions'] as List).map((q) => QuestionModel.fromJson(q)).toList();
  }

  Future<QuestionModel> getCurrentQuestion(String gameId, int questionIndex) async {
    final response = await _apiService.get('/api/games/$gameId/questions/$questionIndex');
    return QuestionModel.fromJson(response);
  }

  Future<AnswerResponse> submitAnswer(String gameId, AnswerRequest answer) async {
    final response = await _apiService.post('/api/games/$gameId/answers', answer.toJson());
    return AnswerResponse.fromJson(response);
  }

  Future<List<LeaderboardEntry>> getLiveLeaderboard(String gameId) async {
    final response = await _apiService.get('/api/games/$gameId/leaderboard/live');
    return (response['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<List<LeaderboardEntry>> getFinalLeaderboard(String gameId) async {
    final response = await _apiService.get('/api/games/$gameId/leaderboard');
    return (response['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getGameResults(String gameId) async {
    return await _apiService.get('/api/games/$gameId/results');
  }

  Future<GameStats> getGameStats(String gameId) async {
    final response = await _apiService.get('/api/games/$gameId/stats');
    return GameStats.fromJson(response);
  }

  Future<List<AnswerResponse>> getPlayerAnswers(String gameId, String playerId) async {
    final response = await _apiService.get('/api/games/$gameId/players/$playerId/answers');
    return (response['answers'] as List).map((a) => AnswerResponse.fromJson(a)).toList();
  }

  Future<void> finishGame(String gameId, String hostId) async {
    await _apiService.post('/api/games/$gameId/finish?hostId=$hostId');
  }

  Future<GameModel> getGameDetails(String gameId) async {
    final response = await _apiService.get('/api/games/$gameId');
    return GameModel.fromJson(response);
  }

  Future<void> pauseGame(String gameId, String hostId) async {
    await _apiService.post('/api/games/$gameId/pause?hostId=$hostId');
  }

  Future<void> resumeGame(String gameId, String hostId) async {
    await _apiService.post('/api/games/$gameId/resume?hostId=$hostId');
  }

  Future<void> nextQuestion(String gameId, String hostId) async {
    await _apiService.post('/api/games/$gameId/next-question?hostId=$hostId');
  }
}
