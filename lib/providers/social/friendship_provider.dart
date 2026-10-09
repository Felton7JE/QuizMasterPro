import 'package:flutter/foundation.dart';
import '../../models/friend_model.dart';
import '../../services/friendship_service.dart';
import '../../services/websocket_service.dart';

class FriendshipProvider extends ChangeNotifier {
  final FriendshipService _friendshipService;
  final WebSocketService _webSocketService = WebSocketService();

  List<FriendModel> _friends = [];
  List<FriendModel> _pendingRequests = [];
  List<FriendModel> _sentRequests = [];
  List<FriendModel> _searchResults = [];
  
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isLoadingSearch = false;
  String? _error;

  FriendshipProvider(this._friendshipService);

  List<FriendModel> get friends => _friends;
  List<FriendModel> get pendingRequests => _pendingRequests;
  List<FriendModel> get sentRequests => _sentRequests;
  List<FriendModel> get searchResults => _searchResults;
  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingSearch => _isLoadingSearch;
  String? get error => _error;

  int? _currentUserId;

  void initPresence(int userId) {
    if (_currentUserId == userId) return; // Já inicializado
    _currentUserId = userId;
    
    // Conecta ao WebSocket passando o userId e ouve eventos de status de amigos
    _webSocketService.connect(
      userId: userId.toString(),
      onFriendStatusUpdate: _handleFriendStatusUpdate,
    );
  }

  void _handleFriendStatusUpdate(Map<String, dynamic> data) {
    final updatedUserId = data['userId'] as int?;
    final isOnline = data['isOnline'] as bool?;

    if (updatedUserId != null && isOnline != null) {
      final index = _friends.indexWhere((f) => f.id == updatedUserId);
      if (index != -1) {
        _friends[index] = _friends[index].copyWith(isOnline: isOnline);
        notifyListeners();
      }
    }
  }

  Future<void> fetchFriends(int userId) async {
    _isLoadingFriends = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await _friendshipService.getFriendsList(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingRequests(int userId) async {
    _isLoadingRequests = true;
    _error = null;
    notifyListeners();

    try {
      _pendingRequests = await _friendshipService.getPendingRequests(userId);
      _sentRequests = await _friendshipService.getSentRequests(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isLoadingSearch = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _friendshipService.searchUsers(query);
      // Remove current user from results if they appear
      if (_currentUserId != null) {
        _searchResults.removeWhere((user) => user.id == _currentUserId);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(int userId, String targetUsername) async {
    try {
      await _friendshipService.sendFriendRequest(userId, targetUsername);
      // Update sent requests
      fetchPendingRequests(userId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<void> acceptRequest(int userId, int friendshipId) async {
    try {
      await _friendshipService.acceptFriendRequest(userId, friendshipId);
      // Remove da lista de pendentes e atualiza a lista de amigos
      _pendingRequests.removeWhere((req) => req.friendshipId == friendshipId);
      await fetchFriends(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<void> rejectRequest(int userId, int friendshipId) async {
    try {
      await _friendshipService.rejectFriendRequest(userId, friendshipId);
      _pendingRequests.removeWhere((req) => req.friendshipId == friendshipId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<void> cancelSentRequest(int userId, int friendshipId) async {
    try {
      await _friendshipService.rejectFriendRequest(userId, friendshipId);
      _sentRequests.removeWhere((req) => req.friendshipId == friendshipId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<void> removeFriend(int userId, int friendId) async {
    try {
      await _friendshipService.removeFriend(userId, friendId);
      _friends.removeWhere((f) => f.id == friendId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      throw Exception(_error);
    }
  }
}
