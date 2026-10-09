import 'package:quizmaster_pro/widgets/core/loading_logo.dart';
import 'package:flutter/material.dart';

/// Botão flutuante para acionar o chat/frases em jogo com indicador visual de cooldown.
class InGameChatButton extends StatelessWidget {
  final VoidCallback onTap;
  final int cooldownSecondsRemaining;
  final int totalCooldownSeconds;

  const InGameChatButton({
    super.key,
    required this.onTap,
    this.cooldownSecondsRemaining = 0,
    this.totalCooldownSeconds = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isCoolingDown = cooldownSecondsRemaining > 0;
    final progress = isCoolingDown
        ? (cooldownSecondsRemaining / totalCooldownSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCoolingDown ? null : onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCoolingDown
                  ? [
                      const Color(0xFF2D3748),
                      const Color(0xFF1A202C),
                    ]
                  : [
                      const Color(0xFF6C5CE7),
                      const Color(0xFF81ECEC),
                    ],
            ),
            boxShadow: isCoolingDown
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
            border: Border.all(
              color: isCoolingDown
                  ? Colors.white24
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isCoolingDown) ...[
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: LoadingLogo(size: 60),
                ),
                Text(
                  '${cooldownSecondsRemaining}s',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
