import 'package:flutter_test/flutter_test.dart';
import 'package:quizmaster_pro/models/game_model.dart';
import 'package:quizmaster_pro/models/room_model.dart';

void main() {
  group('Lógica de Batalha de Equipas (Team Scoreboard)', () {
    test('Deve calcular corretamente a pontuação total e o MVP de cada equipa', () {
      // 1. Preparar os dados falsos (Mock Data)
      final List<LeaderboardEntry> mockLeaderboard = [
        LeaderboardEntry(
          userId: '1',
          username: 'luz1',
          fullName: 'Luz One',
          team: TeamColor.RED,
          score: 500,
          correctAnswers: 5,
          totalAnswers: 5,
          averageTime: 2.0,
          position: 1,
        ),
        LeaderboardEntry(
          userId: '2',
          username: 'luz2',
          fullName: 'Luz Two',
          team: TeamColor.RED,
          score: 300,
          correctAnswers: 3,
          totalAnswers: 5,
          averageTime: 3.5,
          position: 3,
        ),
        LeaderboardEntry(
          userId: '3',
          username: 'luz3',
          fullName: 'Luz Three',
          team: TeamColor.BLUE,
          score: 600,
          correctAnswers: 6,
          totalAnswers: 6,
          averageTime: 1.5,
          position: 2,
        ),
        LeaderboardEntry(
          userId: '4',
          username: 'luz4',
          fullName: 'Luz Four',
          team: TeamColor.BLUE,
          score: 100, // luz3 carregou a equipa azul!
          correctAnswers: 1,
          totalAnswers: 6,
          averageTime: 5.0,
          position: 4,
        ),
      ];

      // 2. Executar a lógica que está no quiz_results_screen.dart
      Map<TeamColor, int> teamScores = {};
      Map<TeamColor, LeaderboardEntry> teamMVPs = {};

      for (var entry in mockLeaderboard) {
        if (entry.team != null) {
          teamScores[entry.team!] = (teamScores[entry.team!] ?? 0) + entry.score;

          if (!teamMVPs.containsKey(entry.team!) || entry.score > teamMVPs[entry.team!]!.score) {
            teamMVPs[entry.team!] = entry;
          }
        }
      }

      // 3. Validar se a matemática bate certo (Testes Aserções)
      
      // A Equipa RED deve ter 500 + 300 = 800 pontos
      expect(teamScores[TeamColor.RED], 800);
      
      // A Equipa BLUE deve ter 600 + 100 = 700 pontos
      expect(teamScores[TeamColor.BLUE], 700);

      // O MVP da Equipa RED deve ser a luz1 (500 pts > 300 pts)
      expect(teamMVPs[TeamColor.RED]?.username, 'luz1');

      // O MVP da Equipa BLUE deve ser a luz3 (600 pts > 100 pts)
      expect(teamMVPs[TeamColor.BLUE]?.username, 'luz3');
    });
  });
}
