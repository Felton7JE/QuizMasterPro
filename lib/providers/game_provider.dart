import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../services/game_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService;
  
  GameModel? _currentGame;
  List<QuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  QuestionModel? _currentQuestion;
  List<LeaderboardEntry> _leaderboard = [];
  Map<String, dynamic>? _gameResults;
  GameStats? _gameStats;
  List<AnswerResponse> _playerAnswers = [];
  bool _isLoading = false;
  String? _error;
  Timer? _questionTimer;
  int _remainingTime = 0;

  GameProvider(this._gameService);

  GameModel? get currentGame => _currentGame;
  List<QuestionModel> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  QuestionModel? get currentQuestion => _currentQuestion;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  Map<String, dynamic>? get gameResults => _gameResults;
  GameStats? get gameStats => _gameStats;
  List<AnswerResponse> get playerAnswers => _playerAnswers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get remainingTime => _remainingTime;
  bool get hasNextQuestion => _currentQuestionIndex < _questions.length - 1;
  bool get isGameFinished => _currentGame?.status == GameStatus.FINISHED;

  Future<bool> loadGameQuestions(String gameId, String userId) async {
    _setLoading(true);
    try {
      _questions = await _gameService.getGameQuestions(gameId, userId);
      _currentQuestionIndex = 0;
      if (_questions.isNotEmpty) {
        _currentQuestion = _questions[0];
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadCurrentQuestion(String gameId, int questionIndex) async {
    try {
      _currentQuestion = await _gameService.getCurrentQuestion(gameId, questionIndex);
      _currentQuestionIndex = questionIndex;
      
      // Atualizar a questão na lista se necessário
      if (questionIndex < _questions.length) {
        _questions[questionIndex] = _currentQuestion!;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitAnswer({
    required String gameId,
    required String userId,
    required int questionId,
    required int selectedAnswer,
    required int timeSpent,
  }) async {
    try {
      final answer = AnswerRequest(
        userId: userId,
        questionId: questionId,
        selectedAnswer: selectedAnswer,
        timeSpent: timeSpent,
      );
      
      final answerResponse = await _gameService.submitAnswer(gameId, answer);
      _playerAnswers.add(answerResponse);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadLiveLeaderboard(String gameId) async {
    try {
      _leaderboard = await _gameService.getLiveLeaderboard(gameId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFinalLeaderboard(String gameId) async {
    try {
      _leaderboard = await _gameService.getFinalLeaderboard(gameId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGameResults(String gameId) async {
    try {
      _gameResults = await _gameService.getGameResults(gameId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGameStats(String gameId) async {
    try {
      _gameStats = await _gameService.getGameStats(gameId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPlayerAnswers(String gameId, String playerId) async {
    try {
      _playerAnswers = await _gameService.getPlayerAnswers(gameId, playerId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> finishGame(String gameId, String hostId) async {
    _setLoading(true);
    try {
      await _gameService.finishGame(gameId, hostId);
      await loadGameResults(gameId);
      await loadFinalLeaderboard(gameId);
      await loadGameStats(gameId);
      _stopQuestionTimer();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> nextQuestion(String gameId, String hostId) async {
    try {
      await _gameService.nextQuestion(gameId, hostId);
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex];
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void startQuestionTimer(int duration) {
    _stopQuestionTimer();
    _remainingTime = duration;
    notifyListeners();
    
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  void moveToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _currentQuestion = _questions[_currentQuestionIndex];
      notifyListeners();
    }
  }

  void resetGame() {
    _currentGame = null;
    _questions = [];
    _currentQuestionIndex = 0;
    _currentQuestion = null;
    _leaderboard = [];
    _gameResults = null;
    _gameStats = null;
    _playerAnswers = [];
    _error = null;
    _stopQuestionTimer();
    _remainingTime = 0;
    notifyListeners();
  }

  void setCurrentGame(GameModel game) {
    _currentGame = game;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  LeaderboardEntry? getPlayerPosition(String userId) {
    return _leaderboard.cast<LeaderboardEntry?>().firstWhere(
      (entry) => entry?.userId == userId,
      orElse: () => null,
    );
  }

  int getPlayerScore(String userId) {
    final entry = getPlayerPosition(userId);
    return entry?.score ?? 0;
  }

  @override
  void dispose() {
    _stopQuestionTimer();
    super.dispose();
  }
}
