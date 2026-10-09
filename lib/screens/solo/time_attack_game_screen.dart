import 'package:quizmaster_pro/widgets/core/loading_logo.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/core/exit_confirm_scope.dart';
import 'package:provider/provider.dart';
import '../../providers/solo/free_mode_provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../services/solo_service.dart';
import '../../services/app_audio_service.dart';

class TimeAttackGameScreen extends StatefulWidget {
  const TimeAttackGameScreen({super.key});

  @override
  State<TimeAttackGameScreen> createState() => _TimeAttackGameScreenState();
}

class _TimeAttackGameScreenState extends State<TimeAttackGameScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _timeLeft = 45;
  int _score = 0;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _gameOver = false;
  
  // Feedback visual para tempo
  String _timeFeedbackText = '';
  Color _timeFeedbackColor = Colors.transparent;
  Timer? _feedbackTimer;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppAudioService>(context, listen: false).playGameMusic();
      Provider.of<FreeModeProvider>(context, listen: false).fetchMoreQuestions(limit: 10).then((_) {
        _slideController.forward();
      });
      _startMainTimer();
    });
  }

  void _startMainTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft <= 5 && _timeLeft > 0) {
            context.read<AppAudioService>().playSfxTimer();
          }
        } else {
          timer.cancel();
          _showGameOver();
        }
      });
    });
  }

  void _showTimeFeedback(String text, Color color) {
    setState(() {
      _timeFeedbackText = text;
      _timeFeedbackColor = color;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _timeFeedbackColor = Colors.transparent;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    _slideController.dispose();
    try {
      Provider.of<AppAudioService>(context, listen: false).playMenuMusic();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _answerQuestion(String option, Map<String, dynamic> question) async {
    if (_selectedOption != null || _gameOver) return;
    
    setState(() {
      _selectedOption = option;
    });

    String correctText = "";
    final rawId = question['id'];
    int? parsedId;
    if (rawId is int) parsedId = rawId;
    else if (rawId != null) parsedId = int.tryParse(rawId.toString());

    if (parsedId != null) {
      try {
         final soloService = Provider.of<SoloService>(context, listen: false);
         correctText = await soloService.getCorrectAnswerText(parsedId);
         question['correctAnswer'] = correctText; // Update it so UI highlights green!
      } catch (e) {
         // handle error
      }
    }

    if (!mounted) return;

    setState(() {
      _isAnswered = true;
      _totalAnswers++;
    });

    bool isCorrect = (option == correctText);
    if (isCorrect) {
      _correctAnswers++;
      _score += 150; // Mais pontos para modo mais difícil
      _timeLeft += 3; // Bónus
      _showTimeFeedback('+3s', Colors.greenAccent);
      context.read<AppAudioService>().playSfxCorrect();
      context.read<AppAudioService>().triggerVibration();
    } else {
      _timeLeft -= 5; // Punição rigorosa
      if (_timeLeft < 0) _timeLeft = 0;
      _showTimeFeedback('-5s', Colors.redAccent);
      context.read<AppAudioService>().playSfxWrong();
      context.read<AppAudioService>().triggerVibration(heavy: true);
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_timeLeft <= 0) {
        _showGameOver();
      } else {
        setState(() {
          _isAnswered = false;
          _selectedOption = null;
          _slideController.reset();
        });
        Provider.of<FreeModeProvider>(context, listen: false).popQuestion();
        _slideController.forward();
      }
    });
  }

  Future<void> _showGameOver() async {
    setState(() => _gameOver = true);
    _timer?.cancel();
    
    String? nextPlayerName;
    int? nextPlayerScore;
    int coinsEarned = 0;
    int xpGained = 0;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userIdStr = authProvider.currentUser?.id;
      if (userIdStr != null) {
        final userId = int.tryParse(userIdStr);
        if (userId != null) {
          final soloService = Provider.of<SoloService>(context, listen: false);
          // Time attack doesn't really have streak the same way, we can pass 0 or track it if needed. Let's pass 0.
          final response = await soloService.submitFreeModeScore(userId, 'TIME_ATTACK', _score, 0);
          if (response['nextPlayerName'] != null) {
            nextPlayerName = response['nextPlayerName'];
            nextPlayerScore = response['nextPlayerScore'];
          }
          if (response['coinsEarned'] != null) {
            coinsEarned = response['coinsEarned'] as int;
          }
          if (response['xpGained'] != null) {
            xpGained = response['xpGained'] as int;
          }
          // Atualiza os dados do usuário
          authProvider.refreshUser();
        }
      }
    } catch (e) {
      debugPrint('Erro ao submeter score: $e');
    }

    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, '/free-mode-results', arguments: {
      'gameMode': 'TIME_ATTACK',
      'score': _score,
      'streak': 0, // Not applicable for Time Attack in the same way
      'correctAnswers': _correctAnswers,
      'totalAnswers': _totalAnswers,
      'reason': 'O tempo acabou!',
      'nextPlayerName': nextPlayerName,
      'nextPlayerScore': nextPlayerScore,
      'coinsEarned': coinsEarned,
      'xpGained': xpGained,
    });
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
                'Contra o Tempo',
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
                  category.toUpperCase(),
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
                color: _timeLeft <= 10 ? Colors.red : const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${_timeLeft}s',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 10 ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Feedback Text
              AnimatedOpacity(
                opacity: _timeFeedbackColor == Colors.transparent ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _timeFeedbackText,
                  style: TextStyle(
                    color: _timeFeedbackColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctAnswers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildAnswerOption(String option, String letter, Map<String, dynamic> question, bool isSmallScreen) {
    final isSelected = _selectedOption == option;
    String? correctAnswer = question['correctAnswer'] as String?;
    final isCorrect = option == correctAnswer;
    final showResult = _isAnswered;

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
      onTap: () {
        if (!_isAnswered) _answerQuestion(option, question);
      },
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

  Widget _buildFooter(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Color(0xFF6366F1), size: 24),
          const SizedBox(width: 8),
          Text('$_score Pts', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExitConfirmScope(
      title: 'Terminar o jogo?',
      message: 'Se saíres agora, a tua pontuação desta ronda não será guardada.',
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<FreeModeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentQuestions.isEmpty) {
            return const Center(child: LoadingLogo(size: 60));
          }
          if (provider.error != null) {
            return Center(child: Text('Erro: ${provider.error}', style: const TextStyle(color: Colors.white)));
          }
          if (provider.currentQuestions.isEmpty) {
            return const Center(child: Text('Sem perguntas disponíveis.', style: TextStyle(color: Colors.white)));
          }

          final question = provider.currentQuestions.first;
          final String questionText = question['questionText'] ?? '';
          final List<dynamic> options = question['options'] ?? [];
          final dynamic correctVal = question['correctAnswer'];
          final dynamic categoryObj = question['category'];
          final String category = categoryObj is Map ? (categoryObj['displayName'] ?? categoryObj['name'] ?? 'Geral') : (categoryObj?.toString() ?? 'Geral');
          
          String correct = '';
          if (correctVal is int && correctVal >= 0 && correctVal < options.length) {
            correct = options[correctVal].toString();
          } else {
            correct = correctVal?.toString() ?? '';
          }

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(isSmallScreen, category),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    child: Column(
                      children: [
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildQuestionCard(questionText, isSmallScreen),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        ...options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final String optionText = entry.value.toString();
                          return Padding(
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                            child: _buildAnswerOption(
                              optionText,
                              String.fromCharCode(65 + index),
                              question,
                              isSmallScreen,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                _buildFooter(isSmallScreen),
              ],
            ),
          );
        },
      ),
    );
  }
}
