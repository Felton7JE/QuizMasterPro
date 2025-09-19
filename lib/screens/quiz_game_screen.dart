import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/question_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/game_provider.dart';
import '../models/question_model.dart';
import '../models/room_model.dart';
import '../models/game_model.dart';
import 'package:flutter/foundation.dart';

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
  int _bestStreak = 0;
  int _totalPoints = 0;
  // Live leaderboard additions
  Timer? _leaderboardTimer;
  bool _loadingLeaderboard = false;
  List<LeaderboardEntry> _liveLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
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
    // ignore: avoid_print
    print('=== DEBUG QUIZ GAME - INICIANDO CARREGAMENTO ===');
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    
    // ignore: avoid_print
    print('DEBUG: args recebidos = $args');
    // ignore: avoid_print
    print('DEBUG: currentRoom = ${roomProv.currentRoom?.toJson()}');
    // ignore: avoid_print
    print('DEBUG: currentUser = ${auth.currentUser?.toJson()}');
    
    // Tentar obter gameId de múltiplas fontes
    _gameId = args?['gameId']?.toString();
    if (_gameId == null || _gameId!.isEmpty) {
      _gameId = roomProv.currentRoom?.gameId;
    }
    
    // Se gameId ainda é null/vazio, tentar buscar via roomCode
    if (_gameId == null || _gameId!.isEmpty) {
      final roomCode = args?['roomCode']?.toString() ?? roomProv.currentRoom?.roomCode;
      if (roomCode != null) {
        print('DEBUG: GameId vazio, usando roomCode como fallback: $roomCode');
        _gameId = 'room_$roomCode'; // Identificador temporário baseado no roomCode
      }
    }
    
    _category = args?['playerCategory'];
  final bool wasPrefetched = args?['prefetched'] == true; // Indica se countdown fez prefetch
  final Map<String, dynamic>? prefetchedQuestionMap = args?['prefetchedQuestion'] as Map<String, dynamic>?;
    
    // ignore: avoid_print
    print('DEBUG: gameId inicial = $_gameId');
    // ignore: avoid_print
    print('DEBUG: category inicial = $_category');
    // ignore: avoid_print
    print('DEBUG: wasPrefetched = $wasPrefetched');
    
    if (_category == null) {
      final userId = auth.currentUser?.id;
      final players = roomProv.currentRoom?.players ?? [];
      
      // ignore: avoid_print
      print('DEBUG: tentando buscar categoria do userId = $userId');
      // ignore: avoid_print
      print('DEBUG: players na sala = ${players.map((p) => p.toJson()).toList()}');
      
      final player = players.firstWhere(
        (p) => p.userId == userId,
        orElse: () => PlayerInRoom(userId: '', username: '', fullName: '', isReady: false, isHost: false),
      );
      
      // ignore: avoid_print
      print('DEBUG: player encontrado = ${player.toJson()}');
      
      if (player.userId.isNotEmpty) {
        _category = player.assignedCategory;
        // ignore: avoid_print
        print('DEBUG: categoria atribuída ao player = $_category');
      }
    }
    
    // ignore: avoid_print
    print('DEBUG: gameId final = $_gameId');
    // ignore: avoid_print
    print('DEBUG: category final = $_category');
    
    // Validação final - só falha se realmente não temos dados mínimos
    if ((_gameId == null || _gameId!.isEmpty) && _category == null) {
      // Tentar buscar gameId uma última vez
      // ignore: avoid_print
      print('DEBUG: Última tentativa de buscar gameId...');
      
      try {
        await roomProv.refreshRoomDetails();
        final room = roomProv.currentRoom;
        
        if (room?.gameId != null && room!.gameId!.isNotEmpty) {
          _gameId = room.gameId;
          print('DEBUG: GameId obtido após refresh: $_gameId');
        } else {
          // Tentar método específico do provider
          final gameId = await roomProv.getGameId();
          if (gameId != null && gameId.isNotEmpty) {
            _gameId = gameId;
            print('DEBUG: GameId obtido via método específico: $_gameId');
          }
        }
        
        // Tentar obter categoria do player atualizado
        if (_category == null) {
          final userId = auth.currentUser?.id;
          final player = room?.players.firstWhere(
            (p) => p.userId == userId,
            orElse: () => PlayerInRoom(userId: '', username: '', fullName: '', isReady: false, isHost: false),
          );
          if (player != null && player.userId.isNotEmpty) {
            _category = player.assignedCategory;
            print('DEBUG: Categoria obtida após refresh: $_category');
          }
        }
        
      } catch (e) {
        // ignore: avoid_print
        print('❌ ERRO: Falha ao buscar dados atualizados: $e');
      }
      
      // Se ainda não temos dados mínimos, mostrar erro
      if ((_gameId == null || _gameId!.isEmpty) || _category == null) {
        // Debug: loga valores recebidos para diagnóstico rápido
        // ignore: avoid_print
        print('❌ ERRO: Dados insuficientes após todas as tentativas - gameId=$_gameId, category=$_category');
        setState(() {
          _error = 'Erro: Dados do jogo não encontrados. Verifique sua conexão e tente novamente.';
          _loading = false;
        });
        return;
      }
    }
    try {
      final qp = Provider.of<QuestionProvider>(context, listen: false);
      List<QuestionData> list = [];
      
      // ignore: avoid_print
      print('DEBUG: Iniciando busca de questões...');
      
      // Se veio da tela de countdown com prefetch, tentar usar cache primeiro
      if (wasPrefetched) {
        // ignore: avoid_print
        print('DEBUG: Tentando buscar do cache (prefetched=true)');
        final userIdStr = auth.currentUser?.id;
        final cached = qp.getQuestions(_gameId!, _category!, userIdStr);
        // ignore: avoid_print
        print('DEBUG: Questões em cache = ${cached.length}');
        if (cached.isNotEmpty) {
          list = cached;
          // ignore: avoid_print
          print('DEBUG: Usando questões do cache');
        }
        // If nothing in cache but we received a prefetched question map, try to use it
        if (list.isEmpty && prefetchedQuestionMap != null) {
          try {
            final q = QuestionData.fromJson(prefetchedQuestionMap);
            list = [q];
            if (kDebugMode) print('DEBUG QuizGame: Usando pergunta prefetched passada via argumentos');
          } catch (e) {
            if (kDebugMode) print('DEBUG QuizGame: falha ao converter prefetchedQuestion -> $e');
          }
        }
      }
      
      // Se não há cache (ou navegação direta), buscar do backend
      if (list.isEmpty) {
        // ignore: avoid_print
        print('DEBUG: Cache vazio, buscando do backend...');
        // ignore: avoid_print
        print('DEBUG: Chamando fetchQuestions com gameId=$_gameId, category=$_category');
        final userIdStr = auth.currentUser?.id;
        list = await qp.fetchQuestions(_gameId!, _category!, userIdStr);
        
        // ignore: avoid_print
        print('DEBUG: Questões retornadas do backend = ${list.length}');
        if (list.isNotEmpty) {
          // ignore: avoid_print
          print('DEBUG: Primeira questão = ${list.first.toJson()}');
        }
      }
      
      if (!mounted) return;
      
      // ignore: avoid_print
      print('DEBUG: Definindo questões no estado (${list.length} questões)');
      
      setState(() {
        _questions = list;
        _loading = false;
        if (roomProv.currentRoom != null) {
          _timeLeft = roomProv.currentRoom!.questionTime;
          // ignore: avoid_print
          print('DEBUG: Tempo definido para ${_timeLeft}s');
        }
      });
      
      if (_questions.isEmpty) {
        // ignore: avoid_print
        print('❌ AVISO: Lista de questões está vazia após carregamento');
      } else {
        // ignore: avoid_print
        print('✅ SUCESSO: ${_questions.length} questões carregadas');
      }
      
      _startQuestion();
    } catch (e) {
      // ignore: avoid_print
      print('❌ ERRO ao carregar perguntas: $e');
      // ignore: avoid_print
      print('❌ Stack trace: ${StackTrace.current}');
      
      setState(() {
        _error = 'Erro ao carregar perguntas: $e';
        _loading = false;
      });
    }
  }

  void _startQuestion() {
    // ignore: avoid_print
    print('=== DEBUG _startQuestion ===');
    // ignore: avoid_print
    print('DEBUG: _questions.length = ${_questions.length}');
    // ignore: avoid_print
    print('DEBUG: _currentQuestion = $_currentQuestion');
    
    if (_questions.isEmpty) {
      // ignore: avoid_print
      print('❌ AVISO: _startQuestion chamado mas _questions está vazio!');
      return;
    }
    
    // ignore: avoid_print
    print('DEBUG: Iniciando questão ${_currentQuestion + 1}/${_questions.length}');
    // ignore: avoid_print
    print('DEBUG: Questão atual: ${_questions[_currentQuestion].toJson()}');
    
    _timer?.cancel();
    setState(() {
      _selectedAnswer = null;
      _isAnswered = false;
      _showCorrectAnswer = false;
      _timeLeft = Provider.of<RoomProvider>(context, listen: false).currentRoom?.questionTime ?? _timeLeft;
    });
    
    // ignore: avoid_print
    print('DEBUG: Tempo configurado: $_timeLeft segundos');
    
    // Ajusta duração do progresso dinamicamente ao tempo configurado da sala
    final newDuration = Duration(seconds: _timeLeft);
    if (_progressController.duration != newDuration) {
      _progressController.duration = newDuration;
    }
    _progressController.reset();
    _progressController.forward();
    _questionController.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isAnswered) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        if (!_isAnswered) _handleTimeUp();
      }
    });
    _scheduleLeaderboardUpdates();
    
    // ignore: avoid_print
    print('DEBUG: _startQuestion finalizado com sucesso');
  }

  void _handleTimeUp() {
    setState(() {
      _isAnswered = true;
      _showCorrectAnswer = true;
      _streak = 0;
    });
    _timer?.cancel();
    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _showCorrectAnswer = true;
    });
    _progressController.stop();
    final currentQ = _questions[_currentQuestion];
    final correctText = currentQ.options[currentQ.correctAnswer];
    final isCorrect = answer == correctText;
    // Envia resposta ao backend para pontuação oficial
    _submitAnswerToServer(isCorrect, currentQ, answer);
    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  Future<void> _submitAnswerToServer(bool isCorrectLocal, QuestionData currentQ, String selectedText) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      if (userId == null) return; // Sem usuário logado
      final gameId = _gameId;
      if (gameId == null) return;
      final gp = Provider.of<GameProvider>(context, listen: false);

      final selectedIndex = currentQ.options.indexOf(selectedText);
      final timeSpent = (Provider.of<RoomProvider>(context, listen: false).currentRoom?.questionTime ?? _timeLeft) - _timeLeft;

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
          // fallback se resposta não retornou (mantém lógica local mínima)
          if (isCorrectLocal) {
            _correctAnswers++;
            _streak++;
            if (_streak > _bestStreak) _bestStreak = _streak;
            final timeBonus = _timeLeft * 10;
            final streakBonus = _streak > 1 ? (_streak * 50) : 0;
            final questionPoints = 100 + timeBonus + streakBonus;
            _totalPoints += questionPoints;
          } else {
            _streak = 0;
          }
        }
      } else {
        // Em caso de falha, aplica fallback local (para evitar UX quebrada)
        if (isCorrectLocal) {
          _correctAnswers++;
          _streak++;
          if (_streak > _bestStreak) _bestStreak = _streak;
          final timeBonus = _timeLeft * 10;
          final streakBonus = _streak > 1 ? (_streak * 50) : 0;
          final questionPoints = 100 + timeBonus + streakBonus;
          _totalPoints += questionPoints;
        } else {
          _streak = 0;
        }
      }
      if (mounted) setState(() {});
      _fetchLeaderboardOnce();
    } catch (e) {
      // Fallback silencioso + print para debug (poderia mostrar snackbar)
      // ignore: avoid_print
      print('Falha ao enviar resposta: $e');
      if (isCorrectLocal) {
        _correctAnswers++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        final timeBonus = _timeLeft * 10;
        final streakBonus = _streak > 1 ? (_streak * 50) : 0;
        final questionPoints = 100 + timeBonus + streakBonus;
        _totalPoints += questionPoints;
      } else {
        _streak = 0;
      }
      if (mounted) setState(() {});
    }
  }

  // Leaderboard helpers
  void _scheduleLeaderboardUpdates() {
    _leaderboardTimer?.cancel();
    final gameId = _gameId;
    if (gameId == null) return;
    _leaderboardTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isAnswered) {
        _fetchLeaderboardOnce();
      }
    });
  }
  Future<void> _fetchLeaderboardOnce() async {
    final gameId = _gameId;
    if (gameId == null || _loadingLeaderboard) return;
    try {
      _loadingLeaderboard = true;
      final gp = Provider.of<GameProvider>(context, listen: false);
      await gp.loadLiveLeaderboard(gameId);
      if (!mounted) return;
      setState(() {
        _liveLeaderboard = gp.leaderboard;
      });
    } catch (_) {} finally {
      _loadingLeaderboard = false;
    }
  }

  void _nextQuestion() {
    if (_currentQuestion + 1 < _questions.length) {
      setState(() => _currentQuestion++);
      _startQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    Navigator.pushReplacementNamed(
      context,
      '/quiz-results',
      arguments: {
        'correctAnswers': _correctAnswers,
        'totalQuestions': _questions.length,
        'totalPoints': _totalPoints,
        'bestStreak': _bestStreak,
        'questions': _questions.map((q) => q.toJson()).toList(),
        'category': _category,
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _leaderboardTimer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('=== DEBUG build() ===');
    // ignore: avoid_print
    print('DEBUG: _loading = $_loading');
    // ignore: avoid_print
    print('DEBUG: _error = $_error');
    // ignore: avoid_print
    print('DEBUG: _questions.length = ${_questions.length}');
    
    if (_loading) {
      // ignore: avoid_print
      print('DEBUG: Mostrando loading');
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    if (_error != null) {
      // ignore: avoid_print
      print('DEBUG: Mostrando erro: $_error');
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
      print('DEBUG: Mostrando "Sem perguntas"');
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('Sem perguntas', style: TextStyle(color: Colors.white))),
      );
    }

    // ignore: avoid_print
    print('DEBUG: Construindo interface principal do quiz');
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final currentQ = _questions[_currentQuestion];
    
    // ignore: avoid_print
    print('DEBUG: currentQuestion = $_currentQuestion, currentQ = ${currentQ.toJson()}');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
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
                          currentQ.correctAnswer,
                          isSmallScreen,
                        ),
                      );
                    }).toList(),
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
            color: Colors.black.withOpacity(0.1),
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
        backgroundColor = const Color(0xFF10B981).withOpacity(0.2);
        borderColor = const Color(0xFF10B981);
      } else if (isSelected && !isCorrect) {
        backgroundColor = const Color(0xFFEF4444).withOpacity(0.2);
        borderColor = const Color(0xFFEF4444);
      } else {
        backgroundColor = const Color(0xFF1E293B);
        borderColor = const Color(0xFF334155);
        textColor = Colors.grey[400]!;
      }
    } else {
      if (isSelected) {
        backgroundColor = const Color(0xFF6366F1).withOpacity(0.2);
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
          Row(
            children: [
              const Icon(
                Icons.lightbulb,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              const Text(
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? const Color(0xFF6366F1) : const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Text('#${e.position}', style: TextStyle(color: Colors.white, fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isPlayerRow ? 'Você' : e.username, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text('${e.score} pts', style: TextStyle(color: const Color(0xFF10B981), fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('${e.correctAnswers}/${e.totalAnswers}', style: TextStyle(color: Colors.grey, fontSize: isSmall ? 10 : 11)),
        ],
      ),
    );
  }
}
