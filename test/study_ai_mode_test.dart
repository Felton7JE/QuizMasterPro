import 'package:flutter_test/flutter_test.dart';
import 'package:quizmaster_pro/models/study_quiz_model.dart';
import 'package:quizmaster_pro/services/study_quiz_service.dart';

void main() {
  group('Study AI Mode Model & Service Tests', () {
    test('CustomStudyQuestion and StudyFlashcard serialization works', () {
      const question = CustomStudyQuestion(
        id: 'q_1',
        questionText: 'Qual a função da mitocôndria?',
        options: ['Produzir ATP', 'Sintetizar lipídios', 'Digestão celular', 'Armazenar DNA'],
        correctAnswer: 0,
        explanation: 'A mitocôndria é a usina de energia da célula, responsável pela respiração celular.',
        hint: 'Pense em energia celular e ATP.',
        topic: 'Biologia',
        difficulty: 'MÉDIO',
      );

      const flashcard = StudyFlashcard(
        id: 'fc_1',
        front: 'O que é Mitocôndria?',
        back: 'Organela celular responsável pela produção de energia (ATP).',
        topic: 'Biologia',
      );

      final quiz = CustomStudyQuiz(
        id: 'quiz_test_1',
        title: 'Quiz de Biologia Celular',
        description: 'Gerado a partir do PDF de Citologia',
        sourceType: 'PDF',
        sourceFileName: 'citologia.pdf',
        createdAt: DateTime.now(),
        questionCount: 1,
        questions: [question],
        flashcards: [flashcard],
        summaryBullets: ['Mitocôndrias produzem ATP', 'DNA mitocondrial é materno'],
        bestScore: 100,
        isShared: true,
        shareCode: 'STUDY-12345',
      );

      final jsonMap = quiz.toJson();
      final reconstructed = CustomStudyQuiz.fromJson(jsonMap);

      expect(reconstructed.id, equals('quiz_test_1'));
      expect(reconstructed.title, equals('Quiz de Biologia Celular'));
      expect(reconstructed.sourceType, equals('PDF'));
      expect(reconstructed.sourceFileName, equals('citologia.pdf'));
      expect(reconstructed.questions.length, equals(1));
      expect(reconstructed.questions.first.questionText, equals('Qual a função da mitocôndria?'));
      expect(reconstructed.questions.first.correctAnswer, equals(0));
      expect(reconstructed.flashcards.length, equals(1));
      expect(reconstructed.flashcards.first.front, equals('O que é Mitocôndria?'));
      expect(reconstructed.summaryBullets.length, equals(2));
      expect(reconstructed.shareCode, equals('STUDY-12345'));
    });

    test('Local Smart Generator creates questions, flashcards and summary', () async {
      final service = StudyQuizService();
      final quiz = await service.generateQuiz(
        title: 'Quiz de História',
        content: 'A Revolução Francesa iniciou-se em 1789 com a Queda da Bastilha. O lema central foi Liberdade, Igualdade e Fraternidade.',
        questionCount: 5,
        difficulty: 'MÉDIO',
        topic: 'História',
      );

      expect(quiz.title, contains('História'));
      expect(quiz.questions.isNotEmpty, isTrue);
      expect(quiz.flashcards.isNotEmpty, isTrue);
      expect(quiz.summaryBullets.isNotEmpty, isTrue);
      expect(quiz.shareCode, isNotNull);
      expect(quiz.shareCode!.startsWith('STUDY-'), isTrue);
    });
  });
}
