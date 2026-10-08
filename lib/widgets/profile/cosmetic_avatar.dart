import 'package:flutter/material.dart';
import '../../config/cosmetics_config.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../services/asset_manager_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../economy/vip_badge_widget.dart';
class CosmeticAvatar extends StatelessWidget {
  final double radius;
  final String? avatarUrl;
  final String username;
  final int? activeFrameId;
  final int? activeAvatarId;
  final bool isVip;

  const CosmeticAvatar({
    super.key,
    this.radius = 20,
    required this.avatarUrl,
    required this.username,
    this.activeFrameId,
    this.activeAvatarId,
    this.isVip = false,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve full URL (supports relative paths served by the backend)
    final resolvedUrl = ApiConfig.resolveAssetUrl(avatarUrl, isThumb: true);
    final assetManager = context.read<AssetManagerService>();
    final localPath = resolvedUrl != null ? assetManager.getLocalPathSync(resolvedUrl) : null;
    
    // Default or custom colored background if no avatarUrl
    final avatarColors = CosmeticsConfig.getAvatarColors(activeAvatarId);

    Widget innerAvatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: resolvedUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: avatarColors,
              )
            : null,
        image: localPath != null
            ? DecorationImage(
                image: FileImage(File(localPath)),
                fit: BoxFit.cover,
              )
            : (resolvedUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      resolvedUrl,
                      maxWidth: (radius * 4).toInt(),
                      maxHeight: (radius * 4).toInt(),
                      headers: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                    ),
                    fit: BoxFit.cover,
                  )
                : null),
      ),
      child: resolvedUrl == null
          ? Center(
              child: Text(
                username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
              ),
            )
          : null,
    );

    if (activeFrameId != null) {
      final frameColors = CosmeticsConfig.getFrameColors(activeFrameId);
      if (frameColors != null) {
        innerAvatar = Container(
          padding: EdgeInsets.all(radius * 0.15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: frameColors,
            ),
            boxShadow: [
              BoxShadow(
                color: frameColors[0].withValues(alpha: 0.5),
                blurRadius: radius * 0.4,
                spreadRadius: radius * 0.05,
              )
            ],
          ),
          child: innerAvatar,
        );
      }
    } else if (isVip) {
      // Aura dourada para VIP se não tiver frame equipado
      innerAvatar = Container(
        padding: EdgeInsets.all(radius * 0.12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFA500),
              Color(0xFFFFE082),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
              blurRadius: radius * 0.35,
              spreadRadius: radius * 0.05,
            )
          ],
        ),
        child: innerAvatar,
      );
    }

    if (!isVip) return innerAvatar;

    // Selo VIP no canto superior do avatar
    return Stack(
      clipBehavior: Clip.none,
      children: [
        innerAvatar,
        Positioned(
          top: -radius * 0.3,
          right: -radius * 0.2,
          child: VipInlineBadge(scale: (radius / 20).clamp(0.6, 1.8)),
        ),
      ],
    );
  }
}
