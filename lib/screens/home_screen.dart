import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/app_logo_text.dart';
import '../widgets/feature_card.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                _buildHeader(context, isSmallScreen),
                // Hero Section
                _buildHeroSection(context, isSmallScreen, screenHeight),
                // Features Section
                _buildFeaturesSection(isSmallScreen, isMediumScreen),
                // Game Modes Section
                _buildGameModesSection(isSmallScreen, isMediumScreen),
                // Footer spacing
                SizedBox(height: isSmallScreen ? 40 : 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20, 
        vertical: isSmallScreen ? 12 : 16
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppLogoText(fontSize: isSmallScreen ? 20 : 24),
            ],
          ),
          if (!isSmallScreen)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: const Color(0xFF6366F1),
                          size: isSmallScreen ? 16 : 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Jogar Agora',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6366F1),
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

  Widget _buildHeroSection(BuildContext context, bool isSmallScreen, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 40 : 80
      ),
      child: Column(
        children: [
          Text(
            'Desafie Seus Amigos no',
            style: TextStyle(
              fontSize: isSmallScreen ? 28 : 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Quiz ',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                TextSpan(
                  text: 'Definitivo',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'Crie salas, forme equipes de até 4 jogadores e teste seus conhecimentos em diferentes categorias. Jogue online ou offline via Wi-Fi hotspot!',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 32 : 48),
          if (isSmallScreen)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Começar a Jogar',
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    isPrimary: true,
                    icon: Icons.play_arrow,
                    isLarge: true,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: 'Começar a Jogar',
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  isPrimary: true,
                  icon: Icons.play_arrow,
                  isLarge: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 40 : 60
      ),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: 'Por que escolher o '),
                AppLogoText.getSpan(fontSize: isSmallScreen ? 16 : 20),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 16),
          Text(
            'Recursos únicos que tornam cada partida emocionante',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 32 : 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isSmallScreen) {
                // Layout em coluna para telas pequenas
                return const Column(
                  children: [
                    FeatureCard(
                      icon: Icons.group,
                      title: 'Multiplayer Épico',
                      description: 'Jogue com até 8 pessoas divididas em 2 equipes de 4 jogadores cada. Cada jogador especialista em uma categoria!',
                    ),
                    SizedBox(height: 16),
                    FeatureCard(
                      icon: Icons.diamond,
                      title: 'Múltiplos Modos',
                      description: 'Modo Equipe, 1v1, Quiz Clássico, estilo Kahoot e muito mais. Cada modo com suas próprias regras e desafios únicos.',
                    ),
                    SizedBox(height: 16),
                    FeatureCard(
                      icon: Icons.wifi,
                      title: 'Online & Offline',
                      description: 'Jogue online com pessoas do mundo todo ou crie um hotspot Wi-Fi para jogar offline com seus amigos próximos.',
                    ),
                  ],
                );
              } else if (isMediumScreen) {
                // Layout em 2 colunas para telas médias
                return const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.group,
                            title: 'Multiplayer Épico',
                            description: 'Jogue com até 8 pessoas divididas em 2 equipes de 4 jogadores cada. Cada jogador especialista em uma categoria!',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.diamond,
                            title: 'Múltiplos Modos',
                            description: 'Modo Equipe, 1v1, Quiz Clássico, estilo Kahoot e muito mais. Cada modo com suas próprias regras e desafios únicos.',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.wifi,
                            title: 'Online & Offline',
                            description: 'Jogue online com pessoas do mundo todo ou crie um hotspot Wi-Fi para jogar offline com seus amigos próximos.',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(child: SizedBox()), // Espaço vazio
                      ],
                    ),
                  ],
                );
              } else {
                // Layout em 3 colunas para telas grandes
                return const Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.group,
                        title: 'Multiplayer Épico',
                        description: 'Jogue com até 8 pessoas divididas em 2 equipes de 4 jogadores cada. Cada jogador especialista em uma categoria!',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.diamond,
                        title: 'Múltiplos Modos',
                        description: 'Modo Equipe, 1v1, Quiz Clássico, estilo Kahoot e muito mais. Cada modo com suas próprias regras e desafios únicos.',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.wifi,
                        title: 'Online & Offline',
                        description: 'Jogue online com pessoas do mundo todo ou crie um hotspot Wi-Fi para jogar offline com seus amigos próximos.',
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameModesSection(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 40,
        vertical: isSmallScreen ? 40 : 60
      ),
      child: Column(
        children: [
          Text(
            'Escolha Seu Modo Favorito',
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 8 : 16),
          Text(
            'Diferentes estilos de jogo para todos os gostos',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 32 : 48),
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  CategoryCard(
                    title: 'SOLO',
                    subtitle: 'Aventura, Temporada e Modo Livre',
                    icon: Icons.person_outline,
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                  const SizedBox(height: 16),
                  CategoryCard(
                    title: 'ONLINE',
                    subtitle: 'Desafia amigos em 1v1, Equipa ou Salas',
                    icon: Icons.public,
                    gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                  const SizedBox(height: 16),
                  CategoryCard(
                    title: 'ESTUDO',
                    subtitle: 'Gera quizzes com IA para estudar',
                    icon: Icons.school_outlined,
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
