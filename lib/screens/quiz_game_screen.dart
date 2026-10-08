import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/exit_confirm_scope.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/room_provider.dart';
import '../models/question_model.dart';
import '../models/room_model.dart';
import '../models/game_model.dart';
import '../services/websocket_service.dart';
import '../services/app_audio_service.dart';
import '../widgets/in_game_chat_bubble.dart';
import '../widgets/in_game_chat_sheet.dart';
import '../widgets/in_game_chat_button.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/vip_badge_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  // Core state
  List<QuestionData> _questions = [];
  int _currentQuestion = 0;
  int _timeLeft = 15; // Will be replaced by room.questionTime
  Timer? _timer;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _showCorrectAnswer = false;
  bool _loading = true;
  String? _error;
  String? _category;
  String? _gameId;

  // Animations
  late AnimationController _progressController;
  late AnimationController _questionController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  // Player stats
  int _correctAnswers = 0;
  int _streak = 0;
  int? _serverCorrectAnswer;
  int _bestStreak = 0;
  int _totalPoints = 0;
  // Live leaderboard
  List<LeaderboardEntry> _liveLeaderboard = [];
  final bool _loadingLeaderboard = false;

  // In-Game Chat
  InGameChatMessageEvent? _latestChatMessage;
  Timer? _chatCooldownTimer;
  int _chatCooldownSeconds = 0;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadVibrationSetting();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WebSocketProvider>(context, listen: false).addListener(_onWebSocketEvent);
      // Inicia música do jogo
      Provider.of<AppAudioService>(context, listen: false).playGameMusic();
      _loadQuestions();
    });
  }

  Future<void> _loadVibrationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatCooldownTimer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    try {
      Provider.of<WebSocketProvider>(context, listen: false).removeListener(_onWebSocketEvent);
      Provider.of<AppAudioService>(context, listen: false).playMenuMusic();
    } catch (_) {}
    super.dispose();
  }

  void _onWebSocketEvent() {
    if (!mounted) return;
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    final event = wsProv.lastLeaderboardUpdateEvent;
    if (event != null) {
      try {
        final list = event.payload as List<dynamic>;
        final parsed = list.map((e) => LeaderboardEntry.fromJson(e)).toList();
        setState(() {
          _liveLeaderboard = parsed;
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao parsear leaderboard via WS: $e');
      }
      wsProv.clearLeaderboardUpdateEvent();
    }

    final chatEvent = wsProv.lastChatMessageEvent;
    if (chatEvent != null) {
      setState(() {
        _latestChatMessage = chatEvent;
      });
      wsProv.clearChatMessageEvent();
    }
  }

  void _startChatCooldown() {
    _chatCooldownTimer?.cancel();
    setState(() {
      _chatCooldownSeconds = 8;
    });

    _chatCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_chatCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _chatCooldownSeconds = 0;
        });
      } else {
        setState(() {
          _chatCooldownSeconds--;
        });
      }
    });
  }

  void _sendChatMessage(String phrase, int? phraseId) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    final user = auth.currentUser;
    final roomCode = roomProv.currentRoom?.roomCode ?? '';

    if (user == null) return;

    final chatMessage = InGameChatMessageEvent(
      roomCode: roomCode,
      userId: user.id,
      username: user.username,
      phraseText: phrase,
      avatar: user.avatar,
      isVip: user.isVip,
      activeFrameId: user.activeFrameId,
      activePhraseId: phraseId ?? user.activePhraseId,
      timestamp: DateTime.now(),
    );

    wsProv.sendChatMessage(roomCode, chatMessage);
    _startChatCooldown();
  }

  void _openChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InGameChatSheet(
        cooldownSecondsRemaining: _chatCooldownSeconds,
        onSelectPhrase: (phrase, phraseId) {
          _sendChatMessage(phrase, phraseId);
        },
      ),
    );
  }

  void _initControllers() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _questionController, curve: Curves.easeOut));
  }

  Future<void> _loadQuestions() async {
    if (kDebugMode) debugPrint('=== DEBUG QUIZ GAME - CARREGANDO TODAS AS PERGUNTAS ===');
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    
    // Obter gameId e categoria dos argumentos (vindos do WebSocket)
    _gameId = args?['gameId']?.toString();
    _category = args?['playerCategory'];
    
    if (_gameId == null || _gameId!.isEmpty) {
      _gameId = roomProv.currentRoom?.gameId;
    }
    
    if (kDebugMode) {
      debugPrint('DEBUG: gameId=$_gameId, category=$_category, userId=${auth.currentUser?.id}');
    }
    
    // Validar gameId
    if (_gameId == null || _gameId!.isEmpty || _gameId!.startsWith('room_') || _gameId!.startsWith('fallback')) {
      setState(() {
        _error = 'Erro: ID do jogo não encontrado.';
        _loading = false;
      });
      return;
    }
    
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _error = 'Erro: Utilizador não autenticado.';
        _loading = false;
      });
      return;
    }

    try {
      // Buscar TODAS as perguntas de uma vez via GET /api/games/{id}/questions?userId=X
      final gp = Provider.of<GameProvider>(context, listen: false);
      final success = await gp.loadGameQuestions(_gameId!, userId);
      
      if (!mounted) return;
      
      if (!success || gp.questions.isEmpty) {
        setState(() {
          _error = gp.error ?? 'Nenhuma pergunta encontrada para a sua categoria.';
          _loading = false;
        });
        return;
      }
      
      // Converter QuestionModel → QuestionData para compatibilidade com a UI existente
      final allQuestions = gp.questions.map((qm) => QuestionData(
        id: qm.id,
        question: qm.question,
        options: qm.options,
        correctAnswer: qm.correctAnswer,
        category: qm.category,
        difficulty: Difficulty.fromString(qm.difficulty.value),
        order: 0,
        explanation: qm.explanation,
      )).toList();
      
      if (kDebugMode) {
        debugPrint('✅ SUCESSO: ${allQuestions.length} perguntas carregadas de uma vez!');
        for (var i = 0; i < allQuestions.length; i++) {
          debugPrint('   Pergunta ${i + 1}: ${allQuestions[i].question.substring(0, allQuestions[i].question.length.clamp(0, 50))}...');
        }
      }
      
      setState(() {
        _questions = allQuestions;
        _currentQuestion = 0;
        _loading = false;
        if (roomProv.currentRoom != null) {
          _timeLeft = roomProv.currentRoom!.questionTime;
        }
      });
      
      _startQuestion();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ERRO ao carregar perguntas: $e');
      setState(() {
        _error = 'Erro ao carregar perguntas: $e';
        _loading = false;
      });
    }
  }

  void _startQuestion() {
    // ignore: avoid_print
    debugPrint('=== DEBUG _startQuestion ===');
    
    if (_questions.isEmpty) {
      debugPrint('❌ AVISO: _startQuestion chamado mas _questions está vazio!');
      return;
    }
    
    _timer?.cancel();
    setState(() {
      _selectedAnswer = null;
      _isAnswered = false;
      _showCorrectAnswer = false;
      _timeLeft = Provider.of<RoomProvider>(context, listen: false).currentRoom?.questionTime ?? _timeLeft;
    });
    
    // Ajusta duração do progresso dinamicamente
    final newDuration = Duration(seconds: _timeLeft);
    if (_progressController.duration != newDuration) {
      _progressController.duration = newDuration;
    }
    _progressController.reset();
    _progressController.forward();
    _questionController.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0 && !_isAnswered) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 5 && _timeLeft > 0) {
          context.read<AppAudioService>().playSfxTimer();
        }
      } else {
        timer.cancel();
        if (!_isAnswered) _handleTimeUp();
      }
    });
    
    debugPrint('DEBUG: _startQuestion finalizado com sucesso');
  }

  Future<void> _handleTimeUp() async {
    setState(() {
      _isAnswered = true;
      _showCorrectAnswer = false;
      _streak = 0;
    });
    _timer?.cancel();
    final currentQ = _questions[_currentQuestion];
    await _submitAnswerToServer(currentQ, "");
  }

  Future<void> _selectAnswer(String answer) async {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _showCorrectAnswer = false;
    });
    _progressController.stop();

    final currentQ = _questions[_currentQuestion];
    await _submitAnswerToServer(currentQ, answer);
  }

  Future<void> _submitAnswerToServer(QuestionData currentQ, String selectedText) async {
    bool isCorrect = false;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      if (userId == null) return; // Sem usuário logado
      final gameId = _gameId;
      if (gameId == null) return;
      final gp = Provider.of<GameProvider>(context, listen: false);

      final selectedIndex = selectedText.isEmpty ? -1 : currentQ.options.indexOf(selectedText);
      final timeSpent = ((Provider.of<RoomProvider>(context, listen: false).currentRoom?.questionTime ?? _timeLeft) - _timeLeft) * 1000;

      final success = await gp.submitAnswer(
        gameId: gameId,
        userId: userId,
        questionId: currentQ.id,
        selectedAnswer: selectedIndex,
        timeSpent: timeSpent,
      );

      if (success) {
        // Busca último AnswerResponse para atualizar pontuação e streak locais conforme servidor
        final answers = gp.playerAnswers.where((a) => a.questionId == currentQ.id).toList();
        if (answers.isNotEmpty) {
          final resp = answers.last;
          isCorrect = resp.isCorrect;
          if (resp.correctAnswer != null) {
            _serverCorrectAnswer = resp.correctAnswer;
          }
          // Atualiza estatísticas locais com dados do servidor
          if (resp.isCorrect) {
            _correctAnswers++;
            _streak++;
            if (_streak > _bestStreak) _bestStreak = _streak;
          } else {
            _streak = 0;
          }
          _totalPoints += resp.points; // Usa pontuação oficial agregada
        } else {
          _streak = 0;
        }
      } else {
        // Falha no servidor. Não dá pontos locais para evitar cheating.
        if (kDebugMode) debugPrint('Falha no servidor ao submeter resposta.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Falha ao enviar resposta: $e');
    }
    
    if (mounted) {
      setState(() {
        _showCorrectAnswer = true;
      });

      if (selectedText.isNotEmpty) {
        if (isCorrect) {
          context.read<AppAudioService>().playSfxCorrect();
          context.read<AppAudioService>().triggerVibration();
        } else {
          context.read<AppAudioService>().playSfxWrong();
          context.read<AppAudioService>().triggerVibration(heavy: true);
        }
      }

      Future.delayed(const Duration(seconds: 2), _nextQuestion);
    }
  }

  void _nextQuestion() {
    _serverCorrectAnswer = null;
    if (_currentQuestion + 1 < _questions.length) {
      setState(() => _currentQuestion++);
      _startQuestion();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isSolo = routeArgs?['isSolo'] == true;
    final isSeason = routeArgs?['isSeason'] == true;
    final isPractice = routeArgs?['isPractice'] == true;

    setState(() => _loading = true);

    // Finalizar o jogo no backend se for host ou solo para contar missões de fim de jogo
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final gameProv = Provider.of<GameProvider>(context, listen: false);

    final isHost = roomProv.isPlayerHost(auth.currentUser?.id ?? '');

    if ((isSolo || isHost) && _gameId != null) {
      try {
        await gameProv.finishGame(_gameId!, auth.currentUser?.id ?? '');
      } catch (e) {
        if (kDebugMode) debugPrint('Erro ao finalizar o jogo: $e');
      }
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/quiz-results',
      arguments: {
        'gameId': _gameId,
        'correctAnswers': _correctAnswers,
        'totalQuestions': _questions.length,
        'totalPoints': _totalPoints,
        'bestStreak': _bestStreak,
        'questions': _questions.map((q) => q.toJson()).toList(),
        'category': _category,
        'isSolo': isSolo,
        'isSeason': isSeason,
        'isPractice': isPractice,
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return ExitConfirmScope(
          title: 'Abandonar a partida?',
          message: 'Se saíres agora, deixas a sala e perdes a tua pontuação nesta partida.',
          confirmLabel: 'Abandonar',
          onConfirm: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            Provider.of<WebSocketProvider>(context, listen: false).disconnect();
            Provider.of<RoomProvider>(context, listen: false)
                .leaveRoom(auth.currentUser?.id ?? '');
            Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
          },
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    // ignore: avoid_print
    debugPrint('=== DEBUG build() ===');
    // ignore: avoid_print
    debugPrint('DEBUG: _loading = $_loading');
    // ignore: avoid_print
    debugPrint('DEBUG: _error = $_error');
    // ignore: avoid_print
    debugPrint('DEBUG: _questions.length = ${_questions.length}');
    
    if (_loading) {
      // ignore: avoid_print
      debugPrint('DEBUG: Mostrando loading');
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    if (_error != null) {
      // ignore: avoid_print
      debugPrint('DEBUG: Mostrando erro: $_error');
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      // ignore: avoid_print
      debugPrint('DEBUG: Mostrando "Sem perguntas"');
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('Sem perguntas', style: TextStyle(color: Colors.white))),
      );
    }

    // ignore: avoid_print
    debugPrint('DEBUG: Construindo interface principal do quiz');
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final currentQ = _questions[_currentQuestion];
    
    // ignore: avoid_print
    debugPrint('DEBUG: currentQuestion = $_currentQuestion, currentQ = ${currentQ.toJson()}');

    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final isChatEnabled = roomProv.currentRoom?.enableChat ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(isSmallScreen, currentQ.category),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    child: Column(
                      children: [
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildQuestionCard(currentQ, isSmallScreen),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        ...currentQ.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                            child: _buildAnswerOption(
                              option,
                              String.fromCharCode(65 + index),
                              _serverCorrectAnswer ?? currentQ.correctAnswer,
                              isSmallScreen,
                            ),
                          );
                        }),
                        if (_showCorrectAnswer) ...[
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          _buildExplanation(currentQ.explanation ?? '', isSmallScreen),
                        ],
                        const SizedBox(height: 32),
                        _buildMiniLeaderboard(isSmallScreen),
                      ],
                    ),
                  ),
                ),
                _buildFooter(isSmallScreen),
              ],
            ),

            // In-Game Chat Overlay
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: InGameChatOverlay(
                latestMessage: _latestChatMessage,
                onDismiss: () {
                  if (mounted) setState(() => _latestChatMessage = null);
                },
              ),
            ),

            // Botão flutuante de Chat / Reações
            if (isChatEnabled)
              Positioned(
                bottom: isSmallScreen ? 16 : 24,
                right: isSmallScreen ? 16 : 24,
                child: InGameChatButton(
                  cooldownSecondsRemaining: _chatCooldownSeconds,
                  onTap: _openChatSheet,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, String category) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta ${_currentQuestion + 1} de ${_questions.length}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Icon(
                Icons.timer,
                color: _timeLeft <= 5 ? Colors.red : const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${_timeLeft}s',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 5 ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) => LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeLeft <= 5 ? Colors.red : const Color(0xFF6366F1),
                    ),
                    minHeight: isSmallScreen ? 6 : 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionData question, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        question.question,
        style: TextStyle(
          fontSize: isSmallScreen ? 18 : 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnswerOption(String option, String letter, int correctIndex, bool isSmallScreen) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = _questions[_currentQuestion].options.indexOf(option) == correctIndex;
    final showResult = _showCorrectAnswer;

    Color backgroundColor;
    Color borderColor;
    Color textColor = Colors.white;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.2);
        borderColor = const Color(0xFF10B981);
      } else if (isSelected && !isCorrect) {
        backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
        borderColor = const Color(0xFFEF4444);
      } else {
        backgroundColor = const Color(0xFF1E293B);
        borderColor = const Color(0xFF334155);
        textColor = Colors.grey[400]!;
      }
    } else {
      if (isSelected) {
        backgroundColor = const Color(0xFF6366F1).withValues(alpha: 0.2);
        borderColor = const Color(0xFF6366F1);
      } else {
        backgroundColor = const Color(0xFF1E293B);
        borderColor = const Color(0xFF334155);
      }
    }

    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 32 : 40,
              height: isSmallScreen ? 32 : 40,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (showResult && isCorrect)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF10B981),
                size: isSmallScreen ? 20 : 24,
              )
            else if (showResult && isSelected && !isCorrect)
              Icon(
                Icons.cancel,
                color: const Color(0xFFEF4444),
                size: isSmallScreen ? 20 : 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(String explanation, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Color(0xFF6366F1),
              ),
              SizedBox(width: 8),
              Text(
                'Explicação',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              color: Colors.grey[300],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.check_circle,
            'Acertos',
            '$_correctAnswers/${_currentQuestion + (_isAnswered ? 1 : 0)}',
            const Color(0xFF10B981),
            isSmallScreen,
          ),
          _buildStatItem(
            Icons.local_fire_department,
            'Sequência',
            '$_streak',
            const Color(0xFFEF4444),
            isSmallScreen,
          ),
            _buildStatItem(
            Icons.stars,
            'Pontos',
            '$_totalPoints',
            const Color(0xFF6366F1),
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[400]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Insert mini leaderboard widget usage where appropriate
  // (Developer note: Replace occurrence after question card)
  Widget _buildMiniLeaderboard(bool isSmallScreen) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final myId = auth.currentUser?.id;
    final top = _liveLeaderboard.take(3).toList();
    LeaderboardEntry? me;
    if (myId != null && !_liveLeaderboard.any((e) => e.userId == myId && e.position <= 3)) {
      me = _liveLeaderboard.where((e) => e.userId == myId).isNotEmpty
          ? _liveLeaderboard.firstWhere((e) => e.userId == myId)
          : null;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 6),
              Text('Ranking ao vivo', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              if (_loadingLeaderboard)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
            ],
          ),
          const SizedBox(height: 8),
          ...top.map((e) => _buildLeaderboardRow(e, isSmallScreen, highlight: myId != null && e.userId == myId)),
          if (me != null) ...[
            const Divider(color: Color(0xFF334155), height: 16),
            _buildLeaderboardRow(me, isSmallScreen, highlight: true, isPlayerRow: true),
          ],
        ],
      ),
    );
  }
  Widget _buildLeaderboardRow(LeaderboardEntry e, bool isSmall, {bool highlight = false, bool isPlayerRow = false}) {
    Widget rankWidget;

    if (e.position == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 16));
    } else if (e.position == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 16));
    } else if (e.position == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 16));
    } else {
      rankWidget = Text(
        '#${e.position}',
        style: TextStyle(
          color: Colors.white70,
          fontSize: isSmall ? 12 : 13,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 6 : 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFF818CF8) : const Color(0xFF334155),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 8),
          CosmeticAvatar(
            radius: isSmall ? 14 : 16,
            avatarUrl: e.avatar,
            username: e.username,
            activeAvatarId: e.activeAvatarId,
            activeFrameId: e.activeFrameId,
            isVip: e.isVip,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: VipUsernameText(
                    username: e.username,
                    isVip: e.isVip,
                    style: TextStyle(
                      color: highlight ? Colors.white : Colors.white70,
                      fontSize: isSmall ? 12 : 13,
                      fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isPlayerRow) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VOCÊ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${e.score} pts',
            style: TextStyle(
              color: const Color(0xFF10B981),
              fontSize: isSmall ? 12 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
