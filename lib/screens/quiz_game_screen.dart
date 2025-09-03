import 'package:flutter/material.dart';
import 'dart:async';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _timeLeft = 15;
  Timer? _timer;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _showCorrectAnswer = false;
  
  late AnimationController _progressController;
  late AnimationController _questionController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  // Dados do quiz (simulado)
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Qual é o resultado de 15 + 27?',
      'category': 'Matemática',
      'options': ['42', '41', '43', '40'],
      'correct': '42',
      'explanation': '15 + 27 = 42',
    },
    {
      'question': 'Qual é o plural de "cidadão"?',
      'category': 'Português',
      'options': ['cidadões', 'cidadãos', 'cidadans', 'cidadães'],
      'correct': 'cidadãos',
      'explanation': 'O plural correto de cidadão é cidadãos.',
    },
    {
      'question': 'Em que ano foi proclamada a independência do Brasil?',
      'category': 'História',
      'options': ['1820', '1822', '1824', '1825'],
      'correct': '1822',
      'explanation': 'A independência do Brasil foi proclamada em 7 de setembro de 1822.',
    },
    {
      'question': 'Qual é a capital do estado de Minas Gerais?',
      'category': 'Geografia',
      'options': ['Uberlândia', 'Juiz de Fora', 'Belo Horizonte', 'Contagem'],
      'correct': 'Belo Horizonte',
      'explanation': 'Belo Horizonte é a capital de Minas Gerais.',
    },
    {
      'question': 'Qual gás é mais abundante na atmosfera terrestre?',
      'category': 'Ciências',
      'options': ['Oxigênio', 'Nitrogênio', 'Gás Carbônico', 'Argônio'],
      'correct': 'Nitrogênio',
      'explanation': 'O nitrogênio representa cerca de 78% da atmosfera terrestre.',
    },
  ];

  // Estatísticas do jogador
  int _correctAnswers = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOut,
    ));

    _startQuestion();
  }

  void _startQuestion() {
    setState(() {
      _timeLeft = 15;
      _selectedAnswer = null;
      _isAnswered = false;
      _showCorrectAnswer = false;
    });

    _questionController.forward();
    _progressController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isAnswered) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        if (!_isAnswered) {
          _handleTimeUp();
        }
      }
    });
  }

  void _handleTimeUp() {
    setState(() {
      _isAnswered = true;
      _showCorrectAnswer = true;
      _streak = 0; // Quebra a sequência
    });
    
    _timer?.cancel();
    
    // Aguarda 3 segundos antes de ir para próxima pergunta
    Timer(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _showCorrectAnswer = true;
    });

    _timer?.cancel();
    _progressController.stop();

    // Verifica se a resposta está correta
    final currentQ = _questions[_currentQuestion];
    final isCorrect = answer == currentQ['correct'];
    
    if (isCorrect) {
      _correctAnswers++;
      _streak++;
      if (_streak > _bestStreak) {
        _bestStreak = _streak;
      }
      
      // Calcula pontos baseado no tempo restante
      final timeBonus = (_timeLeft * 10);
      final streakBonus = (_streak > 1) ? (_streak * 50) : 0;
      final questionPoints = 100 + timeBonus + streakBonus;
      _totalPoints += questionPoints;
    } else {
      _streak = 0;
    }

    // Aguarda 3 segundos antes de ir para próxima pergunta
    Timer(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
      
      _progressController.reset();
      _questionController.reset();
      _startQuestion();
    } else {
      // Quiz finalizado
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
        'questions': _questions,
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final currentQ = _questions[_currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header com progresso
            _buildHeader(isSmallScreen),
            
            // Pergunta
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  children: [
                    // Card da pergunta
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildQuestionCard(currentQ, isSmallScreen),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    
                    // Opções de resposta
                    ...(currentQ['options'] as List<String>).asMap().entries.map<Widget>((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                        child: _buildAnswerOption(
                          option,
                          String.fromCharCode(65 + index), // A, B, C, D
                          currentQ['correct'],
                          isSmallScreen,
                        ),
                      );
                    }).toList(),
                    
                    // Explicação (apenas se respondido)
                    if (_showCorrectAnswer) ...[
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildExplanation(currentQ['explanation'], isSmallScreen),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer com estatísticas
            _buildFooter(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
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
          // Progresso da pergunta
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
                  _questions[_currentQuestion]['category'],
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
          
          // Barra de progresso do tempo
          Row(
            children: [
              Icon(
                Icons.timer,
                color: _timeLeft <= 5 ? Colors.red : const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                '${_timeLeft}s',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 5 ? Colors.red : Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timeLeft <= 5 ? Colors.red : const Color(0xFF6366F1),
                      ),
                      minHeight: isSmallScreen ? 6 : 8,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, bool isSmallScreen) {
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
        question['question'],
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
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == correctAnswer;
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
              Icon(
                Icons.lightbulb,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Explicação',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
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
        Icon(
          icon,
          color: color,
          size: isSmallScreen ? 20 : 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[400],
          ),
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
}
