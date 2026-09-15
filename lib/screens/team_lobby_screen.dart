import 'package:quizmaster_pro/widgets/loading_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/room_provider.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/websocket_provider.dart';
import '../models/room_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/vip_badge_widget.dart';
import '../config/api_config.dart';
import '../providers/store_provider.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_logo_text.dart';

class TeamLobbyScreen extends StatefulWidget {
  const TeamLobbyScreen({super.key});

  @override
  State<TeamLobbyScreen> createState() => _TeamLobbyScreenState();
}

class _TeamLobbyScreenState extends State<TeamLobbyScreen> with TickerProviderStateMixin {
  RoomModel? _currentRoom;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  bool _isAutoAssigning = false;
  bool _isStartingGame = false;
  bool _isDistributingTeams = false;
  bool _isDistributingCategories = false; // Nova variável para distribuição de disciplinas
  bool _isAssigningCategory = false; // Evita corrida na seleção manual
  bool _showGameSettings = false; // Controle de visibilidade das configurações do jogo
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation; // removido _pulseAnimation não utilizado

  @override
  void initState() {
    super.initState();
    
    // Animações
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
  // (Removido _pulseAnimation não utilizado)
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _loadRoomData();
    // Garante que categorias estejam carregadas antes de seleção manual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      } catch (_) {}

      // Ligar ao WebSocket para receber GAME_STARTED em tempo real
      _connectWebSocket();
    });
    _checkAutoAssignment();
    // Manter polling lento (5s) apenas para atualizar lista de jogadores no lobby
    // (jogadores a entrar/sair, estado ready). O início do jogo é feito via WebSocket.
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        _refreshTimer?.cancel();
        return;
      }
      _refreshRoomData();
    });
    
    // Iniciar animação
    _slideController.forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    // NÃO desligar o WebSocket aqui — vai ser usado no countdown/game screen
    // O WebSocketProvider gere o seu próprio ciclo de vida
    super.dispose();
  }

  Future<void> _loadRoomData() async {
    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      if (roomProvider.currentRoom != null) {
        setState(() {
          _currentRoom = roomProvider.currentRoom;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Sala não encontrada';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados da sala: $e';
        _isLoading = false;
      });
    }
  }

  /// Liga ao WebSocket e subscreve os eventos da sala.
  /// Quando o evento GAME_STARTED chegar, navega para o countdown com dados completos.
  void _connectWebSocket() {
    final roomCode = _currentRoom?.roomCode;
    if (roomCode == null || roomCode.isEmpty) return;

    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    wsProv.connectToRoom(roomCode);

    // Monitorizar o provider para detetar o evento GAME_STARTED
    wsProv.addListener(() {
      if (!mounted) return;
      final event = wsProv.lastGameStartedEvent;
      if (event == null) return;

      final userId = auth.currentUser?.id ?? '';
      final playerCategory = event.playerCategories[userId];
      final gameId = event.gameId;

      // Limpar o evento para não navegar duas vezes
      wsProv.clearGameStartedEvent();

      // Cancelar o polling do lobby
      _refreshTimer?.cancel();

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/quiz-countdown',
        arguments: {
          'roomName': _currentRoom?.roomName,
          'categories': _currentRoom?.categories,
          'difficulty': _currentRoom?.difficulty.value,
          'maxPlayers': _currentRoom?.maxPlayers,
          'questionTime': _currentRoom?.questionTime,
          'questionCount': _currentRoom?.questionCount,
          'assignmentType': _currentRoom?.assignmentType,
          // ✅ Dados completos recebidos via WebSocket — sem race condition
          'gameId': gameId,
          'startsAt': event.startsAt.toIso8601String(),
          'playerCategory': playerCategory,
        },
      );
    });
  }

  Future<void> _refreshRoomData() async {
    // Não atualizar enquanto estiver atribuindo disciplina manualmente para não sobrescrever estado
    if (_isAssigningCategory) return;
    if (_currentRoom != null) {
      try {
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        await roomProvider.refreshRoomDetails();
        if (mounted) {
          final newRoom = roomProvider.currentRoom;
          setState(() {
            _currentRoom = newRoom;
          });
          // Nota: Não há mais deteção de estado aqui — o WebSocket trata disso
        }
      } catch (e) {
        // Erro tratado silenciosamente
      }
    }
  }

  void _checkAutoAssignment() {
    if (_currentRoom?.assignmentType == 'RANDOM') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performAutoAssignment();
      });
    }
  }

  Future<void> _performAutoAssignment() async {
    if (_isAutoAssigning || _currentRoom == null) return;
    
    setState(() {
      _isAutoAssigning = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) return;

      final unassignedPlayers = _currentRoom!.players
          .where((player) => player.team == null)
          .toList();

      if (unassignedPlayers.isEmpty) return;

      // Conta quantos jogadores tem em cada equipe
      final teamACounts = _currentRoom!.players
          .where((player) => player.team == TeamColor.RED)
          .length;
      
      final teamBCounts = _currentRoom!.players
          .where((player) => player.team == TeamColor.BLUE)
          .length;

      // Verifica se o usuário atual está na lista de não atribuídos
      final currentPlayerInRoom = _currentRoom!.players
          .where((player) => player.userId == currentUser.id)
          .firstOrNull;

  if (currentPlayerInRoom != null && currentPlayerInRoom.team == null) {
        // Atribui o jogador atual para a equipe com menos membros
        TeamColor assignedTeam;
        if (teamACounts <= teamBCounts) {
          assignedTeam = TeamColor.RED;
        } else {
          assignedTeam = TeamColor.BLUE;
        }

        await Provider.of<RoomProvider>(context, listen: false)
            .setPlayerTeam(currentUser.id, assignedTeam);
            
        // Marca o jogador como pronto após atribuição automática
        await Provider.of<RoomProvider>(context, listen: false)
            .setPlayerReady(currentUser.id);
            
        
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoAssigning = false;
        });
      }
    }
  }

  Future<void> _selectTeam(TeamColor team) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        AppSnackBar.showError(context, 'Usuário não identificado');
        return;
      }

      // Primeiro define a equipe
      await roomProvider.setPlayerTeam(currentUser.id, team);
      
      // Depois marca o jogador como pronto
      await roomProvider.setPlayerReady(currentUser.id);
      
      
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipe selecionada! Você está pronto para jogar.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Erro ao selecionar equipe - mostra na UI
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    }
  }

  bool _isHost() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) return false;
    
    final currentPlayerInRoom = _currentRoom?.players
        .where((player) => player.userId == currentUser.id)
        .firstOrNull;
        
    return currentPlayerInRoom?.isHost == true;
  }

  Future<void> _distributeTeamsRandomly() async {
    if (_isDistributingTeams || _currentRoom == null) return;
    
    try {
      setState(() {
        _isDistributingTeams = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        AppSnackBar.showError(context, 'Usuário não identificado');
        return;
      }

      // Verifica se o usuário é o host
      final currentPlayerInRoom = _currentRoom?.players
          .where((player) => player.userId == currentUser.id)
          .firstOrNull;
      
      if (currentPlayerInRoom?.isHost != true) {
        AppSnackBar.showError(context, 'Apenas o criador da sala pode distribuir as equipes');
        return;
      }

      

      // Chama o backend para distribuir as equipes
      bool success = await roomProvider.distributeTeamsRandomly(currentUser.id);

      if (success) {
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipes distribuídas com sucesso!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Erro ao distribuir equipes: ${roomProvider.error}');
        }
      }
    } catch (e) {
      // Erro ao distribuir equipes (exibido via snackbar abaixo)
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDistributingTeams = false;
        });
      }
    }
  }

  void _copyRoomCode() {
    if (_currentRoom?.roomCode != null) {
      Clipboard.setData(ClipboardData(text: _currentRoom!.roomCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código copiado para área de transferência!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startGame() async {
    if (_isStartingGame) return; // Evita múltiplas chamadas
    
    try {
      setState(() {
        _isStartingGame = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        AppSnackBar.showError(context, 'Usuário não identificado');
        return;
      }

      // Verifica se o usuário é o host
      final currentPlayerInRoom = _currentRoom?.players
          .where((player) => player.userId == currentUser.id)
          .firstOrNull;
      
      if (currentPlayerInRoom?.isHost != true) {
        AppSnackBar.showError(context, 'Apenas o criador da sala pode iniciar o jogo');
        return;
      }

      

      // Chama o backend para iniciar o jogo - O gameId deve vir da resposta
      final startGameResult = await roomProvider.startGame(currentUser.id);

      if (startGameResult != true) {
        if (mounted) {
          AppSnackBar.showError(context, 'Erro ao iniciar o jogo. Tente novamente.');
          setState(() {
            _isStartingGame = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
        setState(() {
          _isStartingGame = false;
        });
      }
    }
  }

  Future<void> _selectCategory(String category) async {
    if (_isAssigningCategory) return; // debounce
    try {
      setState(() => _isAssigningCategory = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        _showSnack('Usuário não identificado');
        return;
      }
      if (_currentRoom == null) {
        _showSnack('Sala não carregada');
        return;
      }

      final player = _currentRoom!.players.firstWhere(
        (p) => p.userId == currentUser.id,
        orElse: () => PlayerInRoom(userId: '', username: '', fullName: '', isHost: false, isReady: false),
      );
      if (player.userId.isEmpty) {
        _showSnack('Jogador não encontrado na sala');
        return;
      }
      if (player.team == null) {
        _showSnack('Selecione uma equipe antes da disciplina');
        return;
      }
      if (player.assignedCategory != null && player.assignedCategory!.isNotEmpty) {
        _showSnack('Você já escolheu uma disciplina');
        return;
      }

      // Regra: uma categoria por equipe – verifica conflitos
      final sameTeamPlayers = _currentRoom!.players.where((p) => p.team == player.team);
      final alreadyTaken = sameTeamPlayers.any((p) => p.assignedCategory == category);
      if (alreadyTaken) {
        _showSnack('Sua equipe já escolheu esta disciplina');
        return;
      }

      final categoryObj = categoryProvider.getCategoryByName(category);
      if (categoryObj == null) {
        _showSnack('Disciplinas ainda carregando. Tente novamente.');
        return;
      }

      final playerId = int.tryParse(currentUser.id);
      if (playerId == null) {
        _showSnack('ID do jogador inválido');
        return;
      }

      

      final ok = await roomProvider.assignCategoryToPlayer(playerId, categoryObj.id);
      if (ok) {
        _showSnack('Disciplina selecionada: ${_getCategoryDisplayName(category)}', success: true);
      } else {
        _showSnack(roomProvider.error ?? 'Falha ao selecionar disciplina');
      }
    } catch (e) {
      // Erro na seleção de disciplina - notificar usuário
      _showSnack('Erro ao selecionar disciplina: $e');
    } finally {
      if (mounted) setState(() => _isAssigningCategory = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _distributeCategoriesAutomatically() async {
    if (_isDistributingCategories || _currentRoom == null) return;

    setState(() {
      _isDistributingCategories = true;
    });

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null || _currentRoom == null) {
        throw Exception('Usuário ou sala não encontrados.');
      }

      final currentPlayerInRoom = _currentRoom!.players
          .firstWhere((p) => p.userId == currentUser.id, orElse: () => throw Exception('Jogador atual não encontrado na sala.'));

      if (!currentPlayerInRoom.isHost) {
        throw Exception('Apenas o host pode distribuir as disciplinas.');
      }

      

      final players = _currentRoom!.players;
      final roomCategories = List<String>.from(_currentRoom!.categories);
      
      final teamRedPlayers = players.where((p) => p.team == TeamColor.RED).toList();
      final teamBluePlayers = players.where((p) => p.team == TeamColor.BLUE).toList();

      // Cria listas de disciplinas disponíveis para cada equipe
      var availableCategoriesForRed = List<String>.from(roomCategories);
      var availableCategoriesForBlue = List<String>.from(roomCategories);
      availableCategoriesForRed.shuffle();
      availableCategoriesForBlue.shuffle();

      List<Future> assignmentFutures = [];

      // Atribui para a equipe vermelha
      for (var player in teamRedPlayers) {
        if (availableCategoriesForRed.isNotEmpty) {
          final categoryToAssign = availableCategoriesForRed.removeAt(0);
          final categoryId = _getCategoryIdFromName(categoryToAssign);
          
          assignmentFutures.add(
            roomProvider.assignCategoryToPlayer(int.parse(player.userId), categoryId)
          );
        }
      }

      // Atribui para a equipe azul
      for (var player in teamBluePlayers) {
        if (availableCategoriesForBlue.isNotEmpty) {
          final categoryToAssign = availableCategoriesForBlue.removeAt(0);
          final categoryId = _getCategoryIdFromName(categoryToAssign);
          
          assignmentFutures.add(
            roomProvider.assignCategoryToPlayer(int.parse(player.userId), categoryId)
          );
        }
      }

      // Aguarda todas as atribuições serem concluídas
      await Future.wait(assignmentFutures);

      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disciplinas distribuídas automaticamente!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Erro ao distribuir disciplinas (exibido via snackbar abaixo)
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDistributingCategories = false;
        });
      }
    }
  }

  String _getCategoryDisplayName(String category) {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final cat = provider.getCategoryByName(category);
    return cat?.displayName ?? category;
  }

  int _getCategoryIdFromName(String category) {
    // MUDANÇA: Usar o CategoryProvider para obter o ID real
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final categoryObj = categoryProvider.getCategoryByName(category);
    return categoryObj?.id ?? 1; // Fallback para ID 1 se não encontrar
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading com animação moderna
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: LoadingLogo(size: 60),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Entrando na sala...',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aguarde um momento',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ops! Algo deu errado',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Voltar ao Menu',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/menu', 
                    (route) => false
                  ),
                  isPrimary: true,
                  isLarge: false,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(isSmallScreen),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header da Sala com melhor visual
              _buildEnhancedRoomHeader(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Código da Sala melhorado
              _buildEnhancedRoomCodeSection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Status do jogo em tempo real
              _buildGameStatusBanner(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Resumo da Configuração mais visual
              _buildEnhancedGameSummary(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Jogadores com melhor organização
              _buildConnectedPlayersSection(),
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Seleção de Equipes mais intuitiva
              _buildTeamSelectionSection(),
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Seleção de Disciplinas melhorada
              _buildCategorySelectionSection(),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Ações com melhor visual
              _buildActionButtons(),
              
              // Espaço extra no final
              SizedBox(height: isSmallScreen ? 20 : 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedPlayersSection() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        final players = _currentRoom?.players ?? [];
        
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: const Color(0xFF10B981),
                    size: isSmallScreen ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jogadores Conectados',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Text(
                      '${players.length}/${_currentRoom?.maxPlayers ?? 4}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Botão de distribuir equipes para modo automático
              if (_currentRoom?.assignmentType == 'RANDOM' && _isHost()) ...[
                SizedBox(height: isSmallScreen ? 8 : 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDistributingTeams ? null : _distributeTeamsRandomly,
                    icon: _isDistributingTeams 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: LoadingLogo(size: 60),
                          )
                        : Icon(Icons.shuffle, size: isSmallScreen ? 16 : 18),
                    label: Text(
                      _isDistributingTeams 
                          ? 'Distribuindo...' 
                          : 'Distribuir Equipes Aleatoriamente',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 8 : 12,
                        horizontal: isSmallScreen ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              if (players.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add,
                          color: Colors.grey[500],
                          size: isSmallScreen ? 32 : 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aguardando jogadores...',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Grid de jogadores para telas maiores, lista para telas menores
                if (isSmallScreen) ...[
                  // Lista vertical em telas pequenas
                  ...players.map((player) => _buildConnectedPlayerTile(player)),
                ] else ...[
                  // Grid em telas maiores
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, index) => _buildConnectedPlayerTile(players[index]),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectedPlayerTile(PlayerInRoom player) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isCurrentUser = player.userId == currentUser?.id;
        
        // Cores baseadas na equipe
        Color backgroundColor = const Color(0xFF374151);
        Color borderColor = const Color(0xFF4B5563);
        Color teamIndicatorColor = Colors.grey;
        String teamText = 'Sem equipe';
        
        if (player.team != null) {
          switch (player.team!) {
            case TeamColor.RED:
              backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
              borderColor = const Color(0xFFEF4444);
              teamIndicatorColor = const Color(0xFFEF4444);
              teamText = 'Equipe Vermelha';
              break;
            case TeamColor.BLUE:
              backgroundColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
              borderColor = const Color(0xFF3B82F6);
              teamIndicatorColor = const Color(0xFF3B82F6);
              teamText = 'Equipe Azul';
              break;
            case TeamColor.GREEN:
              backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.1);
              borderColor = const Color(0xFF10B981);
              teamIndicatorColor = const Color(0xFF10B981);
              teamText = 'Equipe Verde';
              break;
            case TeamColor.YELLOW:
              backgroundColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
              borderColor = const Color(0xFFF59E0B);
              teamIndicatorColor = const Color(0xFFF59E0B);
              teamText = 'Equipe Amarela';
              break;
          }
        }
        
        if (isCurrentUser) {
          borderColor = const Color(0xFF6366F1);
        }
        
        final storeProvider = context.read<StoreProvider>();
        final bannerUrl = storeProvider.getBannerUrl(player.activeBannerId);
        final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isCurrentUser ? 2 : 1,
            ),
            image: resolvedBanner != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      resolvedBanner,
                      headers: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: teamIndicatorColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: CosmeticAvatar(
                  radius: isSmallScreen ? 18 : 20,
                  avatarUrl: player.avatar,
                  username: player.username,
                  activeAvatarId: player.activeAvatarId,
                  activeFrameId: player.activeFrameId,
                  isVip: player.isVip,
                ),
              ),
              const SizedBox(width: 12),
              
              // Informações do jogador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: VipUsernameText(
                            username: player.username,
                            isVip: player.isVip,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VOCÊ',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: teamIndicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            teamText,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: teamIndicatorColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (player.isHost) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HOST',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (player.isReady) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRONTO',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        'AGUARDANDO',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamSelectionSection() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        final players = _currentRoom?.players ?? [];
        final isChooseMode = _currentRoom?.assignmentType == 'CHOOSE';
        
        // Debug: verificar o valor real do assignmentType
        debugPrint('DEBUG TeamSelection: assignmentType = ${_currentRoom?.assignmentType}');
        debugPrint('DEBUG TeamSelection: isChooseMode = $isChooseMode');
        
        // Separa jogadores por equipe e não atribuídos
        List<PlayerInRoom> unassignedPlayers = players.where((p) => p.team == null).toList();
        List<PlayerInRoom> teamRed = players.where((p) => p.team == TeamColor.RED).toList();
        List<PlayerInRoom> teamBlue = players.where((p) => p.team == TeamColor.BLUE).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: const Color(0xFFF59E0B),
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Formação de Equipes',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            if (isChooseMode) ...[
              const SizedBox(height: 8),
              Text(
                'Selecione sua equipe clicando no botão abaixo:',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'As equipes serão formadas automaticamente:',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
            
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            // Jogadores não atribuídos (só aparece no modo CHOOSE)
            if (isChooseMode && unassignedPlayers.isNotEmpty) ...[
              _buildUnassignedSection(unassignedPlayers),
              const SizedBox(height: 16),
            ],
            
            if (isSmallScreen) ...[
              // Em telas pequenas, empilha verticalmente
              _buildTeamSection('Equipe Vermelha', teamRed, const Color(0xFFEF4444), TeamColor.RED, isChooseMode),
              const SizedBox(height: 16),
              _buildTeamSection('Equipe Azul', teamBlue, const Color(0xFF3B82F6), TeamColor.BLUE, isChooseMode),
            ] else ...[
              // Em telas maiores, lado a lado
              Row(
                children: [
                  Expanded(child: _buildTeamSection('Equipe Vermelha', teamRed, const Color(0xFFEF4444), TeamColor.RED, isChooseMode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTeamSection('Equipe Azul', teamBlue, const Color(0xFF3B82F6), TeamColor.BLUE, isChooseMode)),
                ],
              ),
            ],
            
            if (_isAutoAssigning) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: LoadingLogo(size: 60),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Atribuindo equipe automaticamente...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUnassignedSection(List<PlayerInRoom> unassignedPlayers) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF374151).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6B7280)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: const Color(0xFF6B7280),
                    size: isSmallScreen ? 16 : 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aguardando Seleção (${unassignedPlayers.length})',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...unassignedPlayers.map((player) => _buildPlayerTile(player, const Color(0xFF6B7280), showTeamButtons: true)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamSection(String teamName, List<PlayerInRoom> players, Color teamColor, TeamColor team, bool isChooseMode) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        // Verifica se o usuário atual pode se juntar a esta equipe
        final currentPlayerInRoom = _currentRoom?.players
            .where((p) => p.userId == currentUser?.id)
            .firstOrNull;
        
        // Não permite clique se o assignmentType for 'RANDOM'
        final isAutomaticMode = _currentRoom?.assignmentType == 'RANDOM';
        
        final canJoinTeam = !isAutomaticMode &&
                           isChooseMode &&
                           currentPlayerInRoom != null && 
                           currentPlayerInRoom.team == null &&
                           players.length < ((_currentRoom?.maxPlayers ?? 4) ~/ 2);

        final isUserInThisTeam = currentPlayerInRoom?.team == team;
        
        // Debug: vamos ver o que está acontecendo
        debugPrint('DEBUG TeamSection: assignmentType=${_currentRoom?.assignmentType}');
        debugPrint('DEBUG TeamSection: currentPlayerInRoom?.team=${currentPlayerInRoom?.team}');
        debugPrint('DEBUG TeamSection: players.length=${players.length}, maxPerTeam=${(_currentRoom?.maxPlayers ?? 4) ~/ 2}');
        debugPrint('DEBUG TeamSection: canJoinTeam=$canJoinTeam, isUserInThisTeam=$isUserInThisTeam');
        
        return MouseRegion(
          cursor: canJoinTeam ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canJoinTeam ? () {
                debugPrint('DEBUG: Tentando entrar na equipe $team');
                _selectTeam(team);
              } : null,
              borderRadius: BorderRadius.circular(12),
              splashColor: canJoinTeam ? teamColor.withValues(alpha: 0.3) : Colors.transparent,
              highlightColor: canJoinTeam ? teamColor.withValues(alpha: 0.1) : Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: isUserInThisTeam ? 0.2 : (canJoinTeam ? 0.15 : 0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUserInThisTeam ? teamColor : teamColor.withValues(alpha: canJoinTeam ? 1.0 : 0.7),
                    width: isUserInThisTeam ? 2 : (canJoinTeam ? 2 : 1),
                  ),
                  boxShadow: canJoinTeam ? [
                    BoxShadow(
                      color: teamColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: teamColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            teamName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${players.length}/${(_currentRoom?.maxPlayers ?? 4) ~/ 2}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: teamColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // Indicador visual de que é clicável (só aparece se pode se juntar)
                    if (canJoinTeam) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: teamColor.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: teamColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Toque para se juntar',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: teamColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Indicador se o usuário já está na equipe
                    if (isUserInThisTeam) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: teamColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: teamColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Você está nesta equipe',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: teamColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    if (players.isEmpty) ...[
                      Center(
                        child: Text(
                          'Aguardando jogadores...',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ] else ...[
                      ...players.map((player) => _buildPlayerTile(player, teamColor)),
                    ],
                  ],
                ),
              ),
            ),
          ),);
      },
    );
  }


  Widget _buildPlayerTile(PlayerInRoom player, Color teamColor, {bool showTeamButtons = false}) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isCurrentUser = player.userId == currentUser?.id;
        
        final storeProvider = context.read<StoreProvider>();
        final bannerUrl = storeProvider.getBannerUrl(player.activeBannerId);
        final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentUser ? const Color(0xFF6366F1) : const Color(0xFF334155),
              width: isCurrentUser ? 2 : 1,
            ),
            image: resolvedBanner != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      resolvedBanner,
                      headers: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CosmeticAvatar(
                      radius: isSmallScreen ? 16 : 18,
                      avatarUrl: player.avatar,
                      username: player.username,
                      activeAvatarId: player.activeAvatarId,
                      activeFrameId: player.activeFrameId,
                      isVip: player.isVip,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VipUsernameText(
                          username: player.username,
                          isVip: player.isVip,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          Text(
                            'Você',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (player.isHost) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HOST',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              if (showTeamButtons && isCurrentUser) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectTeam(TeamColor.RED),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Vermelho',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectTeam(TeamColor.BLUE),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Azul',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        bool canStart = (_currentRoom?.players.length ?? 0) >= 4; // Mínimo 2 por equipe
        final isHost = _isHost();
        
        String buttonText;
        bool buttonEnabled;
        
        if (_isStartingGame) {
          buttonText = 'Iniciando Quiz...';
          buttonEnabled = false;
        } else if (canStart) {
          buttonText = 'Iniciar Quiz';
          buttonEnabled = true;
        } else {
          buttonText = 'Aguardando Jogadores...';
          buttonEnabled = false;
        }
        
        if (isSmallScreen) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: buttonText,
                  onPressed: () {
                    if (buttonEnabled) {
                      _startGame();
                    }
                  },
                  isPrimary: buttonEnabled,
                  isLarge: true,
                ),
              ),
              if (isHost) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Adicionar 3 Bots (Dev)',
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final currentUser = authProvider.currentUser;
                      if (currentUser != null) {
                        await Provider.of<RoomProvider>(context, listen: false).addBots(currentUser.id, count: 3);
                        AppSnackBar.showSuccess(context, 'Bots adicionados!');
                      }
                    },
                    isPrimary: false,
                    isLarge: false,
                  ),
                ),
              ],
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  if (isHost) ...[
                    Expanded(
                      child: CustomButton(
                        text: '+ 3 Bots',
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final currentUser = authProvider.currentUser;
                          if (currentUser != null) {
                            await Provider.of<RoomProvider>(context, listen: false).addBots(currentUser.id, count: 3);
                            if (!context.mounted) return;
                            AppSnackBar.showSuccess(context, 'Bots adicionados!');
                          }
                        },
                        isPrimary: false,
                        isLarge: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: buttonText,
                      onPressed: () {
                        if (buttonEnabled) {
                          _startGame();
                        }
                      },
                      isPrimary: buttonEnabled,
                      isLarge: true,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  // Nova seção para seleção de disciplinas
  Widget _buildCategorySelectionSection() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        final isManualMode = _currentRoom?.categoryAssignmentMode?.toString().split('.').last == 'MANUAL';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: const Color(0xFF8B5CF6),
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Atribuição de Disciplinas',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            if (isManualMode) ...[
              const SizedBox(height: 8),
              Text(
                'Selecione sua disciplina (uma por equipe):',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'As disciplinas serão distribuídas automaticamente:',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
            
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Botão para distribuição automática (apenas para host no modo AUTO)
            if (!isManualMode && _isHost()) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDistributingCategories ? null : _distributeCategoriesAutomatically,
                  icon: _isDistributingCategories 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: LoadingLogo(size: 60),
                        )
                      : Icon(Icons.casino, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    _isDistributingCategories 
                        ? 'Distribuindo...' 
                        : 'Sortear Disciplinas Automaticamente',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 8 : 12,
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Exibir estatísticas de distribuição
            _buildCategoryDistributionStats(),
            
            // Seletor de disciplina para modo manual
            if (isManualMode) ...[
              const SizedBox(height: 16),
              _buildCategorySelector(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategoryDistributionStats() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        final stats = roomProvider.getCategoryDistributionStats();
        
        if (stats.isEmpty) return const SizedBox.shrink();
        
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribuição por Disciplina',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (isSmallScreen) ...[
                // Lista vertical para telas pequenas
                ...stats.entries.map((entry) => _buildCategoryStatRow(entry.key, entry.value, isSmallScreen)),
              ] else ...[
                // Grid para telas maiores
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final entry = stats.entries.elementAt(index);
                    return _buildCategoryStatRow(entry.key, entry.value, isSmallScreen);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryStatRow(String category, Map<String, dynamic> stat, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getCategoryDisplayName(category),
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Text(
              'V: ${stat['red']}',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF3B82F6)),
            ),
            child: Text(
              'A: ${stat['blue']}',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        if (currentUser == null) return const SizedBox.shrink();
        
        final availableCategories = roomProvider.getAvailableCategoriesForPlayer(currentUser.id);
        final currentPlayer = _currentRoom?.players.firstWhere(
          (p) => p.userId == currentUser.id,
          orElse: () => PlayerInRoom(
            userId: '', 
            username: '', 
            fullName: '',
            isHost: false, 
            isReady: false,
          ),
        );
        
        if (currentPlayer?.team == null) {
          return Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6B7280)),
            ),
            child: Text(
              'Selecione uma equipe primeiro para escolher sua disciplina',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        
        if (currentPlayer?.assignedCategory != null) {
          return Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF10B981),
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disciplina Selecionada:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getCategoryDisplayName(currentPlayer!.assignedCategory!),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        if (availableCategories.isEmpty) {
          return Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Text(
              'Todas as disciplinas já foram ocupadas por sua equipe. Aguarde outros jogadores.',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disciplinas Disponíveis:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: isSmallScreen ? 6 : 8,
              runSpacing: isSmallScreen ? 6 : 8,
              children: availableCategories.map((category) => _buildCategoryChip(category)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final disabled = _isAssigningCategory; // desabilita enquanto requisitando
        
        final categoryIcons = {
          'MATH': Icons.calculate,
          'PORTUGUESE': Icons.language,
          'HISTORY': Icons.history_edu,
          'GEOGRAPHY': Icons.public,
          'SCIENCE': Icons.science,
          'ENGLISH': Icons.chat,
          'MIXED': Icons.category,
        };

        return Opacity(
          opacity: disabled ? 0.6 : 1,
          child: GestureDetector(
            onTap: disabled ? null : () => _selectCategory(category),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcons[category] ?? Icons.category,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Text(
                    _getCategoryDisplayName(category),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isAssigningCategory && !isSmallScreen) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: LoadingLogo(size: 60),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmallScreen) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.quiz,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          AppLogoText(fontSize: isSmallScreen ? 18 : 20),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, 
              '/menu', 
              (route) => false
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.home,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedRoomHeader(bool isSmallScreen) {
    final playersCount = _currentRoom?.players.length ?? 0;
    final maxPlayers = _currentRoom?.maxPlayers ?? 4;
    final progressValue = playersCount / maxPlayers;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: isSmallScreen ? 28 : 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentRoom?.roomName ?? 'Carregando...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'EQUIPES',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '🔴 vs 🔵',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$playersCount/$maxPlayers',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (progressValue * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (progressValue * 100).round(),
                  child: Container(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRoomCodeSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código da Sala',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Compartilhe com seus amigos',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _currentRoom?.roomCode ?? 'XXXX',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 36 : 48,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _copyRoomCode,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatusBanner(bool isSmallScreen) {
    final playersCount = _currentRoom?.players.length ?? 0;
    final readyCount = _currentRoom?.players.where((p) => p.isReady).length ?? 0;
    const minPlayers = 4; // 2 por equipe
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (playersCount < minPlayers) {
      statusText = 'Aguardando mais ${minPlayers - playersCount} jogador(es)';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.hourglass_empty;
    } else if (readyCount < playersCount) {
      statusText = '$readyCount/$playersCount jogadores prontos';
      statusColor = const Color(0xFF3B82F6);
      statusIcon = Icons.people;
    } else {
      statusText = 'Todos prontos! Pode iniciar';
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
    }
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: isSmallScreen ? 24 : 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGameSummary(bool isSmallScreen) {
    String difficultyText = {
      'EASY': 'Fácil',
      'MEDIUM': 'Médio',
      'HARD': 'Difícil',
    }[_currentRoom?.difficulty.value] ?? 'Médio';

    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    String categoriesText = (_currentRoom?.categories ?? []).map((cat) {
      final categoryObj = catProvider.getCategoryByName(cat);
      return categoryObj?.displayName ?? cat;
    }).join(', ');

    if (categoriesText.isEmpty) {
      categoriesText = 'Carregando...';
    }

    String assignmentText = _currentRoom?.assignmentType == 'choose' 
        ? 'Jogador escolhe disciplina'
        : 'Atribuição aleatória';

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showGameSettings = !_showGameSettings;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: const Color(0xFF10B981),
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configurações do Jogo',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  _showGameSettings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                  size: isSmallScreen ? 24 : 28,
                ),
              ],
            ),
          ),
          if (_showGameSettings) ...[
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isSmallScreen ? 1 : 2,
              childAspectRatio: isSmallScreen ? 4 : 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSummaryCard(Icons.category, 'Disciplinas', categoriesText, isSmallScreen),
                _buildSummaryCard(Icons.settings, 'Atribuição', assignmentText, isSmallScreen),
                _buildSummaryCard(Icons.speed, 'Dificuldade', difficultyText, isSmallScreen),
                _buildSummaryCard(Icons.timer, 'Tempo', '${_currentRoom?.questionTime ?? 30}s', isSmallScreen),
                _buildSummaryCard(Icons.quiz, 'Perguntas', '${_currentRoom?.questionCount ?? 10}', isSmallScreen),
                _buildSummaryCard(Icons.group, 'Jogadores', '${(_currentRoom?.maxPlayers ?? 4) ~/ 2} por equipe', isSmallScreen),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, String value, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: isSmallScreen ? 20 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[400],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
