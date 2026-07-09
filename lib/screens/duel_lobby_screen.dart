import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../models/room_model.dart';
import '../widgets/custom_button.dart';
import '../utils/snackbar_utils.dart';
import '../utils/format_utils.dart';

class DuelLobbyScreen extends StatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen>
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
      _refreshRoomData();
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
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

  void _connectWebSocket() {
    final roomCode = _currentRoom?.roomCode;
    if (roomCode == null || roomCode.isEmpty) return;

    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    wsProv.connectToRoom(roomCode);

    wsProv.addListener(() {
      if (!mounted) return;
      final event = wsProv.lastGameStartedEvent;
      if (event == null) return;

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
        },
      );
    });
  }

  Future<void> _refreshRoomData() async {
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
    setState(() {
      _isStartingGame = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        if (mounted) {
          AppSnackBar.showError(context, 'Usuário não autenticado');
        }
        setState(() {
          _isStartingGame = false;
        });
        return;
      }

      final roomProvider = Provider.of<RoomProvider>(context, listen: false);

      // O backend exige que todos estejam 'prontos' para iniciar.
      // Como o modo Duelo não tem botão de 'Pronto', forçamos o estado de todos para true antes de iniciar.
      if (_currentRoom != null) {
        for (var player in _currentRoom!.players) {
          if (!player.isReady) {
            await roomProvider.setPlayerReady(player.userId);
          }
        }
        // Atualiza a sala localmente para garantir que não haja erros de estado no backend
        await roomProvider.refreshRoomDetails();
      }

      final success = await roomProvider.startGame(currentUser.id);

      if (!success && mounted) {
        setState(() {
          _isStartingGame = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao iniciar jogo: $e');
      }
      setState(() {
        _isStartingGame = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
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
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/menu'),
                isPrimary: true,
              ),
            ],
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // Identifica Host e Desafiante
    final hostPlayer = _currentRoom!.players.firstWhere(
      (p) => p.isHost || p.userId == _currentRoom!.hostId?.toString(),
      orElse: () => _currentRoom!.players.isNotEmpty
          ? _currentRoom!.players.first
          : PlayerInRoom(
              userId: '',
              username: 'Host',
              fullName: 'Host',
              isReady: false,
              isHost: true),
    );

    final isHost = hostPlayer.userId == currentUser?.id;

    print(
        'DEBUG LOBBY: currentUser?.id=${currentUser?.id}, hostPlayer.userId=${hostPlayer.userId}, isHost=$isHost');

    final challengerPlayer = _currentRoom!.players.firstWhere(
      (p) => p.userId != hostPlayer.userId,
      orElse: () => PlayerInRoom(
          userId: '',
          username: 'Aguardando Oponente...',
          fullName: 'Aguardando Oponente...',
          isReady: false,
          isHost: false),
    );

    final bool isRoomFull = _currentRoom!.players.length >= 2;
    final bool canStart = isHost && isRoomFull;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lobby de Duelo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
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
            child: Center(
              child: SelectableText(
                'CÓDIGO: ${_currentRoom!.roomCode}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Envie o código no topo para o desafiante',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),

              // Game Details Card
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
                            FormatUtils.formatDifficulty(
                                _currentRoom!.difficulty),
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
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // VS Section
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Host
                    Expanded(
                      child: _buildPlayerCard(
                        player: hostPlayer,
                        isHost: true,
                        isEmpty: false,
                        color: const Color(0xFF6366F1),
                      ),
                    ),

                    // VS Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),

                    // Challenger
                    Expanded(
                      child: _buildPlayerCard(
                        player: challengerPlayer,
                        isHost: false,
                        isEmpty: !isRoomFull,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Actions
              if (isHost) ...[
                if (_isStartingGame)
                  const CircularProgressIndicator(color: Color(0xFF6366F1))
                else
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: canStart
                          ? 'Iniciar Duelo'
                          : 'Aguardando Desafiante...',
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
                const CircularProgressIndicator(color: Color(0xFFEF4444)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required PlayerInRoom player,
    required bool isHost,
    required bool isEmpty,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isEmpty ? const Color(0xFF334155) : color, width: 2),
        boxShadow: isEmpty
            ? []
            : [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor:
                isEmpty ? const Color(0xFF334155) : color.withOpacity(0.2),
            child: isEmpty
                ? const Icon(Icons.person_outline, size: 40, color: Colors.grey)
                : Text(
                    player.username.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'Aguardando...' : player.username,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isEmpty ? Colors.grey : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isHost && !isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Criador',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ],
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
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
