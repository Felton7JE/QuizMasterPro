import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoadingHelper {
  /// Shows a loading indicator, executes [fetchData], pre-caches images from [extractImageUrls],
  /// and then navigates to [routeName].
  static Future<void> navigateWithPreload({
    required BuildContext context,
    required String routeName,
    required Future<void> Function() fetchData,
    required List<String?> Function() extractImageUrls,
    Object? arguments,
  }) async {
    // 1. Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // 2. Fetch data
      await fetchData();

      // 3. Extract and precache images
      if (context.mounted) {
        final urls = extractImageUrls().where((url) => url != null && url.isNotEmpty).cast<String>().toList();
        final precacheFutures = urls.map((url) {
          final resolved = ApiService.resolveImageUrl(url);
          if (resolved != null) {
            return precacheImage(NetworkImage(resolved), context, onError: (e, stackTrace) {
              debugPrint('Error precaching image: $resolved - $e');
            });
          }
          return Future.value();
        });
        await Future.wait(precacheFutures);
      }
    } catch (e) {
      debugPrint('Error in navigateWithPreload: $e');
    } finally {
      if (context.mounted) {
        // 4. Pop loading dialog
        Navigator.of(context).pop();

        // 5. Navigate to the actual screen
        Navigator.pushNamed(context, routeName, arguments: arguments);
      }
    }
  }
}
