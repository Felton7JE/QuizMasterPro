import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/vip_badge_widget.dart';
import '../config/api_config.dart';
import '../utils/snackbar_utils.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';
import '../utils/snackbar_utils.dart';
import '../models/friend_model.dart';
import '../providers/friendship_provider.dart';
import 'social/widgets/friend_profile_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedInventoryTab = 'Títulos';
  Future<Map<String, dynamic>?>? _statsFuture;
  Future<List<Map<String, dynamic>>>? _historyFuture;
  int _historyLimit = 5;

  @override
  void initState() {
    super.initState();
    // Refresh user data if needed when entering profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
      context.read<StoreProvider>().loadAllData();
      setState(() {
        _statsFuture = context.read<AuthProvider>().getUserStats();
        _historyFuture = context.read<AuthProvider>().getUserHistory();
      });
    });
  }

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'AVATAR':
        return Icons.face_rounded;
      case 'PROFILE_FRAME':
        return Icons.crop_square_rounded;
      case 'BANNER':
        return Icons.image_rounded;
      case 'TEXT_PHRASE':
        return Icons.chat_bubble_rounded;
      case 'EMOTE':
      case 'EMOJI':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'TITLE':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Future<bool> _confirmUnequip(String itemName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A3A55)),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Desequipar item?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Você deseja remover "$itemName" do seu perfil?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: Colors.redAccent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Desequipar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmEquip(
      String itemName, String type, String? value) async {
    final resolvedUrl = (value != null && value.isNotEmpty)
        ? ApiConfig.resolveAssetUrl(value)
        : null;
    final isAvatar = type == 'AVATAR';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A3A55)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Ícone / Preview ──────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isAvatar && resolvedUrl != null
                        ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                        : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: isAvatar && resolvedUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: resolvedUrl,
                          fit: BoxFit.cover,
                          httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                          errorWidget: (context, url, error) => Icon(
                            _getItemIcon(type),
                            size: 44,
                            color: Colors.white,
                          ),
                          placeholder: (context, url) => const SizedBox(width: 44, height: 44, child: CircularProgressIndicator()),
                        ),
                      )
                    : Icon(_getItemIcon(type), size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // ── Texto ────────────────────────────────────
              const Text(
                'Equipar Item',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                itemName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Deseja equipar este item?',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // ── Botões ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF2A3A55)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Equipar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Configurações',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, StoreProvider>(
        builder: (context, authProvider, storeProvider, child) {
          final user = authProvider.currentUser;

          if (authProvider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Você precisa estar logado',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('Fazer Login',
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          }

          // Descobrir qual título ele tem ativo a partir das configurações do jogador
          String activeTitleLabel = 'Novato';
          bool titleFound = false;
          if (user.activeTitleId != null) {
            try {
              final allTitles = [...storeProvider.availableTitles, ...storeProvider.earnedTitles];
              final activeTitle = allTitles.firstWhere(
                (t) => t.id == user.activeTitleId,
              );
              activeTitleLabel = activeTitle.name;
              titleFound = true;
            } catch (e) {
              // ignore
            }
          }

          if (!titleFound) {
            if (storeProvider.earnedTitles.isNotEmpty) {
              activeTitleLabel = storeProvider.earnedTitles.first.name;
            } else {
              activeTitleLabel = 'Jogador ${user.level}';
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(context.isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(context, user, activeTitleLabel),
                const SizedBox(height: 32),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    return _buildStatsGrid(context, user, snapshot.data);
                  },
                ),
                const SizedBox(height: 32),
                _buildInventoryTabs(context),
                const SizedBox(height: 16),
                _buildInventorySection(context, storeProvider),
                const SizedBox(height: 32),
                _buildHistorySection(context, authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, String activeTitle) {
    final storeProvider = context.read<StoreProvider>();
    final bannerUrl = storeProvider.getBannerUrl(user.activeBannerId);
    final resolvedBanner = ApiConfig.resolveAssetUrl(bannerUrl);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(24)),
            image: resolvedBanner != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      resolvedBanner,
                      headers: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.35),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'profile_avatar',
                child: CosmeticAvatar(
                  radius: context.isSmallScreen ? 50 : 70,
                  avatarUrl: user.avatar,
                  username: user.username,
                  activeAvatarId: user.activeAvatarId,
                  activeFrameId: user.activeFrameId,
                  isVip: user.isVip,
                ),
              ),
              const SizedBox(height: 16),
              VipUsernameText(
                username: user.username,
                isVip: user.isVip,
                style: TextStyle(
                  fontSize: context.isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 6,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  activeTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLevelBar(context, user),
      ],
    );
  }

  Widget _buildLevelBar(BuildContext context, user) {
    // Cálculo de progresso visual (1000 XP por nível)
    double progress = (user.xp % 1000) / 1000.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nível ${user.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Nível ${user.level + 1}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.black26,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${user.xp} XP Totais',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, user, Map<String, dynamic>? extraStats) {
    return Column(
      children: [
        _buildStatsDropdown(
          context,
          title: 'Estatísticas Globais',
          icon: Icons.public,
          initiallyExpanded: true,
          children: [
            _buildStatCard('Partidas', '${user.gamesPlayed}',
                Icons.sports_esports, Colors.blue),
            _buildStatCard('Vitórias', '${user.gamesWon}', Icons.emoji_events,
                Colors.amber),
            _buildStatCard('Precisão', '${user.accuracy}%', Icons.track_changes,
                Colors.green),
            _buildStatCard('Ofensiva', '${user.currentStreak}',
                Icons.local_fire_department, Colors.orange),
            _buildStatCard(
                'Pontos', '${user.totalPoints}', Icons.stars, Colors.purple),
            _buildStatCard(
                'Liga', user.currentLeague, Icons.shield, Colors.redAccent),
          ],
        ),
        if (extraStats != null) ...[
          const SizedBox(height: 12),
          _buildStatsDropdown(
            context,
            title: 'Recordes - Modo Livre',
            icon: Icons.emoji_events,
            children: [
              _buildStatCard(
                  'Sobrevivência',
                  '${extraStats['survivalHighScore'] ?? 0}',
                  Icons.shield,
                  Colors.teal),
              _buildStatCard(
                  'Ofensiva',
                  '${extraStats['survivalBestStreak'] ?? 0}',
                  Icons.local_fire_department,
                  Colors.red),
              _buildStatCard(
                  'Contra o Tempo',
                  '${extraStats['timeAttackHighScore'] ?? 0}',
                  Icons.timer,
                  Colors.cyan),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatsDropdown(
            context,
            title: 'Temporada Atual',
            icon: Icons.calendar_month,
            children: [
              _buildStatCard('Nível', '${extraStats['seasonLevel'] ?? 1}',
                  Icons.star, Colors.yellow),
              _buildStatCard('Pontos', '${extraStats['seasonPoints'] ?? 0}',
                  Icons.stars, Colors.indigo),
              _buildStatCard(
                  'Premium',
                  (extraStats['hasPremiumPass'] == true) ? 'Ativo' : 'Não',
                  Icons.workspace_premium,
                  Colors.amberAccent),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsDropdown(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children,
      bool initiallyExpanded = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.grey,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            GridView.count(
              crossAxisCount: context.isVerySmallScreen ? 2 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTabs(BuildContext context) {
    final tabs = [
      'Banners',
      'Avatares',
      'Molduras',
      'Frases',
      'Emojis',
      'Extras',
      'Títulos'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tabs.map((tab) {
          final isSelected = _selectedInventoryTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tab),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedInventoryTab = tab;
                  });
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInventorySection(
      BuildContext context, StoreProvider storeProvider) {
    Widget content = const SizedBox();
    String categoryTitle = '';

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();

    if (_selectedInventoryTab == 'Títulos') {
      final titles = storeProvider.earnedTitles;
      categoryTitle = 'Títulos (${titles.length})';
      content = titles.isEmpty
          ? const Text('Nenhum item',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: titles.map((t) {
                final isEquipped = user.activeTitleId == t.id;
                return GestureDetector(
                  onTap: () async {
                    if (isEquipped) {
                      final confirmed = await _confirmUnequip(t.name);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.unequipTitle();
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Título desequipado!');
                      }
                    } else {
                      final confirmed =
                          await _confirmEquip(t.name, 'TITLE', null);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.equipTitle(t);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Título equipado!');
                      }
                    }
                  },
                  child: _buildTextChip(t.name, isEquipped: isEquipped),
                );
              }).toList(),
            );
    } else if (_selectedInventoryTab == 'Banners') {
      final banners = storeProvider.purchasedItems
          .where((i) => i.type == 'BANNER')
          .toList();
      categoryTitle = 'Banners (${banners.length})';
      content = banners.isEmpty
          ? const Text('Nenhum item',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.isSmallScreen ? 1 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.0,
              ),
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                final isEquipped = user.activeBannerId == banner.id;

                return GestureDetector(
                  onTap: () async {
                    if (isEquipped) {
                      final confirmed = await _confirmUnequip(banner.name);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.unequipItem(banner.type);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Banner desequipado!');
                      }
                    } else {
                      final confirmed = await _confirmEquip(
                          banner.name, banner.type, banner.value);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.equipItem(banner);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Banner equipado!');
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isEquipped ? Colors.green : Colors.transparent,
                          width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(fit: StackFit.expand, children: [
                        CachedNetworkImage(
                          imageUrl: ApiConfig.resolveAssetUrl(banner.value) ?? '',
                          fit: BoxFit.cover,
                          httpHeaders: ApiService.token != null ? {'Authorization': 'Bearer ${ApiService.token}'} : null,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white10,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: Colors.white30, size: 40),
                            ),
                          ),
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        ),
                        Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              color: Colors.black.withOpacity(0.5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      banner.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isEquipped)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 14),
                                ],
                              ),
                            ))
                      ]),
                    ),
                  ),
                );
              },
            );
    } else if (_selectedInventoryTab == 'Avatares') {
      final avatars = storeProvider.purchasedItems
          .where((i) => i.type == 'AVATAR')
          .toList();
      categoryTitle = 'Avatares (${avatars.length})';
      content = avatars.isEmpty
          ? const Text('Nenhum item',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: avatars.map((a) {
                final isEquipped = user.activeAvatarId == a.id;
                return GestureDetector(
                  onTap: () async {
                    if (isEquipped) {
                      final confirmed = await _confirmUnequip(a.name);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.unequipItem(a.type);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Avatar desequipado!');
                      }
                    } else {
                      final confirmed =
                          await _confirmEquip(a.name, a.type, a.value);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.equipItem(a);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Avatar equipado!');
                      }
                    }
                  },
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CosmeticAvatar(
                              radius: 30,
                              avatarUrl: a.value.isNotEmpty ? a.value : null,
                              username: user.username,
                              activeAvatarId: a.id,
                              isVip: user.isVip,
                            ),
                            if (isEquipped)
                              Container(
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white),
                                child: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.name,
                          style: TextStyle(
                              color: isEquipped ? Colors.green : Colors.white,
                              fontSize: 10,
                              fontWeight: isEquipped
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
    } else if (_selectedInventoryTab == 'Molduras') {
      final frames = storeProvider.purchasedItems
          .where((i) => i.type == 'PROFILE_FRAME')
          .toList();
      categoryTitle = 'Molduras (${frames.length})';
      content = frames.isEmpty
          ? const Text('Nenhum item',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: frames.map((f) {
                final isEquipped = user.activeFrameId == f.id;
                return GestureDetector(
                  onTap: () async {
                    if (isEquipped) {
                      final confirmed = await _confirmUnequip(f.name);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.unequipItem(f.type);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Moldura desequipada!');
                      }
                    } else {
                      final confirmed =
                          await _confirmEquip(f.name, f.type, f.value);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.equipItem(f);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Moldura equipada!');
                      }
                    }
                  },
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CosmeticAvatar(
                              radius: 30,
                              avatarUrl: user.avatar,
                              username: user.username,
                              activeFrameId: f.id,
                              isVip: user.isVip,
                            ),
                            if (isEquipped)
                              Container(
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white),
                                child: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          f.name,
                          style: TextStyle(
                              color: isEquipped ? Colors.green : Colors.white,
                              fontSize: 10,
                              fontWeight: isEquipped
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
    } else if (_selectedInventoryTab == 'Frases') {
      final phrases = storeProvider.purchasedItems
          .where((i) => i.type == 'TEXT_PHRASE')
          .toList();
      final equippedPhrases = storeProvider.equippedPhrases;
      categoryTitle = 'Frases (${phrases.length}) • Equipadas: ${equippedPhrases.length}/5';
      content = phrases.isEmpty
          ? const Text('Nenhuma frase desbloqueada ainda. Compra na Loja!',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: phrases.map((p) {
                final isEquipped = storeProvider.isItemEquipped(p.id);
                return GestureDetector(
                  onTap: () async {
                    if (isEquipped) {
                      final confirmed = await _confirmUnequip(p.name);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.unequipSpecificItem(p);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Frase desequipada!');
                      }
                    } else {
                      if (equippedPhrases.length >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Limite de 5 frases equipadas atingido! Desequipa uma primeiro.'),
                              backgroundColor: Colors.orange,
                            ));
                        return;
                      }
                      final confirmed =
                          await _confirmEquip(p.name, p.type, p.value);
                      if (!confirmed || !context.mounted) return;
                      final ok = await storeProvider.equipItem(p);
                      if (context.mounted) {
                        if (ok) {
                          AppSnackBar.showInfo(context, 'Frase equipada! (${equippedPhrases.length + 1}/5)');
                        } else if (storeProvider.error != null) {
                          AppSnackBar.showError(context, storeProvider.error!);
                        }
                      }
                    }
                  },
                  child: _buildTextChip('"${p.value}"', isEquipped: isEquipped),
                );
              }).toList(),
            );
    } else if (_selectedInventoryTab == 'Emojis') {
      final emotes = storeProvider.purchasedItems
          .where((i) => i.type == 'EMOTE' || i.type == 'EMOJI')
          .toList();
      final equippedEmotes = storeProvider.equippedEmotes;
      categoryTitle = 'Emojis & Reações (${emotes.length}) • Equipados: ${equippedEmotes.length}/10';
      content = emotes.isEmpty
          ? const Text('Nenhum emoji desbloqueado ainda. Conclua missões ou compre na Loja!',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emotes.map((e) {
                final isEquipped = storeProvider.isItemEquipped(e.id);
                return GestureDetector(
                  onTap: () async {
                    if (isEquipped) {
                      final confirmed = await _confirmUnequip(e.name);
                      if (!confirmed || !context.mounted) return;
                      await storeProvider.unequipSpecificItem(e);
                      if (context.mounted) {
                        AppSnackBar.showInfo(context, 'Emoji desequipado!');
                      }
                    } else {
                      if (equippedEmotes.length >= 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Limite de 10 emojis equipados atingido! Desequipa um primeiro.'),
                              backgroundColor: Colors.orange,
                            ));
                        return;
                      }
                      final confirmed =
                          await _confirmEquip(e.name, e.type, e.value);
                      if (!confirmed || !context.mounted) return;
                      final ok = await storeProvider.equipItem(e);
                      if (context.mounted) {
                        if (ok) {
                          AppSnackBar.showInfo(context, 'Emoji equipado! (${equippedEmotes.length + 1}/10)');
                        } else if (storeProvider.error != null) {
                          AppSnackBar.showError(context, storeProvider.error!);
                        }
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isEquipped
                          ? Colors.green.withValues(alpha: 0.25)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEquipped ? Colors.greenAccent : const Color(0xFF334155),
                        width: isEquipped ? 2 : 1,
                      ),
                      boxShadow: isEquipped
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(alpha: 0.3),
                                blurRadius: 10,
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.value,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.name,
                          style: TextStyle(
                            color: isEquipped ? Colors.greenAccent : Colors.white,
                            fontWeight: isEquipped ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        if (isEquipped) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
    } else if (_selectedInventoryTab == 'Extras') {
      final extras = storeProvider.purchasedItems
          .where((i) => !['BANNER', 'AVATAR', 'PROFILE_FRAME', 'TEXT_PHRASE', 'EMOTE', 'EMOJI']
              .contains(i.type))
          .toList();
      categoryTitle = 'Extras (${extras.length})';
      content = extras.isEmpty
          ? const Text('Nenhum item extra',
              style: TextStyle(color: Colors.grey, fontSize: 14))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: extras.map((e) {
                return _buildTextChip('${e.name} (${e.type})');
              }).toList(),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meu Inventário',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextChip(String text, {bool isEquipped = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEquipped
            ? Colors.green.withOpacity(0.3)
            : AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isEquipped ? Colors.green : AppColors.primary.withOpacity(0.5),
            width: isEquipped ? 2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isEquipped) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas Partidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingLogo(size: 60));
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Erro ao carregar histórico.',
                      style: TextStyle(color: Colors.redAccent)));
            }
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const Center(
                  child: Text('Ainda não jogaste nenhuma partida.',
                      style: TextStyle(color: Colors.grey)));
            }

            final visibleHistory = history.take(_historyLimit).toList();

            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleHistory.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final game = visibleHistory[index];
                final resultsList = game['results'] as List<dynamic>? ?? [];

                // Find current user's result
                final myResult = resultsList.firstWhere(
                  (r) => r['userId'].toString() == authProvider.currentUser?.id,
                  orElse: () => null,
                );

                if (myResult == null) return const SizedBox();

                final gameMode = game['gameMode'] ?? 'CLASSIC';
                final points = myResult['totalPoints'] ?? 0;
                final correctAnswers = myResult['correctAnswers'] ?? 0;
                final totalQuestions = myResult['totalQuestions'] ?? 0;

                // Check if user is the winner
                final winner = game['winner'];
                final isWinner = winner != null &&
                    winner['userId'].toString() == authProvider.currentUser?.id;

                IconData modeIcon;
                Color modeColor;
                switch (gameMode) {
                  case 'DUEL':
                    modeIcon = Icons.sports_kabaddi;
                    modeColor = Colors.orange;
                    break;
                  case 'TEAM':
                    modeIcon = Icons.groups;
                    modeColor = Colors.blue;
                    break;
                  case 'KAHOOT':
                    modeIcon = Icons.school;
                    modeColor = Colors.purple;
                    break;
                  default:
                    modeIcon = Icons.person;
                    modeColor = Colors.green;
                }

                return GestureDetector(
                  onTap: () => _showGameDetailsModal(context, game, authProvider),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isWinner
                              ? Colors.amber.withValues(alpha: 0.5)
                              : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: modeColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(modeIcon, color: modeColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gameMode,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$correctAnswers / $totalQuestions certas',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+$points Pts',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            if (gameMode == 'DUEL' ||
                                gameMode == 'TEAM' ||
                                gameMode == 'KAHOOT') ...[
                              const SizedBox(height: 4),
                              Text(
                                isWinner ? 'VITÓRIA' : 'DERROTA',
                                style: TextStyle(
                                  color:
                                      isWinner ? Colors.amber : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
                if (history.length > _historyLimit) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _historyLimit += 5;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: const Text('Mostrar Mais Partidas', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _showGameDetailsModal(BuildContext context, Map<String, dynamic> game, AuthProvider authProvider) {
    final gameMode = game['gameMode'] ?? 'Desconhecido';
    final startedAt = game['startedAt'];
    final endedAt = game['endedAt'];
    final resultsList = game['results'] as List<dynamic>? ?? [];
    
    // Sort players by score
    resultsList.sort((a, b) => (b['totalPoints'] ?? 0).compareTo(a['totalPoints'] ?? 0));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalhes da Partida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        // Modo e Datas
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.videogame_asset, color: Colors.blueAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modo: $gameMode',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Início: ${startedAt != null ? _formatDateTime(startedAt) : 'Desconhecido'}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Jogadores',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...resultsList.map((player) {
                          final isMe = player['userId'].toString() == authProvider.currentUser?.id;
                          final pts = player['totalPoints'] ?? 0;
                          final avatarUrl = player['avatar'] != null ? ApiConfig.resolveAssetUrl(player['avatar']) : null;
                          final correct = player['correctAnswers'] ?? 0;
                          final total = player['totalQuestions'] ?? 0;
                          final targetUsername = player['username'] ?? 'Desconhecido';
                          final targetUserId = int.tryParse(player['userId']?.toString() ?? '0') ?? 0;
                          final currentUserId = int.tryParse(authProvider.currentUser?.id ?? '0') ?? 0;

                          return Consumer<FriendshipProvider>(
                            builder: (context, friendshipProv, child) {
                              final isFriend = friendshipProv.friends.any((f) => f.id == targetUserId);
                              final hasPending = friendshipProv.pendingRequests.any((f) => f.id == targetUserId) ||
                                                 friendshipProv.sentRequests.any((f) => f.id == targetUserId) ||
                                                 friendshipProv.sentRequests.any((f) => f.username == targetUsername);

                              return GestureDetector(
                                onTap: () {
                                  if (!isMe && targetUserId > 0) {
                                    final dummyFriend = FriendModel(
                                      id: targetUserId,
                                      username: targetUsername,
                                      avatar: player['avatar'],
                                      level: 1,
                                      currentLeague: 'Bronze',
                                      isOnline: false,
                                    );
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => FriendProfileModal(
                                        friend: dummyFriend,
                                        onRemove: () {},
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFF0F172A),
                                    border: isMe ? Border.all(color: Colors.blue.withValues(alpha: 0.3)) : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFF334155),
                                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              targetUsername,
                                              style: TextStyle(
                                                color: isMe ? Colors.blueAccent : Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$correct/$total certas',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '$pts pts',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (!isMe && targetUserId > 0 && !isFriend)
                                        IconButton(
                                          icon: Icon(
                                            hasPending ? Icons.pending : Icons.person_add,
                                            color: hasPending ? Colors.grey : Colors.blueAccent,
                                          ),
                                          onPressed: hasPending
                                              ? null
                                              : () async {
                                                  try {
                                                    await friendshipProv.sendFriendRequest(currentUserId, targetUsername);
                                                    if (context.mounted) {
                                                      AppSnackBar.showSuccess(context, 'Pedido enviado para $targetUsername!');
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      AppSnackBar.showError(context, 'Erro ao enviar pedido.');
                                                    }
                                                  }
                                                },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
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

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
