import 'package:flutter/material.dart';
import '../../../models/friend_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/cosmetic_avatar.dart';
import 'friend_profile_modal.dart';

class FriendCard extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback onRemove;

  const FriendCard({
    super.key,
    required this.friend,
    required this.onRemove,
  });

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FriendProfileModal(
        friend: friend,
        onRemove: () {
          Navigator.pop(ctx);
          onRemove();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showProfileModal(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      child: Row(
        children: [
          Stack(
            children: [
              CosmeticAvatar(
                radius: 24,
                avatarUrl: friend.avatar,
                username: friend.username,
                isVip: false, // Pode ser ajustado se viermos a ter isVip no FriendDTO
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: friend.isOnline ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nível ${friend.level} • ${friend.currentLeague}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Remover Amigo', style: TextStyle(color: Colors.white)),
                  content: Text('Tens a certeza que queres remover ${friend.username} da tua lista?', style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onRemove();
                      },
                      child: const Text('Remover', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
