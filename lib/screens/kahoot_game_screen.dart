import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/websocket_service.dart';

class KahootGameScreen extends StatefulWidget {
  const KahootGameScreen({super.key});

  @override
  State<KahootGameScreen> createState() => _KahootGameScreenState();
}

class _KahootGameScreenState extends State<KahootGameScreen>
    with TickerProviderStateMixin {
  // Game info
  String? _gameId;
  int _questionTime = 15;

  // Current question (driven by NEXT_QUESTION WebSocket events)
  Map<String, dynamic>? _currentQuestion;
  int _questionIndex = 0;
  int _totalQuestions = 0;

  // Per-question state
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;
  bool _showCorrectAnswer = false; // true apenas quando o tempo acaba!
  int _totalPoints = 0;
  int _correctAnswers = 0;
  int _pointsEarned = 0;
  
  // Pending results (para revelar no fim do tempo)
  int _pendingPointsEarned = 0;
  bool _pendingIsCorrect = false;
  
  // Streak tracking
  int _currentStreak = 0;
  int _bestStreak = 0;

  // Timer
  int _timeLeft = 15;
  Timer? _timer;

  // Game end
  bool _gameEnded = false;

  // Animations — mesmo padrão do quiz_game_screen
  late AnimationController _progressController;
  late AnimationController _questionController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    // Remove listener ao sair
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    wsProv.removeListener(_onWebSocketEvent);
    super.dispose();
  }

  void _initGame() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _gameId = args?['gameId']?.toString();
    _questionTime = (args?['questionTime'] as num?)?.toInt() ?? 15;

    // Atualizar duração do progressController com o tempo real
    _progressController.duration = Duration(seconds: _questionTime);

    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    wsProv.addListener(_onWebSocketEvent);

    // Consumir evento pendente (primeira pergunta já foi emitida ao iniciar)
    final pendingNext = wsProv.lastNextQuestionEvent;
    if (pendingNext != null) {
      wsProv.clearNextQuestionEvent();
      _onNextQuestion(pendingNext);
    }

    final pendingEnd = wsProv.lastGameEndedEvent;
    if (pendingEnd != null) {
      wsProv.clearGameEndedEvent();
      _onGameEnded();
    }
  }

  void _onWebSocketEvent() {
    if (!mounted) return;
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);

    final nextQ = wsProv.lastNextQuestionEvent;
    if (nextQ != null) {
      wsProv.clearNextQuestionEvent();
      _onNextQuestion(nextQ);
    }

    final ended = wsProv.lastGameEndedEvent;
    if (ended != null) {
      wsProv.clearGameEndedEvent();
      _onGameEnded();
    }
  }

  void _onNextQuestion(NextQuestionEvent event) {
    _timer?.cancel();
    _progressController.stop();

    setState(() {
      _currentQuestion = event.questionData;
      _questionIndex = event.questionIndex;
      _totalQuestions = event.totalQuestions;
      _selectedAnswerIndex = null;
      _hasAnswered = false;
      _showCorrectAnswer = false;
      _timeLeft = _questionTime;
      _pointsEarned = 0;
      _pendingPointsEarned = 0;
      _pendingIsCorrect = false;
    });

    // Animação de entrada da pergunta
    _questionController.forward(from: 0);

    // Iniciar progresso e timer
    _progressController.duration = Duration(seconds: _questionTime);
    _progressController.forward(from: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } 
      
      // Quando chega a zero, aciona o fim de tempo (seja porque respondeu ou não)
      if (_timeLeft == 0 && !_showCorrectAnswer) {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _progressController.stop();
    setState(() {
      _showCorrectAnswer = true;
      
      // Aplicar os pontos que estavam pendentes
      if (_hasAnswered && _pendingIsCorrect) {
        _correctAnswers++;
        _pointsEarned = _pendingPointsEarned;
        _totalPoints += _pointsEarned;
      }
    });
    // O backend enviará o NEXT_QUESTION após os 4 segundos de revelação
  }

  Future<void> _selectAnswer(int index) async {
    if (_hasAnswered || _currentQuestion == null) return;

    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;
      // NÃO mudamos _showCorrectAnswer para true aqui. Mantemos o suspense!
    });

    // Submeter ao backend em background
    await _submitAnswer(index);
  }

  Future<void> _submitAnswer(int selectedIndex) async {
    if (_gameId == null || _currentQuestion == null) return;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      if (userId == null) return;

      final gp = Provider.of<GameProvider>(context, listen: false);
      final questionId = (_currentQuestion!['id'] as num?)?.toInt() ?? 0;
      final timeSpent = ((_questionTime - _timeLeft) * 1000).clamp(0, _questionTime * 1000);

      final success = await gp.submitAnswer(
        gameId: _gameId!,
        userId: userId,
        questionId: questionId,
        selectedAnswer: selectedIndex,
        timeSpent: timeSpent,
      );

      if (success && mounted) {
        final correctAnswer = (_currentQuestion!['correctAnswer'] as num?)?.toInt() ?? -1;
        final isCorrect = selectedIndex == correctAnswer;

        if (isCorrect) {
          _currentStreak++;
          if (_currentStreak > _bestStreak) {
            _bestStreak = _currentStreak;
          }
          final bonus = _timeLeft * 10;
          // Guardar pendente para revelar APENAS quando o tempo esgotar
          _pendingPointsEarned = 100 + bonus;
          _pendingIsCorrect = true;
        } else {
          _currentStreak = 0;
          _pendingPointsEarned = 0;
          _pendingIsCorrect = false;
        }

        if (kDebugMode) print('Kahoot submit ok: correct=$isCorrect pts=$_pendingPointsEarned (pendente)');
      }
    } catch (e) {
      if (kDebugMode) print('Kahoot submit error: $e');
    }
  }

  void _onGameEnded() {
    _timer?.cancel();
    _progressController.stop();
    if (!mounted) return;
    setState(() => _gameEnded = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/quiz-results',
        arguments: {
          'gameId': _gameId,
          'correctAnswers': _correctAnswers,
          'totalQuestions': _totalQuestions,
          'totalPoints': _totalPoints,
          'bestStreak': _bestStreak,
          'questions': [],
          'isSolo': false,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameEnded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 72),
              SizedBox(height: 16),
              Text('Jogo Finalizado!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('A carregar resultados...',
                  style: TextStyle(color: Colors.white60, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_currentQuestion == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 24),
              Text('Aguardando a primeira pergunta...',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final options = List<String>.from(_currentQuestion?['options'] ?? []);
    final questionText = _currentQuestion?['questionText']?.toString() ?? '';
    final correctAnswer = (_currentQuestion?['correctAnswer'] as num?)?.toInt() ?? -1;
    final category = _currentQuestion?['category']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isSmallScreen, category),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  children: [
                    // Card da pergunta — idêntico ao quiz_game_screen
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildQuestionCard(questionText, isSmallScreen),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Opções em lista vertical — idêntico ao quiz_game_screen
                    ...options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final optionText = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                        child: _buildAnswerOption(
                          index: index,
                          optionText: optionText,
                          letter: String.fromCharCode(65 + index),
                          correctAnswer: correctAnswer,
                          isSmallScreen: isSmallScreen,
                        ),
                      );
                    }).toList(),

                    // Feedback de pontos após revelar a resposta correta
                    if (_showCorrectAnswer && _pointsEarned > 0) ...[
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildPointsFeedback(isSmallScreen),
                    ],

                    // Mensagem de aguardar os outros enquanto o tempo desce
                    if (_hasAnswered && !_showCorrectAnswer) ...[
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildWaitingMessage(isSmallScreen),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header — mesmo padrão do quiz_game_screen ───────────────────────────

  Widget _buildHeader(bool isSmallScreen, String category) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta ${_questionIndex + 1} de $_totalQuestions',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
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
                  // Pontuação total
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Text(
                      '$_totalPoints pts',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ],
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

  // ─── Question card — idêntico ao quiz_game_screen ────────────────────────

  Widget _buildQuestionCard(String questionText, bool isSmallScreen) {
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
        questionText,
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

  // ─── Answer option — mesmo estilo do quiz_game_screen ────────────────────

  Widget _buildAnswerOption({
    required int index,
    required String optionText,
    required String letter,
    required int correctAnswer,
    required bool isSmallScreen,
  }) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == correctAnswer;
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
      onTap: () => _selectAnswer(index),
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
                optionText,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (showResult && isCorrect)
              Icon(Icons.check_circle,
                  color: const Color(0xFF10B981),
                  size: isSmallScreen ? 20 : 24)
            else if (showResult && isSelected && !isCorrect)
              Icon(Icons.cancel,
                  color: const Color(0xFFEF4444),
                  size: isSmallScreen ? 20 : 24),
          ],
        ),
      ),
    );
  }

  // ─── Feedback de pontos ───────────────────────────────────────────────────

  Widget _buildPointsFeedback(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 22),
          const SizedBox(width: 8),
          Text(
            '+$_pointsEarned pontos',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mensagem de aguardar os outros jogadores ───────────────────────────

  Widget _buildWaitingMessage(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Resposta registada! A aguardar os outros...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
