import 'package:flutter/foundation.dart' hide Category;
import '../models/room_model.dart';
import '../models/category_models.dart';
import 'api_service.dart';

class RoomService {
  final ApiService _apiService;

  RoomService(this._apiService);

  Future<RoomModel> createRoom(CreateRoomRequest request) async {
    debugPrint('DEBUG RoomService: Iniciando createRoom...');
    debugPrint('DEBUG RoomService: Body = ${request.toJson()}');
    
    final response = await _apiService.post('/api/rooms', request.toJson());
    
    debugPrint('DEBUG RoomService: Response recebido: $response');
    
    final roomModel = RoomModel.fromJson(response);
    
    debugPrint('DEBUG RoomService: RoomModel criado: ${roomModel.toJson()}');
    
    return roomModel;
  }

  Future<RoomModel> getRoomDetails(String roomCode) async {
    try {
      debugPrint('DEBUG RoomService: Buscando detalhes da sala $roomCode');
      final response = await _apiService.get('/api/rooms/$roomCode');
      debugPrint('DEBUG RoomService: Response getRoomDetails RAW: $response');
      debugPrint('DEBUG RoomService: assignmentType no JSON: ${response['assignmentType']}');
      
      final roomModel = RoomModel.fromJson(response);
      debugPrint('DEBUG RoomService: assignmentType após parsing: ${roomModel.assignmentType}');
      debugPrint('DEBUG RoomService: RoomModel parseado com sucesso');
      
      return roomModel;
    } catch (e, stackTrace) {
      debugPrint('DEBUG RoomService: Erro ao buscar detalhes da sala: $e');
      debugPrint('DEBUG RoomService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<RoomModel> joinRoom(String roomCode, String userId, {String? password}) async {
    final body = {
      'userId': userId,
      if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
    };
    final response = await _apiService.post('/api/rooms/$roomCode/join', body);
    return RoomModel.fromJson(response);
  }

  Future<List<PlayerInRoom>> getRoomPlayers(String roomCode) async {
    final response = await _apiService.get('/api/rooms/$roomCode/players');
    return (response['players'] as List).map((p) => PlayerInRoom.fromJson(p)).toList();
  }

  Future<void> setPlayerTeam(String roomCode, String playerId, TeamColor team) async {
    // Mapeia TeamColor para o enum do backend (A, B)
    String backendTeam;
    switch (team) {
      case TeamColor.RED:
        backendTeam = 'A';
        break;
      case TeamColor.BLUE:
        backendTeam = 'B';
        break;
      default:
        backendTeam = 'A'; // Fallback para equipe A
        break;
    }
    
    final body = {
      'team': backendTeam,
    };
    await _apiService.post('/api/rooms/$roomCode/players/$playerId/team', body);
  }

  Future<void> setPlayerReady(String roomCode, String playerId) async {
    await _apiService.post('/api/rooms/$roomCode/players/$playerId/ready');
  }

  /// Calls backend to start the game and returns the parsed JSON response
  /// (e.g. contains `gameId`, `startTime`, etc.). Throws on failure.
  Future<Map<String, dynamic>> startGame(String roomCode, String hostId) async {
    final body = {
      'hostId': int.tryParse(hostId) ?? 0,
    };

    final response = await _apiService.post('/api/rooms/$roomCode/start', body);

    // Cast response to Map<String, dynamic> (ApiService returns decoded JSON)
    final Map<String, dynamic> parsed = Map<String, dynamic>.from(response);

    // Print only when this function is explicitly called (debug builds).
    // Use kDebugMode from foundation to avoid noisy logs in production.
    // This single print helps you inspect the backend GameResponse when StartGame is
    // invoked (e.g. from the UI debug button we'll add in CreateRoomScreen).
    // Note: importing `foundation.dart` at top of file is acceptable in Flutter code.
    try {
      // Avoid adding heavy logging in production; guard with a debug-only check
      // so it only shows when running in debug mode.
      // (foundation import exists in this file scope)
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // Non-production: print the parsed response
        debugPrint('DEBUG RoomService.startGame response: $parsed');
      }
    } catch (_) {
      // ignore printing errors
    }

    return parsed;
  }

  Future<void> playAgain(String roomCode, String userId) async {
    final body = {
      'hostId': userId, // Backend currently accepts hostId in StartGameRequest, which we repurpose as userId
    };
    await _apiService.post('/api/rooms/$roomCode/play-again', body);
  }

  Future<void> leaveRoom(String roomCode, String userId) async {
    final body = {
      'userId': userId,
    };
    await _apiService.post('/api/rooms/$roomCode/leave', body);
  }

  Future<List<RoomModel>> getPublicRooms({int page = 0, int size = 10}) async {
    final body = {
      'page': page,
      'size': size,
      'isPrivate': false,
    };
    final response = await _apiService.post('/api/rooms/filter', body);
    return (response['rooms'] as List).map((r) => RoomModel.fromJson(r)).toList();
  }

  Future<void> deleteRoom(String roomCode, String hostId) async {
    final body = {
      'hostId': hostId,
    };
    await _apiService.post('/api/rooms/$roomCode/delete', body);
  }

  // Método de teste para verificar conexão
  Future<void> testConnection() async {
    debugPrint('DEBUG RoomService: Testando conexão...');
    try {
      // Usar o novo método de filtrar salas
      await getPublicRooms(page: 0, size: 1);
    } catch (e) {
      debugPrint('DEBUG RoomService: Erro de conexão: $e');
      rethrow;
    }
  }

  // ATUALIZADO: Método para atribuir categoria específica a um jogador usando DTO
  Future<bool> assignCategoryToPlayer(String roomCode, AssignCategoryRequest request) async {
  // Não engolir exceções: deixar ApiException subir para Provider capturar e mostrar mensagem real
  debugPrint('DEBUG RoomService: Atribuindo categoria ${request.categoryId} ao jogador ${request.playerId} na sala $roomCode');
  await _apiService.post('/api/rooms/$roomCode/assign-category', request.toJson());
  return true;
  }

  // ATUALIZADO: Método para distribuir categorias automaticamente usando DTO
  Future<bool> distributeCategoriesAutomatically(String roomCode, DistributeCategoriesRequest request) async {
  debugPrint('DEBUG RoomService: Distribuindo categorias automaticamente na sala $roomCode pelo host ${request.hostId}');
  await _apiService.post('/api/rooms/$roomCode/distribute-categories', request.toJson());
  return true;
  }

  // NOVO: Método para obter estatísticas de distribuição de categorias
  Future<CategoryDistributionStatsResponse?> getCategoryDistributionStats(String roomCode) async {
    try {
      debugPrint('DEBUG RoomService: Buscando estatísticas de distribuição de categorias para sala $roomCode');
      
      final response = await _apiService.get('/api/rooms/$roomCode/category-distribution');
      
      return CategoryDistributionStatsResponse.fromJson(response);
    } catch (e) {
      debugPrint('DEBUG RoomService: Erro ao buscar estatísticas de distribuição: $e');
      return null;
    }
  }

  // NOVO: Método para obter categorias disponíveis para um jogador
  Future<List<Category>> getAvailableCategoriesForPlayer(String roomCode, int playerId) async {
    try {
      debugPrint('DEBUG RoomService: Buscando categorias disponíveis para jogador $playerId na sala $roomCode');
      
      final response = await _apiService.get('/api/rooms/$roomCode/available-categories/$playerId');
      
      return (response as List).map((c) => Category.fromJson(c)).toList();
    } catch (e) {
      debugPrint('DEBUG RoomService: Erro ao buscar categorias disponíveis: $e');
      return [];
    }
  }

  // NOVO: Método para verificar se todas as categorias foram atribuídas
  Future<bool> areAllCategoriesAssigned(String roomCode) async {
    try {
      debugPrint('DEBUG RoomService: Verificando se todas as categorias foram atribuídas na sala $roomCode');
      
      final response = await _apiService.get('/api/rooms/$roomCode/categories-assignment-status');
      
      return response as bool;
    } catch (e) {
      debugPrint('DEBUG RoomService: Erro ao verificar status de atribuição: $e');
      return false;
    }
  }

  // Métodos de conveniência para facilitar o uso dos DTOs
  Future<bool> assignCategoryToPlayerById(String roomCode, int playerId, int categoryId) async {
    final request = AssignCategoryRequest(
      playerId: playerId,
      categoryId: categoryId,
    );
    return assignCategoryToPlayer(roomCode, request);
  }

  Future<bool> distributeCategoriesAutomaticallyByHost(String roomCode, int hostId) async {
    final request = DistributeCategoriesRequest(hostId: hostId);
    return distributeCategoriesAutomatically(roomCode, request);
  }

  Future<void> addBots(String roomCode, String hostId, {int count = 3}) async {
    final body = {
      'hostId': int.tryParse(hostId) ?? 0,
      'count': count,
    };
    await _apiService.post('/api/rooms/$roomCode/add-bots', body);
  }

  Future<void> sendRematchRequest(String roomCode, String userId) async {
    final body = {
      'userId': int.tryParse(userId) ?? 0,
    };
    await _apiService.post('/api/rooms/$roomCode/rematch-request', body);
  }
}
