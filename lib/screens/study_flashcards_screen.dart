import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_quiz_model.dart';
import '../providers/study_quiz_provider.dart';
import 'study_quiz_game_screen.dart';

class StudyFlashcardsScreen extends StatefulWidget {
  final CustomStudyQuiz quiz;

  const StudyFlashcardsScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<StudyFlashcardsScreen> createState() => _StudyFlashcardsScreenState();
}

class _StudyFlashcardsScreenState extends State<StudyFlashcardsScreen> with SingleTickerProviderStateMixin {
  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldAccent = Color(0xFF34D399);

  late PageController _pageController;
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard(int total) {
    if (_currentIndex < total - 1) {
      if (_isFlipped) {
        _flipController.reverse();
        _isFlipped = false;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      if (_isFlipped) {
        _flipController.reverse();
        _isFlipped = false;
      }
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyQuizProvider>();
    final currentQuiz = studyProvider.quizzes.firstWhere(
      (q) => q.id == widget.quiz.id,
      orElse: () => widget.quiz,
    );

    final flashcards = currentQuiz.flashcards.isNotEmpty
        ? currentQuiz.flashcards
        : [
            StudyFlashcard(
              id: 'fc_sample',
              front: 'Conceito Central: ${currentQuiz.title}',
              back: currentQuiz.description,
              topic: 'Estudo',
            )
          ];

    final masteredCount = flashcards.where((f) => f.isMastered).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentQuiz.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Deck de Flashcards • ${flashcards.length} cartões',
              style: TextStyle(fontSize: 12, color: Colors.indigoAccent.shade100),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Resumo da Matéria',
            icon: const Icon(Icons.menu_book_rounded, color: Colors.amberAccent),
            onPressed: () => _showSummarySheet(context, currentQuiz),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Progresso e Métricas
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.style_rounded, color: Colors.indigoAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentIndex + 1} de ${flashcards.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _emerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _emerald.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: _emeraldAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$masteredCount Fixados',
                          style: const TextStyle(color: _emeraldAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Linha visual de progresso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / flashcards.length,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                  minHeight: 6,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Carrossel de Cartões Flip 3D
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: flashcards.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentIndex = idx;
                    _isFlipped = false;
                    _flipController.reset();
                  });
                },
                itemBuilder: (context, index) {
                  final card = flashcards[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * math.pi;
                          final isUnder = angle > (math.pi / 2);

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Perspectiva 3D
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isUnder
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(math.pi),
                                    alignment: Alignment.center,
                                    child: _buildBackCard(card, studyProvider, currentQuiz),
                                  )
                                : _buildFrontCard(card, studyProvider, currentQuiz),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Controles de Navegação
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _flipCard,
                    icon: const Icon(Icons.flip_rounded, size: 18),
                    label: Text(_isFlipped ? 'Ver Pergunta' : 'Virar Resposta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _currentIndex < flashcards.length - 1
                        ? () => _nextCard(flashcards.length)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            // Botão Inferior para iniciar o Quiz
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyQuizGameScreen(quiz: currentQuiz),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.amberAccent),
                label: const Text(
                  'Testar Conhecimento no Quiz com IA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amberAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.amber.withOpacity(0.08),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontCard(StudyFlashcard card, StudyQuizProvider provider, CustomStudyQuiz quiz) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigoAccent.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'FRENTE • CONCEITO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigoAccent.shade100),
                ),
              ),
              IconButton(
                icon: Icon(
                  card.isMastered ? Icons.star_rounded : Icons.star_border_rounded,
                  color: card.isMastered ? Colors.amberAccent : Colors.grey,
                ),
                onPressed: () => provider.toggleFlashcardMastered(quiz.id, card.id),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.help_outline_rounded, size: 48, color: Colors.indigoAccent),
          const SizedBox(height: 16),
          Text(
            card.front,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Toque para virar e ver a resposta',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(StudyFlashcard card, StudyQuizProvider provider, CustomStudyQuiz quiz) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _emeraldAccent.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _emeraldAccent.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _emerald.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VERSO • EXPLICAÇÃO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _emeraldAccent),
                ),
              ),
              IconButton(
                icon: Icon(
                  card.isMastered ? Icons.star_rounded : Icons.star_border_rounded,
                  color: card.isMastered ? Colors.amberAccent : Colors.grey,
                ),
                onPressed: () => provider.toggleFlashcardMastered(quiz.id, card.id),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_outline_rounded, size: 48, color: _emeraldAccent),
          const SizedBox(height: 16),
          Text(
            card.back,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: _emeraldAccent),
              const SizedBox(width: 6),
              const Text(
                'Memorizado pelo Tutor IA',
                style: TextStyle(fontSize: 12, color: _emeraldAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSummarySheet(BuildContext context, CustomStudyQuiz quiz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text(
                    'Pontos-Chave do Resumo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (quiz.summaryBullets.isNotEmpty)
                ...quiz.summaryBullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  quiz.description,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4),
                ),
            ],
          ),
        );
      },
    );
  }
}
