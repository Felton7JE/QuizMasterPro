import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Mostra o diálogo "Queres sair?" no estilo visual do app.
/// Devolve `true` se o jogador confirmar a saída, `false` caso contrário.
Future<bool> showExitConfirmDialog(
  BuildContext context, {
  String title = 'Sair do jogo?',
  String message = 'Se saíres agora, perdes o progresso desta partida.',
  String confirmLabel = 'Sair',
  String cancelLabel = 'Continuar',
  IconData icon = Icons.exit_to_app_rounded,
  Color accentColor = AppColors.error,
}) async {
  HapticFeedback.lightImpact();
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.9),
                        AppColors.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Envolve um ecrã e intercepta o botão voltar do Android (e o gesto de voltar),
/// perguntando ao jogador se quer mesmo sair.
///
/// - [onConfirm]: ação ao confirmar. Por omissão faz `Navigator.pop`.
/// - [enabled]: desativa a confirmação (o voltar comporta-se normalmente).
class ExitConfirmScope extends StatelessWidget {
  final Widget child;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onConfirm;
  final bool enabled;

  const ExitConfirmScope({
    super.key,
    required this.child,
    this.title = 'Sair do jogo?',
    this.message = 'Se saíres agora, perdes o progresso desta partida.',
    this.confirmLabel = 'Sair',
    this.cancelLabel = 'Continuar',
    this.icon = Icons.exit_to_app_rounded,
    this.accentColor = AppColors.error,
    this.onConfirm,
    this.enabled = true,
  });

  Future<void> _handleBack(BuildContext context) async {
    final confirmed = await showExitConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      accentColor: accentColor,
    );
    if (!confirmed || !context.mounted) return;
    if (onConfirm != null) {
      onConfirm!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !enabled,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: child,
    );
  }
}
