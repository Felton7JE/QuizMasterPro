import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/economy/mission_provider.dart';
import '../../providers/economy/store_provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../models/mission_model.dart';
import '../../models/title_model.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/economy/reward_claim_dialog.dart';
import 'package:quizmaster_pro/widgets/core/loading_logo.dart';

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
      context.read<StoreProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          title: const Text(
            'Desafios & Títulos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.indigoAccent,
            labelColor: Colors.indigoAccent,
            unselectedLabelColor: Colors.grey,
            isScrollable: false,
            tabs: [
              Tab(text: 'Diárias'),
              Tab(text: 'Mensais'),
              Tab(text: 'Conquistas'),
              Tab(text: 'Títulos'),
            ],
          ),
        ),
        body: Consumer<MissionProvider>(
          builder: (context, missionProvider, child) {
            if (missionProvider.isLoading && missionProvider.missions.isEmpty) {
              return const Center(child: LoadingLogo(size: 60));
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
                _buildTitlesTab(context),
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
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (mission.rewardCoins > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                      ),
                    if (mission.rewardItemName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            Flexible(
                              child: Text(
                                mission.rewardItemName!,
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
                      RewardClaimDialog.show(
                        context,
                        RewardItemData(
                          title: 'Missão Concluída!',
                          subtitle: mission.title,
                          coins: mission.rewardCoins,
                          itemName: mission.rewardItemName,
                          itemIcon: mission.rewardItemType == 'EMOTE' || mission.rewardItemType == 'EMOJI'
                              ? (mission.rewardItemValue ?? '✨')
                              : '💬',
                          mainIcon: Icons.emoji_events_rounded,
                          mainColor: Colors.amber,
                        ),
                      );
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

  Widget _buildTitlesTab(BuildContext context) {
    return Consumer2<StoreProvider, AuthProvider>(
      builder: (context, storeProv, authProv, child) {
        if (storeProv.isLoading && storeProv.availableTitles.isEmpty) {
          return const Center(child: LoadingLogo(size: 60));
        }

        final allTitles = storeProv.availableTitles;
        final earnedTitles = storeProv.earnedTitles;
        final activeTitleId = authProv.currentUser?.activeTitleId;

        if (allTitles.isEmpty && earnedTitles.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum título disponível.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: allTitles.isNotEmpty ? allTitles.length : earnedTitles.length,
          itemBuilder: (context, index) {
            final TitleModel title = allTitles.isNotEmpty ? allTitles[index] : earnedTitles[index];
            final bool isUnlocked = earnedTitles.any((t) => t.id == title.id);
            final bool isEquipped = activeTitleId == title.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEquipped
                      ? const Color(0xFFFFD700)
                      : isUnlocked
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF334155),
                  width: isEquipped ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isEquipped
                          ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                          : isUnlocked
                              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEquipped
                          ? Icons.military_tech_rounded
                          : isUnlocked
                              ? Icons.emoji_events_rounded
                              : Icons.lock_outline_rounded,
                      color: isEquipped
                          ? const Color(0xFFFFD700)
                          : isUnlocked
                              ? const Color(0xFF818CF8)
                              : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.name,
                          style: TextStyle(
                            color: isUnlocked ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title.description.isNotEmpty
                              ? title.description
                              : 'Conquiste para desbloquear',
                          style: TextStyle(
                            color: isUnlocked ? Colors.white70 : Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isEquipped)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final ok = await storeProv.unequipTitle();
                        if (context.mounted && ok) {
                          AppSnackBar.showInfo(context, 'Título desequipado!');
                        }
                      },
                      child: const Text('Equipado', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else if (isUnlocked)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final ok = await storeProv.equipTitle(title);
                        if (context.mounted && ok) {
                          RewardClaimDialog.show(
                            context,
                            RewardItemData(
                              title: 'Título Equipado!',
                              subtitle: 'Agora estás usando o título "${title.name}"!',
                              mainIcon: Icons.military_tech_rounded,
                              mainColor: const Color(0xFF6366F1),
                            ),
                          );
                        }
                      },
                      child: const Text('Equipar'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Bloqueado',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
