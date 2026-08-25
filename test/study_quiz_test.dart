import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizmaster_pro/models/study_quiz_model.dart';
import 'package:quizmaster_pro/services/study_quiz_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CustomStudyQuiz Model Tests', () {
    test('Deve serializar e deserializar um CustomStudyQuiz com sucesso', () {
      final quiz = CustomStudyQuiz(
        id: 'quiz_test_1',
        title: 'História de Portugal e Navegações',
        description: 'Conteúdo de estudo sobre as rotas marítimas...',
        sourceType: 'TEXT',
        createdAt: DateTime.parse('2026-08-04T12:00:00Z'),
        questionCount: 2,
        crystalsCost: 5,
        isShared: false,
        questions: [
          const CustomStudyQuestion(
            id: 'q1',
            questionText: 'Em que ano chegou Vasco da Gama à Índia?',
            options: ['1498', '1500', '1492', '1512'],
            correctAnswer: 0,
            explanation: 'Vasco da Gama alcançou Calecute na Índia em maio de 1498.',
            topic: 'Navegações Portuguesas',
          ),
          const CustomStudyQuestion(
            id: 'q2',
            questionText: 'Quem comandou a esquadra que chegou ao Brasil em 1500?',
            options: ['Pedro Álvares Cabral', 'Infante D. Henrique', 'Afonso de Albuquerque', 'Bartolomeu Dias'],
            correctAnswer: 0,
            explanation: 'Pedro Álvares Cabral chegou ao litoral brasileiro em 22 de abril de 1500.',
            topic: 'Descobertas',
          ),
        ],
      );

      final json = quiz.toJson();
      final recovered = CustomStudyQuiz.fromJson(json);

      expect(recovered.id, quiz.id);
      expect(recovered.title, quiz.title);
      expect(recovered.sourceType, 'TEXT');
      expect(recovered.questions.length, 2);
      expect(recovered.questions.first.questionText, 'Em que ano chegou Vasco da Gama à Índia?');
      expect(recovered.questions.first.correctAnswer, 0);
      expect(recovered.questions.first.explanation, contains('1498'));
      expect(recovered.crystalsCost, 5);
    });

    test('StudyQuizService deve gerar perguntas estruturadas a partir de texto', () async {
      final service = StudyQuizService();
      final quiz = await service.generateQuiz(
        title: 'Biologia Celular',
        content: 'A mitocôndria é a organela responsável pela respiração celular e produção de ATP. '
            'O núcleo armazena o DNA da célula. O ribossomo é responsável pela síntese de proteínas.',
        questionCount: 3,
        difficulty: 'MÉDIO',
      );

      expect(quiz.title, 'Biologia Celular');
      expect(quiz.questions.isNotEmpty, true);
      expect(quiz.crystalsCost, 5);
      for (final q in quiz.questions) {
        expect(q.options.length, 4);
        expect(q.correctAnswer, inInclusiveRange(0, 3));
        expect(q.explanation.isNotEmpty, true);
      }
    });
  });
}
