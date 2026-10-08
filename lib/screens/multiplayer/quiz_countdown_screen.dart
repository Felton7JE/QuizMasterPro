import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../providers/game/room_provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../services/question_service.dart';
import '../../models/room_model.dart';

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
  late AnimationController _pulseController; // NEW
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation; // NEW

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));

    // Try to align with startsAt if provided via route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final startsAtIso = args != null ? args['startsAt'] as String? : null;

      // gameId e playerCategory chegam DIRETAMENTE do evento WebSocket via argumentos de navegação
      _gameId = args?['gameId']?.toString();
      final argCategory = (args?['playerCategory'] as String?)?.trim();

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final roomProv = Provider.of<RoomProvider>(context, listen: false);
      final userId = auth.currentUser?.id;

      if (argCategory != null && argCategory.isNotEmpty) {
        _playerCategory = argCategory;
      } else {
        // Fallback: tentar obter do estado local da sala (para o host que veio via REST)
        final player = roomProv.currentRoom?.players.firstWhere(
          (p) => p.userId == userId,
          orElse: () => PlayerInRoom(userId: '', username: '', fullName: '', isReady: false, isHost: false),
        );
        if (player != null && player.userId.isNotEmpty) {
          _playerCategory = player.assignedCategory;
        }
      }

      if (kDebugMode) {
        debugPrint('DEBUG QuizCountdown: gameId=$_gameId, category=$_playerCategory');
      }

      // Alinhar countdown com startsAt se disponível
      if (startsAtIso != null) {
        final startsAt = DateTime.tryParse(startsAtIso)?.toLocal();
        if (startsAt != null) {
          final diffSecs = startsAt.difference(DateTime.now()).inSeconds;
          if (mounted) {
            setState(() {
              _countdown = diffSecs.clamp(0, 10);
            });
          }
        }
      }

      // Prefetch da pergunta (opcional, melhora performance)
      if (_gameId != null && _gameId!.isNotEmpty && !_gameId!.startsWith('fallback')) {
        final userIdStr = auth.currentUser?.id;
        if (userIdStr != null && userIdStr.isNotEmpty) {
          _prefetchQuestions(_gameId!, _playerCategory ?? '');
        }
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
        debugPrint('DEBUG QuizCountdown: Pergunta prefetched armazenada: $_prefetchedQuestion');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('DEBUG QuizCountdown: Falha no prefetch: $e\n$st');
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
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        _scaleController.reset();
        _scaleController.forward();
        
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _fadeController.forward().then((_) {
          if (!mounted) return;
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          final gameMode = args['gameMode']?.toString() ?? '';

          String targetRoute;
          if (gameMode == 'KAHOOT') {
            targetRoute = '/kahoot-game';
          } else if (gameMode == 'SURVIVAL') {
            targetRoute = '/survival-game';
          } else if (gameMode == 'TIME_ATTACK') {
            targetRoute = '/time-attack-game';
          } else if (gameMode == 'SOLO_MAP') {
            targetRoute = '/solo-game';
          } else if (gameMode == 'BOSS_BATTLE') {
            targetRoute = '/boss-battle';
          } else {
            targetRoute = '/quiz-game';
          }

          Navigator.pushReplacementNamed(
            context,
            targetRoute,
            arguments: {
              ...args,
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



  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case 'SOLO_MAP':
        return Icons.explore_rounded;
      case 'BOSS_BATTLE':
        return Icons.local_fire_department_rounded;
      case 'DUEL':
        return Icons.flash_on_rounded;
      case 'TIME_ATTACK':
        return Icons.timer_rounded;
      case 'TEAM':
      case 'KAHOOT':
        return Icons.groups_rounded;
      case 'SURVIVAL':
        return Icons.favorite_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final gameModeArg = args['gameMode']?.toString() ?? '';

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Ícone do quiz
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3 * _pulseAnimation.value),
                              blurRadius: 20 * _pulseAnimation.value,
                              spreadRadius: 5 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForMode(gameModeArg),
                          size: isSmallScreen ? 64 : 80,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    );
                  },
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
                            color: _getCountdownColor(_countdown).withValues(alpha: 0.5),
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
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
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
                          if (gameModeArg == 'SURVIVAL') {
                            return _buildInfoItem(Icons.timer_off, 'Tempo', 'Infinito', isSmallScreen);
                          } else if (gameModeArg == 'TIME_ATTACK') {
                            return _buildInfoItem(Icons.timer, 'Tempo', '45s Iniciais', isSmallScreen);
                          }
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
                          if (gameModeArg == 'SURVIVAL' || gameModeArg == 'TIME_ATTACK') {
                            return _buildInfoItem(Icons.all_inclusive, 'Perguntas', 'Infinitas', isSmallScreen);
                          }
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
                          if (gameModeArg == 'SURVIVAL') {
                            return _buildInfoItem(Icons.favorite, 'Modo', 'Sobrevivência', isSmallScreen);
                          } else if (gameModeArg == 'TIME_ATTACK') {
                            return _buildInfoItem(Icons.speed, 'Modo', 'Contra o Tempo', isSmallScreen);
                          }
                          final room = Provider.of<RoomProvider>(context, listen: false).currentRoom;
                          final mode = room?.gameMode;
                          String label;
                          switch (mode) {
                            case GameMode.CLASSIC:
                              label = 'Clássico';
                              break;
                            case GameMode.DUEL:
                              label = 'Duelo';
                              break;
                            case GameMode.KAHOOT:
                              label = 'Kahoot';
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
        const SizedBox(height: 4),
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
