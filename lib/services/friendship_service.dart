import 'package:flutter/foundation.dart';
import '../models/friend_model.dart';
import 'api_service.dart';

class FriendshipService {
  final ApiService _apiService;

  FriendshipService(this._apiService);

  Future<List<FriendModel>> getFriendsList(int userId) async {
    final data = await _apiService.getList('/api/friends?userId=$userId');
    return data.map((json) => FriendModel.fromJson(json)).toList();
  }

  Future<List<FriendModel>> getPendingRequests(int userId) async {
    final data = await _apiService.getList('/api/friends/requests?userId=$userId');
    return data.map((json) => FriendModel.fromJson(json)).toList();
  }

  Future<List<FriendModel>> getSentRequests(int userId) async {
    final data = await _apiService.getList('/api/friends/requests/sent?userId=$userId');
    return data.map((json) => FriendModel.fromJson(json)).toList();
  }

  Future<List<FriendModel>> searchUsers(String query) async {
    final data = await _apiService.getList('/api/users/search?query=$query');
    return data.map((json) => FriendModel(
      id: json['id'] as int,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      level: json['level'] as int? ?? 1,
      currentLeague: json['currentLeague']?.toString() ?? 'BRONZE',
      isOnline: false, // We don't have online status in search response right now
      friendshipId: null,
    )).toList();
  }

  Future<String> sendFriendRequest(int userId, String targetUsername) async {
    try {
      await _apiService.post('/api/friends/request?userId=$userId&targetUsername=$targetUsername');
      return 'Pedido enviado com sucesso!';
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ FriendshipService sendFriendRequest: $e');
      throw Exception('Falha ao enviar pedido');
    }
  }

  Future<String> acceptFriendRequest(int userId, int friendshipId) async {
    try {
      await _apiService.post('/api/friends/accept/$friendshipId?userId=$userId');
      return 'Amigo adicionado!';
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ FriendshipService acceptFriendRequest: $e');
      throw Exception('Falha ao aceitar pedido');
    }
  }

  Future<String> rejectFriendRequest(int userId, int friendshipId) async {
    try {
      await _apiService.post('/api/friends/reject/$friendshipId?userId=$userId');
      return 'Pedido rejeitado.';
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ FriendshipService rejectFriendRequest: $e');
      throw Exception('Falha ao rejeitar pedido');
    }
  }

  Future<String> removeFriend(int userId, int friendId) async {
    try {
      await _apiService.delete('/api/friends/$friendId?userId=$userId');
      return 'Amigo removido.';
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ FriendshipService removeFriend: $e');
      throw Exception('Falha ao remover amigo');
    }
  }
}
