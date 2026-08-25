import 'package:flutter/foundation.dart';
import '../models/store_item.dart';
import '../models/title_model.dart';
import '../services/store_service.dart';
import 'auth_provider.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _storeService;
  final AuthProvider _authProvider;

  List<StoreItem> _availableItems = [];
  List<StoreItem> _purchasedItems = [];
  List<TitleModel> _availableTitles = [];
  List<TitleModel> _earnedTitles = [];
  
  bool _isLoading = false;
  String? _error;

  StoreProvider(this._storeService, this._authProvider) {
    if (_authProvider.isAuthenticated) {
      loadAllData();
    }
  }

  List<StoreItem> get availableItems => _availableItems;
  List<StoreItem> get purchasedItems => _purchasedItems;
  List<TitleModel> get availableTitles => _availableTitles;
  List<TitleModel> get earnedTitles => _earnedTitles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<StoreItem> get equippedPhrases =>
      _purchasedItems.where((i) => i.type == 'TEXT_PHRASE' && i.isEquipped).toList();

  List<StoreItem> get equippedEmotes =>
      _purchasedItems.where((i) => (i.type == 'EMOTE' || i.type == 'EMOJI') && i.isEquipped).toList();

  bool isItemEquipped(int itemId) {
    for (final i in _purchasedItems) {
      if (i.id == itemId) return i.isEquipped;
    }
    final user = _authProvider.currentUser;
    if (user == null) return false;
    return user.activeBannerId == itemId ||
        user.activePhraseId == itemId ||
        user.activeAvatarId == itemId ||
        user.activeFrameId == itemId ||
        user.activeEmoteId == itemId;
  }

  String? getBannerUrl(int? bannerId) {
    if (bannerId == null) return null;
    try {
      final item = [..._availableItems, ..._purchasedItems].firstWhere(
        (i) => i.id == bannerId && i.type == 'BANNER'
      );
      return item.value;
    } catch (e) {
      return null;
    }
  }

  String? getFrameUrl(int? frameId) {
    if (frameId == null) return null;
    try {
      final item = [..._availableItems, ..._purchasedItems].firstWhere(
        (i) => i.id == frameId && i.type == 'PROFILE_FRAME'
      );
      return item.value;
    } catch (e) {
      return null;
    }
  }

  Future<void> loadAllData() async {
    if (!_authProvider.isAuthenticated) return;
    final userIdStr = _authProvider.currentUser!.id;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return;

    _setLoading(true);
    try {
      final futures = await Future.wait([
        _storeService.getAvailableItems(userId),
        _storeService.getPurchasedItems(userId),
        _storeService.getAvailableTitles(userId),
        _storeService.getEarnedTitles(userId),
      ]);

      final allAvailable = futures[0] as List<StoreItem>;
      _purchasedItems = futures[1] as List<StoreItem>;
      _availableItems = allAvailable.where((item) => !_purchasedItems.any((p) => p.id == item.id)).toList();
      _availableTitles = futures[2] as List<TitleModel>;
      _earnedTitles = futures[3] as List<TitleModel>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> buyItem(StoreItem item) async {
    if (!_authProvider.isAuthenticated) return false;
    final user = _authProvider.currentUser!;
    if (user.coins < item.price) {
      _error = 'Moedas insuficientes';
      notifyListeners();
      return false;
    }

    final userId = int.tryParse(user.id);
    if (userId == null) return false;

    // ─── 1. Guardar estado anterior para rollback ───────────────────────
    final previousAvailable = List<StoreItem>.from(_availableItems);
    final previousPurchased = List<StoreItem>.from(_purchasedItems);
    final previousCoins = user.coins;

    // ─── 2. Optimistic Update — UI actualiza IMEDIATAMENTE ─────────────
    _availableItems = _availableItems.where((i) => i.id != item.id).toList();
    _purchasedItems = [..._purchasedItems, item];
    _authProvider.updateUserCoins(user.coins - item.price);
    _error = null;
    notifyListeners();

    try {
      // ─── 3. Chamada à API ──
      await _storeService.buyItem(userId, item.id);

      // ─── 4. Sync — refrescar inventário do servidor ─
      _purchasedItems = await _storeService.getPurchasedItems(userId);
      _availableItems = _availableItems
          .where((i) => !_purchasedItems.any((p) => p.id == i.id))
          .toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      // ─── 5. Rollback ─────────────────
      _availableItems = previousAvailable;
      _purchasedItems = previousPurchased;
      _authProvider.updateUserCoins(previousCoins);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> equipItem(StoreItem item) async {
    if (!_authProvider.isAuthenticated) return false;
    final userId = int.tryParse(_authProvider.currentUser!.id);
    if (userId == null) return false;

    // Check slot limits
    if (item.type == 'TEXT_PHRASE') {
      if (equippedPhrases.length >= 5 && !isItemEquipped(item.id)) {
        _error = 'Limite de 5 frases equipadas atingido. Desequipa uma frase primeiro.';
        notifyListeners();
        return false;
      }
    } else if (item.type == 'EMOTE' || item.type == 'EMOJI') {
      if (equippedEmotes.length >= 10 && !isItemEquipped(item.id)) {
        _error = 'Limite de 10 emojis equipados atingido. Desequipa um emoji primeiro.';
        notifyListeners();
        return false;
      }
    }

    // Optimistic local state update
    if (item.type == 'BANNER' || item.type == 'AVATAR' || item.type == 'PROFILE_FRAME') {
      _purchasedItems = _purchasedItems.map((i) {
        if (i.type == item.type) {
          return i.copyWith(isEquipped: i.id == item.id);
        }
        return i;
      }).toList();
    } else {
      _purchasedItems = _purchasedItems.map((i) {
        if (i.id == item.id) {
          return i.copyWith(isEquipped: true);
        }
        return i;
      }).toList();
    }

    if (item.type == 'BANNER') {
      final updatedUser = _authProvider.currentUser!.copyWith(activeBannerId: item.id);
      _authProvider.setCurrentUser(updatedUser);
    } else if (item.type == 'TEXT_PHRASE') {
      final updatedUser = _authProvider.currentUser!.copyWith(activePhraseId: item.id);
      _authProvider.setCurrentUser(updatedUser);
    } else if (item.type == 'AVATAR') {
      final updatedUser = _authProvider.currentUser!.copyWith(
        activeAvatarId: item.id,
        avatar: item.value,
      );
      _authProvider.setCurrentUser(updatedUser);
    } else if (item.type == 'PROFILE_FRAME') {
      final updatedUser = _authProvider.currentUser!.copyWith(activeFrameId: item.id);
      _authProvider.setCurrentUser(updatedUser);
    } else if (item.type == 'EMOTE' || item.type == 'EMOJI') {
      final updatedUser = _authProvider.currentUser!.copyWith(activeEmoteId: item.id);
      _authProvider.setCurrentUser(updatedUser);
    }

    _error = null;
    notifyListeners();

    try {
      await _storeService.equipItem(userId, item.id);
      _purchasedItems = await _storeService.getPurchasedItems(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _purchasedItems = await _storeService.getPurchasedItems(userId);
      notifyListeners();
      return false;
    }
  }

  Future<bool> unequipSpecificItem(StoreItem item) async {
    if (!_authProvider.isAuthenticated) return false;
    final userId = int.tryParse(_authProvider.currentUser!.id);
    if (userId == null) return false;

    // Optimistic update
    _purchasedItems = _purchasedItems.map((i) {
      if (i.id == item.id) {
        return i.copyWith(isEquipped: false);
      }
      return i;
    }).toList();

    final user = _authProvider.currentUser;
    if (user != null) {
      if (item.type == 'BANNER' && user.activeBannerId == item.id) {
        _authProvider.setCurrentUser(user.clearEquipment('BANNER'));
      } else if (item.type == 'TEXT_PHRASE' && user.activePhraseId == item.id) {
        final nextPhrase = equippedPhrases.where((i) => i.id != item.id).firstOrNull;
        _authProvider.setCurrentUser(user.copyWith(activePhraseId: nextPhrase?.id));
      } else if (item.type == 'AVATAR' && user.activeAvatarId == item.id) {
        _authProvider.setCurrentUser(user.clearEquipment('AVATAR'));
      } else if (item.type == 'PROFILE_FRAME' && user.activeFrameId == item.id) {
        _authProvider.setCurrentUser(user.clearEquipment('PROFILE_FRAME'));
      } else if ((item.type == 'EMOTE' || item.type == 'EMOJI') && user.activeEmoteId == item.id) {
        final nextEmote = equippedEmotes.where((i) => i.id != item.id).firstOrNull;
        _authProvider.setCurrentUser(user.copyWith(activeEmoteId: nextEmote?.id));
      }
    }

    _error = null;
    notifyListeners();

    try {
      await _storeService.unequipSpecificItem(userId, item.id);
      _purchasedItems = await _storeService.getPurchasedItems(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _purchasedItems = await _storeService.getPurchasedItems(userId);
      notifyListeners();
      return false;
    }
  }

  Future<bool> equipTitle(TitleModel title) async {
    if (!_authProvider.isAuthenticated) return false;
    final userId = int.tryParse(_authProvider.currentUser!.id);
    if (userId == null) return false;

    _setLoading(true);
    try {
      await _storeService.equipTitle(userId, title.id);
      final updatedUser = _authProvider.currentUser!.copyWith(activeTitleId: title.id);
      _authProvider.setCurrentUser(updatedUser);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> unequipTitle() async {
    if (!_authProvider.isAuthenticated) return false;
    final userId = int.tryParse(_authProvider.currentUser!.id);
    if (userId == null) return false;

    _setLoading(true);
    try {
      await _storeService.unequipTitle(userId);
      final updatedUser = _authProvider.currentUser!.clearEquipment('TITLE');
      _authProvider.setCurrentUser(updatedUser);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> unequipItem(String type) async {
    if (!_authProvider.isAuthenticated) return false;
    final userId = int.tryParse(_authProvider.currentUser!.id);
    if (userId == null) return false;

    _setLoading(true);
    try {
      await _storeService.unequipItem(userId, type);
      
      _purchasedItems = _purchasedItems.map((i) {
        if (i.type == type || (type == 'EMOTE' && i.type == 'EMOJI') || (type == 'EMOJI' && i.type == 'EMOTE')) {
          return i.copyWith(isEquipped: false);
        }
        return i;
      }).toList();

      final updatedUser = _authProvider.currentUser!.clearEquipment(type);
      _authProvider.setCurrentUser(updatedUser);
      
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Consome um item consumível (ENERGY_REFILL ou XP_BOOST).
  /// Remove o item do inventário e atualiza o estado local.
  Future<bool> consumeItem(String itemType) async {
    if (!_authProvider.isAuthenticated) return false;
    final userId = int.tryParse(_authProvider.currentUser!.id);
    if (userId == null) return false;

    _setLoading(true);
    try {
      await _storeService.consumeItem(userId, itemType);

      // Se for ENERGY_REFILL, atualiza a energia local (volta para 100)
      if (itemType == 'ENERGY_REFILL') {
        final updatedUser = _authProvider.currentUser!.copyWith(energy: 100);
        _authProvider.setCurrentUser(updatedUser);
      }

      // Atualizar inventário para remover o item consumido
      _purchasedItems = await _storeService.getPurchasedItems(userId);
      // Atualizar itens disponíveis para re-exibir o item (agora pode ser recomprado)
      final allAvailable = await _storeService.getAvailableItems(userId);
      _availableItems = allAvailable.where((item) => !_purchasedItems.any((p) => p.id == item.id)).toList();

      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
