import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/study_plan_model.dart';
import '../../services/study_quiz_service.dart';
import './study_quiz_game_screen.dart';

class StudyPlanDetailsScreen extends StatefulWidget {
  final int planId;

  const StudyPlanDetailsScreen({super.key, required this.planId});

  @override
  State<StudyPlanDetailsScreen> createState() => _StudyPlanDetailsScreenState();
}

class _StudyPlanDetailsScreenState extends State<StudyPlanDetailsScreen> {
  bool _isLoading = true;
  StudyPlan? _plan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<StudyQuizService>();
      final plan = await service.getStudyPlanDetails(widget.planId);
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startQuizForDay(StudyPlanDay day) async {
    if (day.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já completaste este dia! ✅'), backgroundColor: Colors.green),
      );
      // We can still allow them to practice or prevent it. For now, we allow them to practice anyway.
    }

    // Gerar um quiz rápido no momento baseado no tópico do dia
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.indigoAccent)),
    );

    try {
      final service = context.read<StudyQuizService>();
      final quiz = await service.generateQuiz(
        title: 'Prática: ${day.title}',
        content: '${_plan!.topic} - ${day.description}',
        questionCount: 5,
        difficulty: 'MEDIO',
        topic: _plan!.topic,
      );

      if (mounted) {
        Navigator.pop(context); // Fechar loading
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudyQuizGameScreen(quiz: quiz)),
        );
        
        // Se voltarem de um jogo, vamos assumir que o dia está concluído (lógica simplificada, poderia ser verificada a pontuação)
        if (result != null || !day.isCompleted) {
          _markDayCompleted(day);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar quiz: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _markDayCompleted(StudyPlanDay day) async {
    try {
      final service = context.read<StudyQuizService>();
      await service.markDayAsCompleted(int.parse(day.id));
      _loadPlan(); // Recarrega para atualizar a UI
    } catch (e) {
      debugPrint('Erro ao marcar concluído: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Roteiro do Plano'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigoAccent));
    }

    if (_error != null || _plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error ?? 'Erro ao carregar', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPlan,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            itemCount: _plan!.days.length,
            itemBuilder: (context, index) {
              final day = _plan!.days[index];
              return _buildTimelineItem(day, isLast: index == _plan!.days.length - 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _plan!.topic,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _plan!.progressPercentage / 100,
                    backgroundColor: Colors.black26,
                    color: Colors.indigoAccent,
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_plan!.progressPercentage}%',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_plan!.durationDays} dias no total',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(StudyPlanDay day, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: day.isCompleted ? Colors.greenAccent : const Color(0xFF2A2A3D),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: day.isCompleted ? Colors.green : Colors.indigoAccent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: day.isCompleted
                        ? const Icon(Icons.check, color: Colors.black, size: 20)
                        : Text(
                            '${day.dayNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: day.isCompleted ? Colors.greenAccent : Colors.white12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
              child: Card(
                color: day.isCompleted ? const Color(0xFF2A3D36) : const Color(0xFF2A2A3D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: day.isCompleted ? Colors.green.withOpacity(0.3) : Colors.transparent),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: day.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _startQuizForDay(day),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: day.isCompleted ? Colors.transparent : Colors.indigoAccent,
                            elevation: day.isCompleted ? 0 : 2,
                            side: day.isCompleted ? const BorderSide(color: Colors.greenAccent) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: Icon(
                            day.isCompleted ? Icons.refresh : Icons.play_arrow,
                            color: day.isCompleted ? Colors.greenAccent : Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            day.isCompleted ? 'Praticar Novamente' : 'Iniciar Estudo',
                            style: TextStyle(color: day.isCompleted ? Colors.greenAccent : Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
