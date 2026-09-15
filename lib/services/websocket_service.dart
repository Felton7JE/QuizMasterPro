import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

/// Evento recebido via WebSocket quando o host inicia o jogo.
class GameStartedEvent {
  final String roomCode;
  final String gameId;
  final DateTime startsAt;
  /// Mapa de userId -> categoryName para todos os jogadores da sala
  final Map<String, String?> playerCategories;

  GameStartedEvent({
    required this.roomCode,
    required this.gameId,
    required this.startsAt,
    required this.playerCategories,
  });

  factory GameStartedEvent.fromJson(Map<String, dynamic> json) {
    final Map<String, String?> categories = {};
    final list = json['playerCategories'] as List<dynamic>? ?? [];
    for (final entry in list) {
      final userId = entry['userId']?.toString() ?? '';
      final catName = entry['categoryName']?.toString();
      if (userId.isNotEmpty) {
        categories[userId] = catName;
      }
    }
    return GameStartedEvent(
      roomCode: json['roomCode'] ?? '',
      gameId: json['gameId']?.toString() ?? '',
      startsAt: json['startsAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startsAt'] as int)
          : DateTime.now().add(const Duration(seconds: 3)),
      playerCategories: categories,
    );
  }
}

/// Evento recebido via WebSocket quando o modo Kahoot avança para a próxima pergunta.
class NextQuestionEvent {
  final String roomCode;
  final String gameId;
  final int questionIndex;
  final int totalQuestions;
  final bool isLastQuestion;
  final Map<String, dynamic> questionData;

  NextQuestionEvent({
    required this.roomCode,
    required this.gameId,
    required this.questionIndex,
    required this.totalQuestions,
    required this.isLastQuestion,
    required this.questionData,
  });

  factory NextQuestionEvent.fromJson(Map<String, dynamic> json) {
    return NextQuestionEvent(
      roomCode: json['roomCode'] ?? '',
      gameId: json['gameId']?.toString() ?? '',
      questionIndex: (json['questionIndex'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      isLastQuestion: json['isLastQuestion'] == true,
      questionData: (json['questionData'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Evento recebido via WebSocket quando o jogo Kahoot termina.
class GameEndedEvent {
  final String roomCode;
  final String gameId;

  GameEndedEvent({required this.roomCode, required this.gameId});

  factory GameEndedEvent.fromJson(Map<String, dynamic> json) {
    return GameEndedEvent(
      roomCode: json['roomCode'] ?? '',
      gameId: json['gameId']?.toString() ?? '',
    );
  }
}

/// Evento recebido via WebSocket quando uma frase/chat é enviada durante o jogo.
class InGameChatMessageEvent {
  final String roomCode;
  final String userId;
  final String username;
  final String phraseText;
  final String? avatar;
  final bool isVip;
  final int? activeFrameId;
  final int? activePhraseId;
  final DateTime timestamp;

  InGameChatMessageEvent({
    required this.roomCode,
    required this.userId,
    required this.username,
    required this.phraseText,
    this.avatar,
    this.isVip = false,
    this.activeFrameId,
    this.activePhraseId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory InGameChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return InGameChatMessageEvent(
      roomCode: json['roomCode']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Jogador',
      phraseText: json['phraseText']?.toString() ?? json['message']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      isVip: json['isVip'] == true,
      activeFrameId: json['activeFrameId'] as int?,
      activePhraseId: json['activePhraseId'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'CHAT_MESSAGE',
      'roomCode': roomCode,
      'userId': userId,
      'username': username,
      'phraseText': phraseText,
      'avatar': avatar,
      'isVip': isVip,
      'activeFrameId': activeFrameId,
      'activePhraseId': activePhraseId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Evento recebido via WebSocket quando o Leaderboard é atualizado.
class LeaderboardUpdateEvent {
  final String roomCode;
  final dynamic payload;

  LeaderboardUpdateEvent({required this.roomCode, required this.payload});

  factory LeaderboardUpdateEvent.fromJson(Map<String, dynamic> json) {
    return LeaderboardUpdateEvent(
      roomCode: json['roomCode'] ?? '',
      payload: json['payload'],
    );
  }
}

/// Serviço singleton que gere a ligação WebSocket STOMP ao backend Spring.
class WebSocketService {
  static String get _wsUrl => AppConfig.wsUrl;

  StompClient? _client;
  bool _connected = false;
  String? _subscribedRoom;

  /// Callback chamado quando o evento GAME_STARTED é recebido
  Function(GameStartedEvent)? onGameStarted;

  /// Callback chamado quando o evento NEXT_QUESTION é recebido (modo Kahoot)
  Function(NextQuestionEvent)? onNextQuestion;

  /// Callback chamado quando o evento GAME_ENDED é recebido (modo Kahoot)
  Function(GameEndedEvent)? onGameEnded;

  /// Callback chamado quando o Leaderboard é atualizado
  Function(LeaderboardUpdateEvent)? onLeaderboardUpdate;

  /// Callback chamado quando um amigo fica online ou offline
  Function(Map<String, dynamic>)? onFriendStatusUpdate;

  /// Callback chamado quando uma frase/chat em jogo é recebida
  Function(InGameChatMessageEvent)? onChatMessage;

  /// Callback chamado quando o evento RETURN_TO_LOBBY é recebido
  Function()? onReturnToLobby;

  /// Callback chamado quando o evento REMATCH_REQUEST é recebido
  Function(String)? onRematchRequest;

  /// Callback chamado quando a ligação é estabelecida
  Function()? onConnected;

  /// Callback chamado quando a ligação falha
  Function(String error)? onError;

  /// Callback chamado quando o WebSocket desconecta
  Function()? onDisconnected;

  bool get isConnected => _connected;

  /// Liga ao servidor WebSocket.
  void connect({
    String? roomCode,
    String? userId,
    Function(GameStartedEvent)? onGameStarted,
    Function(NextQuestionEvent)? onNextQuestion,
    Function(GameEndedEvent)? onGameEnded,
    Function(LeaderboardUpdateEvent)? onLeaderboardUpdate,
    Function(Map<String, dynamic>)? onFriendStatusUpdate,
    Function(InGameChatMessageEvent)? onChatMessage,
    Function()? onReturnToLobby,
    Function(String)? onRematchRequest,
    Function()? onConnected,
    Function()? onDisconnected,
    Function(String)? onError,
  }) {
    this.onGameStarted = onGameStarted;
    this.onNextQuestion = onNextQuestion;
    this.onGameEnded = onGameEnded;
    this.onLeaderboardUpdate = onLeaderboardUpdate;
    this.onFriendStatusUpdate = onFriendStatusUpdate;
    this.onChatMessage = onChatMessage;
    this.onReturnToLobby = onReturnToLobby;
    this.onRematchRequest = onRematchRequest;
    this.onConnected = onConnected;
    this.onDisconnected = onDisconnected;
    this.onError = onError;
    _subscribedRoom = roomCode;

    if (kDebugMode) debugPrint('🔌 WebSocket: A ligar a $_wsUrl para sala $roomCode...');

    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        webSocketConnectHeaders: {
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
        stompConnectHeaders: {
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
          if (userId != null) 'userId': userId,
        },
        onConnect: _onConnect,
        onDisconnect: (_) {
          _connected = false;
          if (kDebugMode) debugPrint('🔌 WebSocket: Desligado');
          this.onDisconnected?.call();
        },
        onStompError: (frame) {
          _connected = false;
          final msg = frame.body ?? 'Erro desconhecido';
          if (kDebugMode) debugPrint('❌ WebSocket STOMP error: $msg');
          this.onError?.call(msg);
        },
        onWebSocketError: (error) {
          _connected = false;
          final msg = error.toString();
          if (kDebugMode) debugPrint('❌ WebSocket error: $msg');
          this.onError?.call(msg);
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    if (kDebugMode) debugPrint('✅ WebSocket: Ligado com sucesso!');
    onConnected?.call();

    if (_subscribedRoom != null && _subscribedRoom!.isNotEmpty) {
      _subscribeToRoom(_subscribedRoom!);
    }
  }

  void subscribeToFriendStatus(String userId) {
    if (_client == null || !_connected) return;

    final topic = '/topic/friends/$userId/status';
    if (kDebugMode) debugPrint('📡 WebSocket: A subscrever status de amigos: $topic');

    _client!.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          onFriendStatusUpdate?.call(json);
        } catch (e) {
          if (kDebugMode) debugPrint('❌ WebSocket: Erro ao parsear status de amigo: $e');
        }
      },
    );
  }

  void _subscribeToRoom(String roomCode) {
    if (_client == null || !_connected) return;

    final topic = '/topic/room/$roomCode';
    if (kDebugMode) debugPrint('📡 WebSocket: A subscrever $topic');

    _client!.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          final type = json['type'] as String?;
          if (kDebugMode) debugPrint('📨 WebSocket: Evento recebido: $type');

          if (type == 'GAME_STARTED') {
            final event = GameStartedEvent.fromJson(json);
            onGameStarted?.call(event);
          } else if (type == 'NEXT_QUESTION') {
            final event = NextQuestionEvent.fromJson(json);
            onNextQuestion?.call(event);
          } else if (type == 'GAME_ENDED') {
            final event = GameEndedEvent.fromJson(json);
            onGameEnded?.call(event);
          } else if (type == 'LEADERBOARD_UPDATE') {
            final event = LeaderboardUpdateEvent.fromJson(json);
            onLeaderboardUpdate?.call(event);
          } else if (type == 'CHAT_MESSAGE' || type == 'IN_GAME_CHAT') {
            final event = InGameChatMessageEvent.fromJson(json);
            onChatMessage?.call(event);
          } else if (type == 'RETURN_TO_LOBBY') {
            onReturnToLobby?.call();
          } else if (type == 'REMATCH_REQUEST') {
            final requesterName = json['requesterName'] as String?;
            if (requesterName != null) {
              onRematchRequest?.call(requesterName);
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ WebSocket: Erro a processar evento: $e');
        }
      },
    );
  }

  /// Envia uma frase/mensagem de chat durante o jogo
  void sendChatMessage(String roomCode, InGameChatMessageEvent message) {
    if (_client == null || !_connected) {
      if (kDebugMode) debugPrint('⚠️ WebSocket: Não conectado para enviar mensagem de chat');
      return;
    }

    final destination = '/app/room/$roomCode/chat';
    final payload = jsonEncode(message.toJson());
    if (kDebugMode) debugPrint('💬 WebSocket: Enviando chat para $destination: $payload');

    _client!.send(
      destination: destination,
      body: payload,
    );
  }

  /// Muda a sala subscrita
  void changeRoom(String newRoomCode) {
    _subscribedRoom = newRoomCode;
    if (_connected) {
      _subscribeToRoom(newRoomCode);
    }
  }

  /// Desliga o WebSocket
  void disconnect() {
    _client?.deactivate();
    _client = null;
    _connected = false;
    _subscribedRoom = null;
    if (kDebugMode) debugPrint('🔌 WebSocket: Desligado manualmente');
  }
}
