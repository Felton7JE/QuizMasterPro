import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/vip_badge_widget.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

import 'menu/widgets/user_gamification_header.dart';
import 'menu/widgets/welcome_section.dart';
import 'menu/widgets/game_mode_card.dart';
import 'menu/widgets/quick_action_card.dart';
import 'menu/widgets/recent_activity_section.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double horizontalPadding = context.isVerySmallScreen ? 16 : 20;
    double verticalPadding = context.isVerySmallScreen ? 16 : 20;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Meu Quiz +',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;

              if (user == null) {
                return Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login, color: AppColors.primary, size: 18),
                      label: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                );
              }

              return Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CosmeticAvatar(
                      radius: 20,
                      avatarUrl: user.avatar,
                      username: user.username,
                      activeAvatarId: user.activeAvatarId,
                      activeFrameId: user.activeFrameId,
                      isVip: user.isVip,
                    ),
                  ),
                  if (user.isVip) ...[  
                    const SizedBox(width: 6),
                    const VipBadge(scale: 0.9),
                  ],
                  const SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Gamification Stats Header
              const UserGamificationHeader(),
              const SizedBox(height: 16),
              
              // Welcome Section
              const WelcomeSection(),
              const SizedBox(height: 32),
              
              // Game Modes Section
              _buildGameModesGrid(context),
              const SizedBox(height: 32),
              
              // Quick Actions Section
              _buildQuickActionsGrid(context),
              const SizedBox(height: 32),
              
              // Recent Activity Section
              const RecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModesGrid(BuildContext context) {
    int crossAxisCount = context.screenWidth > 600 ? 2 : 1;
    double aspectRatio = context.isVerySmallScreen 
        ? 1.3 
        : (context.isSmallScreen ? 1.2 : 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Modos de Jogo',
              style: TextStyle(
                fontSize: context.isVerySmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(context, '/join-room'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: context.isVerySmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
        SizedBox(height: context.screenHeight * 0.02),
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
              title: 'Modo Equipe',
              description: 'Forme equipes de até 4 jogadores e compete em diferentes categorias',
              players: '2-8 Jogadores',
              duration: '15-30 min',
              categories: '4 Categorias',
              badge: 'Popular',
              gameMode: 'team',
            ),
            GameModeCard(
              icon: Icons.flash_on,
              title: 'Duelo 1v1',
              description: 'Desafie um amigo para um duelo direto de conhecimentos',
              players: '2 Jogadores',
              duration: '5-15 min',
              categories: 'Categoria Livre',
              badge: 'Novo',
              gameMode: 'duel',
            ),
            GameModeCard(
              icon: Icons.quiz,
              title: 'Quiz Clássico',
              description: 'Teste seus conhecimentos sozinho no modo tradicional',
              players: 'Solo',
              duration: 'Sem limite',
              categories: 'Todas',
              gameMode: 'solo',
            ),
            GameModeCard(
              icon: Icons.emoji_emotions,
              title: 'Estilo Kahoot',
              description: 'Todos respondem a mesma pergunta simultaneamente',
              players: '2-20 Jogadores',
              duration: '10-20 min',
              categories: 'Tempo Real',
              badge: 'Quente',
              gameMode: 'kahoot',
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
              icon: Icons.school_rounded,
              title: 'Modo Estudo (IA)',
              description: 'Gera quizzes a partir de matérias, PDF e resumos para testes',
              players: 'Solo',
              duration: 'À tua escolha',
              categories: 'Personalizado',
              badge: '5 🔮',
              gameMode: 'study',
            ),
            GameModeCard(
              icon: Icons.celebration,
              title: 'Modo Livre',
              description: 'Treino, Sobrevivência e Corrida Contra o Tempo',
              players: 'Solo',
              duration: 'Variável',
              categories: 'Livre',
              badge: 'Novo',
              gameMode: 'free',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    int crossAxisCount = context.isVerySmallScreen ? 2 : (context.isSmallScreen ? 3 : 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: context.isVerySmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: context.screenHeight * 0.02),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: context.screenWidth * 0.04,
          mainAxisSpacing: context.screenHeight * 0.02,
          childAspectRatio: 1.0,
          children: const [
            QuickActionCard(
              icon: Icons.assignment,
              title: 'Missões',
              description: 'Complete missões e ganhe prêmios',
              route: '/quests',
            ),
            QuickActionCard(
              icon: Icons.storefront,
              title: 'Loja',
              description: 'Compre cosméticos e equipe títulos',
              route: '/store',
            ),
            QuickActionCard(
              icon: Icons.star,
              title: 'Ranking',
              description: 'Veja sua posição no ranking global',
              route: '/ranking',
            ),
            QuickActionCard(
              icon: Icons.settings,
              title: 'Configurações',
              description: 'Personalize sua experiência',
              route: '/settings',
            ),
          ],
        ),
      ],
    );
  }
}
