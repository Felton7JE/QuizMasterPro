import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> createUser({
    required String username,
    required String email,
    String? fullName,
    String? avatar,
  }) async {
    _setLoading(true);
    try {
      final request = CreateUserRequest(
        username: username,
        email: email,
        fullName: fullName,
        avatar: avatar,
      );
      
      _currentUser = await _authService.createUser(request);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String username) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.login(username);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    if (_currentUser == null) return null;
    
    try {
      return await _authService.getUserStats(_currentUser!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserHistory() async {
    if (_currentUser == null) return [];
    
    try {
      return await _authService.getUserHistory(_currentUser!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRanking({
    String period = 'global',
    int page = 0,
    int size = 10,
  }) async {
    try {
      return await _authService.getRanking(
        period: period,
        page: page,
        size: size,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}
