import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/question_model.dart';

class QuestionService {
  final ApiService _api;
  QuestionService(this._api);


  /// Busca a pergunta atual para um jogador específico dentro de um jogo.
  /// Retorna o JSON decodificado como Map para inspeção ou processamento.
  Future<Map<String, dynamic>> getCurrentQuestionForPlayer(int gameId, int userId) async {
    final path = '/api/games/$gameId/players/$userId/current-question';
    if (kDebugMode) print('DEBUG QuestionService: GET $path');
    try {
      final resp = await _api.get(path);
      if (kDebugMode) print('DEBUG QuestionService: current-question response: $resp');
      return Map<String, dynamic>.from(resp);
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG QuestionService: erro ao buscar current-question -> $e');
      }
      rethrow;
    }
  }
}
