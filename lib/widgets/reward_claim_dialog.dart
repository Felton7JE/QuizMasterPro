import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_audio_service.dart';

/// Item de recompensa para exibir no dialog animado.
class RewardItemData {
  final String title;
  final String? subtitle;
  final int coins;
  final int crystals;
  final String? itemName;
  final String? itemIcon; // Emoji ou ícone em texto
  final IconData? mainIcon;
  final Color? mainColor;

  const RewardItemData({
    required this.title,
    this.subtitle,
    this.coins = 0,
    this.crystals = 0,
    this.itemName,
    this.itemIcon,
    this.mainIcon,
    this.mainColor,
  });
}

/// Dialog animado de celebração ao coletar missões, títulos ou prêmios.
class RewardClaimDialog extends StatefulWidget {
  final RewardItemData reward;

  const RewardClaimDialog({
    super.key,
    required this.reward,
  });

  static Future<void> show(BuildContext context, RewardItemData reward) async {
    // Tocar efeito sonoro de recompensa
    final audio = context.read<AppAudioService>();
    audio.playSfxPurchase();
    audio.triggerVibration(heavy: true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => RewardClaimDialog(reward: reward),
    );
  }

  @override
  State<RewardClaimDialog> createState() => _RewardClaimDialogState();
}

class _RewardClaimDialogState extends State<RewardClaimDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;
  late AnimationController _raysAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _raysAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _scaleAnimation = CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.easeIn,
    );

    _mainAnimController.forward();
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _raysAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final primaryColor = reward.mainColor ?? const Color(0xFFFFD700);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Rotação de Raios de Brilho em Fundo
              AnimatedBuilder(
                animation: _raysAnimController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _raysAnimController.value * 2 * math.pi,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.35),
                            primaryColor.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Container Principal do Card
              Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),

                    // Ícone Central do Prêmio
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          reward.mainIcon ?? Icons.military_tech_rounded,
                          color: primaryColor,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Título da Recompensa
                    Text(
                      reward.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    if (reward.subtitle != null && reward.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reward.subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Lista de Prêmios (Moedas, Cristais, Itens)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (reward.coins > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 6),
                                Text(
                                  '+${reward.coins}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (reward.crystals > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💎', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 6),
                                Text(
                                  '+${reward.crystals}',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (reward.itemName != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(reward.itemIcon ?? '🎁', style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 6),
                                Text(
                                  reward.itemName!,
                                  style: const TextStyle(
                                    color: Color(0xFFA855F7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão de Confirmação
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Incrível!',
                          style: TextStyle(
                            fontSize: 17,
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
      ),
    );
  }
}
