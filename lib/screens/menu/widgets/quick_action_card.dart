import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/responsive_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/loading_helper.dart';
import '../../../providers/economy/store_provider.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize = context.isVerySmallScreen ? 24 : 32;
    double titleFontSize = context.isVerySmallScreen ? 12 : 14;
    double descriptionFontSize = context.isVerySmallScreen ? 8 : 10;
    double cardPadding = context.isVerySmallScreen ? 12 : 16;

    return GestureDetector(
      onTap: () {
        if (route == '/store') {
          LoadingHelper.navigateWithPreload(
            context: context,
            routeName: '/store',
            fetchData: () async {
              final prov = context.read<StoreProvider>();
              if (prov.availableItems.isEmpty && prov.availableTitles.isEmpty) {
                await prov.loadAllData();
              }
            },
            extractImageUrls: () {
              final prov = context.read<StoreProvider>();
              return [
                ...prov.availableItems.map((e) => e.value),
                ...prov.purchasedItems.map((e) => e.value),
              ];
            },
          );
        } else if (route == '/ranking' || route == '/quests' || route == '/settings') {
          Navigator.pushNamed(context, route);
        } else {
          // Temporário para rotas não implementadas
          AppSnackBar.showInfo(context, 'Em breve: $title');
        }
      },
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: iconSize,
            ),
            SizedBox(height: context.screenHeight * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: context.screenHeight * 0.005),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: descriptionFontSize,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: context.isVerySmallScreen ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
