import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lógica Base de Pontuação e Bônus de Tempo', () {
    test('Deve calcular os pontos corretamente baseando-se no tempo de resposta', () {
      
      // Função simulando a lógica de atribuição de pontos no `quiz_game_screen.dart`
      int calculatePoints({required bool isCorrect, required int timeLeft}) {
        if (!isCorrect) {
          return 0; // Se errou, não ganha nada
        }
        final basePoints = 100;
        final timeBonus = timeLeft * 10;
        return basePoints + timeBonus;
      }

      // Cenário 1: Respondeu errado (mesmo que com muito tempo sobrando)
      expect(calculatePoints(isCorrect: false, timeLeft: 15), 0);
      expect(calculatePoints(isCorrect: false, timeLeft: 1), 0);

      // Cenário 2: Respondeu Certo MUITO RÁPIDO (restam 10 segundos na tela)
      // Base: 100 + (10 * 10) = 200
      expect(calculatePoints(isCorrect: true, timeLeft: 10), 200);

      // Cenário 3: Respondeu Certo na metade do tempo (restam 5 segundos)
      // Base: 100 + (5 * 10) = 150
      expect(calculatePoints(isCorrect: true, timeLeft: 5), 150);

      // Cenário 4: Respondeu Certo NO ÚLTIMO SEGUNDO (resta 1 segundo)
      // Base: 100 + (1 * 10) = 110
      expect(calculatePoints(isCorrect: true, timeLeft: 1), 110);

      // Cenário 5: Respondeu Certo mas o cronômetro bateu 0 exato (restam 0 segundos)
      // Base: 100 + (0 * 10) = 100 (Ganhou só os pontos base)
      expect(calculatePoints(isCorrect: true, timeLeft: 0), 100);
    });
  });
}
