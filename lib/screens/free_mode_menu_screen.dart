import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'solo_setup_screen.dart';
import 'survival_game_screen.dart';
import 'time_attack_game_screen.dart';

class FreeModeMenuScreen extends StatelessWidget {
  const FreeModeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modo Livre'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolhe o teu desafio!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Sem ranking, sem stress. Apenas diversão.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildModeCard(
              context,
              title: 'Treino Clássico',
              description: 'Escolhe a categoria e joga ao teu ritmo.',
              icon: Icons.school,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SoloSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildModeCard(
              context,
              title: 'Sobrevivência',
              description: '3 vidas. Perguntas infinitas. Até onde consegues ir?',
              icon: Icons.favorite,
              color: Colors.redAccent,
              onTap: () {
                Navigator.pushNamed(context, '/quiz-countdown', arguments: {
                  'gameMode': 'SURVIVAL',
                });
              },
            ),
            const SizedBox(height: 20),
            _buildModeCard(
              context,
              title: 'Corrida Contra o Tempo',
              description: '60 segundos. Responde rápido para ganhar mais tempo!',
              icon: Icons.timer,
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.pushNamed(context, '/quiz-countdown', arguments: {
                  'gameMode': 'TIME_ATTACK',
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
