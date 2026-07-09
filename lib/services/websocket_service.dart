import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

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
  static const String _wsUrl = 'ws://localhost:8080/ws/websocket';

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

  /// Callback chamado quando o evento RETURN_TO_LOBBY é recebido
  Function()? onReturnToLobby;

  /// Callback chamado quando a ligação é estabelecida
  Function()? onConnected;

  /// Callback chamado quando a ligação falha
  Function(String error)? onError;

  bool get isConnected => _connected;

  /// Liga ao servidor WebSocket.
  void connect({
    required String roomCode,
    Function(GameStartedEvent)? onGameStarted,
    Function(NextQuestionEvent)? onNextQuestion,
    Function(GameEndedEvent)? onGameEnded,
    Function(LeaderboardUpdateEvent)? onLeaderboardUpdate,
    Function()? onReturnToLobby,
    Function()? onConnected,
    Function(String)? onError,
  }) {
    this.onGameStarted = onGameStarted;
    this.onNextQuestion = onNextQuestion;
    this.onGameEnded = onGameEnded;
    this.onLeaderboardUpdate = onLeaderboardUpdate;
    this.onReturnToLobby = onReturnToLobby;
    this.onConnected = onConnected;
    this.onError = onError;
    _subscribedRoom = roomCode;

    if (kDebugMode) print('🔌 WebSocket: A ligar a $_wsUrl para sala $roomCode...');

    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: _onConnect,
        onDisconnect: (_) {
          _connected = false;
          if (kDebugMode) print('🔌 WebSocket: Desligado');
        },
        onStompError: (frame) {
          _connected = false;
          final msg = frame.body ?? 'Erro desconhecido';
          if (kDebugMode) print('❌ WebSocket STOMP error: $msg');
          this.onError?.call(msg);
        },
        onWebSocketError: (error) {
          _connected = false;
          final msg = error.toString();
          if (kDebugMode) print('❌ WebSocket error: $msg');
          this.onError?.call(msg);
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 0),
        heartbeatOutgoing: const Duration(seconds: 0),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    if (kDebugMode) print('✅ WebSocket: Ligado com sucesso!');
    onConnected?.call();

    if (_subscribedRoom != null) {
      _subscribeToRoom(_subscribedRoom!);
    }
  }

  void _subscribeToRoom(String roomCode) {
    if (_client == null || !_connected) return;

    final topic = '/topic/room/$roomCode';
    if (kDebugMode) print('📡 WebSocket: A subscrever $topic');

    _client!.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          final type = json['type'] as String?;
          if (kDebugMode) print('📨 WebSocket: Evento recebido: $type');

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
          } else if (type == 'RETURN_TO_LOBBY') {
            onReturnToLobby?.call();
          }
        } catch (e) {
          if (kDebugMode) print('❌ WebSocket: Erro a processar evento: $e');
        }
      },
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
    if (kDebugMode) print('🔌 WebSocket: Desligado manualmente');
  }
}
