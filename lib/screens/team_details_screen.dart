import 'package:flutter/material.dart';
import 'package:quizmaster_pro/models/game_model.dart';
import 'package:quizmaster_pro/models/room_model.dart';

class TeamDetailsScreen extends StatelessWidget {
  final List<LeaderboardEntry> leaderboard;
  
  const TeamDetailsScreen({super.key, required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    // 1. Calcular estatísticas de equipa
    Map<TeamColor, int> teamScores = {};
    Map<TeamColor, int> teamCorrectAnswers = {};
    Map<TeamColor, int> teamTotalAnswers = {};
    
    // Jogadores por equipa
    Map<TeamColor, List<LeaderboardEntry>> teamPlayers = {
      TeamColor.RED: [],
      TeamColor.BLUE: [],
    };

    // Títulos por equipa
    Map<TeamColor, LeaderboardEntry?> teamMVPs = {};
    Map<TeamColor, LeaderboardEntry?> teamFlashes = {};
    Map<TeamColor, LeaderboardEntry?> teamSnipers = {};

    for (var entry in leaderboard) {
      if (entry.team != null) {
        final team = entry.team!;
        teamPlayers[team]?.add(entry);
        
        teamScores[team] = (teamScores[team] ?? 0) + entry.score;
        teamCorrectAnswers[team] = (teamCorrectAnswers[team] ?? 0) + entry.correctAnswers;
        teamTotalAnswers[team] = (teamTotalAnswers[team] ?? 0) + entry.totalAnswers;

        // MVP: Maior pontuação
        if (teamMVPs[team] == null || entry.score > teamMVPs[team]!.score) {
          teamMVPs[team] = entry;
        }

        // O Flash: Menor tempo médio (mas tem de ter acertado alguma coisa)
        if (entry.correctAnswers > 0) {
          if (teamFlashes[team] == null || entry.averageTime < teamFlashes[team]!.averageTime) {
            teamFlashes[team] = entry;
          }
        }

        // Sniper: Maior % de acerto (desempate por pontuação)
        double acc = entry.totalAnswers > 0 ? entry.correctAnswers / entry.totalAnswers : 0;
        double currentSniperAcc = teamSnipers[team] != null && teamSnipers[team]!.totalAnswers > 0 
            ? teamSnipers[team]!.correctAnswers / teamSnipers[team]!.totalAnswers 
            : 0;
            
        if (teamSnipers[team] == null || acc > currentSniperAcc || (acc == currentSniperAcc && entry.score > teamSnipers[team]!.score)) {
          teamSnipers[team] = entry;
        }
      }
    }

    // Ordenar jogadores por pontos dentro de cada equipa
    teamPlayers[TeamColor.RED]?.sort((a, b) => b.score.compareTo(a.score));
    teamPlayers[TeamColor.BLUE]?.sort((a, b) => b.score.compareTo(a.score));

    int totalRedScore = teamScores[TeamColor.RED] ?? 0;
    int totalBlueScore = teamScores[TeamColor.BLUE] ?? 0;
    int globalScore = totalRedScore + totalBlueScore;
    double redPercentage = globalScore > 0 ? totalRedScore / globalScore : 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Fundo escuro premium
      appBar: AppBar(
        title: const Text('Batalha de Equipas - Detalhes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: leaderboard.isEmpty || (totalRedScore == 0 && totalBlueScore == 0)
            ? const Center(
                child: Text('Modo Individual (Equipas não selecionadas)', style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. PLACAR GLOBAL (Cabo de Guerra)
                    const Text('DOMÍNIO DO JOGO', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    _buildTugOfWarBar(totalRedScore, totalBlueScore, redPercentage),
                    const SizedBox(height: 30),

                    // 2. PRÉMIOS ESPECIAIS (Lado a Lado)
                    Row(
                      children: [
                        Expanded(child: _buildTeamAwards(TeamColor.RED, teamMVPs[TeamColor.RED], teamFlashes[TeamColor.RED], teamSnipers[TeamColor.RED])),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTeamAwards(TeamColor.BLUE, teamMVPs[TeamColor.BLUE], teamFlashes[TeamColor.BLUE], teamSnipers[TeamColor.BLUE])),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 3. CONTRIBUIÇÃO INDIVIDUAL
                    const Text('CONTRIBUIÇÃO DOS JOGADORES', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTeamPlayerList(TeamColor.RED, teamPlayers[TeamColor.RED] ?? [], totalRedScore)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTeamPlayerList(TeamColor.BLUE, teamPlayers[TeamColor.BLUE] ?? [], totalBlueScore)),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTugOfWarBar(int redScore, int blueScore, double redPercentage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$redScore PTS', style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('VS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              Text('$blueScore PTS', style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  Expanded(
                    flex: (redPercentage * 100).toInt() == 0 ? 1 : (redPercentage * 100).toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - redPercentage) * 100).toInt() == 0 ? 1 : ((1 - redPercentage) * 100).toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAwards(TeamColor team, LeaderboardEntry? mvp, LeaderboardEntry? flash, LeaderboardEntry? sniper) {
    Color teamColor = team == TeamColor.RED ? Colors.redAccent : Colors.blueAccent;
    String teamName = team == TeamColor.RED ? 'RED TEAM' : 'BLUE TEAM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teamColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teamName, style: TextStyle(color: teamColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white24),
          _buildAwardItem('👑 MVP', mvp?.username ?? '-', '${mvp?.score ?? 0} pts', teamColor),
          _buildAwardItem('⚡ Flash', flash?.username ?? '-', '${flash?.averageTime.toStringAsFixed(1) ?? 0}s', teamColor),
          _buildAwardItem('🎯 Sniper', sniper?.username ?? '-', '${sniper?.correctAnswers ?? 0}/${sniper?.totalAnswers ?? 0}', teamColor),
        ],
      ),
    );
  }

  Widget _buildAwardItem(String title, String player, String stat, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(player, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Text(stat, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPlayerList(TeamColor team, List<LeaderboardEntry> players, int teamTotalScore) {
    Color teamColor = team == TeamColor.RED ? Colors.redAccent : Colors.blueAccent;

    return Column(
      children: players.map((p) {
        double contribution = teamTotalScore > 0 ? p.score / teamTotalScore : 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: teamColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(p.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  Text('${p.score}', style: TextStyle(color: teamColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: contribution,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('${(contribution * 100).toInt()}% do total da equipa', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
