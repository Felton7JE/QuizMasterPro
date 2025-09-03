enum GameMode { 
  INDIVIDUAL('INDIVIDUAL'), 
  TEAM('TEAM'),
  CLASSIC('CLASSIC'); // ✅ Adicionado: CLASSIC como no Postman
  
  const GameMode(this.value);
  final String value;
  
  static GameMode fromString(String value) {
    return GameMode.values.firstWhere((e) => e.value == value);
  }
}

enum Difficulty { 
  EASY('EASY'), 
  MEDIUM('MEDIUM'), 
  HARD('HARD');
  
  const Difficulty(this.value);
  final String value;
  
  static Difficulty fromString(String value) {
    return Difficulty.values.firstWhere((e) => e.value == value);
  }
}

enum RoomStatus { 
  WAITING('WAITING'), 
  STARTING('STARTING'), 
  IN_PROGRESS('IN_PROGRESS'), 
  FINISHED('FINISHED');
  
  const RoomStatus(this.value);
  final String value;
  
  static RoomStatus fromString(String value) {
    return RoomStatus.values.firstWhere((e) => e.value == value);
  }
}

enum TeamColor { 
  RED('RED'), 
  BLUE('BLUE'), 
  GREEN('GREEN'), 
  YELLOW('YELLOW');
  
  const TeamColor(this.value);
  final String value;
  
  static TeamColor fromString(String value) {
    // Mapeia valores do backend (A, B) para valores do frontend
    switch (value) {
      case 'A':
        return TeamColor.RED;
      case 'B':
        return TeamColor.BLUE;
      default:
        // Para valores que já são do frontend ou desconhecidos
        return TeamColor.values.firstWhere(
          (e) => e.value == value, 
          orElse: () => TeamColor.RED, // Fallback para RED
        );
    }
  }
}

enum CategoryAssignmentMode {
  AUTO('AUTO'), // Automático - sorteio aleatório
  MANUAL('MANUAL'); // Manual - jogador escolhe

  const CategoryAssignmentMode(this.value);
  final String value;

  static CategoryAssignmentMode fromString(String value) {
    return CategoryAssignmentMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryAssignmentMode.AUTO,
    );
  }
}

class RoomModel {
  final String id;
  final String roomCode;
  final String roomName;
  final String? password;
  final GameMode gameMode;
  final Difficulty difficulty;
  final int maxPlayers;
  final int questionTime;
  final int questionCount;
  final List<String> categories;
  final String? assignmentType; // Pode ser null
  final CategoryAssignmentMode? categoryAssignmentMode; // Nova propriedade
  final bool allowSpectators;
  final bool enableChat;
  final bool showRealTimeRanking;
  final bool allowReconnection;
  final RoomStatus status;
  final String? hostId; // Pode ser null
  final String? hostName; // Novo campo
  final String? gameId;
  final List<PlayerInRoom> players;
  final int? currentPlayers; // Novo campo
  final bool? isPrivate; // Novo campo
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.roomCode,
    required this.roomName,
    this.password,
    required this.gameMode,
    required this.difficulty,
    required this.maxPlayers,
    required this.questionTime,
    required this.questionCount,
    required this.categories,
    this.assignmentType,
    this.categoryAssignmentMode, // Adicionar ao construtor
    required this.allowSpectators,
    required this.enableChat,
    required this.showRealTimeRanking,
    required this.allowReconnection,
    required this.status,
    this.hostId,
    this.hostName,
    this.gameId,
    required this.players,
    this.currentPlayers,
    this.isPrivate,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      roomCode: json['roomCode'] ?? '',
      roomName: json['roomName'] ?? '',
      password: json['password'],
      gameMode: GameMode.fromString(json['gameMode'] ?? 'TEAM'),
      difficulty: Difficulty.fromString(json['difficulty'] ?? 'MEDIUM'),
      maxPlayers: json['maxPlayers'] ?? 4,
      questionTime: json['questionTime'] ?? 30,
      questionCount: json['questionCount'] ?? 10,
      categories: json['categories'] != null 
        ? (json['categories'] as List).map((category) {
            if (category is Map<String, dynamic>) {
              // Se for um objeto de categoria, pega o nome
              return category['name'] as String;
            } else {
              // Se já for uma string, mantém
              return category.toString();
            }
          }).toList()
        : [],
      assignmentType: json['assignmentType'],
      categoryAssignmentMode: json['categoryAssignmentMode'] != null 
        ? CategoryAssignmentMode.fromString(json['categoryAssignmentMode'])
        : null,
      allowSpectators: json['allowSpectators'] ?? false,
      enableChat: json['enableChat'] ?? true,
      showRealTimeRanking: json['showRealTimeRanking'] ?? true,
      allowReconnection: json['allowReconnection'] ?? true,
      status: RoomStatus.fromString(json['status'] ?? 'WAITING'),
      hostId: json['hostId']?.toString(),
      hostName: json['hostName'],
      gameId: json['gameId']?.toString(),
      players: (json['players'] as List?)?.map((p) => PlayerInRoom.fromJson(p)).toList() ?? [],
      currentPlayers: json['currentPlayers'],
      isPrivate: json['isPrivate'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCode': roomCode,
      'roomName': roomName,
      'password': password,
      'gameMode': gameMode.value,
      'difficulty': difficulty.value,
      'maxPlayers': maxPlayers,
      'questionTime': questionTime,
      'questionCount': questionCount,
      'categories': categories,
      'assignmentType': assignmentType,
      'categoryAssignmentMode': categoryAssignmentMode?.value,
      'allowSpectators': allowSpectators,
      'enableChat': enableChat,
      'showRealTimeRanking': showRealTimeRanking,
      'allowReconnection': allowReconnection,
      'status': status.value,
      'hostId': hostId,
      'hostName': hostName,
      'gameId': gameId,
      'players': players.map((p) => p.toJson()).toList(),
      'currentPlayers': currentPlayers,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CreateRoomRequest {
  final String roomName;
  final String? password;
  final GameMode gameMode;
  final Difficulty difficulty;
  final int maxPlayers;
  final int questionTime;
  final int questionCount;
  final List<int> categoryIds; // MUDANÇA: De List<String> categories para List<int> categoryIds
  final String assignmentType;
  final String? categoryAssignmentMode; // Nova propriedade
  final bool allowSpectators;
  final bool enableChat;
  final bool showRealTimeRanking;
  final bool allowReconnection;
  final String hostId;

  CreateRoomRequest({
    required this.roomName,
    this.password,
    required this.gameMode,
    required this.difficulty,
    required this.maxPlayers,
    required this.questionTime,
    required this.questionCount,
    required this.categoryIds, // MUDANÇA
    required this.assignmentType,
    this.categoryAssignmentMode, // Adicionar ao construtor
    required this.allowSpectators,
    required this.enableChat,
    required this.showRealTimeRanking,
    required this.allowReconnection,
    required this.hostId,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomName': roomName, // ✅ Corrigido: usar "roomName" para corresponder ao backend
      'password': password,
      'gameMode': gameMode.value,
      'difficulty': difficulty.value,
      'maxPlayers': maxPlayers,
      'questionTime': questionTime,
      'questionCount': questionCount,
      'categoryIds': categoryIds, // MUDANÇA: Enviar IDs em vez de strings
      'assignmentType': assignmentType,
      'categoryAssignmentMode': categoryAssignmentMode, // Adicionar ao JSON
      'allowSpectators': allowSpectators,
      'enableChat': enableChat,
      'showRealTimeRanking': showRealTimeRanking,
      'allowReconnection': allowReconnection,
      'hostId': hostId,
    };
  }
}

class PlayerInRoom {
  final String userId;
  final String username;
  final String fullName;
  final String? avatar;
  final TeamColor? team;
  final String? assignedCategory; // Nova propriedade para disciplina atribuída
  final bool isReady;
  final bool isHost;

  PlayerInRoom({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatar,
    this.team,
    this.assignedCategory, // Adicionar ao construtor
    required this.isReady,
    required this.isHost,
  });

  factory PlayerInRoom.fromJson(Map<String, dynamic> json) {
    return PlayerInRoom(
      userId: json['userId']?.toString() ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatar: json['avatar'],
      team: json['team'] != null ? TeamColor.fromString(json['team']) : null,
      assignedCategory: json['assignedCategory'], // Adicionar parsing
      isReady: json['isReady'] ?? false,
      isHost: json['isHost'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
      'team': team?.value,
      'assignedCategory': assignedCategory, // Adicionar ao JSON
      'isReady': isReady,
      'isHost': isHost,
    };
  }
}
