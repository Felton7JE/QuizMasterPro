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
  String? get token => _currentUser?.id;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.loginWithGoogle();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkAndSilentLogin() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.silentLoginWithGoogle();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      // Don't set error for silent login failure, just return false
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    try {
      final updatedUser = await _authService.getUserById(_currentUser!.id);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar dados do usuário: $e');
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

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    if (_currentUser == null) return [];
    
    try {
      return await _authService.getRecentActivity(_currentUser!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRanking({
    String period = 'global',
    String category = 'all',
    int page = 0,
    int size = 10,
  }) async {
    try {
      return await _authService.getRanking(
        period: period,
        category: category,
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
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      await _authService.deleteAccount(_currentUser!.id);
      _currentUser = null;
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

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateUserCoins(int newCoins) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(coins: newCoins);
      notifyListeners();
    }
  }

  void updateUserCrystals(int newCrystals) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(crystals: newCrystals);
      notifyListeners();
    }
  }

  Future<bool> addCrystals(int amount) async {
    if (_currentUser == null) return false;
    try {
      final newCrystals = _currentUser!.crystals + amount;
      final updatedUser = await _authService.updateCrystals(_currentUser!.id, newCrystals);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar cristais: $e');
      return false;
    }
  }

  Future<bool> buyVip() async {
    if (_currentUser == null) return false;
    try {
      await _authService.buyVip(_currentUser!.id);
      await refreshUser();
      return true;
    } catch (e) {
      debugPrint('Erro ao comprar VIP: $e');
      return false;
    }
  }

  Future<String?> applyReferralCode(String referralCode) async {
    if (_currentUser == null) return 'Tens de ter sessão iniciada.';
    _setLoading(true);
    try {
      final res = await _authService.applyReferralCode(_currentUser!.id, referralCode);
      await refreshUser();
      return res['message']?.toString() ?? 'Código de convite aplicado com sucesso!';
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> redeemPromoCode(String code) async {
    if (_currentUser == null) return 'Tens de ter sessão iniciada.';
    _setLoading(true);
    try {
      final res = await _authService.redeemPromoCode(_currentUser!.id, code);
      if (res['success'] == true) {
        // Atualiza a conta
        await refreshUser();
        return res['message']?.toString() ?? 'Código resgatado com sucesso!';
      } else {
        return res['error']?.toString() ?? 'Código inválido ou já utilizado.';
      }
    } catch (e) {
      // API error map parsing might throw an exception if the format isn't what's expected
      final errorStr = e.toString().replaceAll('Exception: ', '');
      if (errorStr.contains('error')) {
         return 'Código inválido ou já expirou.';
      }
      return 'Erro de servidor ao resgatar código. ($errorStr)';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkUsername(String username) async {
    try {
      return await _authService.checkUsername(username);
    } catch (e) {
      debugPrint('Erro ao verificar username: $e');
      return false;
    }
  }

  Future<bool> updateUsername(String newUsername) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      final updatedUser = await _authService.updateUsername(
        _currentUser!.id, 
        newUsername, 
        _currentUser!.email, 
        _currentUser!.avatar
      );
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
