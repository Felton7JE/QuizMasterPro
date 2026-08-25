import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
import '../providers/store_provider.dart';
import '../models/mission_model.dart';
import '../utils/snackbar_utils.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionProvider>().fetchMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          title: const Text(
            'Desafios',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.indigoAccent,
            labelColor: Colors.indigoAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Diárias'),
              Tab(text: 'Mensais'),
              Tab(text: 'Conquistas'),
            ],
          ),
        ),
        body: Consumer<MissionProvider>(
          builder: (context, missionProvider, child) {
            if (missionProvider.isLoading && missionProvider.missions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (missionProvider.error != null && missionProvider.missions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar missões:\n${missionProvider.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => missionProvider.fetchMissions(),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            final dailyMissions = missionProvider.missions.where((m) => m.type == 'DAILY').toList();
            final monthlyMissions = missionProvider.missions.where((m) => m.type == 'MONTHLY').toList();
            final milestoneMissions = missionProvider.missions.where((m) => m.type == 'MILESTONE').toList();

            return TabBarView(
              children: [
                _buildMissionList(dailyMissions),
                _buildMissionList(monthlyMissions),
                _buildMissionList(milestoneMissions),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMissionList(List<MissionModel> missions) {
    if (missions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum desafio nesta categoria.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildQuestCard(context, mission),
        );
      },
    );
  }

  Widget _buildQuestCard(BuildContext context, MissionModel mission) {
    double percent = mission.currentValue / mission.targetValue;
    if (percent > 1.0) percent = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mission.isCompleted && !mission.rewardClaimed 
              ? Colors.amber 
              : const Color(0xFF334155),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Row(
                children: [
                  if (mission.rewardCoins > 0) ...[
                    const Text('🪙 ', style: TextStyle(fontSize: 14)),
                    Text(
                      '+${mission.rewardCoins}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (mission.rewardItemName != null) ...[
                    if (mission.rewardCoins > 0) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mission.rewardItemType == 'EMOTE' || mission.rewardItemType == 'EMOJI'
                                ? (mission.rewardItemValue ?? '✨')
                                : '💬',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mission.rewardItemName!,
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      mission.isCompleted ? Colors.greenAccent : const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${mission.currentValue}/${mission.targetValue}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (mission.isCompleted && !mission.rewardClaimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final provider = context.read<MissionProvider>();
                  bool success = await provider.claimReward(mission.id);
                  if (success) {
                    if (context.mounted) {
                      context.read<StoreProvider>().loadAllData();
                    }
                    String rewardMsg = 'Recompensa coletada!';
                    if (mission.rewardCoins > 0) rewardMsg += ' +${mission.rewardCoins} 🪙';
                    if (mission.rewardItemName != null) rewardMsg += ' + ${mission.rewardItemName}!';
                    if (context.mounted) {
                      AppSnackBar.showInfo(context, rewardMsg);
                    }
                  } else {
                    if (context.mounted) {
                      AppSnackBar.showError(context, 'Erro ao coletar recompensa: ${provider.error}');
                    }
                  }
                },
                child: const Text(
                  'Coletar Recompensa',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          if (mission.isCompleted && mission.rewardClaimed)
            const Center(
              child: Text(
                'Coletado',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
