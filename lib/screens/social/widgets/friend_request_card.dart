import 'package:flutter/material.dart';
import '../../../models/friend_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/profile/cosmetic_avatar.dart';

class FriendRequestCard extends StatelessWidget {
  final FriendModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const FriendRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CosmeticAvatar(
            radius: 24,
            avatarUrl: request.avatar,
            username: request.username,
            isVip: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nível ${request.level} • Quer ser teu amigo',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                onPressed: onAccept,
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
                onPressed: onReject,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
