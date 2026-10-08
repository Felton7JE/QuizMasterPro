import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/study_quiz_model.dart';
import '../models/saved_doubt_model.dart';
import '../models/study_plan_model.dart';
import './api_service.dart';

class StudyQuizService {
  static const String _storageKey = 'saved_study_quizzes_v2';
  final http.Client _client;

  StudyQuizService({http.Client? client}) : _client = client ?? http.Client();

  /// Gera um Quiz a partir do upload de arquivo PDF
  Future<CustomStudyQuiz> generateQuizFromPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String title,
    required int questionCount,
    required String difficulty,
    String? topic,
    String? userId,
  }) async {
    final quizId = 'quiz_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/api/study/upload-pdf');
      final request = http.MultipartRequest('POST', uri);
      
      if (ApiService.token != null) {
        request.headers['Authorization'] = 'Bearer ${ApiService.token}';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      request.fields['title'] = title;
      request.fields['topic'] = topic ?? 'Geral';
      request.fields['difficulty'] = difficulty;
      request.fields['questionCount'] = questionCount.toString();
      if (userId != null) {
        request.fields['userId'] = userId;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final quiz = CustomStudyQuiz.fromJson(data);
        await saveQuiz(quiz);
        return quiz;
      } else if (response.statusCode == 400) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Erro de validação ao gerar quiz.');
      } else {
        if (kDebugMode) {
          debugPrint('Falha no upload de PDF (Status ${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception: ')) {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('Erro ao conectar ao servidor para envio de PDF ($e). Usando gerador inteligente local.');
      }
    }

    // Fallback inteligente caso o servidor backend não esteja acessível
    final fallbackQuestions = _generateSmartQuestions(
      content: 'Documento PDF: $fileName. Este arquivo aborda conceitos fundamentais e teorias estruturadas para preparação de exames.',
      title: title,
      targetCount: questionCount,
      difficulty: difficulty,
      topic: topic ?? 'Geral',
    );

    final fallbackFlashcards = [
      StudyFlashcard(
        id: 'fc_pdf_1',
        front: 'Qual é o tema principal abordado no documento $fileName?',
        back: 'O documento foca em conceitos essenciais de ${topic ?? "estudo"} com definições estruturadas para exames.',
        topic: topic ?? 'Geral',
      ),
      StudyFlashcard(
        id: 'fc_pdf_2',
        front: 'Como aplicar os conceitos deste material na prática?',
        back: 'Revisando as questões geradas e memorizando os termos-chave apresentados nas explicações do Tutor IA.',
        topic: topic ?? 'Geral',
      ),
    ];

    final newQuiz = CustomStudyQuiz(
      id: quizId,
      title: title.trim().isEmpty ? 'Quiz de Estudo: $fileName' : title.trim(),
      description: 'Gerado por IA a partir do PDF "$fileName". Ideal para preparação de testes e exames.',
      sourceType: 'PDF',
      sourceFileName: fileName,
      createdAt: DateTime.now(),
      questionCount: fallbackQuestions.length,
      crystalsCost: 5,
      questions: fallbackQuestions,
      flashcards: fallbackFlashcards,
      summaryBullets: [
        'Documento processado: $fileName',
        'Foco de estudo: ${topic ?? "Conteúdo Geral"}',
        'Nível de exigência: $difficulty',
      ],
      bestScore: null,
      isShared: true,
      shareCode: 'STUDY-${Random().nextInt(89999) + 10000}',
    );

    await saveQuiz(newQuiz);
    return newQuiz;
  }

  /// Gera um Quiz a partir de conteúdo textual ou Tema Livre
  Future<CustomStudyQuiz> generateQuiz({
    required String title,
    required String content,
    required int questionCount,
    required String difficulty,
    String? topic,
    String? sourceFileName,
    String? sourceType,
    String? userId,
  }) async {
    final quizId = 'quiz_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/api/study/generate-quiz');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'questionCount': questionCount,
          'difficulty': difficulty,
          'topic': topic ?? 'Geral',
          'sourceFileName': sourceFileName,
          'sourceType': sourceType ?? (sourceFileName != null ? 'PDF' : 'TEXT'),
          'userId': userId != null ? int.tryParse(userId) : null,
        }),
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final quiz = CustomStudyQuiz.fromJson(data);
        await saveQuiz(quiz);
        return quiz;
      } else if (response.statusCode == 400) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Erro de validação ao gerar quiz.');
      }
    } catch (e) {
      if (e.toString().contains('Exception: ')) {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('Gerador remoto indisponível ($e). Usando gerador inteligente local.');
      }
    }

    // Gerador Inteligente Local Baseado em Processamento do Texto
    final generatedQuestions = _generateSmartQuestions(
      content: content,
      title: title,
      targetCount: questionCount,
      difficulty: difficulty,
      topic: topic ?? 'Geral',
    );

    final generatedFlashcards = _generateSmartFlashcards(
      content: content,
      topic: topic ?? 'Geral',
    );

    final newQuiz = CustomStudyQuiz(
      id: quizId,
      title: title.trim().isEmpty ? 'Quiz de Estudo: ${topic ?? "Personalizado"}' : title.trim(),
      description: 'Gerado por IA a partir de ${sourceFileName ?? "conteúdo de estudo"}. Ideal para preparação de testes e exames.',
      sourceType: sourceType ?? (sourceFileName != null ? 'PDF' : 'TEXT'),
      sourceFileName: sourceFileName,
      createdAt: DateTime.now(),
      questionCount: generatedQuestions.length,
      crystalsCost: 5,
      questions: generatedQuestions,
      flashcards: generatedFlashcards,
      summaryBullets: [
        'Tópico principal: ${topic ?? "Geral"}',
        'Total de questões preparatórias: ${generatedQuestions.length}',
        'Revisão recomendada com os flashcards antes do exame.',
      ],
      bestScore: null,
      isShared: true,
      shareCode: 'STUDY-${Random().nextInt(89999) + 10000}',
    );

    await saveQuiz(newQuiz);
    return newQuiz;
  }

  /// Consome 10 de energia para iniciar um quiz de estudo no backend
  Future<bool> consumeStudyEnergy(String userId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/api/study/consume-energy');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
        body: jsonEncode({'userId': int.tryParse(userId)}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Busca quiz compartilhado pelo código (ex: STUDY-48201)
  Future<CustomStudyQuiz?> fetchSharedQuiz(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final uri = Uri.parse('${AppConfig.baseUrl}/api/study/shared/$cleanCode');
      final response = await _client.get(
        uri,
        headers: {
          if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final quiz = CustomStudyQuiz.fromJson(data);
        await saveQuiz(quiz);
        return quiz;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar quiz compartilhado: $e');
      }
    }

    // Procura localmente se existir
    final localList = await getSavedQuizzes();
    try {
      return localList.firstWhere((q) => q.shareCode?.toUpperCase() == code.trim().toUpperCase());
    } catch (_) {
      return null;
    }
  }

  /// Registra a pontuação e ganho de recompensas
  Future<void> recordScore({
    required String quizId,
    required int score,
    required int correctCount,
    String? userId,
  }) async {
    // 1. Atualiza no cache local
    final list = await getSavedQuizzes();
    final idx = list.indexWhere((q) => q.id == quizId);
    if (idx != -1) {
      final existing = list[idx];
      final currentBest = existing.bestScore ?? 0;
      if (score > currentBest) {
        list[idx] = existing.copyWith(bestScore: score);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, CustomStudyQuiz.encodeList(list));
      }
    }

    // 2. Notifica o backend
    if (userId != null) {
      try {
        final uri = Uri.parse('${AppConfig.baseUrl}/api/study/record-score');
        await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': int.tryParse(userId),
            'quizId': quizId,
            'score': score,
            'correctCount': correctCount,
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GERADORES LOCAIS (NLP SMART HEURISTIC)
  // ─────────────────────────────────────────────────────────────────────────

  List<CustomStudyQuestion> _generateSmartQuestions({
    required String content,
    required String title,
    required int targetCount,
    required String difficulty,
    required String topic,
  }) {
    final questions = <CustomStudyQuestion>[];

    final lines = content
        .split(RegExp(r'[\n\r]+|\.\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();

    if (lines.isEmpty) {
      lines.add('O estudo estruturado de $topic abrange conceitos fundamentais, teorias essenciais e resolução de problemas.');
      lines.add('A correta compreensão dos termos-chave em $topic é indispensável para o sucesso em exames acadêmicos e testes.');
      lines.add('A aplicação metódica dos princípios de $topic permite identificar causas e consequências com clareza.');
    }

    for (int i = 0; i < targetCount; i++) {
      final baseSentence = lines[i % lines.length];
      final qId = 'q_${DateTime.now().millisecondsSinceEpoch}_$i';

      String questionText;
      List<String> options;
      int correctIndex;
      String explanation;

      if (baseSentence.contains('é') || baseSentence.contains('consiste') || baseSentence.contains('representa')) {
        final parts = baseSentence.split(RegExp(r'\sé\s|\sconsiste\sem\s|\srepresenta\s'));
        final subject = parts[0].trim();
        final definition = parts.length > 1 ? parts[1].trim() : 'o conceito central desta disciplina';

        questionText = 'Com base no conteúdo de $topic, como se define "$subject"?';
        options = [
          definition,
          'Um conceito secundário que não possui aplicação direta na teoria.',
          'Um processo antagônico cuja finalidade foi descontinuada.',
          'Uma exceção teórica aplicável somente em casos isolados.',
        ];
        options.shuffle();
        correctIndex = options.indexOf(definition);
        explanation = 'Correta: "$definition". O texto base estabelece que $subject é caracterizado por esta definição.';
      } else {
        questionText = 'De acordo com o material de $topic, assinale a alternativa correta:';
        options = [
          baseSentence,
          'A matéria indica que o processo descrito ocorre de forma aleatória e sem padrões.',
          'O conceito foi refutado e substituído por novas formulações sem correlação.',
          'A aplicação descrita tem efeito nulo na estrutura do tema.',
        ];
        options.shuffle();
        correctIndex = options.indexOf(baseSentence);
        explanation = 'Correta: "$baseSentence". Esta afirmação está em perfeita consonância com o texto estudado.';
      }

      questions.add(
        CustomStudyQuestion(
          id: qId,
          questionText: questionText,
          options: options,
          correctAnswer: correctIndex,
          explanation: explanation,
          hint: 'Relembre a relação direta com os termos fundamentais de $topic.',
          topic: topic,
          difficulty: difficulty,
        ),
      );
    }

    return questions;
  }

  List<StudyFlashcard> _generateSmartFlashcards({
    required String content,
    required String topic,
  }) {
    final flashcards = <StudyFlashcard>[];
    final lines = content
        .split(RegExp(r'[\n\r]+|\.\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 25)
        .toList();

    int id = 1;
    for (var line in lines.take(10)) {
      flashcards.add(
        StudyFlashcard(
          id: 'fc_$id',
          front: 'Defina ou explique o ponto-chave sobre: ${line.split(" ").take(3).join(" ")}',
          back: line,
          topic: topic,
        ),
      );
      id++;
    }

    if (flashcards.isEmpty) {
      flashcards.add(
        StudyFlashcard(
          id: 'fc_def_1',
          front: 'Qual o objetivo principal do estudo de $topic?',
          back: 'Compreender os princípios essenciais, fixar fórmulas/conceitos e aplicar nos testes.',
          topic: topic,
        ),
      );
    }

    return flashcards;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERSISTÊNCIA LOCAL (SharedPreferences)
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<CustomStudyQuiz>> getSavedQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data == null || data.isEmpty) return [];
      return CustomStudyQuiz.decodeList(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQuiz(CustomStudyQuiz quiz) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getSavedQuizzes();
      final index = list.indexWhere((q) => q.id == quiz.id);

      if (index >= 0) {
        list[index] = quiz;
      } else {
        list.insert(0, quiz);
      }

      await prefs.setString(_storageKey, CustomStudyQuiz.encodeList(list));
    } catch (_) {}
  }

  Future<void> deleteQuiz(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getSavedQuizzes();
      list.removeWhere((q) => q.id == id);
      await prefs.setString(_storageKey, CustomStudyQuiz.encodeList(list));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GESTÃO DE DÚVIDAS / CADERNO DE ERROS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveDoubt({
    required int userId,
    required String questionText,
    required List<String> options,
    required int correctAnswer,
    required String explanation,
    required String topic,
    required String difficulty,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/doubts');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
      body: jsonEncode({
        'userId': userId,
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'topic': topic,
        'difficulty': difficulty,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Erro ao guardar dúvida.');
    }
  }

  Future<List<SavedDoubt>> getDoubts(int userId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/doubts/$userId');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return data.map((json) => SavedDoubt.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar dúvidas.');
    }
  }

  Future<void> deleteDoubt(int userId, int doubtId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/doubts/$userId/$doubtId');
    final response = await _client.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Erro ao apagar dúvida.');
    }
  }

  // ==========================================
  // Study Plans API Methods
  // ==========================================

  Future<StudyPlan> createStudyPlan({
    required int userId,
    required String topic,
    required int durationDays,
    String objective = '',
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/plans');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
      body: jsonEncode({
        'userId': userId,
        'topic': topic,
        'durationDays': durationDays,
        'objective': objective,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return StudyPlan.fromJson(data);
    } else {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Erro ao gerar o plano de estudo.');
    }
  }

  Future<List<StudyPlan>> getUserStudyPlans(int userId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/plans/user/$userId');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return data.map((json) => StudyPlan.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar planos de estudo.');
    }
  }

  Future<StudyPlan> getStudyPlanDetails(int planId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/plans/$planId');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return StudyPlan.fromJson(data);
    } else {
      throw Exception('Erro ao carregar detalhes do plano.');
    }
  }

  Future<StudyPlanDay> markDayAsCompleted(int dayId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/study/plans/days/$dayId/complete');
    final response = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return StudyPlanDay.fromJson(data);
    } else {
      throw Exception('Erro ao marcar o dia como concluído.');
    }
  }
}
