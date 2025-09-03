import 'package:flutter/material.dart';
import '../widgets/custom_button_responsive.dart';

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Recebe os resultados
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _results = args;
      _calculatePerformance();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Botões de ação
                _buildActionButtons(isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildActionButtons(bool isSmallScreen) {
    if (isSmallScreen) {
      // Layout vertical para telas pequenas
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Jogar Novamente',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/menu',
                  (route) => false,
                );
              },
              isPrimary: true,
              isLarge: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Ver Detalhes',
              onPressed: () {
                _showDetailsDialog(context);
              },
              isPrimary: false,
              isLarge: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
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
        ],
      );
    } else {
      // Layout horizontal para telas maiores
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Ver Detalhes',
              onPressed: () {
                _showDetailsDialog(context);
              },
              isPrimary: false,
              isLarge: true,
            ),
          ),
          const SizedBox(width: 16),
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
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/menu',
                  (route) => false,
                );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Detalhes do Quiz',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de Perguntas: ${_results['totalQuestions'] ?? 0}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Respostas Corretas: ${_results['correctAnswers'] ?? 0}',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
            Text(
              'Pontos Totais: ${_results['totalPoints'] ?? 0}',
              style: const TextStyle(color: Color(0xFF6366F1)),
            ),
            Text(
              'Maior Sequência: ${_results['bestStreak'] ?? 0}',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
            Text(
              'Acurácia: ${_accuracy.toStringAsFixed(1)}%',
              style: TextStyle(color: _performanceColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
