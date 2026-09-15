import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/season_provider.dart';
import '../models/season_models.dart';
import '../services/api_service.dart';
import '../services/asset_manager_service.dart';
import '../widgets/local_asset_image.dart';
import '../widgets/vip_badge_widget.dart';
import '../widgets/reward_claim_dialog.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';

class SeasonPassScreen extends StatefulWidget {
  const SeasonPassScreen({super.key});

  @override
  State<SeasonPassScreen> createState() => _SeasonPassScreenState();
}

class _SeasonPassScreenState extends State<SeasonPassScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _vipPulseController;
  late Animation<double> _vipPulseAnim;
  bool _needsResourceDownload = false;
  bool _isCheckingResources = false;

  @override
  void initState() {
    super.initState();
    _vipPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _vipPulseAnim = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _vipPulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final prov = context.read<SeasonProvider>();
      if (auth.currentUser != null) {
        if (prov.seasonData == null) {
          await prov.fetchSeasonProgress(auth.currentUser!.id);
        }
        _checkIfResourcesNeedDownload();
      }
    });
  }

  Future<void> _checkIfResourcesNeedDownload() async {
    if (_isCheckingResources) return;
    if (!mounted) return;
    setState(() {
      _isCheckingResources = true;
    });

    try {
      final prov = context.read<SeasonProvider>();
      final assetManager = context.read<AssetManagerService>();
      final season = prov.seasonData;

      if (season == null) {
        if (mounted) {
          setState(() {
            _isCheckingResources = false;
          });
        }
        return;
      }

      final urls = <String>{};
      void addResolved(String? rawUrl) {
        final resolved = ApiService.resolveImageUrl(rawUrl);
        if (resolved != null && resolved.startsWith('http')) {
          urls.add(resolved);
        }
      }

      addResolved(season.bannerUrl);
      addResolved(season.mapBackgroundUrl);
      for (final reward in season.rewards) {
        addResolved(reward.freeRewardImageUrl);
        addResolved(reward.premiumRewardImageUrl);
        addResolved(reward.bossImageUrl);
      }

      bool missingAny = false;
      for (final url in urls) {
        final path = await assetManager.getLocalPath(url);
        if (path == null) {
          missingAny = true;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _needsResourceDownload = missingAny;
          _isCheckingResources = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingResources = false;
        });
      }
    }
  }

  Widget _buildDownloadBanner() {
    if (!_needsResourceDownload) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: Colors.indigoAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.download_for_offline_rounded, color: Colors.indigoAccent, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recursos Adicionais da Temporada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Baixe os avatares e temas da temporada atual para uma melhor visualização.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/resource-download').then((_) {
                _checkIfResourcesNeedDownload();
              });
            },
            child: const Text('Baixar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vipPulseController.dispose();
    super.dispose();
  }

  void _showClaimCelebrationDialog(BuildContext context, String title, String? value) {
    int coins = 0;
    int crystals = 0;
    String? itemName;

    if (title.contains('Moedas') || (value != null && value.contains('Moeda'))) {
      coins = int.tryParse(value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 100;
    } else if (title.contains('Cristais') || (value != null && value.contains('Cristal'))) {
      crystals = int.tryParse(value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 10;
    } else {
      itemName = value ?? title;
    }

    RewardClaimDialog.show(
      context,
      RewardItemData(
        title: 'Recompensa do Passe!',
        subtitle: title,
        coins: coins,
        crystals: crystals,
        itemName: itemName,
        mainIcon: Icons.card_giftcard_rounded,
        mainColor: Colors.amber,
      ),
    );
  }

  void _showBuyVipDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userCoins = auth.currentUser?.coins ?? 0;
    const int vipCost = 500;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Desbloquear VIP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ao ativar o Passe VIP, você desbloqueia a trilha de recompensas exclusivas e dobra seus prêmios em cada nível!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preço do Passe VIP:', style: TextStyle(color: Colors.white70)),
                  Row(
                    children: [
                      Text('🪙 ', style: TextStyle(fontSize: 16)),
                      Text(
                        '$vipCost Moedas',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu saldo atual: $userCoins moedas',
              style: TextStyle(
                color: userCoins >= vipCost ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (auth.currentUser == null) return;
              
              final seasonProv = context.read<SeasonProvider>();
              final success = await seasonProv.buyVipPass(auth.currentUser!.id);
              if (!mounted) return;

              if (success) {
                await auth.refreshUser();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Parabéns! Passe VIP ativado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(seasonProv.error ?? 'Erro ao comprar Passe VIP.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Confirmar Compra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final seasonProv = context.watch<SeasonProvider>();
    final data = seasonProv.seasonData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          data?.name ?? 'Passe de Temporada',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: seasonProv.isLoading
          ? const Center(child: LoadingLogo(size: 60))
          : seasonProv.error != null
              ? Center(
                  child: Text(
                    'Erro: ${seasonProv.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : data == null
                  ? const Center(
                      child: Text(
                        'Nenhuma temporada ativa no momento.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : _buildSeasonContent(context, data),
    );
  }

  Widget _buildSeasonContent(BuildContext context, SeasonResponse data) {
    final int pointsInCurrentLevel = data.seasonPoints % 100;
    final double progressFraction = (pointsInCurrentLevel / 100.0).clamp(0.0, 1.0);

    final assetManager = context.read<AssetManagerService>();
    final bannerUrl = ApiService.resolveImageUrl(data.bannerUrl);
    final bannerPath = bannerUrl != null ? assetManager.getLocalPathSync(bannerUrl) : null;

    return Column(
      children: [
        _buildDownloadBanner(),
        // Cabeçalho da Temporada com Efeitos e Animações
        Stack(
          children: [
            if (bannerUrl != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: LocalAssetImage(
                    imageUrl: bannerUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
            children: [
              Text(
                data.description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'Nível ${data.currentLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${data.seasonPoints} PTs acumulados',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              // Barra de Progresso Animada de EXP da Temporada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progresso do Nível', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('$pointsInCurrentLevel / 100 XP', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progressFraction),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              if (!data.isPremium)
                AnimatedBuilder(
                  animation: _vipPulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _vipPulseAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.45 * _vipPulseAnim.value),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _showBuyVipDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VipBadge(scale: 1.1),
                              SizedBox(width: 10),
                              Text(
                                'COMPRAR PASSE VIP',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                AnimatedBuilder(
                  animation: _vipPulseAnim,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.4 * _vipPulseAnim.value),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VipBadge(scale: 1.1),
                          SizedBox(width: 8),
                          Text(
                            'PASSE VIP ATIVO',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
              const SizedBox(height: 16),
              
              // Botão de Jogar Temporada (se houver categoria exclusiva)
              if (data.exclusiveCategoryId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/season-map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'JOGAR TEMA DA TEMPORADA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        ],
        ),
        
        // Lista de Recompensas
        Expanded(
          child: ListView.builder(
            reverse: false, // Normal order 1 to 30
            padding: const EdgeInsets.all(16),
            itemCount: data.rewards.length,
            itemBuilder: (context, index) {
              final reward = data.rewards[index];
              final isUnlocked = data.currentLevel > reward.levelRequired;
              
              final hasSpecialPrize = reward.premiumRewardImageUrl != null || reward.freeRewardImageUrl != null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasSpecialPrize
                        ? (isUnlocked ? Colors.amber : Colors.amber.withValues(alpha: 0.35))
                        : (isUnlocked ? Colors.blueAccent : Colors.transparent),
                    width: hasSpecialPrize ? 2 : 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Nível / Avatar de Prêmio em Destaque
                      _buildLevelBadge(reward, isUnlocked),
                      const SizedBox(width: 16),
                      
                      // Prêmios
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRewardRow(context, 'Grátis', reward.freeRewardType, reward.freeRewardValue, reward.freeRewardImageUrl, isUnlocked, false, reward.levelRequired, data),
                            if (reward.premiumRewardType != null)
                              const Divider(color: Colors.white12),
                            if (reward.premiumRewardType != null)
                              _buildRewardRow(context, 'VIP', reward.premiumRewardType, reward.premiumRewardValue, reward.premiumRewardImageUrl, isUnlocked, true, reward.levelRequired, data),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardRow(BuildContext context, String tier, String? type, String? value, String? imageUrl, bool isUnlocked, bool isPremiumRow, int levelRequired, SeasonResponse data) {
    if (type == null) return const SizedBox.shrink();
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'COIN':
        icon = Icons.monetization_on_rounded;
        iconColor = Colors.amber;
        break;
      case 'ENERGY':
        icon = Icons.bolt_rounded;
        iconColor = Colors.cyanAccent;
        break;
      case 'AVATAR':
        icon = Icons.face_rounded;
        iconColor = Colors.greenAccent;
        break;
      case 'TITLE':
        icon = Icons.badge_rounded;
        iconColor = Colors.purpleAccent;
        break;
      default:
        icon = Icons.card_giftcard_rounded;
        iconColor = Colors.white;
    }

    bool isClaimed = isPremiumRow 
        ? levelRequired <= data.lastClaimedPremiumLevel 
        : levelRequired <= data.lastClaimedFreeLevel;
        
    bool canClaim = isUnlocked && !isClaimed;
    if (isPremiumRow && !data.isPremium) {
      canClaim = false;
    }

    Widget trailing;
    if (canClaim) {
      trailing = ElevatedButton(
        onPressed: () async {
          final auth = context.read<AuthProvider>();
          final userId = auth.currentUser?.id;
          if (userId != null) {
            final success = await context.read<SeasonProvider>().claimReward(userId, levelRequired, isPremiumRow);
            if (context.mounted && success) {
              _showClaimCelebrationDialog(context, tier, value);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(60, 26),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Coletar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (isClaimed) {
      trailing = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20);
    } else if (!isUnlocked) {
      trailing = const Icon(Icons.lock_rounded, color: Colors.white24, size: 20);
    } else {
      // isUnlocked mas é VIP e user não é VIP
      trailing = const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 20);
    }

    final resolvedImageUrl = ApiService.resolveImageUrl(imageUrl);
    final hasValidImage = resolvedImageUrl != null && resolvedImageUrl.isNotEmpty;

    Widget leadingContent = SizedBox(
      width: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              tier,
              style: TextStyle(
                color: isPremiumRow ? Colors.amber : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          hasValidImage
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: isUnlocked
                        ? LocalAssetImage(imageUrl: resolvedImageUrl, fit: BoxFit.cover)
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                            child: LocalAssetImage(imageUrl: resolvedImageUrl, fit: BoxFit.cover),
                          ),
                  ),
                )
              : Icon(icon, color: isUnlocked ? iconColor : Colors.white24, size: 24),
        ],
      ),
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      leading: leadingContent,
      title: Text(
        value ?? 'Prêmio',
        style: TextStyle(
          color: isUnlocked ? Colors.white : Colors.white38,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildLevelBadge(SeasonReward reward, bool isUnlocked) {
    final specialImageUrl = ApiService.resolveImageUrl(
      reward.premiumRewardImageUrl ?? reward.freeRewardImageUrl,
    );
    final hasSpecialImage = specialImageUrl != null && specialImageUrl.isNotEmpty;

    if (!hasSpecialImage) {
      final isCoinReward = reward.freeRewardType == 'COIN' || reward.premiumRewardType == 'COIN';

      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFF2563EB) : const Color(0xFF334155),
          shape: BoxShape.circle,
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: isCoinReward
              ? Icon(
                  Icons.monetization_on_rounded,
                  color: isUnlocked ? Colors.amber : Colors.white54,
                  size: 28,
                )
              : Text(
                  '${reward.levelRequired}',
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      );
    }

    // Nível com Avatar/Prêmio Especial
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: isUnlocked ? Colors.amberAccent : Colors.amber.shade700,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: isUnlocked
                ? LocalAssetImage(
                    imageUrl: specialImageUrl,
                    fit: BoxFit.cover,
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                    child: LocalAssetImage(
                      imageUrl: specialImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Text(
              '${reward.levelRequired}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

