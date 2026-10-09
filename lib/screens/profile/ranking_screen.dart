import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../services/solo_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/core/app_logo_text.dart';
import '../../widgets/economy/vip_badge_widget.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../providers/economy/store_provider.dart';
import 'package:quizmaster_pro/widgets/core/loading_logo.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _selectedGameMode = 'standard';
  String _selectedFilter = 'global';
  String _selectedCategory = 'all';

  List<Map<String, dynamic>> _topPlayers = [];
  List<Map<String, dynamic>> _allPlayers = [];
  bool _isLoading = true;
  bool _showFullRanking = false;

  @override
  void initState() {
    super.initState();
    _fetchRanking();
  }

  Future<void> _fetchRanking() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      List<dynamic> data;
      
      if (_selectedGameMode == 'standard') {
        data = await authProvider.getRanking(
          period: _selectedFilter,
          category: _selectedCategory,
        );
      } else {
        final soloService = context.read<SoloService>();
        data = await soloService.getFreeModeLeaderboard(_selectedGameMode);
      }
      
      final mappedData = data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        if (_selectedGameMode == 'standard') {
          return {
            'rank': item['position'] ?? (index + 1),
            'name': item['username'] ?? 'User',
            'points': item['totalPoints'] ?? 0,
            'accuracy': item['accuracy']?.toInt() ?? 0,
            'games': item['gamesPlayed'] ?? 0,
            'streak': item['streak'] ?? 0,
            'level': item['level'] ?? 1,
            'avatar': item['avatar'],
            'change': 0,
            'badges': item['activeTitleName'] != null ? [item['activeTitleName']] : [],
            'bannerUrl': item['activeBannerUrl'],
            'activeFrameId': item['activeFrameId'],
            'activeAvatarId': item['activeAvatarId'],
            'isVip': item['isVip'] ?? false,
            'isCurrentUser': item['userId'] == authProvider.currentUser?.id,
          };
        } else {
          // Free mode structure
          return {
            'rank': index + 1,
            'name': item['username'] ?? 'User',
            'points': item['score'] ?? 0,
            'accuracy': 0,
            'games': 0,
            'streak': item['highestStreak'] ?? 0,
            'level': 1,
            'avatar': item['avatar'],
            'change': 0,
            'badges': [],
            'bannerUrl': null,
            'activeFrameId': null,
            'activeAvatarId': null,
            'isCurrentUser': item['username'] == authProvider.currentUser?.username,
          };
        }
      }).toList();

      setState(() {
        _topPlayers = mappedData.take(3).toList();
        if (mappedData.length > 3) {
          _allPlayers = mappedData.skip(3).toList();
        } else {
          _allPlayers = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar ranking: $e');
      setState(() => _isLoading = false);
    }
  }

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
            AppLogoText(fontSize: isSmallScreen ? 18 : 20),

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
      body: _isLoading 
          ? const Center(child: LoadingLogo(size: 60))
          : SingleChildScrollView(
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
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey,
                ),
                children: [
                  const TextSpan(text: 'Veja os melhores jogadores do '),
                  AppLogoText.getSpan(fontSize: isSmallScreen ? 14 : 16),
                ],
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
            // Game Mode Filter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: DropdownButton<String>(
                value: _selectedGameMode,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                dropdownColor: const Color(0xFF1E293B),
                underline: Container(),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Modo Padrão')),
                  DropdownMenuItem(value: 'SURVIVAL', child: Text('Modo Sobrevivência')),
                  DropdownMenuItem(value: 'TIME_ATTACK', child: Text('Modo Contra o Tempo')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedGameMode) {
                    setState(() {
                      _selectedGameMode = newValue;
                    });
                    _fetchRanking();
                  }
                },
              ),
            ),
            
            if (_selectedGameMode == 'standard') ...[
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
                      if (newValue != null && newValue != _selectedCategory) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                        _fetchRanking();
                      }
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
                          if (newValue != null && newValue != _selectedCategory) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                            _fetchRanking();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
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
            if (_selectedFilter != filter) {
              setState(() {
                _selectedFilter = filter;
              });
              _fetchRanking();
            }
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
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              Expanded(
                child: _topPlayers.length > 1 ? _buildPodiumPlace(
                  _topPlayers[1], 
                  2, 
                  isSmallScreen ? 120 : 200, 
                  Colors.grey
                ) : const SizedBox(),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              // 1st Place
              Expanded(
                child: _topPlayers.isNotEmpty ? _buildPodiumPlace(
                  _topPlayers[0], 
                  1, 
                  isSmallScreen ? 150 : 250, 
                  const Color(0xFFFFD700)
                ) : const SizedBox(),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              // 3rd Place
              Expanded(
                child: _topPlayers.length > 2 ? _buildPodiumPlace(
                  _topPlayers[2], 
                  3, 
                  isSmallScreen ? 90 : 150, 
                  const Color(0xFFCD7F32)
                ) : const SizedBox(),
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
        
        final storeProvider = context.read<StoreProvider>();
        final bannerUrl = storeProvider.getBannerUrl(player['activeBannerId']);
        final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Player Info
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  children: [
                    if (resolvedBanner != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: resolvedBanner,
                          httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.6),
                          colorBlendMode: BlendMode.darken,
                          placeholder: (context, url) => Container(color: const Color(0xFF1E293B)),
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CosmeticAvatar(
                                radius: place == 1 
                                  ? (isSmallScreen ? 25 : 40) 
                                  : (isSmallScreen ? 18 : 30),
                                avatarUrl: player['avatar']?.toString(),
                                username: player['name'] ?? 'U',
                                activeAvatarId: player['activeAvatarId'],
                                activeFrameId: player['activeFrameId'],
                                isVip: player['isVip'] ?? false,
                              ),
                              if (place <= 3)
                                Positioned(
                                  top: -5,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    '👑',
                                    style: TextStyle(
                                      fontSize: place == 1 
                                          ? (isSmallScreen ? 16 : 24)
                                          : (isSmallScreen ? 12 : 18),
                                    ),
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
                                    '$placeº',
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
                          VipUsernameText(
                            username: player['name'],
                            isVip: player['isVip'] ?? false,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            showBadge: false,
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
                                  color: color.withValues(alpha: 0.2),
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
                  ],
                ),
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
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.4),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '1,247 jogadores ativos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
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
            ...(_showFullRanking ? _allPlayers : _allPlayers.take(47)).map((player) => _buildPlayerRow(player)),
            if (_allPlayers.length > 47)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFullRanking = !_showFullRanking;
                      });
                    },
                    icon: Icon(
                      _showFullRanking ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                    label: Text(
                      _showFullRanking ? 'Mostrar Menos' : 'Mostrar Top ${_allPlayers.length + 3}',
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
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
        final resolvedBanner = ApiConfig.resolveAssetUrl(player['bannerUrl']);
        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: isCurrentUser ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: isCurrentUser ? Border.all(color: const Color(0xFF6366F1)) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                if (resolvedBanner != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: resolvedBanner,
                      httpHeaders: ApiService.token != null
                          ? {'Authorization': 'Bearer ${ApiService.token}'}
                          : null,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.6),
                      colorBlendMode: BlendMode.darken,
                      placeholder: (context, url) => Container(color: const Color(0xFF1E293B)),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 12),
                  child: isSmallScreen
                    ? _buildMobilePlayerRow(player, isCurrentUser)
                    : _buildDesktopPlayerRow(player, isCurrentUser),
                ),
              ],
            ),
          ),
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
            CosmeticAvatar(
              radius: 20,
              avatarUrl: player['avatar']?.toString(),
              username: player['name'] ?? 'U',
              activeAvatarId: player['activeAvatarId'],
              activeFrameId: player['activeFrameId'],
              isVip: player['isVip'] ?? false,
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Info do jogador
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VipUsernameText(
                username: player['name'],
                isVip: player['isVip'] ?? false,
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
              CosmeticAvatar(
                radius: 24,
                avatarUrl: player['avatar']?.toString(),
                username: player['name'] ?? 'U',
                activeAvatarId: player['activeAvatarId'],
                activeFrameId: player['activeFrameId'],
                isVip: player['isVip'] ?? false,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VipUsernameText(
                    username: player['name'],
                    isVip: player['isVip'] ?? false,
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

