import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_quiz_model.dart';
import '../providers/auth_provider.dart';
import '../providers/study_quiz_provider.dart';
import 'study_flashcards_screen.dart';

class StudyQuizGameScreen extends StatefulWidget {
  final CustomStudyQuiz quiz;

  const StudyQuizGameScreen({super.key, required this.quiz});

  @override
  State<StudyQuizGameScreen> createState() => _StudyQuizGameScreenState();
}

class _StudyQuizGameScreenState extends State<StudyQuizGameScreen> with SingleTickerProviderStateMixin {
  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldAccent = Color(0xFF34D399);

  late AnimationController _progressAnimController;

  int _currentIndex = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  bool _showHint = false;
  bool _isUntimedMode = false; // Alternar entre Modo Exame (20s) e Modo Focado (sem tempo)
  int _score = 0;
  int _correctCount = 0;
  int _timeLeft = 20;
  Timer? _timer;
  bool _isCompleted = false;

  final List<Map<String, dynamic>> _userReviewList = [];

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _startQuestionTurn();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimController.dispose();
    super.dispose();
  }

  void _startQuestionTurn() {
    _timer?.cancel();
    _progressAnimController.reset();

    setState(() {
      _selectedOption = null;
      _isAnswered = false;
      _showHint = false;
      _timeLeft = 20;
    });

    if (!_isUntimedMode) {
      _progressAnimController.forward();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_timeLeft <= 1) {
          t.cancel();
          _handleTimeOut();
        } else {
          setState(() {
            _timeLeft--;
          });
        }
      });
    }
  }

  void _handleTimeOut() {
    if (_isAnswered) return;
    final currentQ = widget.quiz.questions[_currentIndex];
    setState(() {
      _isAnswered = true;
      _selectedOption = -1; // Time out
    });

    _userReviewList.add({
      'question': currentQ.questionText,
      'selected': 'Tempo Esgotado',
      'correct': currentQ.options[currentQ.correctAnswer],
      'isCorrect': false,
      'explanation': currentQ.explanation,
    });
  }

  void _handleAnswer(int optionIndex) {
    if (_isAnswered) return;
    _timer?.cancel();
    _progressAnimController.stop();

    final currentQ = widget.quiz.questions[_currentIndex];
    final isCorrect = optionIndex == currentQ.correctAnswer;

    setState(() {
      _selectedOption = optionIndex;
      _isAnswered = true;
      if (isCorrect) {
        _correctCount++;
        _score += 100 + (_isUntimedMode ? 0 : _timeLeft * 5);
      }
    });

    _userReviewList.add({
      'question': currentQ.questionText,
      'selected': currentQ.options[optionIndex],
      'correct': currentQ.options[currentQ.correctAnswer],
      'isCorrect': isCorrect,
      'explanation': currentQ.explanation,
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < widget.quiz.questions.length) {
      setState(() {
        _currentIndex++;
      });
      _startQuestionTurn();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    setState(() {
      _isCompleted = true;
    });

    final study = context.read<StudyQuizProvider>();
    final auth = context.read<AuthProvider>();

    study.recordScore(
      quizId: widget.quiz.id,
      score: _score,
      correctCount: _correctCount,
      userId: auth.currentUser?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildResultsView();
    }

    final currentQ = widget.quiz.questions[_currentIndex];
    final totalQ = widget.quiz.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.quiz.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _isUntimedMode ? 'Mudar para Modo Exame (Com Tempo)' : 'Mudar para Modo Estudo Focado (Sem Tempo)',
            icon: Icon(
              _isUntimedMode ? Icons.hourglass_disabled_rounded : Icons.timer_rounded,
              color: _isUntimedMode ? _emeraldAccent : Colors.indigoAccent,
            ),
            onPressed: () {
              setState(() {
                _isUntimedMode = !_isUntimedMode;
                _startQuestionTurn();
              });
            },
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$_score pts',
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header com progresso e timer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pergunta ${_currentIndex + 1} de $totalQ',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (!_isUntimedMode)
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: _timeLeft <= 5 ? Colors.redAccent : Colors.indigoAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_timeLeft}s',
                              style: TextStyle(
                                color: _timeLeft <= 5 ? Colors.redAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(Icons.self_improvement_rounded, size: 16, color: _emeraldAccent),
                            SizedBox(width: 4),
                            Text(
                              'Modo Focado (Sem Pressa)',
                              style: TextStyle(color: _emeraldAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / totalQ,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Área de Conteúdo da Questão
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge de Categoria e Dificuldade
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentQ.topic.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigoAccent.shade100),
                          ),
                        ),
                        if (!_isAnswered)
                          TextButton.icon(
                            onPressed: () => setState(() => _showHint = !_showHint),
                            icon: const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amberAccent),
                            label: Text(
                              _showHint ? 'Ocultar Dica' : 'Dica do Tutor',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                            ),
                          ),
                      ],
                    ),

                    if (_showHint && !_isAnswered)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentQ.hint,
                                style: const TextStyle(color: Color(0xFFFEF3C7), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Card da Pergunta
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        currentQ.questionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Opções de Resposta
                    ...List.generate(currentQ.options.length, (index) {
                      return _buildOptionButton(index, currentQ);
                    }),

                    // Card do Tutor IA com Explicação Pedagógica
                    if (_isAnswered) ...[
                      const SizedBox(height: 20),
                      _buildTutorExplanationCard(currentQ),
                    ],
                  ],
                ),
              ),
            ),

            // Botão Avançar / Concluir
            if (_isAnswered)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(top: BorderSide(color: Color(0xFF334155))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _currentIndex + 1 < totalQ ? 'Próxima Questão' : 'Ver Resultado Final',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, CustomStudyQuestion question) {
    final optionText = question.options[index];
    final isCorrect = index == question.correctAnswer;
    final isSelected = _selectedOption == index;

    Color bgColor = const Color(0xFF1E293B);
    Color borderColor = Colors.grey.withValues(alpha: 0.2);
    Color textColor = Colors.white;
    IconData? trailingIcon;

    if (_isAnswered) {
      if (isCorrect) {
        bgColor = _emerald.withValues(alpha: 0.2);
        borderColor = _emeraldAccent;
        textColor = _emeraldAccent;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bgColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.redAccent;
        textColor = Colors.redAccent;
        trailingIcon = Icons.cancel_rounded;
      }
    }

    final optionLabels = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAnswered ? null : () => _handleAnswer(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    optionLabels[index % 4],
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(color: textColor, fontSize: 14, height: 1.35),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: borderColor, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorExplanationCard(CustomStudyQuestion question) {
    final isCorrect = _selectedOption == question.correctAnswer;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCorrect ? _emerald.withValues(alpha: 0.1) : Colors.indigo.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect ? _emerald.withValues(alpha: 0.4) : Colors.indigoAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: isCorrect ? _emeraldAccent : Colors.indigoAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Explicação do Tutor IA',
                style: TextStyle(
                  color: isCorrect ? _emeraldAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.explanation,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final total = widget.quiz.questions.length;
    final percentage = ((_correctCount / total) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Resultado do Estudo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Card de Resumo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      percentage >= 70 ? '🎉 Excelente Desempenho!' : '📚 Bom Treino de Estudo!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$percentage%',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acertaste $_correctCount de $total questões',
                      style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResultStat('Pontuação', '$_score pts', Icons.military_tech_rounded, Colors.amberAccent),
                        _buildResultStat('XP Ganho', '+${(_score / 5).round()}', Icons.bolt_rounded, Colors.indigoAccent),
                        _buildResultStat('Moedas', '+${_correctCount * 2}', Icons.monetization_on_rounded, Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botões de Ação
              Row(
                children: [
                  if (widget.quiz.flashcards.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyFlashcardsScreen(quiz: widget.quiz),
                            ),
                          );
                        },
                        icon: const Icon(Icons.style_rounded, color: Colors.indigoAccent),
                        label: const Text('Revisar Flashcards', style: TextStyle(color: Colors.indigoAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.indigoAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text('Concluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Revisão detalhada de cada pergunta
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gabarito & Justificativas do Tutor IA',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              ..._userReviewList.map((review) {
                final isCorr = review['isCorrect'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorr ? _emerald.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorr ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isCorr ? _emeraldAccent : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              review['question'] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sua resposta: ${review['selected']}',
                        style: TextStyle(color: isCorr ? _emeraldAccent : Colors.redAccent, fontSize: 13),
                      ),
                      if (!isCorr)
                        Text(
                          'Resposta certa: ${review['correct']}',
                          style: const TextStyle(color: _emeraldAccent, fontSize: 13),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 Explicação: ${review['explanation']}',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
