import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/feature_card.dart';
import '../widgets/game_mode_card.dart';

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
              Text(
                'QuizMaster',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8, 
                  vertical: isSmallScreen ? 2 : 4
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pro',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
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
                  onTap: () => Navigator.pushNamed(context, '/join-room'),
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
                    onPressed: () => Navigator.pushNamed(context, '/menu'),
                    isPrimary: true,
                    icon: Icons.play_arrow,
                    isLarge: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Saiba Mais',
                    onPressed: () {},
                    isPrimary: false,
                    icon: Icons.info_outline,
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
                  onPressed: () => Navigator.pushNamed(context, '/menu'),
                  isPrimary: true,
                  icon: Icons.play_arrow,
                  isLarge: true,
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'Saiba Mais',
                  onPressed: () {},
                  isPrimary: false,
                  icon: Icons.info_outline,
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
          Text(
            'Por que escolher o QuizMaster?',
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
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
                return Column(
                  children: [
                    FeatureCard(
                      icon: Icons.group,
                      title: 'Multiplayer Épico',
                      description: 'Jogue com até 8 pessoas divididas em 2 equipes de 4 jogadores cada. Cada jogador especialista em uma categoria!',
                    ),
                    const SizedBox(height: 16),
                    FeatureCard(
                      icon: Icons.diamond,
                      title: 'Múltiplos Modos',
                      description: 'Modo Equipe, 1v1, Quiz Clássico, estilo Kahoot e muito mais. Cada modo com suas próprias regras e desafios únicos.',
                    ),
                    const SizedBox(height: 16),
                    FeatureCard(
                      icon: Icons.wifi,
                      title: 'Online & Offline',
                      description: 'Jogue online com pessoas do mundo todo ou crie um hotspot Wi-Fi para jogar offline com seus amigos próximos.',
                    ),
                  ],
                );
              } else if (isMediumScreen) {
                // Layout em 2 colunas para telas médias
                return Column(
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.diamond,
                            title: 'Múltiplos Modos',
                            description: 'Modo Equipe, 1v1, Quiz Clássico, estilo Kahoot e muito mais. Cada modo com suas próprias regras e desafios únicos.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.wifi,
                            title: 'Online & Offline',
                            description: 'Jogue online com pessoas do mundo todo ou crie um hotspot Wi-Fi para jogar offline com seus amigos próximos.',
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()), // Espaço vazio
                      ],
                    ),
                  ],
                );
              } else {
                // Layout em 3 colunas para telas grandes
                return Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.group,
                        title: 'Multiplayer Épico',
                        description: 'Jogue com até 8 pessoas divididas em 2 equipes de 4 jogadores cada. Cada jogador especialista em uma categoria!',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.diamond,
                        title: 'Múltiplos Modos',
                        description: 'Modo Equipe, 1v1, Quiz Clássico, estilo Kahoot e muito mais. Cada modo com suas próprias regras e desafios únicos.',
                      ),
                    ),
                    const SizedBox(width: 16),
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
              if (isSmallScreen) {
                // Layout em coluna para telas pequenas
                return Column(
                  children: [
                    GameModeCard(
                      icon: Icons.group,
                      title: 'Modo Equipe',
                      description: 'Forme equipes de até 4 jogadores e compete em diferentes categorias',
                      players: '2-8 Jogadores',
                      duration: '15-30 min',
                      categories: '4 Categorias',
                      badge: 'Popular',
                      onTap: () => Navigator.pushNamed(context, '/menu'),
                    ),
                    const SizedBox(height: 16),
                    GameModeCard(
                      icon: Icons.flash_on,
                      title: 'Duelo 1v1',
                      description: 'Desafie um amigo para um duelo direto de conhecimentos',
                      players: '2 Jogadores',
                      duration: '5-15 min',
                      categories: 'Categoria Livre',
                      badge: 'Novo',
                      onTap: () => Navigator.pushNamed(context, '/menu'),
                    ),
                  ],
                );
              } else if (isMediumScreen) {
                // Layout em 2 colunas para telas médias
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GameModeCard(
                            icon: Icons.group,
                            title: 'Modo Equipe',
                            description: 'Forme equipes de até 4 jogadores e compete em diferentes categorias',
                            players: '2-8 Jogadores',
                            duration: '15-30 min',
                            categories: '4 Categorias',
                            badge: 'Popular',
                            onTap: () => Navigator.pushNamed(context, '/menu'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GameModeCard(
                            icon: Icons.flash_on,
                            title: 'Duelo 1v1',
                            description: 'Desafie um amigo para um duelo direto de conhecimentos',
                            players: '2 Jogadores',
                            duration: '5-15 min',
                            categories: 'Categoria Livre',
                            badge: 'Novo',
                            onTap: () => Navigator.pushNamed(context, '/menu'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GameModeCard(
                            icon: Icons.quiz,
                            title: 'Quiz Clássico',
                            description: 'Teste seus conhecimentos sozinho no modo tradicional',
                            players: 'Solo',
                            duration: 'Sem limite',
                            categories: 'Todas',
                            onTap: () => Navigator.pushNamed(context, '/quiz-game'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GameModeCard(
                            icon: Icons.emoji_emotions,
                            title: 'Estilo Kahoot',
                            description: 'Todos respondem a mesma pergunta simultaneamente',
                            players: '2-20 Jogadores',
                            duration: '10-20 min',
                            categories: 'Tempo Real',
                            badge: 'Quente',
                            onTap: () => Navigator.pushNamed(context, '/menu'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Layout em 4 colunas para telas grandes
                return Row(
                  children: [
                    Expanded(
                      child: GameModeCard(
                        icon: Icons.group,
                        title: 'Modo Equipe',
                        description: 'Forme equipes de até 4 jogadores e compete em diferentes categorias',
                        players: '2-8 Jogadores',
                        duration: '15-30 min',
                        categories: '4 Categorias',
                        badge: 'Popular',
                        onTap: () => Navigator.pushNamed(context, '/menu'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GameModeCard(
                        icon: Icons.flash_on,
                        title: 'Duelo 1v1',
                        description: 'Desafie um amigo para um duelo direto de conhecimentos',
                        players: '2 Jogadores',
                        duration: '5-15 min',
                        categories: 'Categoria Livre',
                        badge: 'Novo',
                        onTap: () => Navigator.pushNamed(context, '/menu'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GameModeCard(
                        icon: Icons.quiz,
                        title: 'Quiz Clássico',
                        description: 'Teste seus conhecimentos sozinho no modo tradicional',
                        players: 'Solo',
                        duration: 'Sem limite',
                        categories: 'Todas',
                        onTap: () => Navigator.pushNamed(context, '/quiz-game'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GameModeCard(
                        icon: Icons.emoji_emotions,
                        title: 'Estilo Kahoot',
                        description: 'Todos respondem a mesma pergunta simultaneamente',
                        players: '2-20 Jogadores',
                        duration: '10-20 min',
                        categories: 'Tempo Real',
                        badge: 'Quente',
                        onTap: () => Navigator.pushNamed(context, '/menu'),
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
}

