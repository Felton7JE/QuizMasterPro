import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/asset_manager_service.dart';
import '../services/store_service.dart';
import '../providers/auth_provider.dart';

class ResourceDownloadScreen extends StatefulWidget {
  final VoidCallback onDownloadComplete;

  const ResourceDownloadScreen({Key? key, required this.onDownloadComplete}) : super(key: key);

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
      final urls = items
          .where((item) => (item.type == 'AVATAR' || item.type == 'BANNER') && item.value.startsWith('http'))
          .map((item) => item.value)
          .toSet() // Remove duplicates
          .toList();

      final assetManager = context.read<AssetManagerService>();
      if (urls.isNotEmpty) {
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
