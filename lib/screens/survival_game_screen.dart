import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/free_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../services/solo_service.dart';
import '../theme/app_colors.dart';

class SurvivalGameScreen extends StatefulWidget {
  const SurvivalGameScreen({super.key});

  @override
  State<SurvivalGameScreen> createState() => _SurvivalGameScreenState();
}

class _SurvivalGameScreenState extends State<SurvivalGameScreen> with SingleTickerProviderStateMixin {
  int _lives = 3;
  int _score = 0;
  int _streak = 0;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _gameOver = false;
  
  Timer? _questionTimer;
  Timer? _livesFeedbackTimer;
  String _livesFeedbackText = '';
  Color _livesFeedbackColor = Colors.transparent;
  int _questionTimeLeft = 15;

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
      Provider.of<FreeModeProvider>(context, listen: false).fetchMoreQuestions(limit: 10).then((_) {
        _slideController.forward();
      });
      _startQuestionTimer();
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    setState(() => _questionTimeLeft = 15);
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_questionTimeLeft > 0) {
          _questionTimeLeft--;
        } else {
          timer.cancel();
          _showGameOver(reason: 'Tempo Esgotado!');
        }
      });
    });
  }
  void _showLivesFeedback(String text, Color color) {
    setState(() {
      _livesFeedbackText = text;
      _livesFeedbackColor = color;
    });
    _livesFeedbackTimer?.cancel();
    _livesFeedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _livesFeedbackColor = Colors.transparent;
        });
      }
    });
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _livesFeedbackTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _answerQuestion(String option, String correct) {
    if (_isAnswered || _gameOver) return;
    
    _questionTimer?.cancel();
    
    setState(() {
      _isAnswered = true;
      _selectedOption = option;
    });

    bool isCorrect = (option == correct);
    _totalAnswers++;
    if (isCorrect) {
      _correctAnswers++;
      _score += 100 + (_streak * 10);
      _streak++;
    } else {
      _streak = 0;
      _lives--;
      _showLivesFeedback('-1', Colors.redAccent);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_lives <= 0) {
        _showGameOver(reason: 'Ficaste sem vidas!');
      } else {
        setState(() {
          _isAnswered = false;
          _selectedOption = null;
          _slideController.reset();
        });
        Provider.of<FreeModeProvider>(context, listen: false).popQuestion();
        _slideController.forward();
        _startQuestionTimer();
      }
    });
  }

  Future<void> _showGameOver({String reason = 'Ficaste sem vidas!'}) async {
    setState(() => _gameOver = true);
    _questionTimer?.cancel();
    
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
          final response = await soloService.submitFreeModeScore(userId, 'SURVIVAL', _score, _streak);
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
          // Atualiza os dados do usuário para refletir as novas moedas/xp
          authProvider.refreshUser();
        }
      }
    } catch (e) {
      debugPrint('Erro ao submeter score: $e');
    }

    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, '/free-mode-results', arguments: {
      'gameMode': 'SURVIVAL',
      'score': _score,
      'streak': _streak,
      'correctAnswers': _correctAnswers,
      'totalAnswers': _totalAnswers,
      'reason': reason,
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
                'Sobrevivência',
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
                color: _questionTimeLeft <= 5 ? Colors.red : const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${_questionTimeLeft}s',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: _questionTimeLeft <= 5 ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: _questionTimeLeft / 15,
                  backgroundColor: const Color(0xFF334155),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _questionTimeLeft <= 5 ? Colors.red : const Color(0xFF6366F1),
                  ),
                  minHeight: isSmallScreen ? 6 : 8,
                ),
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

  Widget _buildAnswerOption(String option, String letter, String correctAnswer, bool isSmallScreen) {
    final isSelected = _selectedOption == option;
    final isCorrect = option == correctAnswer;
    final showResult = _isAnswered;

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
      onTap: () {
        if (!_isAnswered) _answerQuestion(option, correctAnswer);
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 8),
              Text('$_score', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 8),
              Text('$_streak', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: List.generate(3, (index) {
                  return Icon(
                    index < _lives ? Icons.favorite : Icons.favorite_border,
                    color: Colors.redAccent,
                    size: 24,
                  );
                }),
              ),
              Positioned(
                top: -24,
                child: AnimatedOpacity(
                  opacity: _livesFeedbackColor == Colors.transparent ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _livesFeedbackText,
                    style: TextStyle(
                      color: _livesFeedbackColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<FreeModeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentQuestions.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
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
                              correct,
                              isSmallScreen,
                            ),
                          );
                        }).toList(),
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
