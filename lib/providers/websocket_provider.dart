import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';

/// Provider que expõe o WebSocket ao resto da aplicação Flutter via Provider.
class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _service = WebSocketService();

  bool _connected = false;
  String? _lastError;
  GameStartedEvent? _lastGameStartedEvent;
  NextQuestionEvent? _lastNextQuestionEvent;
  GameEndedEvent? _lastGameEndedEvent;
  LeaderboardUpdateEvent? _lastLeaderboardUpdateEvent;
  bool _returnToLobbyEvent = false;

  bool get isConnected => _connected;
  String? get lastError => _lastError;
  GameStartedEvent? get lastGameStartedEvent => _lastGameStartedEvent;
  NextQuestionEvent? get lastNextQuestionEvent => _lastNextQuestionEvent;
  GameEndedEvent? get lastGameEndedEvent => _lastGameEndedEvent;
  LeaderboardUpdateEvent? get lastLeaderboardUpdateEvent => _lastLeaderboardUpdateEvent;
  bool get returnToLobbyEvent => _returnToLobbyEvent;


  /// Liga ao WebSocket e subscreve a sala.
  void connectToRoom(String roomCode) {
    if (_service.isConnected) {
      _service.changeRoom(roomCode);
      return;
    }

    _service.connect(
      roomCode: roomCode,
      onConnected: () {
        _connected = true;
        _lastError = null;
        if (kDebugMode) print('✅ WebSocketProvider: Ligado');
        notifyListeners();
      },
      onGameStarted: (event) {
        if (kDebugMode) {
          print('🎮 WebSocketProvider: GAME_STARTED recebido!');
          print('   gameId: ${event.gameId}');
          print('   startsAt: ${event.startsAt}');
        }
        _lastGameStartedEvent = event;
        notifyListeners();
      },
      onNextQuestion: (event) {
        if (kDebugMode) {
          print('➡️ WebSocketProvider: NEXT_QUESTION recebido!');
          print('   questionIndex: ${event.questionIndex}/${event.totalQuestions}');
          print('   isLast: ${event.isLastQuestion}');
        }
        _lastNextQuestionEvent = event;
        notifyListeners();
      },
      onGameEnded: (event) {
        if (kDebugMode) {
          print('🏁 WebSocketProvider: GAME_ENDED recebido!');
          print('   gameId: ${event.gameId}');
        }
        _lastGameEndedEvent = event;
        notifyListeners();
      },
      onLeaderboardUpdate: (event) {
        if (kDebugMode) {
          print('📊 WebSocketProvider: LEADERBOARD_UPDATE recebido!');
        }
        _lastLeaderboardUpdateEvent = event;
        notifyListeners();
      },
      onReturnToLobby: () {
        if (kDebugMode) {
          print('🏠 WebSocketProvider: RETURN_TO_LOBBY recebido!');
        }
        _returnToLobbyEvent = true;
        notifyListeners();
      },
      onError: (error) {
        _connected = false;
        _lastError = error;
        if (kDebugMode) print('❌ WebSocketProvider: Erro: $error');
        notifyListeners();
      },
    );
  }

  /// Obtém a categoria atribuída a um jogador específico no último evento GAME_STARTED.
  String? getCategoryForPlayer(String userId) {
    return _lastGameStartedEvent?.playerCategories[userId];
  }

  /// Limpa o evento GAME_STARTED (após navegação)
  void clearGameStartedEvent() {
    _lastGameStartedEvent = null;
  }

  /// Limpa o evento NEXT_QUESTION (após consumir)
  void clearNextQuestionEvent() {
    _lastNextQuestionEvent = null;
  }

  /// Limpa o evento GAME_ENDED (após consumir)
  void clearGameEndedEvent() {
    _lastGameEndedEvent = null;
  }

  /// Limpa o evento LEADERBOARD_UPDATE
  void clearLeaderboardUpdateEvent() {
    _lastLeaderboardUpdateEvent = null;
  }

  /// Limpa o evento RETURN_TO_LOBBY
  void clearReturnToLobbyEvent() {
    _returnToLobbyEvent = false;
  }

  void disconnect() {
    _service.disconnect();
    _connected = false;
    _lastGameStartedEvent = null;
    _lastNextQuestionEvent = null;
    _lastGameEndedEvent = null;
    _lastLeaderboardUpdateEvent = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}
