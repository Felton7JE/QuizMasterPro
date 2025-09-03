import 'package:flutter/material.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _selectedFilter = 'global';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _topPlayers = [
    {
      'rank': 1,
      'name': 'João Santos',
      'points': 3420,
      'accuracy': 94,
      'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
      'badges': ['👑 Campeão', '⚡ Velocista', '🎯 Preciso'],
    },
    {
      'rank': 2,
      'name': 'Maria Silva',
      'points': 2850,
      'accuracy': 89,
      'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face',
      'badges': ['🏆 Mestre', '🔥 Sequência'],
    },
    {
      'rank': 3,
      'name': 'Pedro Costa',
      'points': 2640,
      'accuracy': 85,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
      'badges': ['📚 Estudioso', '🎲 Sortudo'],
    },
  ];

  final List<Map<String, dynamic>> _allPlayers = [
    {
      'rank': 4,
      'name': 'Ana Oliveira',
      'points': 2480,
      'accuracy': 91,
      'games': 45,
      'streak': 7,
      'level': 18,
      'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=40&h=40&fit=crop&crop=face',
      'change': 0,
    },
    {
      'rank': 5,
      'name': 'Carlos Lima',
      'points': 2350,
      'accuracy': 88,
      'games': 38,
      'streak': 2,
      'level': 16,
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=40&h=40&fit=crop&crop=face',
      'change': -1,
    },
    {
      'rank': 6,
      'name': 'Sofia Mendes',
      'points': 2290,
      'accuracy': 86,
      'games': 41,
      'streak': 5,
      'level': 15,
      'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=40&h=40&fit=crop&crop=face',
      'change': 2,
    },
    {
      'rank': 7,
      'name': 'Lucas Ferreira',
      'points': 2180,
      'accuracy': 83,
      'games': 35,
      'streak': 1,
      'level': 14,
      'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=40&h=40&fit=crop&crop=face',
      'change': 0,
    },
    {
      'rank': 42,
      'name': 'Você',
      'points': 1250,
      'accuracy': 87,
      'games': 23,
      'streak': 3,
      'level': 12,
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=40&h=40&fit=crop&crop=face',
      'change': 3,
      'isCurrentUser': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Text(
              'QuizMaster',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : 6, 
                vertical: 2
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
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
        actions: [
          if (!isSmallScreen)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/menu'),
              child: const Text(
                'Voltar ao Menu',
                style: TextStyle(color: Color(0xFF6366F1)),
              ),
            )
          else
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/menu'),
              icon: const Icon(
                Icons.home,
                color: Color(0xFF6366F1),
              ),
            ),
          SizedBox(width: isSmallScreen ? 8 : 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Ranking Global',
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Veja os melhores jogadores do QuizMaster',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),

            // Ranking Filters
            _buildRankingFilters(),
            SizedBox(height: isSmallScreen ? 24 : 32),

            // Top 3 Podium
            _buildPodiumSection(),
            SizedBox(height: isSmallScreen ? 24 : 32),

            // Ranking List
            _buildRankingListSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingFilters() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Column(
          children: [
            if (isSmallScreen) ...[
              // Em telas pequenas, empilha verticalmente
              Row(
                children: [
                  Expanded(child: _buildFilterTab('global', 'Global', Icons.public)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('weekly', 'Semanal', Icons.calendar_today)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildFilterTab('monthly', 'Mensal', Icons.calendar_month)),
                ],
              ),
              const SizedBox(height: 12),
              // Category Filter em linha separada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1E293B),
                  underline: Container(),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todas as Categorias')),
                    DropdownMenuItem(value: 'math', child: Text('Matemática')),
                    DropdownMenuItem(value: 'portuguese', child: Text('Português')),
                    DropdownMenuItem(value: 'history', child: Text('História')),
                    DropdownMenuItem(value: 'geography', child: Text('Geografia')),
                    DropdownMenuItem(value: 'science', child: Text('Ciências')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ] else ...[
              // Em telas maiores, mantém layout horizontal
              Row(
                children: [
                  _buildFilterTab('global', 'Global', Icons.public),
                  const SizedBox(width: 8),
                  _buildFilterTab('weekly', 'Semanal', Icons.calendar_today),
                  const SizedBox(width: 8),
                  _buildFilterTab('monthly', 'Mensal', Icons.calendar_month),
                  const Spacer(),
                  // Category Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF1E293B),
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todas as Categorias')),
                        DropdownMenuItem(value: 'math', child: Text('Matemática')),
                        DropdownMenuItem(value: 'portuguese', child: Text('Português')),
                        DropdownMenuItem(value: 'history', child: Text('História')),
                        DropdownMenuItem(value: 'geography', child: Text('Geografia')),
                        DropdownMenuItem(value: 'science', child: Text('Ciências')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterTab(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilter = filter;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 16, 
              vertical: isSmallScreen ? 8 : 12
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
              ),
            ),
            child: isSmallScreen 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }

  Widget _buildPodiumSection() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Container(
          height: isSmallScreen ? 200 : 300,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              Expanded(
                child: _buildPodiumPlace(
                  _topPlayers[1], 
                  2, 
                  isSmallScreen ? 120 : 200, 
                  Colors.grey
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              // 1st Place
              Expanded(
                child: _buildPodiumPlace(
                  _topPlayers[0], 
                  1, 
                  isSmallScreen ? 150 : 250, 
                  const Color(0xFFFFD700)
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              // 3rd Place
              Expanded(
                child: _buildPodiumPlace(
                  _topPlayers[2], 
                  3, 
                  isSmallScreen ? 90 : 150, 
                  const Color(0xFFCD7F32)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodiumPlace(Map<String, dynamic> player, int place, double height, Color color) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Player Info
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: place == 1 
                          ? (isSmallScreen ? 25 : 40) 
                          : (isSmallScreen ? 18 : 30),
                        backgroundImage: NetworkImage(player['avatar']),
                      ),
                      if (place == 1)
                        Positioned(
                          top: -5,
                          left: 0,
                          right: 0,
                          child: Text(
                            '👑',
                            style: TextStyle(fontSize: isSmallScreen ? 16 : 24),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${place}º',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 12),
                  Text(
                    player['name'],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  if (!isSmallScreen) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${player['points']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Pontos',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${player['accuracy']}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Precisão',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: player['badges'].map<Widget>((badge) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 8,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )).toList(),
                    ),
                  ] else ...[
                    // Em telas pequenas, mostra apenas os pontos
                    Text(
                      '${player['points']} pts',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            // Podium Base
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.4),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Text(
                  '$place',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 32 : 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRankingListSection() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Classificação Completa',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isSmallScreen)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '1,247 jogadores ativos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Atualizado há 5 min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            if (!isSmallScreen) ...[
              // Table Header apenas em telas maiores
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 40, child: Text('Pos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 3, child: Text('Jogador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                    SizedBox(width: 60, child: Text('Pontos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                    SizedBox(width: 60, child: Text('Precisão', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                    SizedBox(width: 50, child: Text('Jogos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                    SizedBox(width: 60, child: Text('Sequência', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Player Rows
            ..._allPlayers.map((player) => _buildPlayerRow(player)),
          ],
        );
      },
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player) {
    final isCurrentUser = player['isCurrentUser'] ?? false;
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16, 
            vertical: isSmallScreen ? 8 : 12
          ),
          decoration: BoxDecoration(
            color: isCurrentUser ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: isCurrentUser ? Border.all(color: const Color(0xFF6366F1)) : null,
          ),
          child: isSmallScreen 
            ? _buildMobilePlayerRow(player, isCurrentUser)
            : _buildDesktopPlayerRow(player, isCurrentUser),
        );
      },
    );
  }

  Widget _buildMobilePlayerRow(Map<String, dynamic> player, bool isCurrentUser) {
    return Row(
      children: [
        // Rank e Avatar
        Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${player['rank']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? const Color(0xFF6366F1) : Colors.white,
                  ),
                ),
                if (player['change'] != 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    player['change'] > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: player['change'] > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(player['avatar']),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Info do jogador
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? const Color(0xFF6366F1) : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Nível ${player['level']}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${player['points']} pts',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${player['accuracy']}% precisão',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${player['streak']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    player['streak'] >= 5 ? '🔥' : player['streak'] >= 3 ? '⚡' : '⭐',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopPlayerRow(Map<String, dynamic> player, bool isCurrentUser) {
    return Row(
      children: [
        // Rank
        SizedBox(
          width: 40,
          child: Row(
            children: [
              Text(
                '${player['rank']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? const Color(0xFF6366F1) : Colors.white,
                ),
              ),
              if (player['change'] != 0) ...[
                const SizedBox(width: 4),
                Icon(
                  player['change'] > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: player['change'] > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ],
            ],
          ),
        ),
        // Player
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(player['avatar']),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? const Color(0xFF6366F1) : Colors.white,
                    ),
                  ),
                  Text(
                    'Nível ${player['level']}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Points
        SizedBox(
          width: 60,
          child: Text(
            '${player['points']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        // Accuracy
        SizedBox(
          width: 60,
          child: Text(
            '${player['accuracy']}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        // Games
        SizedBox(
          width: 50,
          child: Text(
            '${player['games']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        // Streak
        SizedBox(
          width: 60,
          child: Row(
            children: [
              Text(
                '${player['streak']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                player['streak'] >= 5 ? '🔥' : player['streak'] >= 3 ? '⚡' : '⭐',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

