import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<UserModel> createUser(CreateUserRequest request) async {
    final response = await _apiService.post('/api/users', request.toJson());
    return UserModel.fromJson(response);
  }

  Future<UserModel> login(String username) async {
    final response = await _apiService.post('/api/auth/login?username=$username');
    return UserModel.fromJson(response);
  }

  Future<UserModel> getUserById(String userId) async {
    final response = await _apiService.get('/api/users/$userId');
    return UserModel.fromJson(response);
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return await _apiService.get('/api/users/$userId/stats');
  }

  Future<List<Map<String, dynamic>>> getUserHistory(String userId) async {
    final response = await _apiService.get('/api/users/$userId/history');
    return List<Map<String, dynamic>>.from(response['history'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getRanking({
    String period = 'global',
    int page = 0,
    int size = 10,
  }) async {
    final response = await _apiService.get('/api/users/ranking?period=$period&page=$page&size=$size');
    return List<Map<String, dynamic>>.from(response['ranking'] ?? []);
  }

  Future<void> logout() async {
    // Implementar logout se necessário no backend
    // await _apiService.post('/api/auth/logout');
  }
}
