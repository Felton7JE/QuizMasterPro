import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/core/custom_button.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/responsive_utils.dart';
import '../../../utils/loading_helper.dart';
import '../../../providers/core/auth_provider.dart';
import '../../../providers/solo/solo_provider.dart';
import '../../../providers/economy/season_provider.dart';
import '../../modes/free_mode_menu_screen.dart';

class GameModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String players;
  final String duration;
  final String categories;
  final String? badge;
  final String gameMode;

  const GameModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.players,
    required this.duration,
    required this.categories,
    required this.gameMode,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize = context.isVerySmallScreen ? 20 : 24;
    double titleFontSize = context.isVerySmallScreen ? 14 : 16;
    double descriptionFontSize = context.isVerySmallScreen ? 10 : 12;
    double badgeFontSize = context.isVerySmallScreen ? 7 : 8;
    double cardPadding = context.isVerySmallScreen ? 8 : 12;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.isVerySmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: iconSize,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.isVerySmallScreen ? 4 : 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badge == 'Popular'
                        ? AppColors.warning
                        : badge == 'Novo'
                            ? AppColors.success
                            : AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.screenHeight * 0.008),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: context.screenHeight * 0.004),
          Text(
            description,
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.grey,
              height: 1.2,
            ),
            maxLines: context.isVerySmallScreen ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.screenHeight * 0.008),
          _buildModeStats(context, players, duration, categories),
          const Spacer(),
          SizedBox(height: context.screenHeight * 0.008),
          if (gameMode == 'solo')
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Jogar',
                    onPressed: () {
                      LoadingHelper.navigateWithPreload(
                        context: context,
                        routeName: '/solo-map',
                        fetchData: () async {
                          final prov = context.read<SoloProvider>();
                          if (prov.mapData == null) {
                            await prov.fetchMapProgress();
                          }
                        },
                        extractImageUrls: () {
                          final data = context.read<SoloProvider>().mapData;
                          if (data == null) return [];
                          return data.levels.map((l) => l.bossAvatar).toList();
                        },
                      );
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            )
          else if (gameMode == 'season')
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Ver Passe',
                    onPressed: () {
                      LoadingHelper.navigateWithPreload(
                        context: context,
                        routeName: '/season-pass',
                        fetchData: () async {
                          final prov = context.read<SeasonProvider>();
                          final userId = context.read<AuthProvider>().currentUser?.id;
                          if (userId != null && prov.seasonData == null) {
                            await prov.fetchSeasonProgress(userId);
                          }
                        },
                        extractImageUrls: () {
                          final data = context.read<SeasonProvider>().seasonData;
                          if (data == null) return [];
                          final urls = [
                            data.bannerUrl,
                            data.mapBackgroundUrl,
                            data.lockedNodeIconUrl,
                            data.currentNodeIconUrl,
                            data.completedNodeIconUrl,
                          ];
                          for (var reward in data.rewards) {
                            urls.add(reward.freeRewardImageUrl);
                            urls.add(reward.premiumRewardImageUrl);
                            urls.add(reward.bossImageUrl);
                          }
                          return urls;
                        },
                      );
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            )
          else if (gameMode == 'study')
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Estudar com IA',
                    onPressed: () {
                      Navigator.pushNamed(context, '/study-mode');
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            )
          else if (gameMode == 'free')
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Jogar Agora',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FreeModeMenuScreen()),
                      );
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Criar Sala',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create-room',
                        arguments: {'gameMode': gameMode},
                      );
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildModeStats(
      BuildContext context, String players, String duration, String categories) {
    double spacing = context.isVerySmallScreen ? 0.5 : 1;

    return Column(
      children: [
        _buildStatRow(context, Icons.group, players),
        SizedBox(height: spacing),
        _buildStatRow(context, Icons.timer, duration),
        SizedBox(height: spacing),
        _buildStatRow(context, Icons.category, categories),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String text) {
    double iconSize = context.isVerySmallScreen ? 12 : 14;
    double textSize = context.isVerySmallScreen ? 8 : 10;
    double spacing = context.isVerySmallScreen ? 6 : 8;

    return Row(
      children: [
        Icon(icon, size: iconSize, color: Colors.grey[400]),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: textSize,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
