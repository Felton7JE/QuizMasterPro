import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/solo_provider.dart';
import '../services/solo_service.dart';
import '../services/websocket_service.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/vip_badge_widget.dart';
import '../widgets/in_game_chat_bubble.dart';
import '../widgets/in_game_chat_sheet.dart';
import '../widgets/in_game_chat_button.dart';

class SoloQuizGameScreen extends StatefulWidget {
  const SoloQuizGameScreen({super.key});

  @override
  State<SoloQuizGameScreen> createState() => _SoloQuizGameScreenState();
}

class _SoloQuizGameScreenState extends State<SoloQuizGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerAnimController;
  late AnimationController _bossAuraController;
  late Animation<double> _bossAuraAnim;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _tauntAnimController;
  late Animation<double> _tauntFadeAnim;
  late Animation<Offset> _tauntSlideAnim;

  Timer? _questionTimer;
  Timer? _botThinkingTimer;
  Timer? _chatCooldownTimer;

  bool _isLoading = true;
  String? _errorMessage;

  SoloStartLevelResponse? _gameData;
  int _currentQuestionIndex = 0;
  final int _questionTimeSeconds = 15;
  int _timeRemaining = 15;

  int _playerScore = 0;
  int _botScore = 0;
  int _playerCorrectCount = 0;

  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  bool _botAnsweredThisTurn = false;
  bool? _botWasCorrectThisTurn;
  bool _playerDamagedThisTurn = false;

  // In-game Chat & Phrases
  InGameChatMessageEvent? _latestChatMessage;
  int _chatCooldownSeconds = 0;

  final List<Map<String, dynamic>> _answeredQuestions = [];

  @override
  void initState() {
    super.initState();
    _timerAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _questionTimeSeconds),
    );

    // Aura pulsante de fogo para o chefe
    _bossAuraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bossAuraAnim = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _bossAuraController, curve: Curves.easeInOut),
    );

    // Efeito de tremor (screen shake / boss hit)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 8.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Animação de fala/provocação do Boss
    _tauntAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tauntFadeAnim = CurvedAnimation(parent: _tauntAnimController, curve: Curves.easeIn);
    _tauntSlideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tauntAnimController, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final levelNumber = args?['levelNumber'] as int? ?? 1;
      _initSoloGame(levelNumber);
    });
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _botThinkingTimer?.cancel();
    _chatCooldownTimer?.cancel();
    _timerAnimController.dispose();
    _bossAuraController.dispose();
    _shakeController.dispose();
    _tauntAnimController.dispose();
    super.dispose();
  }

  void _startChatCooldown() {
    _chatCooldownTimer?.cancel();
    setState(() {
      _chatCooldownSeconds = 6;
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

  void _sendSoloChatMessage(String phrase, int? phraseId) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _latestChatMessage = InGameChatMessageEvent(
        roomCode: 'SOLO',
        userId: user.id,
        username: user.username,
        phraseText: phrase,
        avatar: user.avatar,
        isVip: user.isVip,
        activeFrameId: user.activeFrameId,
        activePhraseId: phraseId ?? user.activePhraseId,
        timestamp: DateTime.now(),
      );
    });

    _startChatCooldown();

    // Se for Boss Level, o Boss responde com 60% de chance após 1.5s
    if (_gameData?.isBossLevel == true) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        final bossResponses = [
          'Achaste isso impressionante? 😈',
          'Vais precisar de muito mais do que isso! 🔥',
          'Não me faças rir! 😂',
          'Sinto pena da tua pontuação... 💀',
          'Eu sou invencível! ⚡',
        ];
        bossResponses.shuffle();
        setState(() {
          _latestChatMessage = InGameChatMessageEvent(
            roomCode: 'SOLO',
            userId: 'BOSS_ID',
            username: _gameData?.botName ?? 'Boss Guardião',
            phraseText: bossResponses.first,
            avatar: _gameData?.botAvatar ?? 'boss_avatar',
            isVip: true,
            activeFrameId: null,
            activePhraseId: null,
            timestamp: DateTime.now(),
          );
        });
      });
    }
  }

  void _openChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InGameChatSheet(
        cooldownSecondsRemaining: _chatCooldownSeconds,
        onSelectPhrase: (phrase, phraseId) {
          _sendSoloChatMessage(phrase, phraseId);
        },
      ),
    );
  }

  Future<void> _initSoloGame(int levelNumber) async {
    final soloProv = context.read<SoloProvider>();
    final data = await soloProv.startLevel(levelNumber);

    if (data == null || data.questions.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as perguntas do nível $levelNumber.';
      });
      return;
    }

    setState(() {
      _gameData = data;
      _isLoading = false;
    });

    _startQuestionTurn();
  }

  void _startQuestionTurn() {
    _questionTimer?.cancel();
    _botThinkingTimer?.cancel();

    setState(() {
      _timeRemaining = _questionTimeSeconds;
      _selectedOptionIndex = null;
      _hasAnswered = false;
      _botAnsweredThisTurn = false;
      _botWasCorrectThisTurn = null;
      _playerDamagedThisTurn = false;
    });

    _timerAnimController.reset();
    _timerAnimController.forward();
    _tauntAnimController.forward(from: 0.0);

    // Cronómetro do Jogador (15s)
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        if (!_hasAnswered) {
          _submitPlayerAnswer(-1); // Tempo esgotado
        }
      }
    });

    // Simulação do BOT / CHEFE (Delay aleatório)
    if (_gameData != null) {
      final random = math.Random();
      final minMs = _gameData!.botMinDelayMs;
      final maxMs = _gameData!.botMaxDelayMs;
      final delayMs = minMs + random.nextInt(math.max(1, maxMs - minMs));

      _botThinkingTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!mounted || _botAnsweredThisTurn) return;

        final isCorrect = random.nextDouble() <= _gameData!.botAccuracyRate;
        final isGoldenLast = (_currentQuestionIndex == _gameData!.questions.length - 1);
        final multiplier = isGoldenLast ? 2 : 1;

        // Bónus de velocidade do BOT
        final botSpeedBonus = (_timeRemaining * 20) * multiplier;
        final basePoints = 100 * multiplier;
        final pointsEarned = isCorrect ? (basePoints + botSpeedBonus) : 0;

        if (isCorrect && _gameData!.isBossLevel) {
          _shakeController.forward(from: 0.0);
        }

        setState(() {
          _botAnsweredThisTurn = true;
          _botWasCorrectThisTurn = isCorrect;
          if (isCorrect) {
            _botScore += pointsEarned;
          }
        });
      });
    }
  }

  void _submitPlayerAnswer(int optionIndex) {
    if (_hasAnswered) return;

    _questionTimer?.cancel();
    _timerAnimController.stop();

    final currentQuestion = _gameData!.questions[_currentQuestionIndex];
    final int correctAnswerIndex = currentQuestion['correctAnswer'] ?? 0;
    final bool isCorrect = (optionIndex == correctAnswerIndex);

    final isGoldenLast = (_currentQuestionIndex == _gameData!.questions.length - 1);
    final multiplier = isGoldenLast ? 2 : 1;
    final speedBonus = (_timeRemaining * 25) * multiplier;
    final basePoints = 100 * multiplier;
    final pointsEarned = isCorrect ? (basePoints + speedBonus) : 0;

    // Feedback háptico nativo e tremor de tela
    if (isCorrect) {
      HapticFeedback.lightImpact();
      _shakeController.forward(from: 0.0);
    } else {
      HapticFeedback.heavyImpact();
      if (_gameData?.isBossLevel == true) {
        _playerDamagedThisTurn = true;
        _shakeController.forward(from: 0.0);
      }
    }

    setState(() {
      _hasAnswered = true;
      _selectedOptionIndex = optionIndex;
      if (isCorrect) {
        _playerScore += pointsEarned;
        _playerCorrectCount++;
      }
    });

    _answeredQuestions.add({
      'questionId': currentQuestion['id'],
      'wasCorrect': isCorrect,
    });

    // Avançar para a próxima pergunta após 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _gameData!.questions.length - 1) {
        setState(() => _currentQuestionIndex++);
        _startQuestionTurn();
      } else {
        _finishGame();
      }
    });
  }

  Future<void> _finishGame() async {
    final soloProv = context.read<SoloProvider>();
    final response = await soloProv.finishLevel(
      levelNumber: _gameData!.levelNumber,
      playerScore: _playerScore,
      botScore: _botScore,
      correctCount: _playerCorrectCount,
      totalQuestions: _gameData!.questions.length,
      answeredQuestions: _answeredQuestions,
    );

    if (!mounted || response == null) return;

    _showResultsDialog(response);
  }

  static const Map<String, String> _bossImages = {
    'ciencias': 'assets/images/solo/boss_ciencias_v2.png',
    'ciência': 'assets/images/solo/boss_ciencias_v2.png',
    'ciências': 'assets/images/solo/boss_ciencias_v2.png',
    'science': 'assets/images/solo/boss_ciencias_v2.png',
    'geografia': 'assets/images/solo/boss_geografia_v2.png',
    'geography': 'assets/images/solo/boss_geografia_v2.png',
    'historia': 'assets/images/solo/boss_historia_v2.png',
    'história': 'assets/images/solo/boss_historia_v2.png',
    'history': 'assets/images/solo/boss_historia_v2.png',
    'ingles': 'assets/images/solo/boss_ingles_v2.png',
    'inglês': 'assets/images/solo/boss_ingles_v2.png',
    'english': 'assets/images/solo/boss_ingles_v2.png',
    'matematica': 'assets/images/solo/boss_matematica_v2.png',
    'matemática': 'assets/images/solo/boss_matematica_v2.png',
    'math': 'assets/images/solo/boss_matematica_v2.png',
    'portugues': 'assets/images/solo/boss_portugues_v2.png',
    'português': 'assets/images/solo/boss_portugues_v2.png',
    'portuguese': 'assets/images/solo/boss_portugues_v2.png',
  };

  static String? _getBossImage(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    for (final entry in _bossImages.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  void _showResultsDialog(SoloFinishLevelResponse res) {
    final isBoss = _gameData?.isBossLevel == true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isBoss ? (res.victory ? Colors.amber : Colors.redAccent) : Colors.transparent,
              width: 2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                res.victory
                    ? (isBoss ? Icons.military_tech_rounded : Icons.emoji_events_rounded)
                    : (isBoss ? Icons.dangerous_rounded : Icons.sentiment_very_dissatisfied_rounded),
                size: 72,
                color: res.victory ? Colors.amber : Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                res.victory
                    ? (isBoss ? '👑 CHEFE DERROTADO!' : 'VITÓRIA!')
                    : (isBoss ? '💀 O CHEFE VENCEU!' : 'DERROTA!'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: res.victory ? Colors.amber : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                res.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Placar comparativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('TU', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('$_playerScore pts',
                            style: const TextStyle(
                                color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Text('VS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    Column(
                      children: [
                        Text(_gameData?.botName ?? 'BOT', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('$_botScore pts',
                            style: const TextStyle(
                                color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Estrelas (Se venceu)
              if (res.victory)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (starIdx) {
                    return Icon(
                      Icons.star_rounded,
                      size: 32,
                      color: starIdx < res.starsEarned ? Colors.amber : Colors.white24,
                    );
                  }),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Fechar Dialog
                  Navigator.pop(context); // Voltar ao Mapa
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('VOLTAR AO MAPA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (_errorMessage != null || _gameData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Erro desconhecido', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar ao Mapa'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _gameData!.questions[_currentQuestionIndex];
    final List<dynamic> options = currentQuestion['options'] ?? [];
    final bool isGoldenLast = (_currentQuestionIndex == _gameData!.questions.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'Nível ${_gameData!.levelNumber} - Pergunta ${_currentQuestionIndex + 1}/${_gameData!.questions.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            final offset = _shakeAnim.value > 0
                ? Offset(math.sin(_shakeAnim.value * math.pi) * 6, 0)
                : Offset.zero;
            return Transform.translate(
              offset: offset,
              child: child,
            );
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // Placar DUPLO: Jogador VS BOT / CHEFE
                  _buildScoreBoard(context),

                  // Banner de Provocação do Chefe Animado
                  if (_gameData!.isBossLevel && (_gameData!.bossTaunt != null && _gameData!.bossTaunt!.isNotEmpty))
                    SlideTransition(
                      position: _tauntSlideAnim,
                      child: FadeTransition(
                        opacity: _tauntFadeAnim,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF991B1B), Color(0xFF450A0A)],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology_alt_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_gameData!.botName}: "${_gameData!.bossTaunt}"',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Banner da Pergunta de Ouro (2x Pontos)
                  if (isGoldenLast)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.amber,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.black87, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'PERGUNTA DE OURO - VALOR DUPLO (2X PONTOS)',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  // Barra do Timer Regressivo
                  AnimatedBuilder(
                    animation: _timerAnimController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: 1.0 - _timerAnimController.value,
                        backgroundColor: Colors.white10,
                        color: _timeRemaining <= 4 ? Colors.redAccent : (_gameData!.isBossLevel ? Colors.orangeAccent : Colors.amber),
                        minHeight: 6,
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Pergunta
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _gameData!.isBossLevel
                                      ? Colors.redAccent.withValues(alpha: 0.6)
                                      : (isGoldenLast ? Colors.amber : Colors.white10),
                                  width: isGoldenLast || _gameData!.isBossLevel ? 2 : 1),
                              boxShadow: _gameData!.isBossLevel
                                  ? [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              currentQuestion['questionText'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Opções de Resposta
                          Expanded(
                            child: ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (ctx, idx) {
                                return _buildOptionButton(idx, options[idx].toString(), currentQuestion['correctAnswer']);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Overlay de dano sofrido (Flash avermelhado)
              if (_playerDamagedThisTurn)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7), width: 4),
                    ),
                  ),
                ),

              // In-Game Chat Overlay (bolhas animadas)
              Positioned(
                top: 90,
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
              Positioned(
                bottom: 16,
                right: 16,
                child: InGameChatButton(
                  cooldownSecondsRemaining: _chatCooldownSeconds,
                  onTap: _openChatSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isBoss = _gameData?.isBossLevel == true;
    final bossImg = isBoss ? _getBossImage(_gameData?.categoryName ?? '') : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBoss ? const Color(0xFF1C1322) : const Color(0xFF1E293B),
        border: isBoss ? const Border(bottom: BorderSide(color: Colors.redAccent, width: 1.5)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Jogador
          Row(
            children: [
              CosmeticAvatar(
                radius: 20,
                avatarUrl: user?.avatar,
                username: user?.username ?? 'U',
                activeAvatarId: user?.activeAvatarId,
                activeFrameId: user?.activeFrameId,
                isVip: user?.isVip ?? false,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VipUsernameText(
                    username: user?.username ?? 'Jogador',
                    isVip: user?.isVip ?? false,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text('$_playerScore pts',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),

          // VS Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isBoss ? Colors.red.shade900 : const Color(0xFF0F172A),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: isBoss
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Text(
              isBoss ? '⚔️ CHEFE' : 'VS',
              style: TextStyle(
                color: isBoss ? Colors.white : Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),

          // BOT / CHEFE Oponente
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBoss) const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                      Text(
                        _gameData?.botName ?? 'BOT',
                        style: TextStyle(
                          color: isBoss ? Colors.orangeAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('$_botScore pts',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_botAnsweredThisTurn) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _botWasCorrectThisTurn == true ? Icons.check_circle : Icons.cancel,
                          color: _botWasCorrectThisTurn == true ? Colors.greenAccent : Colors.redAccent,
                          size: 14,
                        ),
                      ]
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (isBoss)
                AnimatedBuilder(
                  animation: _bossAuraAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bossAuraAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.5 * _bossAuraAnim.value),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.purple.shade900,
                          backgroundImage: bossImg != null ? AssetImage(bossImg) : null,
                          child: bossImg == null
                              ? Text((_gameData?.botName ?? 'B')[0],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                    );
                  },
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.redAccent,
                  child: Text((_gameData?.botName ?? 'B')[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String optionText, int? correctAnswerIndex) {
    Color btnColor = const Color(0xFF1E293B);
    Color borderColor = Colors.white10;

    if (_hasAnswered) {
      if (index == correctAnswerIndex) {
        btnColor = const Color(0xFF059669); // Verde para correta
        borderColor = Colors.greenAccent;
      } else if (index == _selectedOptionIndex) {
        btnColor = const Color(0xFFDC2626); // Vermelho para incorreta
        borderColor = Colors.redAccent;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _hasAnswered ? null : () => _submitPlayerAnswer(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
