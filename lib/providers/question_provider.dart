import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';

class QuestionProvider extends ChangeNotifier {
  final QuestionService _service;
  QuestionProvider(this._service);

  final Map<String, List<QuestionData>> _cache = {}; // chave: gameId|category
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  String _key(String gameId, String category, String? userId) => '$gameId|$category|${userId ?? ''}';

  /// Retorna questões em cache (pode ser vazia)
  List<QuestionData> getQuestions(String gameId, String category, String? userId) {
    final key = _key(gameId, category, userId);
    return _cache[key] ?? [];
  }

  /// Busca a pergunta atual para este jogador (backend fornece current-question por jogador)
  Future<List<QuestionData>> fetchQuestions(String gameId, String category, String? userId) async {
    final key = _key(gameId, category, userId);
    if (_loading[key] == true) return _cache[key] ?? [];
    _loading[key] = true;
    _errors[key] = null;
    notifyListeners();

    try {
      if (userId == null || userId.isEmpty) {
        throw Exception('UserId ausente para fetchQuestions');
      }
      final gid = int.tryParse(gameId);
      final uid = int.tryParse(userId);
      if (gid == null || uid == null) {
        throw Exception('IDs inválidos para fetchQuestions');
      }

      final resp = await _service.getCurrentQuestionForPlayer(gid, uid);
      final q = QuestionData.fromJson(resp);
      _cache[key] = [q];
      return _cache[key]!;
    } catch (e) {
      _errors[key] = e.toString();
      return _cache[key] ?? [];
    } finally {
      _loading[key] = false;
      notifyListeners();
    }
  }



  void clearGame(String gameId) {
    _cache.removeWhere((k, v) => k.startsWith('$gameId|'));
    _loading.removeWhere((k, v) => k.startsWith('$gameId|'));
    _errors.removeWhere((k, v) => k.startsWith('$gameId|'));
    notifyListeners();
  }
}
