import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button_responsive.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../models/game_model.dart';
import '../models/room_model.dart';
import '../providers/websocket_provider.dart';
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
    });
  }

  void _onWebSocketEvent() {
    if (!mounted) return;
    final wsProv = Provider.of<WebSocketProvider>(context, listen: false);
    if (wsProv.returnToLobbyEvent) {
      wsProv.clearReturnToLobbyEvent();
      _navigateBackToLobby();
    }
  }

  void _navigateBackToLobby() {
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isSolo = args?['isSolo'] == true || roomProv.currentRoom?.gameMode == GameMode.CLASSIC;
    final isTeamMode = !isSolo && roomProv.currentRoom?.gameMode == GameMode.TEAM;
    final isDuelMode = roomProv.currentRoom?.gameMode == GameMode.DUEL;
    final isKahootMode = roomProv.currentRoom?.gameMode == GameMode.KAHOOT;

    String route = '/menu';
    if (isSolo) route = '/solo-setup';
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
    if (args != null) {
      _results = args;
      _calculatePerformance();
      _gameId = args['gameId']?.toString();
      _loadFinalLeaderboard();
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
                
                // Título e ícone de troféu
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                        decoration: BoxDecoration(
                          color: _performanceColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _performanceColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _accuracy >= 80 ? Icons.emoji_events : 
                          _accuracy >= 60 ? Icons.star : 
                          _accuracy >= 40 ? Icons.thumb_up : Icons.sentiment_satisfied,
                          size: isSmallScreen ? 64 : 80,
                          color: _performanceColor,
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      
                      Text(
                        'Quiz Finalizado!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      Text(
                        _performance,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w600,
                          color: _performanceColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
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
                  child: _buildMainResultsCard(isSmallScreen),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
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

                if (!isKahootMode) ...[
                  // Final Leaderboard (para modos não-Kahoot)
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
    if (redScore > blueScore) {
      winnerText = 'Vitória da Equipa RED!';
      winnerColor = Colors.redAccent;
    } else if (blueScore > redScore) {
      winnerText = 'Vitória da Equipa BLUE!';
      winnerColor = Colors.blueAccent;
    } else {
      winnerText = 'Empate!';
      winnerColor = Colors.amber;
    }

    double total = (redScore + blueScore).toDouble();
    double redPercentage = total > 0 ? redScore / total : 0.5;

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

    String winnerText;
    Color winnerColor;
    
    if (player2 == null) {
      winnerText = 'Vencedor: ${player1.username}';
      winnerColor = const Color(0xFF10B981);
    } else if (player1.score > player2.score) {
      winnerText = 'Vencedor: ${player1.username}!';
      winnerColor = const Color(0xFF10B981);
    } else if (player2.score > player1.score) {
      winnerText = 'Vencedor: ${player2.username}!';
      winnerColor = const Color(0xFF10B981);
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
                      Text(player1.username, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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
                      Text(player2.username, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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
            child: Text(
              isPlayerRow ? 'Você' : entry.username,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildMainResultsCard(bool isSmallScreen) {
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
                size: isSmallScreen ? 24 : 28,
              ),
              SizedBox(width: 8),
              Text(
                '$totalPoints',
                style: TextStyle(
                  fontSize: isSmallScreen ? 32 : 40,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'pontos',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.grey[300],
                ),
              ),
            ],
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
    if (isSmallScreen) {
      // Layout vertical para telas pequenas
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Jogar Novamente',
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final roomProv = Provider.of<RoomProvider>(context, listen: false);
                final isHost = roomProv.isPlayerHost(auth.currentUser?.id ?? '');
                
                if (isHost && !isSolo) {
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
              text: 'Jogar Novamente',
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final roomProv = Provider.of<RoomProvider>(context, listen: false);
                final isHost = roomProv.isPlayerHost(auth.currentUser?.id ?? '');
                
                if (isHost && !isSolo) {
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

