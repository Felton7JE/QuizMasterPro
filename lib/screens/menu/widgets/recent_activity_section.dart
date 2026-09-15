import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';

class RecentActivitySection extends StatefulWidget {
  const RecentActivitySection({super.key});

  @override
  State<RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  Future<List<Map<String, dynamic>>>? _activityFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _activityFuture = context.read<AuthProvider>().getRecentActivity();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Recente',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingLogo(size: 60));
            }
            if (snapshot.hasError) {
              return const Text('Erro ao carregar atividade.', style: TextStyle(color: Colors.redAccent));
            }
            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return const Text('Nenhuma atividade recente.', style: TextStyle(color: Colors.grey));
            }

            // Mostrar as últimas 3 atividades
            final recent = activities.take(3).toList();

            return Column(
              children: recent.map((activity) {
                final type = activity['type'] ?? 'GAME';
                final title = activity['title'] ?? '';
                final description = activity['description'] ?? '';
                final points = activity['points'] ?? '';
                final isGlobal = activity['global'] ?? false;
                
                IconData icon;
                Color color;

                switch (type) {
                  case 'GLOBAL':
                    icon = Icons.campaign;
                    color = Colors.amber;
                    break;
                  case 'LEVEL_UP':
                    icon = Icons.star;
                    color = Colors.purpleAccent;
                    break;
                  case 'ACHIEVEMENT':
                    icon = Icons.military_tech;
                    color = AppColors.secondary;
                    break;
                  case 'GAME':
                  default:
                    icon = Icons.videogame_asset;
                    color = AppColors.success;
                    break;
                }

                // Calcula o tempo desde a atividade
                String time = 'Recentemente';
                if (activity['createdAt'] != null) {
                  try {
                    final date = DateTime.parse(activity['createdAt']).toLocal();
                    final diff = DateTime.now().difference(date);
                    if (diff.inMinutes < 60) {
                      time = diff.inMinutes <= 1 ? 'Agora mesmo' : '${diff.inMinutes} min atrás';
                    } else if (diff.inHours < 24) {
                      time = '${diff.inHours} h atrás';
                    } else {
                      time = '${diff.inDays} dias atrás';
                    }
                  } catch (_) {}
                }

                return _buildActivityItem(
                  icon,
                  title,
                  description,
                  time,
                  points,
                  color,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(
      IconData icon, String title, String description, String time, String points, Color customColor) {
    final color = customColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
