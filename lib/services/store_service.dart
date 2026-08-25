import '../models/store_item.dart';
import '../models/title_model.dart';
import 'api_service.dart';

class StoreService {
  final ApiService _apiService = ApiService();

  // ----- Store Items -----

  Future<List<StoreItem>> getAvailableItems(int userId) async {
    final response = await _apiService.getList('/api/store/items/available/$userId');
    return response.map((json) => StoreItem.fromJson(json)).toList();
  }

  Future<List<StoreItem>> getPurchasedItems(int userId) async {
    final response = await _apiService.getList('/api/store/items/purchased/$userId');
    return response.map((json) {
      final itemMap = Map<String, dynamic>.from(json['storeItem'] as Map);
      itemMap['isEquipped'] = json['isEquipped'] ?? false;
      return StoreItem.fromJson(itemMap);
    }).toList();
  }

  Future<void> buyItem(int userId, int itemId) async {
    await _apiService.post('/api/store/buy?userId=$userId&itemId=$itemId');
  }

  Future<void> equipItem(int userId, int itemId) async {
    await _apiService.post('/api/store/equip?userId=$userId&itemId=$itemId');
  }

  Future<void> unequipSpecificItem(int userId, int itemId) async {
    await _apiService.post('/api/store/unequip?userId=$userId&itemId=$itemId');
  }

  // ----- Titles -----

  Future<List<TitleModel>> getAvailableTitles(int userId) async {
    final response = await _apiService.getList('/api/titles/available/$userId');
    return response.map((json) => TitleModel.fromJson(json)).toList();
  }

  Future<List<TitleModel>> getEarnedTitles(int userId) async {
    final response = await _apiService.getList('/api/titles/earned/$userId');
    return response.map((json) => TitleModel.fromJson(json['title'])).toList();
  }

  Future<void> equipTitle(int userId, int titleId) async {
    await _apiService.post('/api/titles/equip?userId=$userId&titleId=$titleId');
  }

  Future<void> unequipTitle(int userId) async {
    await _apiService.post('/api/titles/unequip?userId=$userId');
  }

  Future<void> unequipItem(int userId, String itemType) async {
    await _apiService.post('/api/store/unequip?userId=$userId&itemType=$itemType');
  }

  Future<void> consumeItem(int userId, String itemType) async {
    await _apiService.post('/api/store/consume?userId=$userId&itemType=$itemType');
  }
}
