import 'dart:async';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import 'cosmetic_avatar.dart';
import 'vip_badge_widget.dart';

/// Widget de sobreposição que exibe bolhas de chat/frases animadas durante a partida.
class InGameChatOverlay extends StatefulWidget {
  final InGameChatMessageEvent? latestMessage;
  final VoidCallback? onDismiss;

  const InGameChatOverlay({
    super.key,
    this.latestMessage,
    this.onDismiss,
  });

  @override
  State<InGameChatOverlay> createState() => _InGameChatOverlayState();
}

class _InGameChatOverlayState extends State<InGameChatOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;
  InGameChatMessageEvent? _currentMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    if (widget.latestMessage != null) {
      _showMessage(widget.latestMessage!);
    }
  }

  @override
  void didUpdateWidget(covariant InGameChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latestMessage != null &&
        widget.latestMessage != oldWidget.latestMessage) {
      _showMessage(widget.latestMessage!);
    }
  }

  void _showMessage(InGameChatMessageEvent message) {
    _autoDismissTimer?.cancel();
    setState(() {
      _currentMessage = message;
    });

    _animController.forward(from: 0.0);

    _autoDismissTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentMessage = null;
            });
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMessage == null) {
      return const SizedBox.shrink();
    }

    final isVip = _currentMessage!.isVip;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: () {
                _autoDismissTimer?.cancel();
                _animController.reverse().then((_) {
                  if (mounted) {
                    setState(() => _currentMessage = null);
                    widget.onDismiss?.call();
                  }
                });
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isVip
                        ? [
                            const Color(0xFF2E1A47).withValues(alpha: 0.96),
                            const Color(0xFF1E1035).withValues(alpha: 0.98),
                          ]
                        : [
                            const Color(0xFF1A2238).withValues(alpha: 0.95),
                            const Color(0xFF111827).withValues(alpha: 0.98),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVip
                        ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                        : const Color(0xFF6C5CE7).withValues(alpha: 0.6),
                    width: isVip ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isVip
                          ? const Color(0xFFFFD700).withValues(alpha: 0.35)
                          : const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    CosmeticAvatar(
                      avatarUrl: _currentMessage!.avatar,
                      username: _currentMessage!.username,
                      activeFrameId: _currentMessage!.activeFrameId,
                      radius: 20,
                      isVip: isVip,
                    ),
                    const SizedBox(width: 12),
                    // Conteúdo da mensagem
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VipUsernameText(
                            username: _currentMessage!.username,
                            isVip: isVip,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isVip
                                  ? const Color(0xFFFFE082)
                                  : const Color(0xFF81ECEC),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Builder(
                            builder: (context) {
                              final text = _currentMessage!.phraseText;
                              final isEmoji = text.characters.length <= 2;
                              if (isEmoji) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 26,
                                    ),
                                  ),
                                );
                              }
                              return Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ícone de balãozinho
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isVip ? Colors.amber : const Color(0xFF6C5CE7))
                            .withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: isVip ? const Color(0xFFFFD700) : const Color(0xFF81ECEC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
