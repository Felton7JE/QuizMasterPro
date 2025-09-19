import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../services/question_service.dart';
import '../models/room_model.dart';

class QuizCountdownScreen extends StatefulWidget {
  const QuizCountdownScreen({super.key});

  @override
  State<QuizCountdownScreen> createState() => _QuizCountdownScreenState();
}

class _QuizCountdownScreenState extends State<QuizCountdownScreen>
    with TickerProviderStateMixin {
  int _countdown = 3;
  bool _prefetching = false;
  String? _prefetchError;
  String? _gameId;
  String? _playerCategory;
  Map<String, dynamic>? _prefetchedQuestion;
  Timer? _timer; // NEW: hold reference to cancel on dispose
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Try to align with startsAt if provided via route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final startsAtIso = args != null ? args['startsAt'] as String? : null;
      _gameId = args?['gameId']?.toString() ?? Provider.of<RoomProvider>(context, listen: false).currentRoom?.gameId;
      // Categoria: preferir a que veio por argumentos; se ausente, tenta derivar do player
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final roomProv = Provider.of<RoomProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      final player = roomProv.currentRoom?.players.firstWhere(
        (p) => p.userId == userId,
        orElse: () => PlayerInRoom(userId: '', username: '', fullName: '', isReady: false, isHost: false),
      );
      final argCategory = (args?['playerCategory'] as String?)?.trim();
      if (argCategory != null && argCategory.isNotEmpty) {
        _playerCategory = argCategory;
      } else if (player != null && player.userId.isNotEmpty) {
        _playerCategory = player.assignedCategory;
      }

      if (startsAtIso != null) {
        final startsAt = DateTime.tryParse(startsAtIso)?.toLocal();
        if (startsAt != null) {
          final diffSecs = startsAt.difference(DateTime.now()).inSeconds;
          setState(() {
            _countdown = diffSecs.clamp(0, 10);
          });
        }
      }
      // Prefetch perguntas
      if (_gameId != null && _playerCategory != null) {
        _prefetchQuestions(_gameId!, _playerCategory!);
      }
      _startCountdown();
    });
  }

  Future<void> _prefetchQuestions(String gameId, String playerCategory) async {
    // Tenta buscar a pergunta atual para o jogador e guardar em memória para navegação rápida
    setState(() {
      _prefetching = true;
      _prefetchError = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final questionService = Provider.of<QuestionService>(context, listen: false);
      final userIdStr = auth.currentUser?.id;
      if (userIdStr == null || userIdStr.isEmpty) {
        throw Exception('Usuário não autenticado');
      }

      final userId = int.tryParse(userIdStr);
      final gid = int.tryParse(gameId);
      if (userId == null || gid == null) {
        // IDs inválidos (p.ex. fallback strings) -> não tentar prefetch
        throw Exception('IDs inválidos para prefetch (gameId or userId não são numéricos)');
      }

      final resp = await questionService.getCurrentQuestionForPlayer(gid, userId);
      setState(() {
        _prefetchedQuestion = Map<String, dynamic>.from(resp);
      });
      if (kDebugMode) {
        print('DEBUG QuizCountdown: Pergunta prefetched armazenada: $_prefetchedQuestion');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('DEBUG QuizCountdown: Falha no prefetch: $e\n$st');
      }
      setState(() {
        _prefetchError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _prefetching = false;
        });
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _scaleController.reset();
        _scaleController.forward();
        
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _fadeController.forward().then((_) async {
          // Aguardar gameId ser criado antes de navegar
          await _waitForGameCreation();
          
          // Navegar para a tela do quiz
          Navigator.pushReplacementNamed(
            context,
            '/quiz-game',
            arguments: {
              ...(ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {}),
              'gameId': _gameId,
              'playerCategory': _playerCategory,
              'prefetched': true,
              'prefetchedQuestion': _prefetchedQuestion,
            },
          );
        });
      }
    });
  }


  Future<void> _waitForGameCreation() async {
    // ignore: avoid_print
    print('DEBUG QuizCountdown: Aguardando criação do jogo no backend...');
    
    // Se já temos gameId dos argumentos, usar ele
    if (_gameId != null && _gameId!.isNotEmpty) {
      print('DEBUG QuizCountdown: GameId já disponível: $_gameId');
      return;
    }
    
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    int attempts = 0;
    const maxAttempts = 15; // 15 segundos de espera máxima
    
    while (attempts < maxAttempts) {
      try {
        // ignore: avoid_print
        print('DEBUG QuizCountdown: Tentativa ${attempts + 1}/$maxAttempts');
        
        // Primeiro, tenta buscar via método específico do gameId
        if (attempts > 2) {
          try {
            final gameId = await roomProvider.getGameId();
            if (gameId != null && gameId.isNotEmpty) {
              // ignore: avoid_print
              print('DEBUG QuizCountdown: GameId obtido via método específico: $gameId');
              if (mounted) {
                setState(() {
                  _gameId = gameId;
                });
              }
              return;
            }
          } catch (e) {
            // ignore: avoid_print
            print('DEBUG QuizCountdown: Erro no método específico: $e');
          }
        }
        
        // Refresh dos dados da sala
        await roomProvider.refreshRoomDetails();
        final room = roomProvider.currentRoom;
        
        // ignore: avoid_print
        print('DEBUG QuizCountdown: Room após refresh - gameId: ${room?.gameId}, status: ${room?.status}');
        
        if (room?.gameId != null && room!.gameId!.isNotEmpty) {
          // ignore: avoid_print
          print('DEBUG QuizCountdown: GameId obtido via refresh: ${room.gameId}');
          if (mounted) {
            setState(() {
              _gameId = room.gameId;
            });
          }
          return;
        }
        
        // Se o status mudou para IN_PROGRESS mas ainda não temos gameId, aguardar mais
        if (room?.status == 'IN_PROGRESS' || room?.status == 'STARTING') {
          print('DEBUG QuizCountdown: Jogo em progresso, aguardando gameId...');
          // Aguardar um pouco mais quando o jogo está em progresso
          await Future.delayed(const Duration(milliseconds: 1500));
          attempts++; // Contar como tentativa extra
          continue;
        }
        
      } catch (e) {
        // ignore: avoid_print
        print('DEBUG QuizCountdown: Erro ao buscar gameId: $e');
      }
      
      attempts++;
      await Future.delayed(const Duration(seconds: 1));
    }
    
    // ignore: avoid_print
    print('❌ ERRO QuizCountdown: Timeout aguardando criação do jogo');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Jogo não foi iniciado corretamente. Tentando continuar...'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Mesmo sem gameId, tentar continuar com roomCode como fallback
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final roomCode = roomProvider.currentRoom?.roomCode;
      if (roomCode != null) {
        print('DEBUG QuizCountdown: Continuando com roomCode como fallback: $roomCode');
        setState(() {
          _gameId = 'fallback_$roomCode'; // Identificador temporário
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone do quiz
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.quiz,
                    size: isSmallScreen ? 64 : 80,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Texto "Prepare-se"
                Text(
                  'Prepare-se!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Texto "O quiz começará em"
                Text(
                  'O quiz começará em',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    color: Colors.grey[300],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Contador animado + estado de prefetch
                if (_countdown > 0)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: isSmallScreen ? 120 : 150,
                      height: isSmallScreen ? 120 : 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCountdownColor(_countdown),
                        boxShadow: [
                          BoxShadow(
                            color: _getCountdownColor(_countdown).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _countdown.toString(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 48 : 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  // "Começando!" quando countdown for 0
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 24 : 32,
                        vertical: isSmallScreen ? 16 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        'Começando!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                
                SizedBox(height: isSmallScreen ? 48 : 64),
                if (_prefetching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
                        SizedBox(width: 8),
                        Text('Carregando perguntas...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  )
                else if (_prefetchError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Falha ao pré-carregar perguntas: $_prefetchError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  )
                else if (_playerCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Disciplina: $_playerCategory',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                
                // Informações do quiz
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Builder(
                        builder: (context) {
                          final room = Provider.of<RoomProvider>(context, listen: false).currentRoom;
                          final questionTime = room?.questionTime ?? 15;
                          return _buildInfoItem(
                            Icons.timer,
                            'Tempo',
                            '${questionTime}s por pergunta',
                            isSmallScreen,
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final room = Provider.of<RoomProvider>(context, listen: false).currentRoom;
                          final qCount = room?.questionCount ?? 10;
                          return _buildInfoItem(
                            Icons.quiz,
                            'Perguntas',
                            '$qCount questões',
                            isSmallScreen,
                          );
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final room = Provider.of<RoomProvider>(context, listen: false).currentRoom;
                          final mode = room?.gameMode;
                          String label;
                          switch (mode) {
                            case GameMode.INDIVIDUAL:
                              label = 'Individual';
                              break;
                            case GameMode.CLASSIC:
                              label = 'Clássico';
                              break;
                            case GameMode.TEAM:
                            default:
                              label = 'Equipe';
                          }
                          return _buildInfoItem(
                            Icons.group,
                            'Modo',
                            label,
                            isSmallScreen,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCountdownColor(int count) {
    switch (count) {
      case 3:
        return const Color(0xFF10B981); // Verde
      case 2:
        return const Color(0xFFF59E0B); // Amarelo
      case 1:
        return const Color(0xFFEF4444); // Vermelho
      default:
        return const Color(0xFF6366F1); // Azul padrão
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isSmallScreen) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: isSmallScreen ? 20 : 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
