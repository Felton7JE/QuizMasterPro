import 'package:flutter/foundation.dart';
import '../../models/season_models.dart';
import '../../services/season_service.dart';

class SeasonProvider extends ChangeNotifier {
  final SeasonService _seasonService;
  
  SeasonResponse? seasonData;
  bool isLoading = false;
  String? error;

  SeasonProvider(this._seasonService);

  Future<void> fetchSeasonProgress(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _seasonService.getSeasonProgress(userId);
      seasonData = res;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPoints(String userId, int points) async {
    try {
      await _seasonService.addSeasonPoints(userId, points);
      await fetchSeasonProgress(userId); // Refresh data
    } catch (e) {
      debugPrint('Error adding season points: $e');
    }
  }

  Future<bool> claimReward(String userId, int level, bool isPremium) async {
    bool success = await _seasonService.claimReward(userId, level, isPremium);
    if (success) {
      await fetchSeasonProgress(userId);
    }
    return success;
  }

  Future<bool> buyVipPass(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _seasonService.buyVipPass(userId);
      seasonData = res;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
