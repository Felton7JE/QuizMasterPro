import 'package:flutter/foundation.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class MissionProvider with ChangeNotifier {
  final MissionService _missionService;
  final AuthProvider _authProvider;

  List<MissionModel> _missions = [];
  bool _isLoading = false;
  String? _error;

  MissionProvider(this._missionService, this._authProvider) {
    if (_authProvider.isAuthenticated) {
      fetchMissions();
    }
  }

  List<MissionModel> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMissions() async {
    if (!_authProvider.isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _missionService.getActiveMissions(ApiService.token!);
      final uniqueMissions = <int, MissionModel>{};
      for (var mission in fetched) {
        uniqueMissions[mission.id] = mission;
      }
      _missions = uniqueMissions.values.toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimReward(int missionId) async {
    if (!_authProvider.isAuthenticated) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _missionService.claimReward(ApiService.token!, missionId);
      
      // Update coins in AuthProvider
      if (response['success'] == true) {
        int newCoins = response['newCoinsBalance'];
        _authProvider.updateUserCoins(newCoins);
        
        // Refresh missions to update UI
        await fetchMissions();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
