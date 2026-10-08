import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

/// Selo VIP real da Temporada 1 (imagem servida pelo backend)
class VipBadge extends StatelessWidget {
  final double scale;
  final bool showLabel;

  const VipBadge({
    super.key,
    this.scale = 1.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = 32.0 * scale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 8 * scale,
            spreadRadius: 1 * scale,
          ),
        ],
      ),
      child: CachedNetworkImage(
        imageUrl: ApiConfig.vipSealUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
        errorWidget: (context, url, error) => _buildFallbackBadge(size),
        placeholder: (context, url) => _buildFallbackBadge(size),
      ),
    );
  }

  Widget _buildFallbackBadge(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 6 * scale,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '👑',
          style: TextStyle(fontSize: size * 0.55, height: 1.0),
        ),
      ),
    );
  }
}

/// Badge inline pequeno (para listas, lobbies, ranking)
class VipInlineBadge extends StatelessWidget {
  final double scale;

  const VipInlineBadge({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final size = 22.0 * scale;
    return CachedNetworkImage(
      imageUrl: ApiConfig.vipSealUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
      errorWidget: (context, url, error) => Text(
        '👑',
        style: TextStyle(fontSize: size * 0.7, height: 1.0),
      ),
    );
  }
}

/// Texto com gradiente dourado e selo VIP inline para VIP users
class VipUsernameText extends StatelessWidget {
  final String username;
  final bool isVip;
  final TextStyle? style;
  final bool showBadge;
  final MainAxisSize mainAxisSize;

  const VipUsernameText({
    super.key,
    required this.username,
    this.isVip = false,
    this.style,
    this.showBadge = true,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

    if (!isVip) {
      return Text(
        username,
        style: baseStyle,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Se for VIP: nome em gradiente dourado + selo real
    return Row(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFF099),
                Color(0xFFFFD700),
                Color(0xFFFFA500),
                Color(0xFFFFE082),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              username,
              style: baseStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: 5),
          const VipInlineBadge(scale: 0.9),
        ],
      ],
    );
  }
}
