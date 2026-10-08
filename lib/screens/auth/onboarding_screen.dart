import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/core/app_logo_text.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Bem-vindo ao',
      'subtitle': 'QuizMaster Pro! 🚀',
      'description': 'O desafio definitivo de conhecimento! Testa a tua mente, completa missões, sobe de escalão e prova que és o melhor.',
      'icon': Icons.emoji_events_rounded,
      'color': const Color(0xFFFFD700),
    },
    {
      'title': 'Aventura a Solo e',
      'subtitle': 'Estudo 🧠',
      'description': 'Avança no mapa enfrentando bosses na Aventura Solo. Queres focar-te na aprendizagem? Gera quizzes automáticos no Modo Estudo com IA ou relaxa no Modo Livre!',
      'icon': Icons.map_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Modos Online e',
      'subtitle': 'Multijogador ⚔️',
      'description': 'Mostra quem manda! Cria salas para um Duelo 1v1, junta a tua Equipa (2-8 jogadores) ou participa de sessões massivas no Estilo Kahoot com até 20 jogadores!',
      'icon': Icons.public_rounded,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Energia e',
      'subtitle': 'Passe VIP 🌟',
      'description': 'Fica de olho na tua Energia (⚡) para continuares a jogar. Completa o Passe VIP sazonal para desbloquear recompensas e cosméticos incríveis.',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Loja de Cosméticos',
      'subtitle': '🪙 vs 🔮',
      'description': 'Visita a Loja! Usa as Moedas (🪙) que ganhaste para personalizar o teu Avatar. Para itens Supremos e Molduras Raras, coleciona os raros Cristais (🔮)!',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFFA855F7),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/menu');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Pular',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glassmorphism Icon Container
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: slide['color'].withValues(alpha: 0.15),
                            border: Border.all(
                              color: slide['color'].withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: slide['color'].withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              slide['icon'],
                              size: 80,
                              color: slide['color'],
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        
                        // Title
                        Text(
                          slide['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        if (index == 0)
                           const AppLogoText(fontSize: 32)
                        else
                          Text(
                            slide['subtitle'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              color: slide['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Description
                        Text(
                          slide['description'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Footer (Indicators and Next Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _slides[_currentPage]['color']
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next Button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _slides[_currentPage]['color'],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _slides[_currentPage]['color'].withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Começar a Jogar!' : 'Avançar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
