import 'package:flutter/material.dart';
import '../services/solo_service.dart';
import 'auth_provider.dart';

class SoloProvider with ChangeNotifier {
  final SoloService _soloService;
  final AuthProvider _authProvider;

  SoloMapResponse? _mapData;
  bool _isLoadingMap = false;
  String? _error;

  SoloMapResponse? get mapData => _mapData;
  bool get isLoadingMap => _isLoadingMap;
  String? get error => _error;

  SoloProvider(this._soloService, this._authProvider);

  Future<void> fetchMapProgress() async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;

    _isLoadingMap = true;
    _error = null;
    notifyListeners();

    try {
      _mapData = await _soloService.getMapProgress(int.parse(userId));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMap = false;
      notifyListeners();
    }
  }

  Future<SoloStartLevelResponse?> startLevel(int levelNumber) async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return null;

    try {
      return await _soloService.startLevel(int.parse(userId), levelNumber);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<SoloFinishLevelResponse?> finishLevel({
    required int levelNumber,
    required int playerScore,
    required int botScore,
    required int correctCount,
    required int totalQuestions,
    required List<Map<String, dynamic>> answeredQuestions,
  }) async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _soloService.finishLevel(
        userId: int.parse(userId),
        levelNumber: levelNumber,
        playerScore: playerScore,
        botScore: botScore,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        answeredQuestions: answeredQuestions,
      );

      // Recarregar o mapa para refletir alterações de progresso/estrelas/vidas
      try {
        await fetchMapProgress();
      } catch (e) {
        debugPrint('Erro ao atualizar mapa no finishLevel: $e');
      }

      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
