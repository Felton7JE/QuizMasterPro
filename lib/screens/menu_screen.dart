import 'package:flutter/material.dart';
import '../widgets/exit_confirm_scope.dart';
import 'package:flutter/services.dart';
import '../widgets/app_logo_text.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/cosmetic_avatar.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import '../services/app_audio_service.dart';

import 'menu/widgets/user_gamification_header.dart';
import 'menu/widgets/welcome_section.dart';
import 'menu/widgets/quick_action_card.dart';
import 'menu/widgets/recent_activity_section.dart';
import '../widgets/category_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _musicStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_musicStarted) {
      _musicStarted = true;
      context.read<AppAudioService>().playMenuMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExitConfirmScope(
          title: 'Sair do QuizMaster Pro?',
          message: 'Tens a certeza que queres fechar a aplicação?',
          confirmLabel: 'Fechar app',
          cancelLabel: 'Ficar',
          icon: Icons.power_settings_new_rounded,
          onConfirm: () => SystemNavigator.pop(),
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    double horizontalPadding = context.isVerySmallScreen ? 16 : 20;
    double verticalPadding = context.isVerySmallScreen ? 16 : 20;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const AppLogoText(fontSize: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white, size: 24),
            tooltip: 'Amigos',
            onPressed: () => Navigator.pushNamed(context, '/social', arguments: 0),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
            tooltip: 'Mensagens',
            onPressed: () => Navigator.pushNamed(context, '/social', arguments: 2),
          ),
          const SizedBox(width: 4),
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
    return Column(
      children: [
        CategoryCard(
          title: 'SOLO',
          subtitle: 'Aventura, Temporada e Modo Livre',
          icon: Icons.person_outline,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          onTap: () => Navigator.pushNamed(context, '/solo_modes'),
        ),
        const SizedBox(height: 16),
        CategoryCard(
          title: 'ONLINE',
          subtitle: 'Desafia amigos em 1v1, Equipa ou Salas',
          icon: Icons.public,
          gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          onTap: () => Navigator.pushNamed(context, '/online_modes'),
        ),
        const SizedBox(height: 16),
        CategoryCard(
          title: 'ESTUDO',
          subtitle: 'Gera quizzes com IA para estudar',
          icon: Icons.school_outlined,
          gradient: const [Color(0xFF10B981), Color(0xFF059669)],
          onTap: () => Navigator.pushNamed(context, '/study_modes'),
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
