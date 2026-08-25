import 'package:flutter/foundation.dart';
import '../models/season_models.dart';
import 'api_service.dart';

class SeasonService {
  final ApiService _api;

  SeasonService(this._api);

  Future<SeasonResponse?> getSeasonProgress(String userId) async {
    try {
      final res = await _api.get('/api/season/progress?userId=$userId');
      if (res['active'] == false) {
        return null;
      }
      return SeasonResponse.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching season progress: $e');
      return null;
    }
  }

  Future<void> addSeasonPoints(String userId, int points) async {
    try {
      await _api.post('/api/season/add-points?userId=$userId&points=$points', {});
    } catch (e) {
      debugPrint('Error adding season points: $e');
    }
  }

  Future<bool> claimReward(String userId, int level, bool isPremium) async {
    try {
      await _api.post('/api/season/claim?userId=$userId&level=$level&isPremium=$isPremium', {});
      return true;
    } catch (e) {
      debugPrint('Error claiming season reward: $e');
      return false;
    }
  }

  Future<SeasonResponse?> buyVipPass(String userId) async {
    try {
      final res = await _api.post('/api/season/buy-vip?userId=$userId', {});
      return SeasonResponse.fromJson(res);
    } catch (e) {
      debugPrint('Error buying VIP pass: $e');
      rethrow;
    }
  }
}
