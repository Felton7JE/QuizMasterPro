import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'menu/widgets/game_mode_card.dart';

class SoloModesScreen extends StatelessWidget {
  const SoloModesScreen({super.key});

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
          'Modos Solo',
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
                'Aventura a Solo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jogue sozinho, passe níveis e conquiste o passe de temporada.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
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
                    icon: Icons.map,
                    title: 'Aventura Solo',
                    description: 'Enfrente bosses e passe níveis no mapa',
                    players: 'Solo',
                    duration: 'Sem limite',
                    categories: 'Todas',
                    badge: 'Novo',
                    gameMode: 'solo',
                  ),
                  GameModeCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Passe VIP',
                    description: 'Jogue e desbloqueie prêmios incríveis',
                    players: 'Solo',
                    duration: 'Temporada',
                    categories: 'Temática',
                    badge: 'Evento',
                    gameMode: 'season',
                  ),
                  GameModeCard(
                    icon: Icons.quiz,
                    title: 'Modo Livre',
                    description: 'Responda sem pressão no treino infinito',
                    players: 'Solo',
                    duration: 'Infinito',
                    categories: 'Livre',
                    gameMode: 'free',
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
