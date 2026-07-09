import 'package:flutter_test/flutter_test.dart';
import 'package:quizmaster_pro/models/game_model.dart';

void main() {
  group('Lógica de Batalha em Duelo (Duel Mode)', () {
    test('Deve identificar corretamente o vencedor ou empate entre dois jogadores', () {
      
      // Função simulando a lógica de quiz_results_screen.dart para duelos
      Map<String, dynamic> evaluateDuel(List<LeaderboardEntry> leaderboard) {
        final player1 = leaderboard.isNotEmpty ? leaderboard[0] : null;
        final player2 = leaderboard.length > 1 ? leaderboard[1] : null;

        if (player1 == null) return {'winner': null, 'text': 'Sem jogadores'};

        if (player2 == null) {
          return {'winner': player1.username, 'text': 'Vencedor: ${player1.username}'};
        } else if (player1.score > player2.score) {
          return {'winner': player1.username, 'text': 'Vencedor: ${player1.username}!'};
        } else if (player2.score > player1.score) {
          return {'winner': player2.username, 'text': 'Vencedor: ${player2.username}!'};
        } else {
          return {'winner': 'Draw', 'text': 'Empate!'};
        }
      }

      // Cenário 1: Jogador 1 ganha
      final List<LeaderboardEntry> p1Wins = [
        LeaderboardEntry(userId: '1', username: 'Luz', fullName: 'Luz', score: 1500, position: 1, correctAnswers: 10, totalAnswers: 10, averageTime: 2.0),
        LeaderboardEntry(userId: '2', username: 'Goku', fullName: 'Goku', score: 1200, position: 2, correctAnswers: 8, totalAnswers: 10, averageTime: 2.5),
      ];
      final res1 = evaluateDuel(p1Wins);
      expect(res1['winner'], 'Luz');
      expect(res1['text'], 'Vencedor: Luz!');

      // Cenário 2: Jogador 2 ganha
      final List<LeaderboardEntry> p2Wins = [
        LeaderboardEntry(userId: '1', username: 'Luz', fullName: 'Luz', score: 1200, position: 2, correctAnswers: 8, totalAnswers: 10, averageTime: 2.5),
        LeaderboardEntry(userId: '2', username: 'Goku', fullName: 'Goku', score: 1800, position: 1, correctAnswers: 10, totalAnswers: 10, averageTime: 1.5),
      ];
      final res2 = evaluateDuel(p2Wins);
      expect(res2['winner'], 'Goku');
      expect(res2['text'], 'Vencedor: Goku!');

      // Cenário 3: Empate
      final List<LeaderboardEntry> draw = [
        LeaderboardEntry(userId: '1', username: 'Luz', fullName: 'Luz', score: 1500, position: 1, correctAnswers: 10, totalAnswers: 10, averageTime: 2.0),
        LeaderboardEntry(userId: '2', username: 'Goku', fullName: 'Goku', score: 1500, position: 1, correctAnswers: 10, totalAnswers: 10, averageTime: 2.0),
      ];
      final res3 = evaluateDuel(draw);
      expect(res3['winner'], 'Draw');
      expect(res3['text'], 'Empate!');

      // Cenário 4: Apenas um jogador na sala (Desistência do oponente)
      final List<LeaderboardEntry> solo = [
        LeaderboardEntry(userId: '1', username: 'Luz', fullName: 'Luz', score: 1500, position: 1, correctAnswers: 10, totalAnswers: 10, averageTime: 2.0),
      ];
      final res4 = evaluateDuel(solo);
      expect(res4['winner'], 'Luz');
      expect(res4['text'], 'Vencedor: Luz');
    });
  });
}
