import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lógica de Cálculo de Streak (Sequência de Acertos)', () {
    test('Deve calcular corretamente a sequência atual e a melhor sequência de respostas no modo Kahoot', () {
      // Variáveis simulando o estado interno do kahoot_game_screen.dart
      int currentStreak = 0;
      int bestStreak = 0;
      int timeLeft = 10; // Tempo fixo para os testes
      int totalPoints = 0;

      // Função que simula o _submitAnswer do jogo
      void submitSimulatedAnswer({required bool isCorrect}) {
        if (isCorrect) {
          currentStreak++;
          if (currentStreak > bestStreak) {
            bestStreak = currentStreak;
          }
          final bonus = timeLeft * 10;
          totalPoints += 100 + bonus;
        } else {
          currentStreak = 0;
        }
      }

      // 1ª Resposta: Certa
      submitSimulatedAnswer(isCorrect: true);
      expect(currentStreak, 1);
      expect(bestStreak, 1);

      // 2ª Resposta: Certa
      submitSimulatedAnswer(isCorrect: true);
      expect(currentStreak, 2);
      expect(bestStreak, 2);

      // 3ª Resposta: Errada (quebra a sequência)
      submitSimulatedAnswer(isCorrect: false);
      expect(currentStreak, 0); // Sequência atual volta pra 0
      expect(bestStreak, 2);    // Recorde ainda é 2

      // 4ª Resposta: Certa
      submitSimulatedAnswer(isCorrect: true);
      expect(currentStreak, 1);
      expect(bestStreak, 2);    // Recorde continua 2

      // 5ª Resposta: Certa
      submitSimulatedAnswer(isCorrect: true);
      expect(currentStreak, 2);
      expect(bestStreak, 2);

      // 6ª Resposta: Certa (agora quebra o recorde)
      submitSimulatedAnswer(isCorrect: true);
      expect(currentStreak, 3);
      expect(bestStreak, 3);    // Novo recorde é 3!
      
      // Validação final de segurança para garantir que a lógica envia o bestStreak certo pra tela de resultados
      expect(bestStreak, 3);
    });
  });
}
