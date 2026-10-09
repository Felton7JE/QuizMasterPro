import 'package:flutter/foundation.dart';
import '../../models/study_quiz_model.dart';
import '../../models/user_model.dart';
import '../../services/study_quiz_service.dart';
import '../core/auth_provider.dart';

class StudyQuizProvider with ChangeNotifier {
  final StudyQuizService _service;
  
  List<CustomStudyQuiz> _quizzes = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  static const int generationCostCrystals = 5;

  StudyQuizProvider({StudyQuizService? service})
      : _service = service ?? StudyQuizService() {
    loadQuizzes();
  }

  List<CustomStudyQuiz> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  /// Retorna o limite máximo de quizzes por dia conforme VIP (10) ou Free (5)
  int getMaxDailyQuizzes(UserModel? user) {
    if (user == null) return 5;
    return user.isVip ? 10 : 5;
  }

  /// Retorna os quizzes gerados hoje
  int getDailyQuizzesUsed(UserModel? user) {
    if (user == null) return 0;
    return user.dailyAiQuizCount;
  }

  /// Verifica se atingiu o limite diário
  bool hasReachedDailyLimit(UserModel? user) {
    if (user == null) return false;
    return user.dailyAiQuizCount >= getMaxDailyQuizzes(user);
  }

  /// Tempo de cooldown obrigatório em segundos (180s = 3 min VIP / 360s = 6 min Free)
  int getCooldownSecondsRequired(UserModel? user) {
    if (user == null) return 360;
    return user.isVip ? 180 : 360;
  }

  /// Segundos restantes de cooldown (0 se livre)
  int getRemainingSecondsCooldown(UserModel? user) {
    if (user == null || user.lastAiQuizTimestamp == null) return 0;
    final cooldownRequired = getCooldownSecondsRequired(user);
    final elapsedSeconds = DateTime.now().difference(user.lastAiQuizTimestamp!).inSeconds;
    final remaining = cooldownRequired - elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica se o cooldown está ativo
  bool isCooldownActive(UserModel? user) {
    return getRemainingSecondsCooldown(user) > 0;
  }

  /// Formata os segundos de cooldown em MM:SS
  String formatCooldownTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Retorna o tempo restante de cooldown formatado em MM:SS (ex: "02:45")
  String getFormattedCooldown(UserModel? user) {
    return formatCooldownTime(getRemainingSecondsCooldown(user));
  }

  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _quizzes = await _service.getSavedQuizzes();
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar quizzes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gera um novo quiz a partir do upload de arquivo PDF
  Future<CustomStudyQuiz?> generateQuizFromPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String title,
    required int questionCount,
    required String difficulty,
    String? topic,
    required AuthProvider authProvider,
  }) async {
    final user = authProvider.currentUser;
    if (user == null) {
      _error = 'Tens de ter sessão iniciada para gerar quizzes com IA.';
      notifyListeners();
      return null;
    }

    final isVip = user.isVip;

    // 1. Verificação de Limite Diário (Free 5 / VIP 10)
    if (hasReachedDailyLimit(user)) {
      _error = 'Atingiste o teu limite diário de ${getMaxDailyQuizzes(user)} quizzes de IA para hoje. O contador zera à meia-noite (00:00).';
      notifyListeners();
      return null;
    }

    // 2. Verificação de Cooldown (Free 6 min / VIP 3 min)
    final remainingCooldown = getRemainingSecondsCooldown(user);
    if (remainingCooldown > 0) {
      _error = 'Intervalo de segurança ativo! Aguarda ${formatCooldownTime(remainingCooldown)} min para gerar o próximo quiz.';
      notifyListeners();
      return null;
    }

    // 3. Verificação de Cristais (Free: 5 cristais / VIP: Grátis 0 cristais)
    if (!isVip && user.crystals < generationCostCrystals) {
      _error = 'Contas gratuitas necessitam de $generationCostCrystals Cristais 🔮 por quiz gerado. Adquire cristais ou assina o Passe VIP!';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final quiz = await _service.generateQuizFromPdf(
        fileBytes: fileBytes,
        fileName: fileName,
        title: title,
        questionCount: questionCount,
        difficulty: difficulty,
        topic: topic,
        userId: user.id,
      );

      // Atualiza os dados do usuário para sincronizar cristais e contadores de IA
      await authProvider.refreshUser();
      await loadQuizzes();
      return quiz;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Gera um novo quiz com IA por Tema Livre ou Texto colado
  Future<CustomStudyQuiz?> generateQuiz({
    required String title,
    required String content,
    required int questionCount,
    required String difficulty,
    String? topic,
    String? sourceFileName,
    required AuthProvider authProvider,
  }) async {
    final user = authProvider.currentUser;
    if (user == null) {
      _error = 'Tens de ter sessão iniciada para gerar quizzes com IA.';
      notifyListeners();
      return null;
    }

    final isVip = user.isVip;

    // 1. Verificação de Limite Diário (Free 5 / VIP 10)
    if (hasReachedDailyLimit(user)) {
      _error = 'Atingiste o teu limite diário de ${getMaxDailyQuizzes(user)} quizzes de IA para hoje. O contador zera à meia-noite (00:00).';
      notifyListeners();
      return null;
    }

    // 2. Verificação de Cooldown (Free 6 min / VIP 3 min)
    final remainingCooldown = getRemainingSecondsCooldown(user);
    if (remainingCooldown > 0) {
      _error = 'Intervalo de segurança ativo! Aguarda ${formatCooldownTime(remainingCooldown)} min para gerar o próximo quiz.';
      notifyListeners();
      return null;
    }

    // 3. Verificação de Cristais (Free: 5 cristais / VIP: Grátis 0 cristais)
    if (!isVip && user.crystals < generationCostCrystals) {
      _error = 'Contas gratuitas necessitam de $generationCostCrystals Cristais 🔮 por quiz gerado. Adquire cristais ou assina o Passe VIP!';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final quiz = await _service.generateQuiz(
        title: title,
        content: content,
        questionCount: questionCount,
        difficulty: difficulty,
        topic: topic,
        sourceFileName: sourceFileName,
        userId: user.id,
      );

      // Atualiza os dados do usuário para sincronizar cristais e contadores de IA
      await authProvider.refreshUser();
      await loadQuizzes();
      return quiz;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Consome 10 de energia ao iniciar uma sessão de estudo e atualiza o estado local
  Future<bool> consumeEnergy(AuthProvider authProvider) async {
    final user = authProvider.currentUser;
    if (user == null) return false;
    if (user.energy < 10) return false;

    final success = await _service.consumeStudyEnergy(user.id);
    if (success) {
      await authProvider.refreshUser();
      return true;
    }
    return false;
  }

  /// Importa um Quiz compartilhado por outro aluno usando o código STUDY-XXXXX
  Future<CustomStudyQuiz?> importSharedQuiz(String shareCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final quiz = await _service.fetchSharedQuiz(shareCode);
      if (quiz == null) {
        _error = 'Nenhum quiz encontrado para o código $shareCode.';
        return null;
      }
      await loadQuizzes();
      return quiz;
    } catch (e) {
      _error = 'Erro ao buscar quiz: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Regista pontuação obtida pelo jogador no modo solo de estudo
  Future<void> recordScore({
    required String quizId,
    required int score,
    required int correctCount,
    String? userId,
  }) async {
    await _service.recordScore(
      quizId: quizId,
      score: score,
      correctCount: correctCount,
      userId: userId,
    );
    await loadQuizzes();
  }

  /// Alterna estado de fixação do flashcard
  Future<void> toggleFlashcardMastered(String quizId, String cardId) async {
    final quizIdx = _quizzes.indexWhere((q) => q.id == quizId);
    if (quizIdx == -1) return;

    final quiz = _quizzes[quizIdx];
    final updatedFlashcards = quiz.flashcards.map((f) {
      if (f.id == cardId) {
        return f.copyWith(isMastered: !f.isMastered);
      }
      return f;
    }).toList();

    final updatedQuiz = quiz.copyWith(flashcards: updatedFlashcards);
    _quizzes[quizIdx] = updatedQuiz;
    await _service.saveQuiz(updatedQuiz);
    notifyListeners();
  }

  /// Apaga um quiz de estudo
  Future<void> deleteQuiz(String quizId) async {
    await _service.deleteQuiz(quizId);
    await loadQuizzes();
  }
}
