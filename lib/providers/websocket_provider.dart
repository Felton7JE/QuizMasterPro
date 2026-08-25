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
  InGameChatMessageEvent? _lastChatMessageEvent;
  bool _returnToLobbyEvent = false;
  String? _rematchRequesterName;

  bool get isConnected => _connected;
  String? get lastError => _lastError;
  GameStartedEvent? get lastGameStartedEvent => _lastGameStartedEvent;
  NextQuestionEvent? get lastNextQuestionEvent => _lastNextQuestionEvent;
  GameEndedEvent? get lastGameEndedEvent => _lastGameEndedEvent;
  LeaderboardUpdateEvent? get lastLeaderboardUpdateEvent => _lastLeaderboardUpdateEvent;
  InGameChatMessageEvent? get lastChatMessageEvent => _lastChatMessageEvent;
  bool get returnToLobbyEvent => _returnToLobbyEvent;
  String? get rematchRequesterName => _rematchRequesterName;


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
        if (kDebugMode) debugPrint('✅ WebSocketProvider: Ligado');
        notifyListeners();
      },
      onGameStarted: (event) {
        if (kDebugMode) {
          debugPrint('🎮 WebSocketProvider: GAME_STARTED recebido!');
          debugPrint('   gameId: ${event.gameId}');
          debugPrint('   startsAt: ${event.startsAt}');
        }
        _lastGameStartedEvent = event;
        notifyListeners();
      },
      onNextQuestion: (event) {
        if (kDebugMode) {
          debugPrint('➡️ WebSocketProvider: NEXT_QUESTION recebido!');
          debugPrint('   questionIndex: ${event.questionIndex}/${event.totalQuestions}');
          debugPrint('   isLast: ${event.isLastQuestion}');
        }
        _lastNextQuestionEvent = event;
        notifyListeners();
      },
      onGameEnded: (event) {
        if (kDebugMode) {
          debugPrint('🏁 WebSocketProvider: GAME_ENDED recebido!');
          debugPrint('   gameId: ${event.gameId}');
        }
        _lastGameEndedEvent = event;
        notifyListeners();
      },
      onLeaderboardUpdate: (event) {
        if (kDebugMode) {
          debugPrint('📊 WebSocketProvider: LEADERBOARD_UPDATE recebido!');
        }
        _lastLeaderboardUpdateEvent = event;
        notifyListeners();
      },
      onChatMessage: (event) {
        if (kDebugMode) {
          debugPrint('💬 WebSocketProvider: CHAT_MESSAGE recebido de ${event.username}: "${event.phraseText}"');
        }
        _lastChatMessageEvent = event;
        notifyListeners();
      },
      onReturnToLobby: () {
        if (kDebugMode) {
          debugPrint('🏠 WebSocketProvider: RETURN_TO_LOBBY recebido!');
        }
        _returnToLobbyEvent = true;
        notifyListeners();
      },
      onRematchRequest: (requesterName) {
        if (kDebugMode) {
          debugPrint('⚔️ WebSocketProvider: REMATCH_REQUEST recebido de $requesterName!');
        }
        _rematchRequesterName = requesterName;
        notifyListeners();
      },
      onDisconnected: () {
        _connected = false;
        _lastError = 'Conexão perdida com o servidor';
        if (kDebugMode) debugPrint('⚠️ WebSocketProvider: Desconectado');
        notifyListeners();
      },
      onError: (error) {
        _connected = false;
        _lastError = error;
        if (kDebugMode) debugPrint('❌ WebSocketProvider: Erro: $error');
        notifyListeners();
      },
    );
  }

  /// Envia mensagem de chat durante a partida
  void sendChatMessage(String roomCode, InGameChatMessageEvent message) {
    _service.sendChatMessage(roomCode, message);
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

  /// Limpa o evento CHAT_MESSAGE
  void clearChatMessageEvent() {
    _lastChatMessageEvent = null;
  }

  /// Limpa o evento RETURN_TO_LOBBY
  void clearReturnToLobbyEvent() {
    _returnToLobbyEvent = false;
  }

  /// Limpa o evento REMATCH_REQUEST
  void clearRematchRequestEvent() {
    _rematchRequesterName = null;
  }

  void disconnect() {
    _service.disconnect();
    _connected = false;
    _lastGameStartedEvent = null;
    _lastNextQuestionEvent = null;
    _lastGameEndedEvent = null;
    _lastLeaderboardUpdateEvent = null;
    _lastChatMessageEvent = null;
    _rematchRequesterName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}
