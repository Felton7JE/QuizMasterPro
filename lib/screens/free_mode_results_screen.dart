import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button_responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/solo_service.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../widgets/cosmetic_avatar.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';

class FreeModeResultsScreen extends StatefulWidget {
  const FreeModeResultsScreen({super.key});

  @override
  State<FreeModeResultsScreen> createState() => _FreeModeResultsScreenState();
}

class _FreeModeResultsScreenState extends State<FreeModeResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  List<dynamic>? _leaderboard;
  bool _isLoadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLeaderboard();
      Provider.of<AuthProvider>(context, listen: false).refreshUser();
    });
  }
  
  Future<void> _fetchLeaderboard() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String gameMode = args['gameMode']?.toString() ?? 'UNKNOWN';
    if (gameMode == 'UNKNOWN') {
      setState(() => _isLoadingLeaderboard = false);
      return;
    }
    
    try {
      final soloService = Provider.of<SoloService>(context, listen: false);
      final lb = await soloService.getFreeModeLeaderboard(gameMode);
      if (mounted) {
        setState(() {
          _leaderboard = lb.take(5).toList();
          _isLoadingLeaderboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLeaderboard = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAccuracyChart(bool isSmallScreen, double accuracy) {
    Color performanceColor;
    if (accuracy >= 80) {
      performanceColor = const Color(0xFF10B981); // Verde
    } else if (accuracy >= 50) {
      performanceColor = Colors.amber;
    } else {
      performanceColor = Colors.redAccent;
    }

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
            'Desempenho Geral',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Text(
                'Acurácia',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: isSmallScreen ? 8 : 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: accuracy / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: performanceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simpleInfoCard(String text, IconData icon, Color color, bool isSmallScreen, String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: isSmallScreen ? 12 : 14),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(color: color, fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String gameMode = args['gameMode']?.toString() ?? 'UNKNOWN';
    final int score = args['score'] as int? ?? 0;
    final int streak = args['streak'] as int? ?? 0;
    final int correctAnswers = args['correctAnswers'] as int? ?? 0;
    final int totalAnswers = args['totalAnswers'] as int? ?? 0;
    final String reason = args['reason']?.toString() ?? 'Fim de Jogo!';
    final String? nextPlayerName = args['nextPlayerName'] as String?;
    final int? nextPlayerScore = args['nextPlayerScore'] as int?;
    final int coinsEarned = args['coinsEarned'] as int? ?? 0;
    final int xpGained = args['xpGained'] as int? ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    double accuracy = 0.0;
    if (totalAnswers > 0) {
      accuracy = (correctAnswers / totalAnswers) * 100;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16.0 : 32.0,
            vertical: 24.0,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildSoloBanner(isSmallScreen, accuracy, reason, gameMode),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  
                  // Main Results Card (identical to online)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
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
                                '/$totalAnswers',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 32,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Respostas Corretas',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: Colors.grey[300],
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          
                          Container(
                            height: 1,
                            color: const Color(0xFF334155),
                            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          
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
                                '$score',
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
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Accuracy Chart
                  _buildAccuracyChart(isSmallScreen, accuracy),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Secondary stat card
                  if (gameMode == 'SURVIVAL')
                    _simpleInfoCard(
                      '$streak 🔥',
                      Icons.local_fire_department,
                      Colors.orangeAccent,
                      isSmallScreen,
                      'Maior Sequência',
                    ),
                  
                  if (coinsEarned > 0 || xpGained > 0) ...[
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Row(
                      children: [
                        Expanded(
                          child: _simpleInfoCard(
                            '+$coinsEarned',
                            Icons.monetization_on,
                            Colors.amber,
                            isSmallScreen,
                            'Moedas Ganhas',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _simpleInfoCard(
                            '+$xpGained',
                            Icons.star,
                            Colors.purpleAccent,
                            isSmallScreen,
                            'XP Ganho',
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (nextPlayerName != null && nextPlayerScore != null) ...[
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.leaderboard, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Alvo a Abater!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: 'Jogue mais para superar '),
                                TextSpan(
                                  text: nextPlayerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                ),
                                const TextSpan(text: ', que está logo acima com '),
                                TextSpan(
                                  text: '$nextPlayerScore pts',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                ),
                                const TextSpan(text: '! 🔥'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Leaderboard Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Top 5 - $gameMode',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        if (_isLoadingLeaderboard)
                          const Center(child: LoadingLogo(size: 60))
                        else if (_leaderboard == null || _leaderboard!.isEmpty)
                          const Text('Nenhum ranking encontrado', style: TextStyle(color: Colors.white54))
                        else
                          ..._leaderboard!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Text(
                                    '#${index + 1}',
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['username'] ?? 'User',
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '${item['score']} pts',
                                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 24 : 40),
                  
                  // Action Buttons
                  if (isSmallScreen)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Jogar Novamente',
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/quiz-countdown', arguments: {
                                'gameMode': gameMode,
                              });
                            },
                            isPrimary: true,
                            isLarge: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Voltar ao Menu',
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
                            },
                            isPrimary: false,
                            isLarge: true,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Voltar ao Menu',
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
                            },
                            isPrimary: false,
                            isLarge: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: 'Jogar Novamente',
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/quiz-countdown', arguments: {
                                'gameMode': gameMode,
                              });
                            },
                            isPrimary: true,
                            isLarge: true,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoloBanner(bool isSmallScreen, double accuracy, String reason, String gameMode) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    final storeProvider = context.watch<StoreProvider>();
    final bannerUrl = storeProvider.getBannerUrl(user.activeBannerId);
    final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);
    
    Color performanceColor;
    if (accuracy >= 80) {
      performanceColor = const Color(0xFF10B981); // Verde
    } else if (accuracy >= 50) {
      performanceColor = Colors.amber;
    } else {
      performanceColor = Colors.redAccent;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: performanceColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: performanceColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
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
                  color: Colors.black.withValues(alpha: 0.6),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (context, url) => Container(color: const Color(0xFF1E293B)),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 32 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      if (accuracy >= 80)
                        Positioned(
                          top: isSmallScreen ? -35 : -45,
                          child: Icon(
                            Icons.emoji_events,
                            size: isSmallScreen ? 50 : 70,
                            color: Colors.amberAccent,
                          ),
                        )
                      else
                        Positioned(
                          top: isSmallScreen ? -25 : -35,
                          child: Icon(
                            accuracy >= 50 ? Icons.star : Icons.sentiment_satisfied,
                            size: isSmallScreen ? 40 : 50,
                            color: performanceColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason.toUpperCase(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.w900,
                      color: performanceColor,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MODO ${gameMode == "SURVIVAL" ? "SOBREVIVÊNCIA" : "CONTRA O TEMPO"}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.5,
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
}

