import '../models/user_model.dart';
import './api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Para Web, use 'clientId'. Para obter token no Android/iOS, use 'serverClientId' e configure o SHA-1 no Google Cloud Console.
    clientId: kIsWeb ? '502311568221-o528dh1d2e77055t3jvb6nma2djr7gps.apps.googleusercontent.com' : null, 
    serverClientId: kIsWeb ? null : '502311568221-o528dh1d2e77055t3jvb6nma2djr7gps.apps.googleusercontent.com',
  );

  AuthService(this._apiService);

  Future<UserModel> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login cancelado pelo usuário');
    }
    return _processGoogleAuth(googleUser);
  }

  Future<UserModel> silentLoginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) {
      throw Exception('Usuário não está logado silenciosamente');
    }
    return _processGoogleAuth(googleUser);
  }

  Future<UserModel> _processGoogleAuth(GoogleSignInAccount googleUser) async {
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Falha ao obter token do Google');
    }

    final response = await _apiService.post('/api/auth/google', {
      'idToken': idToken,
    });

    if (response['token'] != null) {
      ApiService.token = response['token'];
    }

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
    final response = await _apiService.getList('/api/users/$userId/history');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    final response = await _apiService.getList('/api/activities/feed/$userId');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRanking({
    String period = 'global',
    String category = 'all',
    int page = 0,
    int size = 10,
  }) async {
    final response = await _apiService.getList('/api/users/ranking?period=$period&category=$category&page=$page&size=$size');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> applyReferralCode(String userId, String referralCode) async {
    final response = await _apiService.post('/api/users/$userId/referral/apply', {'referralCode': referralCode});
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> redeemPromoCode(String userId, String code) async {
    // A API pode retornar um 400 Bad Request que o _apiService deve conseguir lidar e jogar a excepção, ou retornar Map
    // Ajuste se o seu _apiService tratar erros não-200.
    final response = await _apiService.post('/api/promocodes/redeem?userId=$userId', {'code': code});
    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteAccount(String userId) async {
    await _apiService.delete('/api/users/$userId');
    await _googleSignIn.signOut();
    ApiService.token = null;
  }

  Future<bool> checkUsername(String username) async {
    final response = await _apiService.getRaw('/api/auth/check-username?username=$username');
    return response == 'true'; // A API retorna booleano
  }

  Future<UserModel> updateUsername(String userId, String newUsername, String email, String? avatar) async {
    final response = await _apiService.put('/api/users/$userId', {
      'username': newUsername,
      'email': email,
      'avatar': avatar,
    });
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateCrystals(String userId, int crystals) async {
    final response = await _apiService.put('/api/users/$userId/crystals', {
      'crystals': crystals,
    });
    return UserModel.fromJson(response);
  }

  Future<void> buyVip(String userId) async {
    await _apiService.post('/api/season/buy-vip?userId=$userId', {});
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    ApiService.token = null;
    // Implementar logout se necessário no backend
    // await _apiService.post('/api/auth/logout');
  }
}
