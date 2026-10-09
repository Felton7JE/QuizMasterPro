import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/friend_model.dart';
import '../../../models/user_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/profile/cosmetic_avatar.dart';
import '../../../widgets/economy/vip_badge_widget.dart';
import '../../../widgets/core/loading_logo.dart';
import '../../../services/api_service.dart';
import '../../../config/api_config.dart';
import '../../../providers/economy/store_provider.dart';
import '../../multiplayer/create_room_screen.dart';
class FriendProfileModal extends StatefulWidget {
  final FriendModel friend;
  final VoidCallback onRemove;

  const FriendProfileModal({
    super.key,
    required this.friend,
    required this.onRemove,
  });

  @override
  State<FriendProfileModal> createState() => _FriendProfileModalState();
}

class _FriendProfileModalState extends State<FriendProfileModal> {
  UserModel? _fullProfile;
  List<dynamic> _purchasedItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService().get('/api/users/${widget.friend.id}');
      final itemsData = await ApiService().getList('/api/store/items/purchased/${widget.friend.id}');
      
      setState(() {
        _fullProfile = UserModel.fromJson(data);
        _purchasedItems = itemsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: LoadingLogo(size: 60)),
      );
    }

    if (_error != null || _fullProfile == null) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Text(
            'Erro ao carregar perfil.\n${_error ?? ""}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final user = _fullProfile!;
    final storeProvider = context.read<StoreProvider>();
    final bannerUrl = storeProvider.getBannerUrl(user.activeBannerId);
    final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);
    
    // Resolve active title
    String activeTitleLabel = 'Novato';
    if (user.activeTitleId != null) {
      try {
        final activeTitle = storeProvider.availableTitles.firstWhere(
          (t) => t.id == user.activeTitleId,
        );
        activeTitleLabel = activeTitle.name;
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Banner & Avatar Section
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Banner background
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  image: resolvedBanner != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            resolvedBanner,
                            headers: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.35),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
              ),
              // Indicator line
              Positioned(
                top: 12,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Avatar
              Positioned(
                top: 70, // Overlap banner
                child: Stack(
                  children: [
                    CosmeticAvatar(
                      radius: 46,
                      avatarUrl: user.avatar,
                      username: user.username,
                      activeAvatarId: user.activeAvatarId,
                      activeFrameId: user.activeFrameId,
                      isVip: user.isVip,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.friend.isOnline ? Colors.greenAccent : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 55), // Space for avatar overlap
          
          // Username and VIP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                VipUsernameText(
                  username: user.username,
                  isVip: user.isVip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Title Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    activeTitleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Level and League
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'Nível ${user.level} • ${user.currentLeague}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stats Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('Vitórias', user.gamesWon.toString(), Colors.amber),
                    _buildStatCol('Derrotas', (user.gamesPlayed - user.gamesWon).toString(), Colors.redAccent),
                    _buildStatCol('Partidas', user.gamesPlayed.toString(), Colors.blue),
                    _buildStatCol('Precisão', '${user.accuracy.toStringAsFixed(1)}%', Colors.green),
                  ],
                ),
                const SizedBox(height: 32),
                
                if (_purchasedItems.isNotEmpty) ...[
                  _buildPurchasedItems(),
                  const SizedBox(height: 32),
                ],

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateRoomScreen(
                                initialMode: 'duel',
                                invitedFriendId: widget.friend.id.toString(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.sports_esports, color: Colors.white),
                        label: const Text(
                          'Desafiar',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Remover Amigo', style: TextStyle(color: Colors.white)),
                            content: Text('Tens a certeza que queres remover ${user.username} da tua lista?', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.onRemove();
                                },
                                child: const Text('Remover', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.person_remove, color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasedItems() {
    final titles = _purchasedItems.where((i) => i['storeItem']?['type'] == 'TITLE').toList();
    final banners = _purchasedItems.where((i) => i['storeItem']?['type'] == 'BANNER').toList();
    final avatars = _purchasedItems.where((i) => i['storeItem']?['type'] == 'AVATAR').toList();
    final phrases = _purchasedItems.where((i) => i['storeItem']?['type'] == 'TEXT_PHRASE').toList();
    final emotes = _purchasedItems.where((i) => i['storeItem']?['type'] == 'EMOTE' || i['storeItem']?['type'] == 'EMOJI').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Coleção', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (titles.isNotEmpty) _buildItemsRow('Títulos', titles, Icons.label),
        if (banners.isNotEmpty) _buildItemsRow('Banners', banners, Icons.image),
        if (avatars.isNotEmpty) _buildItemsRow('Avatares', avatars, Icons.person),
        if (phrases.isNotEmpty) _buildItemsRow('Frases', phrases, Icons.chat_bubble),
        if (emotes.isNotEmpty) _buildItemsRow('Emojis & Reações', emotes, Icons.sentiment_satisfied_alt),
      ],
    );
  }

  Widget _buildItemsRow(String title, List<dynamic> items, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final storeItem = item['storeItem'] ?? {};
                final name = storeItem['name'] ?? 'Item';
                final isEquipped = item['isEquipped'] == true;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEquipped ? AppColors.primary.withValues(alpha: 0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isEquipped ? AppColors.primary : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: TextStyle(color: isEquipped ? AppColors.primary : Colors.white60, fontSize: 12)),
                      if (isEquipped) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 12),
                      ]
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
