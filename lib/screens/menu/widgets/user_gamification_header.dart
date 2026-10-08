import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_service.dart';
import '../../../providers/core/auth_provider.dart';
import '../../../providers/economy/store_provider.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';

class UserGamificationHeader extends StatelessWidget {
  const UserGamificationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        final bannerUrl = storeProvider.getBannerUrl(user.activeBannerId);
        final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            image: resolvedBanner != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      resolvedBanner,
                      headers: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(Icons.local_fire_department, Colors.orange, '${user.currentStreak}', 'Ofensiva'),
                      _buildDivider(),
                      _buildStatItem(Icons.monetization_on, Colors.amber, '${user.coins}', 'Moedas'),
                      _buildDivider(),
                      _buildStatItem(Icons.auto_awesome, const Color(0xFFC084FC), '${user.crystals}', 'Cristais 🔮'),
                      _buildDivider(),
                      _buildStatItem(Icons.bolt, Colors.lightBlueAccent, '${user.energy}', 'Energia'),
                      _buildDivider(),
                      _buildStatItem(Icons.star, Colors.purpleAccent, 'Nvl ${user.level}', '${user.xp} XP'),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.border,
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
