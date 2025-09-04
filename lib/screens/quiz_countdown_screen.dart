import 'package:flutter/material.dart';
import 'dart:async';

class QuizCountdownScreen extends StatefulWidget {
  const QuizCountdownScreen({super.key});

  @override
  State<QuizCountdownScreen> createState() => _QuizCountdownScreenState();
}

class _QuizCountdownScreenState extends State<QuizCountdownScreen>
    with TickerProviderStateMixin {
  int _countdown = 3;
  Timer? _timer; // NEW: hold reference to cancel on dispose
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Try to align with startsAt if provided via route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final startsAtIso = args != null ? args['startsAt'] as String? : null;
      if (startsAtIso != null) {
        final startsAt = DateTime.tryParse(startsAtIso)?.toLocal();
        if (startsAt != null) {
          final diffSecs = startsAt.difference(DateTime.now()).inSeconds;
          setState(() {
            _countdown = diffSecs.clamp(0, 10);
          });
        }
      }
      _startCountdown();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        _scaleController.reset();
        _scaleController.forward();
        
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _fadeController.forward().then((_) {
          // Navegar para a tela do quiz
          Navigator.pushReplacementNamed(
            context,
            '/quiz-game',
            arguments: ModalRoute.of(context)?.settings.arguments,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone do quiz
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.quiz,
                    size: isSmallScreen ? 64 : 80,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Texto "Prepare-se"
                Text(
                  'Prepare-se!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Texto "O quiz começará em"
                Text(
                  'O quiz começará em',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    color: Colors.grey[300],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 48),
                
                // Contador animado
                if (_countdown > 0)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: isSmallScreen ? 120 : 150,
                      height: isSmallScreen ? 120 : 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCountdownColor(_countdown),
                        boxShadow: [
                          BoxShadow(
                            color: _getCountdownColor(_countdown).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _countdown.toString(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 48 : 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  // "Começando!" quando countdown for 0
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 24 : 32,
                        vertical: isSmallScreen ? 16 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        'Começando!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                
                SizedBox(height: isSmallScreen ? 48 : 64),
                
                // Informações do quiz
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.timer,
                        'Tempo',
                        '15s por pergunta',
                        isSmallScreen,
                      ),
                      _buildInfoItem(
                        Icons.quiz,
                        'Perguntas',
                        '10 questões',
                        isSmallScreen,
                      ),
                      _buildInfoItem(
                        Icons.group,
                        'Modo',
                        'Equipe',
                        isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCountdownColor(int count) {
    switch (count) {
      case 3:
        return const Color(0xFF10B981); // Verde
      case 2:
        return const Color(0xFFF59E0B); // Amarelo
      case 1:
        return const Color(0xFFEF4444); // Vermelho
      default:
        return const Color(0xFF6366F1); // Azul padrão
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isSmallScreen) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: isSmallScreen ? 20 : 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
