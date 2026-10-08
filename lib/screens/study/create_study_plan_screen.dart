import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../services/study_quiz_service.dart';

class CreateStudyPlanScreen extends StatefulWidget {
  const CreateStudyPlanScreen({super.key});

  @override
  State<CreateStudyPlanScreen> createState() => _CreateStudyPlanScreenState();
}

class _CreateStudyPlanScreenState extends State<CreateStudyPlanScreen> {
  final _topicController = TextEditingController();
  final _objectiveController = TextEditingController();
  int _days = 5;
  bool _isGenerating = false;

  Future<void> _generatePlan() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insere o tema do plano.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final auth = context.read<AuthProvider>();
      final service = context.read<StudyQuizService>();

      await service.createStudyPlan(
        userId: int.parse(auth.currentUser!.id),
        topic: _topicController.text.trim(),
        durationDays: _days,
        objective: _objectiveController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano gerado com sucesso! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _objectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Novo Plano de Estudo'),
      ),
      body: _isGenerating
          ? _buildLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: const Text(
                            'A nossa IA vai gerar um roteiro de estudo diário para ti.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Qual é o tema que queres estudar?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _topicController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ex: Biologia Celular, História de Portugal...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Quantos dias queres estudar?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Slider(
                    value: _days.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    activeColor: Colors.indigoAccent,
                    inactiveColor: Colors.white12,
                    label: '$_days dias',
                    onChanged: (val) => setState(() => _days = val.toInt()),
                  ),
                  Center(
                    child: Text('$_days dias', style: const TextStyle(color: Colors.indigoAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Objetivo (Opcional)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _objectiveController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ex: Preparar para o exame final, focar na parte teórica...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _generatePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('✨ Gerar Plano com IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.indigoAccent),
          const SizedBox(height: 24),
          const Text(
            'A IA está a criar o teu plano perfeito...',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Isto pode demorar alguns segundos.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
