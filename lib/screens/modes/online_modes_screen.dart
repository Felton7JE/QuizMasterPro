import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_utils.dart';
import '../menu/widgets/game_mode_card.dart';

class OnlineModesScreen extends StatelessWidget {
  const OnlineModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = context.screenWidth > 600 ? 2 : 1;
    double aspectRatio = context.isVerySmallScreen 
        ? 1.3 
        : (context.isSmallScreen ? 1.2 : 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Modos Online',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.isVerySmallScreen ? 16 : 20,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desafie Amigos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jogue contra amigos, crie equipas e participe em eventos ao vivo.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/join-room'),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar em Sala com Código'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: context.screenWidth * 0.04,
                mainAxisSpacing: context.screenHeight * 0.015,
                childAspectRatio: aspectRatio,
                children: const [
                  GameModeCard(
                    icon: Icons.group,
                    title: 'Modo Equipa',
                    description: 'Forme equipas de até 4 jogadores e compita em várias categorias.',
                    players: '2-8 Jogadores',
                    duration: '15-30 min',
                    categories: 'Livre',
                    badge: 'Popular',
                    gameMode: 'team',
                  ),
                  GameModeCard(
                    icon: Icons.flash_on,
                    title: 'Duelo 1v1',
                    description: 'Desafie um amigo para um duelo direto de conhecimentos.',
                    players: '2 Jogadores',
                    duration: '5-15 min',
                    categories: 'Livre',
                    badge: 'Rápido',
                    gameMode: 'duel',
                  ),
                  GameModeCard(
                    icon: Icons.emoji_emotions,
                    title: 'Estilo Kahoot',
                    description: 'Todos respondem à mesma pergunta simultaneamente.',
                    players: '2-20 Jogadores',
                    duration: '10-20 min',
                    categories: 'Tempo Real',
                    badge: 'Quente',
                    gameMode: 'kahoot',
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
