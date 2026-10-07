import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_plan_model.dart';
import '../providers/auth_provider.dart';
import '../services/study_quiz_service.dart';
import 'create_study_plan_screen.dart';
import 'study_plan_details_screen.dart';

class StudyPlansListScreen extends StatefulWidget {
  const StudyPlansListScreen({super.key});

  @override
  State<StudyPlansListScreen> createState() => _StudyPlansListScreenState();
}

class _StudyPlansListScreenState extends State<StudyPlansListScreen> {
  bool _isLoading = true;
  List<StudyPlan> _plans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser == null) return;

      final service = context.read<StudyQuizService>();
      final plans = await service.getUserStudyPlans(int.parse(auth.currentUser!.id));
      
      if (mounted) {
        setState(() {
          _plans = plans;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateStudyPlanScreen()),
          );
          if (result == true) {
            _loadPlans();
          }
        },
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Criar Plano', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigoAccent));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao carregar planos', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPlans,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ainda não tens planos de estudo.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cria um novo plano guiado por IA!',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlans,
      color: Colors.indigoAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return _buildPlanCard(plan);
        },
      ),
    );
  }

  Widget _buildPlanCard(StudyPlan plan) {
    return Card(
      color: const Color(0xFF2A2A3D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyPlanDetailsScreen(planId: int.parse(plan.id)),
            ),
          );
          _loadPlans(); // Reload to update progress if changed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.topic,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigoAccent.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${plan.durationDays} Dias',
                      style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (plan.objective.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan.objective,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: plan.progressPercentage / 100,
                        backgroundColor: Colors.white12,
                        color: plan.progressPercentage == 100 ? Colors.greenAccent : Colors.indigoAccent,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${plan.progressPercentage}%',
                    style: TextStyle(
                      color: plan.progressPercentage == 100 ? Colors.greenAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
