import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

class AssetManagerService extends ChangeNotifier {
  double progress = 0.0;
  int totalAssets = 0;
  int downloadedAssets = 0;
  bool isDownloading = false;
  bool isPaused = false;
  String currentTaskStatus = '';

  final Map<String, String> _localPaths = {};
  final Set<String> _failedUrls = {};
  List<DownloadTask> _tasks = [];
  
  bool hasFailed(String url) => _failedUrls.contains(url);

  Future<void> initialize() async {
    // Notifications disabled to prevent spamming the Android notification tray
    // The user already sees the progress on the ResourceDownloadScreen
  }

  Future<void> startDownload(List<String> urls) async {
    isDownloading = true;
    isPaused = false;
    progress = 0.0;
    totalAssets = urls.length;
    downloadedAssets = 0;
    notifyListeners();

    if (urls.isEmpty) {
      isDownloading = false;
      progress = 1.0;
      notifyListeners();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _tasks = [];
    
    // Check existing files
    for (var url in urls) {
      final fileName = getFileNameFromUrl(url);
      final filePath = '${dir.path}/assets/$fileName';
      if (await File(filePath).exists()) {
        _localPaths[url] = filePath;
      }
    }

    for (var url in urls) {
      if (_localPaths.containsKey(url)) {
        downloadedAssets++;
        progress = downloadedAssets / totalAssets;
        notifyListeners();
        continue;
      }
      
      final fileName = getFileNameFromUrl(url);
      final task = DownloadTask(
        url: url,
        filename: fileName,
        directory: 'assets',
        group: 'assets',
        updates: Updates.statusAndProgress,
        retries: 3,
        allowPause: true,
      );
      _tasks.add(task);
    }

    if (_tasks.isEmpty) {
      isDownloading = false;
      progress = 1.0;
      notifyListeners();
      return;
    }

    await FileDownloader().downloadBatch(
      _tasks,
      batchProgressCallback: (succeeded, failed) {
        downloadedAssets = succeeded + failed;
        progress = downloadedAssets / totalAssets;
        notifyListeners();
      },
      taskStatusCallback: (update) {
        final task = update.task;
        final status = update.status;
        if (status == TaskStatus.complete) {
          _localPaths[task.url] = '${dir.path}/assets/${task.filename}';
          _failedUrls.remove(task.url);
        } else if (status == TaskStatus.failed || status == TaskStatus.notFound || status == TaskStatus.canceled) {
          _failedUrls.add(task.url);
        } else if (status == TaskStatus.paused) {
          isPaused = true;
          notifyListeners();
        } else if (status == TaskStatus.running) {
          isPaused = false;
          notifyListeners();
        }
      },
    );
    
    isDownloading = false;
    progress = 1.0;
    notifyListeners();
  }

  Future<void> pauseDownload() async {
    if (isDownloading && !isPaused) {
      for (var task in _tasks) {
        await FileDownloader().pause(task);
      }
      isPaused = true;
      notifyListeners();
    }
  }

  Future<void> resumeDownload() async {
    if (isDownloading && isPaused) {
      for (var task in _tasks) {
        await FileDownloader().resume(task);
      }
      isPaused = false;
      notifyListeners();
    }
  }

  static String getFileNameFromUrl(String url) {
    return '${url.hashCode}_${Uri.parse(url).pathSegments.last}';
  }

  String? getLocalPathSync(String url) {
    return _localPaths[url];
  }

  Future<String?> getLocalPath(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    if (_localPaths.containsKey(url)) return _localPaths[url];

    final dir = await getApplicationDocumentsDirectory();
    final fileName = getFileNameFromUrl(url);
    final file = File('${dir.path}/assets/$fileName');
    if (await file.exists()) {
      _localPaths[url] = file.path;
      return file.path;
    }
    return null;
  }

  Future<List<String>> getMissingUrls(List<String> urls) async {
    final dir = await getApplicationDocumentsDirectory();
    final missing = <String>[];
    for (var url in urls) {
      final fileName = getFileNameFromUrl(url);
      final filePath = '${dir.path}/assets/$fileName';
      if (!(await File(filePath).exists())) {
        missing.add(url);
      } else {
        _localPaths[url] = filePath;
      }
    }
    return missing;
  }
}
