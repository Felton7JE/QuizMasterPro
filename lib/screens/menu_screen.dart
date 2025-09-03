import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'QuizMaster',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pro',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              
              // Se não estiver logado, mostra botão de login
              if (user == null) {
                return Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login, color: Color(0xFF6366F1), size: 18),
                      label: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                );
              }
              
              // Se estiver logado, mostra o perfil atual
              return Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${user.totalPoints}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Pontos',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${user.gamesWon}/${user.gamesPlayed}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Vitórias',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : null,
                    backgroundColor: const Color(0xFF6366F1),
                    child: user.avatar == null
                        ? Text(
                            user.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            double horizontalPadding = screenWidth < 400 ? 16 : 20;
            double verticalPadding = screenWidth < 400 ? 16 : 20;
            
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: 32),
                  // Game Modes Section
                  _buildGameModesSection(context),
                  const SizedBox(height: 32),
                  // Quick Actions Section
                  _buildQuickActionsSection(context),
                  const SizedBox(height: 32),
                  // Recent Activity Section
                  _buildRecentActivitySection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final winRate = user?.gamesPlayed != null && user!.gamesPlayed > 0
            ? ((user.gamesWon / user.gamesPlayed) * 100).toStringAsFixed(0)
            : '0';
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo de volta, ${user?.fullName ?? user?.username ?? 'Jogador'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha seu modo de jogo favorito e comece a diversão',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat('🏆', '${user?.gamesWon ?? 0}', 'Vitórias'),
                  _buildQuickStat('🎯', '$winRate%', 'Taxa de Vitória'),
                  _buildQuickStat('⚡', '${user?.bestStreak ?? 0}', 'Melhor Sequência'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildGameModesSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calcular crossAxisCount baseado no tamanho da tela
    int crossAxisCount = screenWidth > 600 ? 2 : 1;
    
    // Calcular aspectRatio baseado no tamanho da tela
    double aspectRatio;
    if (screenWidth < 400) {
      aspectRatio = 1.3; // Telas pequenas - mais largo que alto
    } else if (screenWidth < 600) {
      aspectRatio = 1.2; // Telas médias - mais largo que alto
    } else {
      aspectRatio = 1.0; // Telas grandes - quadrado
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modos de Jogo',
          style: TextStyle(
            fontSize: screenWidth < 400 ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenHeight * 0.015,
          childAspectRatio: aspectRatio,
          children: [
            _buildGameModeCard(
              context,
              Icons.group,
              'Modo Equipe',
              'Forme equipes de até 4 jogadores e compete em diferentes categorias',
              '2-8 Jogadores',
              '15-30 min',
              '4 Categorias',
              'Popular',
              'team',
            ),
            _buildGameModeCard(
              context,
              Icons.flash_on,
              'Duelo 1v1',
              'Desafie um amigo para um duelo direto de conhecimentos',
              '2 Jogadores',
              '5-15 min',
              'Categoria Livre',
              'Novo',
              'duel',
            ),
            _buildGameModeCard(
              context,
              Icons.quiz,
              'Quiz Clássico',
              'Teste seus conhecimentos sozinho no modo tradicional',
              'Solo',
              'Sem limite',
              'Todas',
              null,
              'solo',
            ),
            _buildGameModeCard(
              context,
              Icons.emoji_emotions,
              'Estilo Kahoot',
              'Todos respondem a mesma pergunta simultaneamente',
              '2-20 Jogadores',
              '10-20 min',
              'Tempo Real',
              'Quente',
              'kahoot',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameModeCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String players,
    String duration,
    String categories,
    String? badge,
    String gameMode,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Tamanhos responsivos
    double iconSize = screenWidth < 400 ? 20 : 24;
    double titleFontSize = screenWidth < 400 ? 14 : 16;
    double descriptionFontSize = screenWidth < 400 ? 10 : 12;
    double badgeFontSize = screenWidth < 400 ? 7 : 8;
    double cardPadding = screenWidth < 400 ? 8 : 12;
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth < 400 ? 6 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: iconSize,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 400 ? 4 : 6, 
                    vertical: 2
                  ),
                  decoration: BoxDecoration(
                    color: badge == 'Popular' ? const Color(0xFFF59E0B) : 
                           badge == 'Novo' ? const Color(0xFF10B981) : 
                           const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.004),
          Text(
            description,
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.grey,
              height: 1.2,
            ),
            maxLines: screenWidth < 400 ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenHeight * 0.008),
          _buildModeStats(players, duration, categories),
          const Spacer(),
          SizedBox(height: screenHeight * 0.008),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Criar Sala',
                  onPressed: () {
                    if (gameMode == 'solo') {
                      Navigator.pushNamed(context, '/quiz-game');
                    } else {
                      Navigator.pushNamed(
                        context, 
                        '/create-room',
                        arguments: {'gameMode': gameMode},
                      );
                    }
                  },
                  isPrimary: true,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: CustomButton(
                  text: 'Entrar',
                  onPressed: () {
                    Navigator.pushNamed(context, '/join-room');
                  },
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeStats(String players, String duration, String categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        double spacing = screenWidth < 400 ? 0.5 : 1;
        
        return Column(
          children: [
            _buildStatRow('👥', players),
            SizedBox(height: spacing),
            _buildStatRow('⏱️', duration),
            SizedBox(height: spacing),
            _buildStatRow('🎯', categories),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String emoji, String text) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        double emojiSize = screenWidth < 400 ? 10 : 12;
        double textSize = screenWidth < 400 ? 8 : 10;
        double spacing = screenWidth < 400 ? 6 : 8;
        
        return Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: emojiSize)),
            SizedBox(width: spacing),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: textSize,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calcular crossAxisCount baseado no tamanho da tela
    int crossAxisCount;
    if (screenWidth < 400) {
      crossAxisCount = 2; // Telas muito pequenas
    } else if (screenWidth < 600) {
      crossAxisCount = 3; // Telas pequenas/médias
    } else {
      crossAxisCount = 4; // Telas grandes
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: screenWidth < 400 ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Botão destacado para Entrar em Sala
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                          'Entrar em Sala',
                          style: TextStyle(
                            fontSize: screenWidth < 400 ? 12 : 14,
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
        SizedBox(height: screenHeight * 0.02),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenHeight * 0.02,
          childAspectRatio: 1.0,
          children: [
            _buildQuickActionCard(
              context,
              Icons.star,
              'Ranking',
              'Veja sua posição no ranking global',
              '/ranking',
            ),
            _buildQuickActionCard(
              context,
              Icons.emoji_events,
              'Conquistas',
              'Veja suas medalhas e troféus',
              '/achievements',
            ),
            _buildQuickActionCard(
              context,
              Icons.person,
              'Perfil',
              'Gerencie sua conta e estatísticas',
              '/profile',
            ),
            _buildQuickActionCard(
              context,
              Icons.settings,
              'Configurações',
              'Personalize sua experiência',
              '/settings',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String route,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Tamanhos responsivos
    double iconSize = screenWidth < 400 ? 24 : 32;
    double titleFontSize = screenWidth < 400 ? 12 : 14;
    double descriptionFontSize = screenWidth < 400 ? 8 : 10;
    double cardPadding = screenWidth < 400 ? 12 : 16;
    
    return GestureDetector(
      onTap: () {
        if (route == '/ranking') {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: iconSize,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenHeight * 0.005),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: descriptionFontSize,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: screenWidth < 400 ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Recente',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityItem('🏆', 'Vitória em Duelo 1v1', 'Você venceu João em Matemática', '2 horas atrás', '+50 pts'),
        _buildActivityItem('🎖️', 'Nova Conquista', 'Desbloqueou "Mestre em História"', '1 dia atrás', '+100 pts'),
        _buildActivityItem('👥', 'Partida em Equipe', 'Sua equipe venceu por 1200-980', '2 dias atrás', '+75 pts'),
      ],
    );
  }

  Widget _buildActivityItem(String emoji, String title, String description, String time, String points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

