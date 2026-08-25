import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button_responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../models/game_model.dart';
import '../models/room_model.dart';
import '../providers/websocket_provider.dart';
import '../providers/season_provider.dart';
import '../providers/store_provider.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/vip_badge_widget.dart';
import 'team_details_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic> _results = {};
  double _accuracy = 0.0;
  String _performance = '';
  Color _performanceColor = Colors.white;
  bool _loadingLeaderboard = true;
  bool _leaderboardError = false;
  List<LeaderboardEntry> _finalLeaderboard = [];
  LeaderboardEntry? _myEntry;
  String? _gameId;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Iniciar animações
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
      wsProv.addListener(_onWebSocketEvent);
      final storeProv = Provider.of<StoreProvider>(context, listen: false);
      storeProv.loadAllData();
    });
  }

  bool _isWaitingRematchResponse = false;
  bool _isShowingRematchDialog = false;

  void _onWebSocketEvent() {
    if (!mounted) return;
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    
    if (wsProv.returnToLobbyEvent) {
      wsProv.clearReturnToLobbyEvent();
      // Se estivesse com diálogo de revanche aberto, fecha
      if (_isShowingRematchDialog) {
        Navigator.of(context).pop();
        _isShowingRematchDialog = false;
      }
      _navigateBackToLobby();
    }
    
    if (wsProv.rematchRequesterName != null) {
      final requesterName = wsProv.rematchRequesterName!;
      wsProv.clearRematchRequestEvent();
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (requesterName != auth.currentUser?.username) {
        _showRematchDialog(requesterName);
      }
    }
  }

  void _showRematchDialog(String requesterName) {
    if (_isShowingRematchDialog) return;
    _isShowingRematchDialog = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pedido de Revanche'),
        content: Text('O jogador $requesterName marcou uma revanche! Deseja jogar novamente?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isShowingRematchDialog = false;
            },
            child: const Text('Recusar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _isShowingRematchDialog = false;
              
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final roomProv = Provider.of<RoomProvider>(context, listen: false);
              // Como aceitei, aciono o playAgain para todos voltarem pro lobby
              await roomProv.playAgain(auth.currentUser?.id ?? '');
            },
            child: const Text('Aceitar'),
          ),
        ],
      ),
    ).then((_) {
      _isShowingRematchDialog = false;
    });
  }

  void _navigateBackToLobby() {
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isSeason = args?['isSeason'] == true;
    final isSolo = args?['isSolo'] == true || roomProv.currentRoom?.gameMode == GameMode.CLASSIC;
    final isTeamMode = !isSolo && roomProv.currentRoom?.gameMode == GameMode.TEAM;
    final isDuelMode = roomProv.currentRoom?.gameMode == GameMode.DUEL;
    final isKahootMode = roomProv.currentRoom?.gameMode == GameMode.KAHOOT;

    String route = '/menu';
    if (isSeason) route = '/season-map';
    else if (isSolo) route = '/solo-map';
    else if (isTeamMode) route = '/team-lobby'; // Corrigido de /menu para /team-lobby se houver
    else if (isDuelMode) route = '/duel-lobby';
    else if (isKahootMode) route = '/kahoot-lobby';

    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
    );
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Recebe os resultados
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _gameId == null) {
      _results = args;
      _calculatePerformance();
      _gameId = args['gameId']?.toString();
      _loadFinalLeaderboard();
      
      // Atualizar o perfil do utilizador para refletir moedas, xp e elo ganhos
      Provider.of<AuthProvider>(context, listen: false).refreshUser();
      
      // Conceder PTs da temporada se vencer a partida
      if (args['isSeason'] == true && _accuracy >= 50.0) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final seasonProv = Provider.of<SeasonProvider>(context, listen: false);
        final levelNumber = args['levelNumber'] as int?;
        final currentSeasonLevel = seasonProv.seasonData?.currentLevel ?? 1;

        // Se for fase já concluída anteriormente: +10 pts de treino. Se for a fase atual: +100 pts (First Clear).
        final isReplay = (levelNumber != null && levelNumber < currentSeasonLevel);
        final pointsToAdd = isReplay ? 10 : 100;

        final userId = auth.currentUser?.id;
        if (userId != null) {
          seasonProv.addPoints(userId, pointsToAdd);
        }
      }
    }
  }

  Future<void> _loadFinalLeaderboard() async {
    if (_gameId == null) {
      setState(() { _loadingLeaderboard = false; });
      return;
    }
    try {
      final gp = Provider.of<GameProvider>(context, listen: false);
      await gp.loadFinalLeaderboard(_gameId!);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id;
      final list = gp.leaderboard;
      LeaderboardEntry? me;
      if (userId != null) {
        me = list.where((e) => e.userId == userId).isNotEmpty
            ? list.firstWhere((e) => e.userId == userId)
            : null;
      }
      setState(() {
        _finalLeaderboard = list;
        _myEntry = me;
        if (me != null) {
          _results['coinsEarned'] = me.coinsEarned;
          _results['xpEarned'] = me.xpEarned;
        }
        _loadingLeaderboard = false;
      });
    } catch (e) {
      setState(() { _leaderboardError = true; _loadingLeaderboard = false; });
    }
  }

  void _calculatePerformance() {
    final correctAnswers = _results['correctAnswers'] ?? 0;
    final totalQuestions = _results['totalQuestions'] ?? 1;
    _accuracy = (correctAnswers / totalQuestions) * 100;
    
    if (_accuracy >= 80) {
      _performance = 'Excelente!';
      _performanceColor = const Color(0xFF10B981);
    } else if (_accuracy >= 60) {
      _performance = 'Muito Bom!';
      _performanceColor = const Color(0xFF6366F1);
    } else if (_accuracy >= 40) {
      _performance = 'Bom!';
      _performanceColor = const Color(0xFFF59E0B);
    } else {
      _performance = 'Continue Tentando!';
      _performanceColor = const Color(0xFFEF4444);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    wsProv.removeListener(_onWebSocketEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isSeason = args?['isSeason'] == true;
    final isSolo = args?['isSolo'] == true || roomProv.currentRoom?.gameMode == GameMode.CLASSIC;
    final isTeamMode = !isSolo && roomProv.currentRoom?.gameMode == GameMode.TEAM;
    final isDuelMode = roomProv.currentRoom?.gameMode == GameMode.DUEL;
    final isKahootMode = roomProv.currentRoom?.gameMode == GameMode.KAHOOT;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),
                
                // Título e banner de resultado/vencedor
                if (isDuelMode || isKahootMode || (!isSolo && !isSeason && _finalLeaderboard.isNotEmpty)) ...[
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildWinnerBanner(isSmallScreen),
                  ),
                ] else ...[
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildSoloBanner(isSmallScreen),
                  ),
                ],
                
                SizedBox(height: isSmallScreen ? 32 : 48),

                if (isTeamMode) ...[
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildTeamResultsCard(isSmallScreen),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
                
                if (isDuelMode) ...[
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildDuelResultsCard(isSmallScreen),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
                
                if (isKahootMode) ...[
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildFinalLeaderboardSection(isSmallScreen),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
                
                // Card de resultados principais
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildMainResultsCard(isSmallScreen, args),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Card de Boss
                if (_results['isBossLevel'] == true) ...[
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildBossResultSection(isSmallScreen),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
                
                // Estatísticas detalhadas
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildDetailedStats(isSmallScreen),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Gráfico de acurácia
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildAccuracyChart(isSmallScreen),
                ),

                SizedBox(height: isSmallScreen ? 24 : 32),

                if (!isKahootMode && !isSolo && !isDuelMode) ...[
                  // Final Leaderboard (apenas para Team)
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildFinalLeaderboardSection(isSmallScreen),
                  ),
                ],
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Botões de ação
                _buildActionButtons(isSmallScreen, isTeamMode, isSolo, isDuelMode, isKahootMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerBanner(bool isSmallScreen) {
    if (_loadingLeaderboard || _leaderboardError || _finalLeaderboard.isEmpty) {
      return const SizedBox.shrink();
    }

    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final storeProvider = context.watch<StoreProvider>();

    final player1 = _finalLeaderboard[0];
    final player2 = _finalLeaderboard.length > 1 ? _finalLeaderboard[1] : null;

    LeaderboardEntry? winner;
    if (player2 == null || player1.score > player2.score) {
      winner = player1;
    } else if (player2.score > player1.score) {
      winner = player2;
    }

    if (winner == null) {
      // Empate
      final bannerUrl = storeProvider.getBannerUrl(currentUser?.activeBannerId);
      final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              if (resolvedBanner != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: resolvedBanner,
                    httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.55),
                    colorBlendMode: BlendMode.darken,
                    placeholder: (context, url) => Container(color: const Color(0xFF1E293B)),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 28 : 40, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'EMPATE!',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CosmeticAvatar(
                          radius: isSmallScreen ? 36 : 46,
                          avatarUrl: player1.avatar,
                          username: player1.username,
                          activeAvatarId: player1.activeAvatarId,
                          activeFrameId: player1.activeFrameId,
                          isVip: player1.isVip,
                        ),
                        const SizedBox(width: 20),
                        if (player2 != null)
                          CosmeticAvatar(
                            radius: isSmallScreen ? 36 : 46,
                            avatarUrl: player2.avatar,
                            username: player2.username,
                            activeAvatarId: player2.activeAvatarId,
                            activeFrameId: player2.activeFrameId,
                            isVip: player2.isVip,
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Identifica se o jogador logado é o vencedor
    final isWinner = currentUser != null &&
        (winner.userId == currentUser.id ||
         winner.username.trim().toLowerCase() == currentUser.username.trim().toLowerCase());

    // Obter banner do vencedor
    final bannerId = winner.activeBannerId ?? (isWinner ? currentUser.activeBannerId : null);
    final bannerUrl = storeProvider.getBannerUrl(bannerId) ??
        (isWinner ? storeProvider.getBannerUrl(currentUser.activeBannerId) : null);
    final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);

    const statusColor = Color(0xFF10B981);
    final mainStatusText = isWinner ? 'VOCÊ É O VENCEDOR!' : 'VENCEDOR';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (resolvedBanner != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: resolvedBanner,
                  httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.55),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (context, url) => Container(color: const Color(0xFF1E293B)),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 32 : 48, horizontal: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      CosmeticAvatar(
                        radius: isSmallScreen ? 50 : 70,
                        avatarUrl: winner.avatar,
                        username: winner.username,
                        activeAvatarId: winner.activeAvatarId,
                        activeFrameId: winner.activeFrameId,
                        isVip: winner.isVip,
                      ),
                      // Coroa do vencedor
                      Positioned(
                        top: isSmallScreen ? -35 : -45,
                        child: Icon(
                          Icons.emoji_events,
                          size: isSmallScreen ? 50 : 70,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  VipUsernameText(
                    username: winner.username,
                    isVip: winner.isVip,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.6), width: 1.5),
                    ),
                    child: Text(
                      mainStatusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF34D399),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (isWinner) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Parabéns pela grande vitória!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoloBanner(bool isSmallScreen) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    final storeProvider = context.watch<StoreProvider>();
    final bannerUrl = storeProvider.getBannerUrl(user.activeBannerId);
    final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);
    
    final isSuccess = _accuracy >= 50.0;
    final color = isSuccess ? _performanceColor : const Color(0xFFEF4444);
    final mainStatusText = isSuccess ? 'VOCÊ É O VENCEDOR!' : 'OPS! ATÉ A PRÓXIMA...';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (resolvedBanner != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: resolvedBanner,
                  httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.55),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (context, url) => Container(color: const Color(0xFF1E293B)),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 32 : 48, horizontal: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      CosmeticAvatar(
                        radius: isSmallScreen ? 50 : 70,
                        avatarUrl: user.avatar,
                        username: user.username,
                        activeAvatarId: user.activeAvatarId,
                        activeFrameId: user.activeFrameId,
                        isVip: user.isVip,
                      ),
                      if (_accuracy >= 80)
                        Positioned(
                          top: isSmallScreen ? -35 : -45,
                          child: Icon(
                            Icons.emoji_events,
                            size: isSmallScreen ? 50 : 70,
                            color: Colors.amberAccent,
                          ),
                        )
                      else if (isSuccess)
                        Positioned(
                          top: isSmallScreen ? -25 : -35,
                          child: Icon(
                            _accuracy >= 60 ? Icons.star : Icons.thumb_up,
                            size: isSmallScreen ? 40 : 50,
                            color: color,
                          ),
                        )
                      else
                        Positioned(
                          top: isSmallScreen ? -25 : -35,
                          child: Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            size: isSmallScreen ? 40 : 50,
                            color: const Color(0xFFF87171),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  VipUsernameText(
                    username: user.username,
                    isVip: user.isVip,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.6), width: 1.5),
                    ),
                    child: Text(
                      mainStatusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        color: isSuccess ? (color == const Color(0xFF10B981) ? const Color(0xFF34D399) : color) : const Color(0xFFFCA5A5),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _performance,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTeamResultsCard(bool isSmallScreen) {
    if (_loadingLeaderboard) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
        decoration: _cardDecoration(),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    
    if (_leaderboardError || _finalLeaderboard.isEmpty) {
      return const SizedBox.shrink();
    }

    int redScore = 0;
    int blueScore = 0;
    for (var entry in _finalLeaderboard) {
      if (entry.team == TeamColor.RED) {
        redScore += entry.score;
      } else if (entry.team == TeamColor.BLUE) {
        blueScore += entry.score;
      }
    }

    if (redScore == 0 && blueScore == 0) {
      return const SizedBox.shrink();
    }

    String winnerText;
    Color winnerColor;
    TeamColor? winningTeam;
    if (redScore > blueScore) {
      winnerText = 'Vitória da Equipa RED!';
      winnerColor = Colors.redAccent;
      winningTeam = TeamColor.RED;
    } else if (blueScore > redScore) {
      winnerText = 'Vitória da Equipa BLUE!';
      winnerColor = Colors.blueAccent;
      winningTeam = TeamColor.BLUE;
    } else {
      winnerText = 'Empate!';
      winnerColor = Colors.amber;
      winningTeam = null;
    }

    double total = (redScore + blueScore).toDouble();
    double redPercentage = total > 0 ? redScore / total : 0.5;

    final winningMembers = winningTeam != null 
        ? _finalLeaderboard.where((e) => e.team == winningTeam).toList()
        : <LeaderboardEntry>[];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winnerColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: winnerColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: winnerColor, size: isSmallScreen ? 28 : 36),
              const SizedBox(width: 8),
              Text(
                winnerText,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: winnerColor,
                ),
              ),
            ],
          ),
          
          if (winningMembers.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: winningMembers.map((member) {
                return Column(
                  children: [
                    CosmeticAvatar(
                      radius: isSmallScreen ? 25 : 35,
                      avatarUrl: member.avatar,
                      username: member.username,
                      activeAvatarId: member.activeAvatarId,
                      activeFrameId: member.activeFrameId,
                      isVip: member.isVip,
                    ),
                    const SizedBox(height: 8),
                    VipUsernameText(
                      username: member.username,
                      isVip: member.isVip,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  ],
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$redScore PTS', style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('VS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              Text('$blueScore PTS', style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  Expanded(
                    flex: (redPercentage * 100).toInt() == 0 ? 1 : (redPercentage * 100).toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - redPercentage) * 100).toInt() == 0 ? 1 : ((1 - redPercentage) * 100).toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuelResultsCard(bool isSmallScreen) {
    if (_loadingLeaderboard) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
        decoration: _cardDecoration(),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    
    if (_leaderboardError || _finalLeaderboard.isEmpty) {
      return const SizedBox.shrink();
    }

    // Expecting 2 players for DUEL
    final player1 = _finalLeaderboard.isNotEmpty ? _finalLeaderboard[0] : null;
    final player2 = _finalLeaderboard.length > 1 ? _finalLeaderboard[1] : null;

    if (player1 == null) return const SizedBox.shrink();

    final currentUsername = Provider.of<AuthProvider>(context, listen: false).currentUser?.username;
    String winnerText;
    Color winnerColor;
    
    if (player2 == null) {
      final isMe = currentUsername != null && currentUsername == player1.username;
      winnerText = isMe ? 'Você é o Vencedor!' : 'Vencedor: ${player1.username}';
      winnerColor = const Color(0xFF10B981);
    } else if (player1.score > player2.score) {
      if (currentUsername != null && currentUsername == player1.username) {
        winnerText = 'Você é o Vencedor!';
        winnerColor = const Color(0xFF10B981);
      } else if (currentUsername != null && currentUsername == player2.username) {
        winnerText = 'Ops! Até à próxima...';
        winnerColor = const Color(0xFFEF4444);
      } else {
        winnerText = 'Vencedor: ${player1.username}!';
        winnerColor = const Color(0xFF10B981);
      }
    } else if (player2.score > player1.score) {
      if (currentUsername != null && currentUsername == player2.username) {
        winnerText = 'Você é o Vencedor!';
        winnerColor = const Color(0xFF10B981);
      } else if (currentUsername != null && currentUsername == player1.username) {
        winnerText = 'Ops! Até à próxima...';
        winnerColor = const Color(0xFFEF4444);
      } else {
        winnerText = 'Vencedor: ${player2.username}!';
        winnerColor = const Color(0xFF10B981);
      }
    } else {
      winnerText = 'Empate!';
      winnerColor = Colors.amber;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winnerColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: winnerColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: winnerColor, size: isSmallScreen ? 28 : 36),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  winnerText,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: winnerColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (player2 != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      VipUsernameText(
                        username: player1.username,
                        isVip: player1.isVip,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('${player1.score} PTS', style: TextStyle(color: player1.score >= player2.score ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('VS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      VipUsernameText(
                        username: player2.username,
                        isVip: player2.isVip,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('${player2.score} PTS', style: TextStyle(color: player2.score >= player1.score ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFinalLeaderboardSection(bool isSmallScreen) {
    if (_loadingLeaderboard) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: _cardDecoration(),
        child: Row(
          children: const [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
            SizedBox(width: 12),
            Text('Carregando ranking final...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    if (_leaderboardError) {
      return _simpleInfoCard('Não foi possível carregar o ranking final.', Icons.error_outline, const Color(0xFFEF4444), isSmallScreen);
    }
    if (_finalLeaderboard.isEmpty) {
      return _simpleInfoCard('Ranking indisponível.', Icons.info_outline, const Color(0xFF6366F1), isSmallScreen);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.leaderboard, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text('Ranking Final', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ..._finalLeaderboard.map((e) => _buildLeaderboardRow(e, isSmallScreen, highlight: _myEntry != null && _myEntry!.userId == e.userId)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, bool isSmallScreen, {bool highlight = false, bool isPlayerRow = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? const Color(0xFF6366F1) : const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Text('#${entry.position}', style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: isPlayerRow
                ? Text(
                    'Você',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w500),
                  )
                : VipUsernameText(
                    username: entry.username,
                    isVip: entry.isVip,
                    style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w500),
                  ),
          ),
          const SizedBox(width: 10),
          Text('${entry.score} pts', style: TextStyle(color: const Color(0xFF10B981), fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text('${entry.correctAnswers}/${entry.totalAnswers}', style: TextStyle(color: Colors.grey, fontSize: isSmallScreen ? 11 : 12)),
        ],
      ),
    );
  }

  Widget _simpleInfoCard(String text, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 12 : 14)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      );

  Widget _buildMainResultsCard(bool isSmallScreen, Map<String, dynamic>? args) {
    final correctAnswers = _results['correctAnswers'] ?? 0;
    final totalQuestions = _results['totalQuestions'] ?? 1;
    final totalPoints = _results['totalPoints'] ?? 0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Desempenho Individual',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          // Pontuação principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$correctAnswers',
                style: TextStyle(
                  fontSize: isSmallScreen ? 48 : 64,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
              Text(
                '/$totalQuestions',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Respostas Corretas',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: Colors.grey[300],
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Linha divisória
          Container(
            height: 1,
            color: const Color(0xFF334155),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Pontos totais
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.stars,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 24 : 32,
              ),
              const SizedBox(width: 8),
              Text(
                '$totalPoints',
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pts',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          
          if (args?['isSeason'] == true) ...[
            SizedBox(height: isSmallScreen ? 16 : 24),
            Builder(
              builder: (ctx) {
                final seasonProv = Provider.of<SeasonProvider>(ctx, listen: false);
                final levelNumber = args?['levelNumber'] as int?;
                final currentSeasonLevel = seasonProv.seasonData?.currentLevel ?? 1;
                final isReplay = (levelNumber != null && levelNumber < currentSeasonLevel);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        isReplay
                            ? '+10 PTS DA TEMPORADA (TREINO)'
                            : '+100 PTS DA TEMPORADA!',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          
          Builder(
            builder: (ctx) {
              final roomProv = Provider.of<RoomProvider>(ctx, listen: false);
              final isDuelMode = roomProv.currentRoom?.gameMode == GameMode.DUEL;
              final entryFee = roomProv.currentRoom?.entryFee ?? 0;
              final coinsEarned = _results['coinsEarned'] ?? 0;
              final xpEarned = _results['xpEarned'] ?? 0;
              
              final hasCoinReward = coinsEarned > 0;
              final hasCoinLoss = isDuelMode && coinsEarned == 0 && entryFee > 0;
              
              if (hasCoinReward || hasCoinLoss || xpEarned > 0) {
                return Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Container(
                      height: 1,
                      color: const Color(0xFF334155),
                      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (hasCoinReward)
                          Column(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                '+$coinsEarned',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Moedas',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          )
                        else if (hasCoinLoss)
                          Column(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.redAccent, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                '-$entryFee',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Moedas',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        if (xpEarned > 0)
                          Column(
                            children: [
                              const Icon(Icons.star, color: Colors.blueAccent, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                '+$xpEarned',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'XP',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBossResultSection(bool isSmallScreen) {
    final bool victory = _results['victory'] == true;
    final int livesRemaining = _results['bossLivesRemaining'] ?? 0;
    final bool checkpointReverted = _results['checkpointReverted'] == true;
    final int newLevel = _results['newCurrentLevel'] ?? 1;

    if (victory) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
        ),
        child: Column(
          children: const [
            Icon(Icons.military_tech, color: Color(0xFF10B981), size: 48),
            SizedBox(height: 8),
            Text('BOSS DERROTADO!', style: TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Ganhaste recompensas especiais!', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }

    // Derrota
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent, width: checkpointReverted ? 3 : 1),
      ),
      child: Column(
        children: [
          Icon(checkpointReverted ? Icons.warning_amber_rounded : Icons.heart_broken, color: Colors.redAccent, size: 48),
          const SizedBox(height: 8),
          Text(
            checkpointReverted ? 'GAME OVER NO BOSS!' : 'DERROTA!',
            style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (checkpointReverted) ...[
            Text('Perdeste todas as vidas. Retrocedeste para o Nível $newLevel', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ] else ...[
            Text('Vidas restantes: $livesRemaining', style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < livesRemaining ? Icons.favorite : Icons.favorite_border,
                  color: index < livesRemaining ? Colors.redAccent : Colors.white24,
                  size: 32,
                );
              }),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/store');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            icon: const Icon(Icons.store, color: Colors.black87),
            label: const Text('Comprar Vida na Loja', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(bool isSmallScreen) {
    final bestStreak = _results['bestStreak'] ?? 0;
    final totalQuestions = _results['totalQuestions'] ?? 1;
    final correctAnswers = _results['correctAnswers'] ?? 0;
    final wrongAnswers = totalQuestions - correctAnswers;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas Detalhadas',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          if (isSmallScreen) ...[
            // Layout vertical para telas pequenas
            _buildStatItem('Acurácia', '${_accuracy.toStringAsFixed(1)}%', const Color(0xFF10B981), isSmallScreen),
            SizedBox(height: 12),
            _buildStatItem('Maior Sequência', '$bestStreak', const Color(0xFFEF4444), isSmallScreen),
            SizedBox(height: 12),
            _buildStatItem('Respostas Erradas', '$wrongAnswers', const Color(0xFFF59E0B), isSmallScreen),
          ] else ...[
            // Layout em grade para telas maiores
            Row(
              children: [
                Expanded(child: _buildStatItem('Acurácia', '${_accuracy.toStringAsFixed(1)}%', const Color(0xFF10B981), isSmallScreen)),
                SizedBox(width: 16),
                Expanded(child: _buildStatItem('Maior Sequência', '$bestStreak', const Color(0xFFEF4444), isSmallScreen)),
                SizedBox(width: 16),
                Expanded(child: _buildStatItem('Respostas Erradas', '$wrongAnswers', const Color(0xFFF59E0B), isSmallScreen)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 8 : 12,
            height: isSmallScreen ? 8 : 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChart(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desempenho',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Barra de progresso da acurácia
          Row(
            children: [
              Text(
                'Acurácia',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[300],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: isSmallScreen ? 8 : 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _accuracy / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _performanceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${_accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: _performanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen, bool isTeamMode, bool isSolo, bool isDuelMode, bool isKahootMode) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isProgressionMode = args?['isSolo'] == true;

    if (isSmallScreen) {
      // Layout vertical para telas pequenas
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: _isWaitingRematchResponse ? 'Aguardando...' : (isProgressionMode ? 'Próximo Nível' : 'Jogar Novamente'),
              onPressed: _isWaitingRematchResponse ? () {} : () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final roomProv = Provider.of<RoomProvider>(context, listen: false);
                final isHost = roomProv.isPlayerHost(auth.currentUser?.id ?? '');
                
                if (isDuelMode) {
                  setState(() => _isWaitingRematchResponse = true);
                  await roomProv.sendRematchRequest(auth.currentUser?.id ?? '');
                } else if (isHost && !isSolo) {
                  // O backend vai emitir RETURN_TO_LOBBY para todos
                  await roomProv.playAgain(auth.currentUser?.id ?? '');
                } else {
                  // Se for solo, ou se for jogador normal (fallback), navega localmente
                  _navigateBackToLobby();
                }
              },
              isPrimary: true,
              isLarge: true,
            ),
          ),
          if (isTeamMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Detalhes das Equipas',
                onPressed: () {
                  _showDetailsDialog(context);
                },
                isPrimary: false,
                isLarge: true,
              ),
            ),
          ],
          if (isKahootMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Estatísticas',
                onPressed: () {
                  _showKahootStatsDialog(context, isSmallScreen);
                },
                isPrimary: false,
                isLarge: true,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Voltar ao Menu',
              onPressed: () {
                final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
                final roomProv = Provider.of<RoomProvider>(context, listen: false);
                wsProv.disconnect();
                roomProv.clearRoom();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/menu',
                  (route) => false,
                );
              },
              isPrimary: false,
              isLarge: true,
            ),
          ),
        ],
      );
    } else {
      // Layout horizontal para telas maiores
      return Row(
        children: [
          if (isTeamMode) ...[
            Expanded(
              child: CustomButton(
                text: 'Detalhes Equipas',
                onPressed: () {
                  _showDetailsDialog(context);
                },
                isPrimary: false,
                isLarge: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (isKahootMode) ...[
            Expanded(
              child: CustomButton(
                text: 'Estatísticas',
                onPressed: () {
                  _showKahootStatsDialog(context, isSmallScreen);
                },
                isPrimary: false,
                isLarge: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: CustomButton(
              text: 'Voltar ao Menu',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/menu',
                  (route) => false,
                );
              },
              isPrimary: false,
              isLarge: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _isWaitingRematchResponse ? 'Aguardando...' : (isProgressionMode ? 'Próximo Nível' : 'Jogar Novamente'),
              onPressed: _isWaitingRematchResponse ? () {} : () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final roomProv = Provider.of<RoomProvider>(context, listen: false);
                final isHost = roomProv.isPlayerHost(auth.currentUser?.id ?? '');
                
                if (isDuelMode) {
                  setState(() => _isWaitingRematchResponse = true);
                  await roomProv.sendRematchRequest(auth.currentUser?.id ?? '');
                } else if (isHost && !isSolo) {
                  // O backend vai emitir RETURN_TO_LOBBY para todos
                  await roomProv.playAgain(auth.currentUser?.id ?? '');
                } else {
                  _navigateBackToLobby();
                }
              },
              isPrimary: true,
              isLarge: true,
            ),
          ),
        ],
      );
    }
  }

  void _showDetailsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamDetailsScreen(leaderboard: _finalLeaderboard),
      ),
    );
  }

  void _showKahootStatsDialog(BuildContext context, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'As Tuas Estatísticas',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailedStats(isSmallScreen),
                  const SizedBox(height: 16),
                  _buildAccuracyChart(isSmallScreen),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

