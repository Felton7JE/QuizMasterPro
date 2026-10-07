import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/asset_manager_service.dart';
import '../services/store_service.dart';
import '../services/season_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

class ResourceDownloadScreen extends StatefulWidget {
  final VoidCallback onDownloadComplete;

  const ResourceDownloadScreen({super.key, required this.onDownloadComplete});

  @override
  _ResourceDownloadScreenState createState() => _ResourceDownloadScreenState();
}

class _ResourceDownloadScreenState extends State<ResourceDownloadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDownloadProcess();
    });
  }

  Future<void> _startDownloadProcess() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final storeService = context.read<StoreService>();
      final userIdStr = authProvider.currentUser?.id;
      final userId = userIdStr != null ? int.tryParse(userIdStr) : null;
      
      if (userId == null) {
        widget.onDownloadComplete();
        return;
      }

      // Fetch all items from the store to extract image URLs
      final items = await storeService.getAvailableItems(userId);
      
      // Filter out items that are images
      final urlsSet = items
          .where((item) => (item.type == 'AVATAR' || item.type == 'BANNER'))
          .map((item) => ApiConfig.resolveAssetUrl(item.value))
          .where((url) => url != null && url.startsWith('http'))
          .cast<String>()
          .toSet();

      // Fetch season progress to get season pass and season map assets
      try {
        if (!mounted) return;
        final seasonService = context.read<SeasonService>();
        final season = await seasonService.getSeasonProgress(userIdStr!);
        if (season != null) {
          final bannerUrl = ApiService.resolveImageUrl(season.bannerUrl);
          if (bannerUrl != null && bannerUrl.startsWith('http')) {
            urlsSet.add(bannerUrl);
          }
          final mapBgUrl = ApiService.resolveImageUrl(season.mapBackgroundUrl);
          if (mapBgUrl != null && mapBgUrl.startsWith('http')) {
            urlsSet.add(mapBgUrl);
          }
          final lockedUrl = ApiService.resolveImageUrl(season.lockedNodeIconUrl);
          if (lockedUrl != null && lockedUrl.startsWith('http')) {
            urlsSet.add(lockedUrl);
          }
          final currentUrl = ApiService.resolveImageUrl(season.currentNodeIconUrl);
          if (currentUrl != null && currentUrl.startsWith('http')) {
            urlsSet.add(currentUrl);
          }
          final completedUrl = ApiService.resolveImageUrl(season.completedNodeIconUrl);
          if (completedUrl != null && completedUrl.startsWith('http')) {
            urlsSet.add(completedUrl);
          }
          for (final reward in season.rewards) {
            final freeUrl = ApiService.resolveImageUrl(reward.freeRewardImageUrl);
            if (freeUrl != null && freeUrl.startsWith('http')) {
              urlsSet.add(freeUrl);
            }
            final premiumUrl = ApiService.resolveImageUrl(reward.premiumRewardImageUrl);
            if (premiumUrl != null && premiumUrl.startsWith('http')) {
              urlsSet.add(premiumUrl);
            }
            final bossUrl = ApiService.resolveImageUrl(reward.bossImageUrl);
            if (bossUrl != null && bossUrl.startsWith('http')) {
              urlsSet.add(bossUrl);
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching season assets: $e");
      }

      final urls = urlsSet.toList();

      if (!mounted) return;
      final assetManager = context.read<AssetManagerService>();
      if (urls.isNotEmpty) {
        bool? proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A2235),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Baixar Recursos', style: TextStyle(color: Colors.white)),
            content: Text(
              'Foram encontrados ${urls.length} recursos da loja/temporada que precisam ser baixados.\nDesejas baixar agora? (Pode consumir dados móveis)',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Mais Tarde', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Baixar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (proceed != true) {
          if (mounted) widget.onDownloadComplete();
          return;
        }

        await assetManager.startDownload(urls);
      } else {
        widget.onDownloadComplete();
      }
    } catch (e) {
      debugPrint("Error fetching assets: $e");
      widget.onDownloadComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<AssetManagerService>(
        builder: (context, assetManager, child) {
          
          if (!assetManager.isDownloading && assetManager.progress == 1.0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onDownloadComplete();
            });
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download, size: 80, color: Colors.indigoAccent),
                  const SizedBox(height: 24),
                  const Text(
                    'Baixando Recursos...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${assetManager.downloadedAssets} / ${assetManager.totalAssets} arquivos',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LinearProgressIndicator(
                    value: assetManager.totalAssets == 0 ? 0 : assetManager.progress,
                    backgroundColor: Colors.white24,
                    color: Colors.indigoAccent,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(assetManager.progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: assetManager.isDownloading
                            ? (assetManager.isPaused 
                                ? assetManager.resumeDownload 
                                : assetManager.pauseDownload)
                            : null,
                        icon: Icon(assetManager.isPaused ? Icons.play_arrow : Icons.pause),
                        label: Text(assetManager.isPaused ? 'Continuar' : 'Pausar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
