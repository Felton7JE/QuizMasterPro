import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/room_model.dart';
import '../models/category_models.dart' as CategoryModels;
import '../services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _roomService;
  
  RoomModel? _currentRoom;
  List<PlayerInRoom> _players = [];
  List<RoomModel> _publicRooms = [];
  bool _isLoading = false;
  String? _error;
  int? _lastStartedGameId;
  Map<String, dynamic>? _lastStartedGameResponse;
  Map<String, dynamic>? get lastStartedGameResponse => _lastStartedGameResponse;
  int? get lastStartedGameId => _lastStartedGameId;

  RoomProvider(this._roomService);

  RoomModel? get currentRoom => _currentRoom;
  List<PlayerInRoom> get players => _players;
  List<RoomModel> get publicRooms => _publicRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInRoom => _currentRoom != null;

  Future<bool> createRoom({
    required String roomName,
    String? password,
    required GameMode gameMode,
    required Difficulty difficulty,
    required int maxPlayers,
    required int questionTime,
    required int questionCount,
    required List<int> categoryIds, // MUDANÇA: De List<String> para List<int>
    required String assignmentType,
    String? categoryAssignmentMode, // Nova propriedade
    required bool allowSpectators,
    required bool enableChat,
    required bool showRealTimeRanking,
    required bool allowReconnection,
    required String hostId,
  }) async {
    print('DEBUG RoomProvider: ===== INÍCIO createRoom =====');
    print('DEBUG RoomProvider: hostId = $hostId');
    print('DEBUG RoomProvider: roomNamzze = $roomName');
    print('DEBUG RoomProvider: categoryIds = $categoryIds'); // MUDANÇA
    
    // Teste 1: setLoading
    print('DEBUG RoomProvider: Teste 1 - setLoading(true)...');
    _setLoading(true);
    print('DEBUG RoomProvider: SUCESSO - _isLoading agora é: $_isLoading');
    
    try {
      // Teste 2: Criar request
      print('DEBUG RoomProvider: Teste 2 - Criando CreateRoomRequest...');
      final request = CreateRoomRequest(
        roomName: roomName,
        password: password,
        gameMode: gameMode,
        difficulty: difficulty,
        maxPlayers: maxPlayers,
        questionTime: questionTime,
        questionCount: questionCount,
        categoryIds: categoryIds, // MUDANÇA
        assignmentType: assignmentType,
        categoryAssignmentMode: categoryAssignmentMode, // Adicionar novo parâmetro
        allowSpectators: allowSpectators,
        enableChat: enableChat,
        showRealTimeRanking: showRealTimeRanking,
        allowReconnection: allowReconnection,
        hostId: hostId,
      );
      
      print('DEBUG RoomProvider: SUCESSO - Request criado');
      print('DEBUG RoomProvider: Request JSON: ${request.toJson()}');
      
      // Teste 3: Chamar roomService
      print('DEBUG RoomProvider: Teste 3 - Chamando _roomService.createRoom...');
      print('DEBUG RoomProvider: _roomService = $_roomService');
      
      _currentRoom = await _roomService.createRoom(request);
      
      print('DEBUG RoomProvider: SUCESSO - roomService retornou');
      print('DEBUG RoomProvider: _currentRoom = $_currentRoom');
      
      // Teste 4: Processar resultado
      print('DEBUG RoomProvider: Teste 4 - Processando resultado...');
      _players = _currentRoom!.players;
      _error = null;
      print('DEBUG RoomProvider: SUCESSO - Resultado processado');
      
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('DEBUG RoomProvider: ERRO CAPTURADO: $e');
      print('DEBUG RoomProvider: Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      print('DEBUG RoomProvider: Finally - setLoading(false)...');
      _setLoading(false);
      print('DEBUG RoomProvider: ===== FIM createRoom =====');
    }
  }

  // Método de teste para verificar conexão
  Future<void> testConnection() async {
    print('DEBUG RoomProvider: Testando conexão...');
    try {
      // Faz uma chamada simples para verificar a conexão
      await _roomService.testConnection();
      print('DEBUG RoomProvider: Conexão OK');
    } catch (e) {
      print('DEBUG RoomProvider: Erro de conexão: $e');
      throw e;
    }
  }

  Future<bool> joinRoom(String roomCode, String userId) async {
    print('DEBUG RoomProvider: Tentando entrar na sala $roomCode com userId $userId');
    _setLoading(true);
    try {
      _currentRoom = await _roomService.joinRoom(roomCode, userId);
      _players = _currentRoom!.players;
      _error = null;
      print('DEBUG RoomProvider: Sucesso ao entrar na sala - ${_players.length} jogadores');
      notifyListeners();
      return true;
    } catch (e) {
      print('DEBUG RoomProvider: Erro ao entrar na sala: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshRoomDetails() async {
    if (_currentRoom == null) return;
    
    try {
      print('DEBUG RoomProvider: Atualizando detalhes da sala ${_currentRoom!.roomCode}');
      print('DEBUG RoomProvider: GameId antes do refresh: ${_currentRoom!.gameId}');
      
      // Busca os detalhes atualizados da sala
      final rawResponse = await _roomService.getRoomDetails(_currentRoom!.roomCode);
      print('DEBUG RoomProvider: Response getRoomDetails RAW: $rawResponse');
      
      _currentRoom = rawResponse;
      _players = _currentRoom!.players;
      _error = null;
      
      print('DEBUG RoomProvider: GameId após refresh: ${_currentRoom!.gameId}');
      print('DEBUG RoomProvider: assignmentType após parsing: ${_currentRoom!.assignmentType}');
      print('DEBUG RoomProvider: Sala atualizada - ${_players.length} jogadores');
      notifyListeners();
    } catch (e, stackTrace) {
      print('DEBUG RoomProvider: Erro ao atualizar sala: $e');
      print('DEBUG RoomProvider: Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Método específico para buscar gameId com múltiplas tentativas
  Future<String?> getGameId() async {
    if (_currentRoom == null) return null;
    
    // If we have a cached gameId from a recent start, return it first
    if (_lastStartedGameId != null) return _lastStartedGameId.toString();
    
    // Se já tem gameId, retorna
    if (_currentRoom!.gameId != null) {
      return _currentRoom!.gameId;
    }
    
    // Tenta buscar com múltiplas tentativas
    for (int i = 0; i < 5; i++) {
      try {
        print('DEBUG RoomProvider: getGameId tentativa ${i + 1}/5');
        await refreshRoomDetails();
        
        if (_currentRoom?.gameId != null) {
          print('DEBUG RoomProvider: GameId obtido na tentativa ${i + 1}: ${_currentRoom!.gameId}');
          return _currentRoom!.gameId;
        }
        
        // Aguarda um pouco antes da próxima tentativa
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('DEBUG RoomProvider: Erro na tentativa ${i + 1}: $e');
      }
    }
    
    print('DEBUG RoomProvider: getGameId falhou após 5 tentativas');
    return null;
  }

  Future<void> refreshPlayers() async {
    if (_currentRoom == null) return;
    
    try {
      _players = await _roomService.getRoomPlayers(_currentRoom!.roomCode);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> setPlayerTeam(String playerId, TeamColor team) async {
    if (_currentRoom == null) return false;
    
    try {
      await _roomService.setPlayerTeam(_currentRoom!.roomCode, playerId, team);
      await refreshPlayers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPlayerReady(String playerId) async {
    if (_currentRoom == null) return false;
    
    try {
      await _roomService.setPlayerReady(_currentRoom!.roomCode, playerId);
      await refreshPlayers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> distributeTeamsRandomly(String hostId) async {
    if (_currentRoom == null) return false;
    
    _setLoading(true);
    try {
      // Obter lista de jogadores não atribuídos
      final unassignedPlayers = _currentRoom!.players
          .where((player) => player.team == null)
          .toList();

      if (unassignedPlayers.isEmpty) {
        print('DEBUG: Não há jogadores para distribuir');
        return true;
      }

      // Embaralhar a lista de jogadores
      final random = Random();
      unassignedPlayers.shuffle(random);

      // Contar jogadores já nas equipes
      int redCount = _currentRoom!.players.where((p) => p.team == TeamColor.RED).length;
      int blueCount = _currentRoom!.players.where((p) => p.team == TeamColor.BLUE).length;

      print('DEBUG: Distribuindo ${unassignedPlayers.length} jogadores');
      print('DEBUG: Equipe Vermelha atual: $redCount, Equipe Azul atual: $blueCount');

      // Distribuir jogadores de forma equilibrada
      for (int i = 0; i < unassignedPlayers.length; i++) {
        final player = unassignedPlayers[i];
        TeamColor assignedTeam;

        // Alternar entre as equipes, começando pela que tem menos jogadores
        if (redCount <= blueCount) {
          assignedTeam = TeamColor.RED;
          redCount++;
        } else {
          assignedTeam = TeamColor.BLUE;
          blueCount++;
        }

        // Definir equipe no backend
        await _roomService.setPlayerTeam(_currentRoom!.roomCode, player.userId, assignedTeam);
        
        // Marcar jogador como pronto
        await _roomService.setPlayerReady(_currentRoom!.roomCode, player.userId);
        
        print('DEBUG: Jogador ${player.userId} atribuído à ${assignedTeam == TeamColor.RED ? "Equipe Vermelha" : "Equipe Azul"} e marcado como pronto');
      }

      // Atualizar dados da sala
      await refreshRoomDetails();
      
      return true;
    } catch (e) {
      print('DEBUG: Erro ao distribuir equipes: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> startGame(String hostId) async {
    if (_currentRoom == null) return false;
    
    _setLoading(true);
    try {
      // Call service which now returns the backend JSON (including gameId)
      final Map<String, dynamic> response = await _roomService.startGame(_currentRoom!.roomCode, hostId);

      // Store returned gameId for immediate access (if present)
      // Store full response and gameId for quick access in UI
      _lastStartedGameResponse = response;
      if (response.containsKey('gameId')) {
        final dynamic gid = response['gameId'];
        _lastStartedGameId = gid != null ? int.tryParse(gid.toString()) : null;
      }

      // Buscar status STARTING/startsAt do backend e atualizar estado local
      await refreshRoomDetails();
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

  Future<void> loadPublicRooms({int page = 0, int size = 10}) async {
    try {
      _publicRooms = await _roomService.getPublicRooms(page: page, size: size);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> leaveRoom(String userId) async {
    if (_currentRoom == null) return false;
    
    try {
      await _roomService.leaveRoom(_currentRoom!.roomCode, userId);
      _currentRoom = null;
      _players = [];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearRoom() {
    _currentRoom = null;
    _players = [];
    _error = null;
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

  PlayerInRoom? getPlayerById(String userId) {
    return _players.cast<PlayerInRoom?>().firstWhere(
      (player) => player?.userId == userId,
      orElse: () => null,
    );
  }

  bool isPlayerHost(String userId) {
    final player = getPlayerById(userId);
    return player?.isHost ?? false;
  }

  bool areAllPlayersReady() {
    return _players.isNotEmpty && _players.every((player) => player.isReady);
  }

  int get readyPlayersCount => _players.where((player) => player.isReady).length;

  // ATUALIZADO: Método para atribuir disciplina específica a um jogador usando DTO
  Future<bool> assignCategoryToPlayer(int playerId, int categoryId) async {
    try {
      print('DEBUG RoomProvider: Atribuindo categoria $categoryId ao jogador $playerId');
      
      if (_currentRoom == null) {
        _error = 'Nenhuma sala ativa encontrada';
        notifyListeners();
        return false;
      }

      // Evita pedir ao backend algo que já está atribuído localmente
      final alreadyAssignedLocal = _currentRoom!.players.any((p) =>
          p.userId == playerId.toString() &&
          p.assignedCategory != null &&
          p.assignedCategory!.isNotEmpty);
      if (alreadyAssignedLocal) {
        _error = 'Jogador já possui disciplina';
        notifyListeners();
        return false;
      }

      final request = CategoryModels.AssignCategoryRequest(
        playerId: playerId,
        categoryId: categoryId,
      );

      await _roomService.assignCategoryToPlayer(_currentRoom!.roomCode, request);
      await refreshRoomDetails();
      _error = null;
      return true;
    } catch (e) {
      print('ERROR RoomProvider: Erro ao atribuir categoria: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ATUALIZADO: Método para distribuir disciplinas automaticamente usando DTO
  Future<bool> distributeCategoriesAutomatically(int hostId) async {
    try {
      print('DEBUG RoomProvider: Distribuindo categorias automaticamente');
      
      if (_currentRoom == null) {
        _error = 'Nenhuma sala ativa encontrada';
        notifyListeners();
        return false;
      }

      final request = CategoryModels.DistributeCategoriesRequest(hostId: hostId);

      bool success = await _roomService.distributeCategoriesAutomatically(_currentRoom!.roomCode, request);
      
      if (success) {
        await refreshRoomDetails();
        return true;
      } else {
        _error = 'Erro ao distribuir disciplinas';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('ERROR RoomProvider: Erro ao distribuir categorias: $e');
      _error = 'Erro de conexão ao distribuir disciplinas: $e';
      notifyListeners();
      return false;
    }
  }

  // NOVO: Método para obter estatísticas de distribuição de categorias do backend
  Future<CategoryModels.CategoryDistributionStatsResponse?> getCategoryDistributionStatsFromApi() async {
    try {
      if (_currentRoom == null) return null;
      
      print('DEBUG RoomProvider: Buscando estatísticas de distribuição da API');
      
      return await _roomService.getCategoryDistributionStats(_currentRoom!.roomCode);
    } catch (e) {
      print('ERROR RoomProvider: Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  // NOVO: Método para obter categorias disponíveis para um jogador do backend
  Future<List<CategoryModels.Category>> getAvailableCategoriesForPlayerFromApi(int playerId) async {
    try {
      if (_currentRoom == null) return [];
      
      print('DEBUG RoomProvider: Buscando categorias disponíveis para jogador $playerId');
      
      return await _roomService.getAvailableCategoriesForPlayer(_currentRoom!.roomCode, playerId);
    } catch (e) {
      print('ERROR RoomProvider: Erro ao buscar categorias disponíveis: $e');
      return [];
    }
  }

  // NOVO: Método para verificar se todas as categorias foram atribuídas do backend
  Future<bool> areAllCategoriesAssignedFromApi() async {
    try {
      if (_currentRoom == null) return false;
      
      print('DEBUG RoomProvider: Verificando se todas as categorias foram atribuídas');
      
      return await _roomService.areAllCategoriesAssigned(_currentRoom!.roomCode);
    } catch (e) {
      print('ERROR RoomProvider: Erro ao verificar atribuições: $e');
      return false;
    }
  }

  // Métodos de conveniência para facilitar o uso
  Future<bool> assignCategoryToPlayerById(int playerId, int categoryId) async {
    return await assignCategoryToPlayer(playerId, categoryId);
  }

  Future<bool> distributeCategoriesAutomaticallyByHost(int hostId) async {
    return await distributeCategoriesAutomatically(hostId);
  }

  // MANTIDO: Método para verificar se todas as disciplinas foram atribuídas (versão local)
  bool areAllCategoriesAssigned() {
    if (_currentRoom == null) return false;
    
    final playersWithTeams = _currentRoom!.players.where((p) => p.team != null).toList();
    
    for (final player in playersWithTeams) {
      if (player.assignedCategory == null || player.assignedCategory!.isEmpty) {
        return false;
      }
    }
    
    return playersWithTeams.isNotEmpty;
  }

  // Método para obter disciplinas disponíveis para um jogador
  List<String> getAvailableCategoriesForPlayer(String userId) {
    if (_currentRoom == null) return [];

    final currentPlayer = _currentRoom!.players.firstWhere(
      (p) => p.userId == userId,
      orElse: () => PlayerInRoom(userId: '', username: '', fullName: '', isHost: false, isReady: false),
    );

    // Se o jogador não for encontrado ou não tiver equipe, não há categorias disponíveis
    if (currentPlayer.userId.isEmpty || currentPlayer.team == null) {
      return [];
    }

    // Pega todas as categorias da sala
    final allRoomCategories = Set<String>.from(_currentRoom!.categories);

    // Pega as categorias já escolhidas por jogadores DA MESMA EQUIPE
    final takenCategoriesByTeam = _currentRoom!.players
        .where((p) => p.team == currentPlayer.team && p.assignedCategory != null)
        .map((p) => p.assignedCategory!)
        .toSet();

    // Retorna a lista de categorias da sala que não foram escolhidas pela equipe do jogador
    return allRoomCategories.difference(takenCategoriesByTeam).toList();
  }

  // Método para obter estatísticas de distribuição de disciplinas
  Map<String, dynamic> getCategoryDistributionStats() {
    if (_currentRoom == null) return {};
    
    final stats = <String, dynamic>{};
    
    for (final category in _currentRoom!.categories) {
      final redPlayers = _currentRoom!.players
          .where((p) => p.team == TeamColor.RED && p.assignedCategory == category)
          .length;
      final bluePlayers = _currentRoom!.players
          .where((p) => p.team == TeamColor.BLUE && p.assignedCategory == category)
          .length;
      
      stats[category] = {
        'red': redPlayers,
        'blue': bluePlayers,
        'total': redPlayers + bluePlayers,
      };
    }
    
    return stats;
  }
}
