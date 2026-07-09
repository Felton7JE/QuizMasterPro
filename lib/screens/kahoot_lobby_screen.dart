import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../models/room_model.dart';
import '../widgets/custom_button.dart';
import '../utils/snackbar_utils.dart';
import '../utils/format_utils.dart';

class KahootLobbyScreen extends StatefulWidget {
  const KahootLobbyScreen({super.key});

  @override
  State<KahootLobbyScreen> createState() => _KahootLobbyScreenState();
}

class _KahootLobbyScreenState extends State<KahootLobbyScreen>
    with TickerProviderStateMixin {
  RoomModel? _currentRoom;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  bool _isStartingGame = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadRoomData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        _refreshTimer?.cancel();
        return;
      }
      _refreshRoomData();
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    try {
      Provider.of<WebSocketProvider>(context, listen: false).removeListener(_onWebSocketEvent);
    } catch (_) {}
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

  void _onWebSocketEvent() {
    if (!mounted) return;
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    final event = wsProv.lastGameStartedEvent;
    if (event == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';
    final playerCategory = event.playerCategories[userId];
    final gameId = event.gameId;

    wsProv.clearGameStartedEvent();
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
        'gameId': gameId,
        'startsAt': event.startsAt.toIso8601String(),
        'playerCategory': playerCategory,
        'gameMode': 'KAHOOT', // sinaliza ao countdown para ir para /kahoot-game
      },
    );
  }

  void _connectWebSocket() {
    final roomCode = _currentRoom?.roomCode;
    if (roomCode == null || roomCode.isEmpty) return;

    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    wsProv.connectToRoom(roomCode);

    // Mesmo padrão do Duel Lobby: escuta GAME_STARTED → vai para countdown
    wsProv.addListener(_onWebSocketEvent);
  }

  Future<void> _refreshRoomData() async {
    if (!mounted) return;
    if (_currentRoom != null) {
      try {
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        await roomProvider.refreshRoomDetails();
        if (mounted) {
          final updatedRoom = roomProvider.currentRoom;
          setState(() {
            _currentRoom = updatedRoom;
          });
        }
      } catch (e) {
        // Ignora erros de polling
      }
    }
  }

  Future<void> _startGame() async {
    setState(() => _isStartingGame = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        if (mounted) AppSnackBar.showError(context, 'Usuário não autenticado');
        setState(() => _isStartingGame = false);
        return;
      }

      final roomProvider = Provider.of<RoomProvider>(context, listen: false);

      // Auto-ready todos os jogadores (igual ao Duel Lobby)
      if (_currentRoom != null) {
        for (var player in _currentRoom!.players) {
          if (!player.isReady) {
            await roomProvider.setPlayerReady(player.userId);
          }
        }
        await roomProvider.refreshRoomDetails();
      }

      final success = await roomProvider.startGame(currentUser.id);

      if (!success && mounted) {
        setState(() => _isStartingGame = false);
        AppSnackBar.showError(context, roomProvider.error ?? 'Falha ao iniciar o jogo');
      }
      // Navegação é tratada pelo WebSocket GAME_STARTED
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingGame = false);
        AppSnackBar.showError(context, 'Erro ao iniciar jogo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_error != null || _currentRoom == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Erro desconhecido',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Voltar ao Menu',
                onPressed: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  Provider.of<WebSocketProvider>(context, listen: false).disconnect();
                  Provider.of<RoomProvider>(context, listen: false).leaveRoom(auth.currentUser?.id ?? '');
                  Navigator.pushReplacementNamed(context, '/menu');
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final hostPlayer = _currentRoom!.players.firstWhere(
      (p) => p.isHost || p.userId == _currentRoom!.hostId?.toString(),
      orElse: () => _currentRoom!.players.isNotEmpty
          ? _currentRoom!.players.first
          : PlayerInRoom(
              userId: '', username: 'Host', fullName: 'Host',
              isReady: false, isHost: true),
    );

    final isHost = hostPlayer.userId == currentUser?.id;
    final playerCount = _currentRoom!.players.length;
    final bool canStart = isHost && playerCount >= 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lobby Kahoot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Provider.of<WebSocketProvider>(context, listen: false).disconnect();
            Provider.of<RoomProvider>(context, listen: false)
                .leaveRoom(currentUser?.id ?? '');
            Navigator.pushReplacementNamed(context, '/menu');
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.copy, color: Color(0xFF6366F1), size: 14),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _currentRoom!.roomCode));
                    AppSnackBar.showSuccess(context, 'Código copiado!');
                  },
                  child: SelectableText(
                    'CÓDIGO: ${_currentRoom!.roomCode}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                _currentRoom!.roomName,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Compartilhe o código para os jogadores entrarem',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),

              // Game Details Card — idêntico ao Duel Lobby
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(Icons.timer,
                            '${_currentRoom!.questionTime}s', 'Por Pergunta'),
                        _buildDetailItem(Icons.format_list_numbered,
                            '${_currentRoom!.questionCount}', 'Questões'),
                        _buildDetailItem(
                            Icons.bar_chart,
                            FormatUtils.formatDifficulty(_currentRoom!.difficulty),
                            'Dificuldade'),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category,
                            color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentRoom!.categories.join(', '),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Players Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, color: Color(0xFF6366F1), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$playerCount Jogador${playerCount != 1 ? "es" : ""} na Sala',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: playerCount == 0
                            ? const Center(
                                child: Text('Nenhum jogador ainda...',
                                    style: TextStyle(color: Colors.white54)),
                              )
                            : ListView.separated(
                                itemCount: _currentRoom!.players.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Color(0xFF334155), height: 16),
                                itemBuilder: (_, index) {
                                  final player = _currentRoom!.players[index];
                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: player.isHost
                                            ? const Color(0xFF6366F1).withOpacity(0.2)
                                            : const Color(0xFF334155),
                                        child: Text(
                                          (player.username.isNotEmpty
                                                  ? player.username[0]
                                                  : '?')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: player.isHost
                                                ? const Color(0xFF6366F1)
                                                : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          player.username,
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 15),
                                        ),
                                      ),
                                      if (player.isHost)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1)
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Criador',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF6366F1)),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botões — mesmo padrão do Duel Lobby
              if (isHost) ...[
                if (_isStartingGame)
                  const CircularProgressIndicator(color: Color(0xFF6366F1))
                else
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: canStart
                          ? 'Iniciar Kahoot!'
                          : 'Aguardando jogadores (mín. 2)...',
                      onPressed: canStart ? () => _startGame() : null,
                      isPrimary: canStart,
                      isLarge: true,
                    ),
                  ),
              ] else ...[
                const Text(
                  'Aguardando o anfitrião iniciar a partida...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: Color(0xFF6366F1)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
