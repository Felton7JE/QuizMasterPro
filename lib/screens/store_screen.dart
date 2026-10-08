import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/meu_quiz_logo_text.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/auth_provider.dart';
import '../models/store_item.dart';
import '../models/title_model.dart';
import '../models/user_model.dart';
import '../config/cosmetics_config.dart';
import '../config/api_config.dart';
import '../widgets/cosmetic_avatar.dart';
import '../widgets/crystal_balance_chip.dart';
import '../widgets/vip_badge_widget.dart';
import '../widgets/local_asset_image.dart';

// ============================================================
//  Paleta de cores e utilitários de raridade
// ============================================================
class _StoreColors {
  static const bg = Color(0xFF0A0E1A);
  static const surface = Color(0xFF111827);
  static const card = Color(0xFF1A2235);
  static const cardBorder = Color(0xFF2A3A55);
  static const accent = Color(0xFF6366F1);
  static const accentGlow = Color(0x446366F1);
  static const gold = Color(0xFFFFD700);
  static const goldGlow = Color(0x44FFD700);
  static const success = Color(0xFF10B981);
  static const textPrimary = Color(0xFFEDF2F7);
  static const textSecondary = Color(0xFF94A3B8);
  static const bannerGradStart = Color(0xFF7C3AED);
  static const bannerGradEnd = Color(0xFF4F46E5);
  static const phraseGradStart = Color(0xFF0EA5E9);
  static const phraseGradEnd = Color(0xFF6366F1);
  static const phraseGlow = Color(0x440EA5E9);
  static const titleGradStart = Color(0xFFD97706);
  static const titleGradEnd = Color(0xFFEF4444);
}

// ============================================================
//  StoreScreen principal
// ============================================================
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0; // 0 = Banners, 1 = Frases

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final coins = user?.coins ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: _StoreColors.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: MeuQuizLogoText(
          fontSize: isSmallScreen ? 18 : 20,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _CoinsWidget(coins: coins),
          const SizedBox(width: 8),
          const CrystalBalanceChip(),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigoAccent,
          labelColor: Colors.indigoAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Cosméticos'),
            Tab(text: 'Títulos'),
            Tab(text: '🔮 Cristais & VIP'),
          ],
        ),
      ),
      body: Consumer<StoreProvider>(
        builder: (context, store, _) {
          if (store.isLoading) return _buildShimmerGrid();
          if (store.error != null) return _buildErrorState(store);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCosmeticsTab(store),
              _buildTitlesTab(store),
              _buildCrystalsAndVipTab(context, store),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCarousels(
    List<StoreItem> items, 
    StoreProvider store, 
    Widget Function(StoreItem item) cardBuilder,
  ) {
    if (items.isEmpty) {
      return [
        const SliverToBoxAdapter(child: _EmptyState(message: 'Nenhum item disponível.')),
      ];
    }
    
    final slivers = <Widget>[];

    // Destaques (Top 5 items by ID)
    final featured = items.toList()..sort((a, b) => b.id.compareTo(a.id));
    final topFeatured = featured.take(5).toList();
    if (topFeatured.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text('Itens em Destaque', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topFeatured.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) => SizedBox(width: 160, child: cardBuilder(topFeatured[i])),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    // Rarities
    final rarities = ['LEGENDARY', 'EPIC', 'RARE', 'COMMON'];
    for (final rarity in rarities) {
      final rarityItems = items.where((i) => (i.rarity).toUpperCase() == rarity).toList();
      if (rarityItems.isEmpty) continue;

      Color rarityColor;
      String rarityLabel;
      switch (rarity) {
        case 'LEGENDARY': rarityColor = Colors.orange; rarityLabel = 'Lendário'; break;
        case 'EPIC': rarityColor = Colors.purpleAccent; rarityLabel = 'Épico'; break;
        case 'RARE': rarityColor = Colors.lightBlueAccent; rarityLabel = 'Raro'; break;
        default: rarityColor = Colors.grey; rarityLabel = 'Comum'; break;
      }

      slivers.add(
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: rarityColor, size: 20),
                    const SizedBox(width: 8),
                    Text(rarityLabel, style: TextStyle(color: rarityColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rarityItems.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) => SizedBox(width: 160, child: cardBuilder(rarityItems[i])),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return slivers;
  }

  // ----------------------------------------------------------
  //  Tab de CosmÃ©ticos
  // ----------------------------------------------------------
  Widget _buildCosmeticsTab(StoreProvider store) {
    // Filtrar por tipo
    final bannerItems = [
      ...store.availableItems.where((i) => i.type == 'BANNER'),
      ...store.purchasedItems.where((i) => i.type == 'BANNER'),
    ];
    final phraseItems = [
      ...store.availableItems.where((i) => i.type == 'TEXT_PHRASE'),
      ...store.purchasedItems.where((i) => i.type == 'TEXT_PHRASE'),
    ];
    final emoteItems = [
      ...store.availableItems.where((i) => i.type == 'EMOTE' || i.type == 'EMOJI'),
      ...store.purchasedItems.where((i) => i.type == 'EMOTE' || i.type == 'EMOJI'),
    ];
    final avatarItems = [
      ...store.availableItems.where((i) => i.type == 'AVATAR'),
      ...store.purchasedItems.where((i) => i.type == 'AVATAR'),
    ];
    final frameItems = [
      ...store.availableItems.where((i) => i.type == 'PROFILE_FRAME'),
      ...store.purchasedItems.where((i) => i.type == 'PROFILE_FRAME'),
    ];
    final extraItems = [
      ...store.availableItems
          .where((i) => ['ENERGY_REFILL', 'XP_BOOST'].contains(i.type)),
      ...store.purchasedItems
          .where((i) => ['ENERGY_REFILL', 'XP_BOOST'].contains(i.type)),
    ];

    final bool hasBanners = bannerItems.isNotEmpty;
    final bool hasPhrases = phraseItems.isNotEmpty;
    final bool hasEmotes = emoteItems.isNotEmpty;
    final bool hasAvatars = avatarItems.isNotEmpty;
    final bool hasFrames = frameItems.isNotEmpty;
    final bool hasExtras = extraItems.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // Selector de sub-categoria
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'Banners',
                    icon: Icons.image_rounded,
                    isSelected: _selectedCategoryIndex == 0,
                    gradient: const LinearGradient(colors: [
                      _StoreColors.bannerGradStart,
                      _StoreColors.bannerGradEnd
                    ]),
                    onTap: () => setState(() => _selectedCategoryIndex = 0),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: 'Frases',
                    icon: Icons.chat_bubble_rounded,
                    isSelected: _selectedCategoryIndex == 1,
                    gradient: const LinearGradient(colors: [
                      _StoreColors.phraseGradStart,
                      _StoreColors.phraseGradEnd
                    ]),
                    onTap: () => setState(() => _selectedCategoryIndex = 1),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: 'Emojis',
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    isSelected: _selectedCategoryIndex == 2,
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF5722),
                      Color(0xFFFF9800),
                    ]),
                    onTap: () => setState(() => _selectedCategoryIndex = 2),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: 'Avatares',
                    icon: Icons.face_rounded,
                    isSelected: _selectedCategoryIndex == 3,
                    gradient: const LinearGradient(
                        colors: [Colors.purpleAccent, Colors.deepPurple]),
                    onTap: () => setState(() => _selectedCategoryIndex = 3),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: 'Molduras',
                    icon: Icons.crop_square_rounded,
                    isSelected: _selectedCategoryIndex == 4,
                    gradient: const LinearGradient(
                        colors: [Colors.orangeAccent, Colors.deepOrange]),
                    onTap: () => setState(() => _selectedCategoryIndex = 4),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: 'Extras',
                    icon: Icons.star_rounded,
                    isSelected: _selectedCategoryIndex == 5,
                    gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.teal]),
                    onTap: () => setState(() => _selectedCategoryIndex = 5),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_selectedCategoryIndex == 0) ...[
          _buildSectionHeader(
              'Banners',
              Icons.image_rounded,
              const LinearGradient(colors: [
                _StoreColors.bannerGradStart,
                _StoreColors.bannerGradEnd
              ])),
          if (!hasBanners)
            const SliverToBoxAdapter(
              child: _EmptyState(message: 'Nenhum banner disponível.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _BannerCard(
                    item: bannerItems[i],
                    isPurchased: store.purchasedItems.contains(bannerItems[i]),
                    store: store,
                    onBuy: () => _handleBuy(bannerItems[i], store),
                    onEquip: () => _handleEquip(bannerItems[i], store),
                  ),
                  childCount: bannerItems.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
              ),
            ),
        ] else if (_selectedCategoryIndex == 1) ...[
          // Header de secção Frases
          _buildSectionHeader(
              'Frases Provocativas',
              Icons.chat_bubble_rounded,
              const LinearGradient(colors: [
                _StoreColors.phraseGradStart,
                _StoreColors.phraseGradEnd
              ])),

          if (!hasPhrases)
            const SliverToBoxAdapter(
              child: _EmptyState(message: 'Nenhuma frase disponível.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PhraseCard(
                    item: phraseItems[i],
                    isPurchased: store.purchasedItems.contains(phraseItems[i]),
                    store: store,
                    onBuy: () => _handleBuy(phraseItems[i], store),
                    onEquip: () => _handleEquip(phraseItems[i], store),
                  ),
                  childCount: phraseItems.length,
                ),
              ),
            )
        ] else if (_selectedCategoryIndex == 2) ...[
          // ---------- EMOJIS & REAÇÕES ----------
          _buildSectionHeader(
              'Emojis & Reações',
              Icons.sentiment_satisfied_alt_rounded,
              const LinearGradient(colors: [
                Color(0xFFFF5722),
                Color(0xFFFF9800),
              ])),

          if (!hasEmotes)
            const SliverToBoxAdapter(
              child: _EmptyState(message: 'Nenhum emoji disponível no momento.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _EmoteCard(
                    item: emoteItems[i],
                    isPurchased: store.purchasedItems.any((p) => p.id == emoteItems[i].id),
                    store: store,
                    onBuy: () => _handleBuy(emoteItems[i], store),
                    onEquip: () => _handleEquip(emoteItems[i], store),
                  ),
                  childCount: emoteItems.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
              ),
            ),
        ] else if (_selectedCategoryIndex == 3) ...[
          // ---------- AVATARES ----------
          if (!hasAvatars)
            const SliverToBoxAdapter(
              child: _EmptyState(message: 'Nenhum avatar disponível.'),
            )
          else ...() {
            // Agrupar avatares por raridade
            final Map<String, List<StoreItem>> groupedAvatares = {};
            for (var item in avatarItems) {
              final r = item.rarity;
              if (!groupedAvatares.containsKey(r)) {
                groupedAvatares[r] = [];
              }
              groupedAvatares[r]!.add(item);
            }
            
            // Definir a ordem e configurações de cada raridade
            final rarities = [
              {'name': 'Básico', 'icon': Icons.person_outline, 'colors': [Colors.grey.shade400, Colors.grey.shade600]},
              {'name': 'Comum', 'icon': Icons.face_rounded, 'colors': [Colors.blue.shade300, Colors.blue.shade500]},
              {'name': 'Incomum', 'icon': Icons.videogame_asset_rounded, 'colors': [Colors.green.shade400, Colors.green.shade600]},
              {'name': 'Raro', 'icon': Icons.auto_awesome, 'colors': [Colors.purple.shade400, Colors.purple.shade600]},
              {'name': 'Épico', 'icon': Icons.local_fire_department_rounded, 'colors': [Colors.orange.shade400, Colors.deepOrange.shade600]},
              {'name': 'Lendário', 'icon': Icons.workspace_premium_rounded, 'colors': [Colors.amber.shade400, Colors.amber.shade700]},
              {'name': 'Supremo', 'icon': Icons.diamond_rounded, 'colors': [Colors.pinkAccent.shade400, Colors.purpleAccent.shade700]},
            ];

            List<Widget> slivers = [];
            
            for (var r in rarities) {
              final rName = r['name'] as String;
              if (groupedAvatares.containsKey(rName) && groupedAvatares[rName]!.isNotEmpty) {
                final groupItems = groupedAvatares[rName]!;
                
                slivers.add(
                  _buildSectionHeader(
                    rName.toUpperCase(),
                    r['icon'] as IconData,
                    LinearGradient(colors: r['colors'] as List<Color>)
                  )
                );
                
                slivers.add(
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupItems.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                        itemBuilder: (ctx, i) => SizedBox(
                          width: 150,
                          child: _AvatarCard(
                            item: groupItems[i],
                            isPurchased: store.purchasedItems.any((p) => p.id == groupItems[i].id),
                            store: store,
                            onBuy: () => _handleBuy(groupItems[i], store),
                            onEquip: () => _handleEquip(groupItems[i], store),
                          ),
                        ),
                      ),
                    ),
                  )
                );
              }
            }
            
            // Adicionar itens que possam não ter caído nas raridades predefinidas
            final predefinedKeys = rarities.map((e) => e['name'] as String).toList();
            for (var key in groupedAvatares.keys) {
              if (!predefinedKeys.contains(key)) {
                final groupItems = groupedAvatares[key]!;
                slivers.add(
                  _buildSectionHeader(
                    key.toUpperCase(),
                    Icons.face_rounded,
                    const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)])
                  )
                );
                slivers.add(
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupItems.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                        itemBuilder: (ctx, i) => SizedBox(
                          width: 150,
                          child: _AvatarCard(
                            item: groupItems[i],
                            isPurchased: store.purchasedItems.any((p) => p.id == groupItems[i].id),
                            store: store,
                            onBuy: () => _handleBuy(groupItems[i], store),
                            onEquip: () => _handleEquip(groupItems[i], store),
                          ),
                        ),
                      ),
                    ),
                  )
                );
              }
            }
            
            return slivers;
          }(),
        ] else if (_selectedCategoryIndex == 4) ...[
          // ---------- MOLDURAS ----------
          _buildSectionHeader(
              'Molduras',
              Icons.crop_square_rounded,
              const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEF4444)])),
          if (!hasFrames)
            const SliverToBoxAdapter(
              child: _EmptyState(message: 'Nenhuma moldura disponível.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FrameCard(
                    item: frameItems[i],
                    isPurchased: store.purchasedItems
                        .any((p) => p.id == frameItems[i].id),
                    store: store,
                    onBuy: () => _handleBuy(frameItems[i], store),
                    onEquip: () => _handleEquip(frameItems[i], store),
                  ),
                  childCount: frameItems.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
              ),
            ),
        ] else if (_selectedCategoryIndex == 5) ...[
          // ---------- EXTRAS ----------
          _buildSectionHeader(
              'Itens Consumíveis',
              Icons.bolt_rounded,
              const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF0EA5E9)])),
          ..._buildCarousels(extraItems, store, (item) => _ExtraCard(
            item: item,
            isPurchased: store.purchasedItems.any((p) => p.id == item.id),
            store: store,
            onBuy: () => _handleBuy(item, store),
            onConsume: () => _handleConsume(item, store),
          )),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ----------------------------------------------------------
  //  Tab de Titulos
  // ----------------------------------------------------------
  Widget _buildTitlesTab(StoreProvider store) {
    return CustomScrollView(
      slivers: [
        if (store.earnedTitles.isNotEmpty) ...[
          _buildSectionHeader(
              'Meus Titulos',
              Icons.workspace_premium_rounded,
              const LinearGradient(colors: [
                _StoreColors.titleGradStart,
                _StoreColors.titleGradEnd
              ])),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TitleCard(
                  title: store.earnedTitles[i],
                  isEarned: true,
                  store: store,
                  onEquip: () =>
                      _handleEquipTitle(store.earnedTitles[i], store),
                ),
                childCount: store.earnedTitles.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        _buildSectionHeader(
            'Titulos a Conquistar',
            Icons.lock_outline_rounded,
            LinearGradient(colors: [
              Colors.grey.shade700,
              Colors.grey.shade600,
            ])),
        if (store.availableTitles.isEmpty)
          const SliverToBoxAdapter(
            child:
                _EmptyState(message: 'Todos os titulos foram conquistados!'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TitleCard(
                  title: store.availableTitles[i],
                  isEarned: false,
                  store: store,
                ),
                childCount: store.availableTitles.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ----------------------------------------------------------
  //  Sliver section header
  // ----------------------------------------------------------
  Widget _buildSectionHeader(String title, IconData icon, Gradient gradient) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (gradient as LinearGradient)
                        .colors
                        .first
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: _StoreColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  //  Shimmer de carregamento
  // ----------------------------------------------------------
  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }

  // ----------------------------------------------------------
  //  Estado de erro
  // ----------------------------------------------------------
  Widget _buildErrorState(StoreProvider store) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            store.error!,
            style: const TextStyle(color: _StoreColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => store.loadAllData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _StoreColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Tentar Novamente',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  //  Helpers de localização do item
  // ----------------------------------------------------------
  String _getEquipLocation(StoreItem item) {
    switch (item.type) {
      case 'AVATAR':        return 'Loja → Avatares ou Menu → Perfil';
      case 'PROFILE_FRAME': return 'Loja → Molduras ou Menu → Perfil';
      case 'BANNER':        return 'Loja → Banners ou Menu → Perfil';
      case 'TEXT_PHRASE':   return 'Loja → Frases ou Menu → Perfil';
      case 'EMOTE':
      case 'EMOJI':         return 'Loja → Emojis ou Menu → Perfil';
      case 'ENERGY_REFILL': return 'Loja → Extras (usa automaticamente)';
      case 'XP_BOOST':      return 'Loja → Extras (usa automaticamente)';
      default:              return 'Loja → Cosméticos';
    }
  }

  IconData _getItemIcon(StoreItem item) {
    switch (item.type) {
      case 'AVATAR':        return Icons.face_rounded;
      case 'PROFILE_FRAME': return Icons.crop_square_rounded;
      case 'BANNER':        return Icons.image_rounded;
      case 'TEXT_PHRASE':   return Icons.chat_bubble_rounded;
      case 'EMOTE':
      case 'EMOJI':         return Icons.sentiment_satisfied_alt_rounded;
      case 'ENERGY_REFILL': return Icons.bolt_rounded;
      case 'XP_BOOST':      return Icons.star_rounded;
      default:              return Icons.shopping_bag_rounded;
    }
  }

  // ----------------------------------------------------------
  //  Dialog de confirmação de compra
  // ----------------------------------------------------------
  Future<bool> _showPurchaseConfirmDialog(StoreItem item) async {
    final resolvedUrl = ApiConfig.resolveAssetUrl(item.value);
    final isAvatar = item.type == 'AVATAR';
    final isEmote = item.type == 'EMOTE' || item.type == 'EMOJI';

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
                        child: LocalAssetImage(
                          imageUrl: resolvedUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : isEmote
                        ? Center(
                            child: Text(
                              item.value,
                              style: const TextStyle(fontSize: 42),
                            ),
                          )
                        : Icon(_getItemIcon(item), size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // ── Texto ────────────────────────────────────
              const Text(
                'Confirmar Compra',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // ── Preço ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '${item.price} moedas',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                        'Confirmar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  // ----------------------------------------------------------
  //  Dialog de sucesso pós-compra
  // ----------------------------------------------------------
  void _showPurchaseSuccessDialog(StoreItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Ícone de sucesso animado ──────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Compra realizada!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // ── Onde equipar ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3A55)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Encontre seu item em:',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getItemIcon(item), color: const Color(0xFF6366F1), size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getEquipLocation(item),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
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
                    'Entendido!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  //  Handlers de acção
  // ----------------------------------------------------------
  Future<void> _handleBuy(StoreItem item, StoreProvider store) async {
    // 1. Mostrar dialog de confirmação
    final confirmed = await _showPurchaseConfirmDialog(item);
    if (!confirmed || !mounted) return;

    // 2. Processar a compra
    final success = await store.buyItem(item);
    if (!mounted) return;

    if (success) {
      // 3. Mostrar dialog de sucesso com indicação de onde equipar
      _showPurchaseSuccessDialog(item);
    } else {
      // Erro: mostrar snackbar vermelho
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.redAccent,
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  store.error ?? 'Erro ao comprar item.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleEquip(StoreItem item, StoreProvider store) async {
    final success = await store.equipItem(item);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _StoreColors.accent,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('${item.name} equipado!',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    } else if (store.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(store.error!,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleConsume(StoreItem item, StoreProvider store) async {
    final success = await store.consumeItem(item.type);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: success ? _StoreColors.success : Colors.redAccent,
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              success
                  ? '${item.name} usado com sucesso! ⚡'
                  : store.error ?? 'Erro ao usar item.',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEquipTitle(TitleModel title, StoreProvider store) async {
    final success = await store.equipTitle(title);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _StoreColors.gold.withValues(alpha: 0.9),
          content: Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Título "${title.name}" equipado! 👑',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------
  //  Tab de Cristais Mágicos 🔮 e Desbloqueio VIP
  // ----------------------------------------------------------
  Widget _buildCrystalsAndVipTab(BuildContext context, StoreProvider store) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isVip = user?.isVip ?? false;
    final crystals = user?.crystals ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Destaque VIP
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B0764),
                  Color(0xFF1E1B4B),
                  Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isVip ? const Color(0xFFFFD700) : const Color(0xFFA855F7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isVip ? const Color(0xFFFFD700) : const Color(0xFFA855F7))
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('👑', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Passe VIP Meu Quiz +',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isVip)
                                    const VipBadge(scale: 0.9)
                                  else
                                    const Text(
                                      'Desbloqueio Permanente',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vantagens Exclusivas VIP:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVipPerkRow(Icons.auto_awesome, '10 Quizzes de Estudo IA por dia (0 Cristais)'),
                _buildVipPerkRow(Icons.timer_outlined, 'Cooldown Ultrarrápido de apenas 3 minutos'),
                _buildVipPerkRow(Icons.verified, 'Selo VIP Dourado oficial em todos os modos e rankings'),
                _buildVipPerkRow(Icons.stars_rounded, 'Bónus de 2x XP e multiplicador de recompensas'),
                const SizedBox(height: 18),
                if (isVip)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'STATUS VIP ATIVO ⭐',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: const Text('👑', style: TextStyle(fontSize: 18)),
                      label: const Text(
                        'Assinar Passe VIP (250 MT / mês)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () => _buyVipWithCrystals(context, auth),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Seção de Indicação / Referral (5 amigos = 15 cristais)
          _buildReferralCard(user, auth),
          const SizedBox(height: 18),
          
          // Seção de Resgate de Código Promocional
          _buildPromoCodeCard(context, auth),
          const SizedBox(height: 24),

          // Seção de Pacotes de Cristais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔮 Pacotes de Cristais Mágicos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1065),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Text('🔮', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$crystals',
                      style: const TextStyle(
                        color: Color(0xFFE9D5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...CrystalShopModal.crystalPacks.map((pack) {
            final isPopular = pack['isPopular'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161C30),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPopular
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFA855F7).withValues(alpha: 0.3),
                  width: isPopular ? 1.8 : 1.0,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1065),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      pack['icon'] as String,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${pack['crystals']} Cristais',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (pack['bonus'] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${pack['bonus']} BÓNUS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  pack['title'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFA855F7),
                    foregroundColor: isPopular ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final added = (pack['crystals'] as int) + (pack['bonus'] as int);
                    
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF131127),
                        title: const Text('Confirmar Compra', style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Desejas comprar o pacote ${pack['title']} por ${pack['price']}?',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
                            child: const Text('Comprar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && context.mounted) {
                      final updated = user!.copyWith(crystals: user.crystals + added);
                      auth.updateUser(updated);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('🎉 Recebeste +$added Cristais Mágicos!'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    pack['price'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVipPerkRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(UserModel? user, AuthProvider auth) {
    final referralCode = user?.referralCode ?? 'QM-PRO';
    final count = user?.referralCount ?? 0;
    final inCycle = count % 5;
    final needed = 5 - inCycle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF3B0764)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎁', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convide Amigos & Ganhe Cristais',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'A cada 5 amigos = +15 Cristais 🔮',
                      style: TextStyle(
                        color: Color(0xFFE9D5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Partilha o teu código único com colegas. Quando eles se cadastrarem e resgatarem o teu código, vocês dois ganham!',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Caixa do Código de Convite
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEU CÓDIGO DE CONVITE',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      referralCode,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copiar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Código de convite copiado para a área de transferência!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Barra de Progresso para a próxima recompensa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso: $inCycle/5 convites',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Faltam $needed para +15 🔮',
                style: const TextStyle(color: Color(0xFFFDE047), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: inCycle / 5.0,
              minHeight: 8,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total de amigos convidados: $count',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Botão para resgatar código recebido de amigo
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE9D5FF),
                side: const BorderSide(color: Color(0xFFA855F7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
              label: const Text('Foste convidado? Resgatar Código (+5 🔮)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () => _showRedeemReferralDialog(context, auth),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemReferralDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎁 ', style: TextStyle(fontSize: 22)),
            Text('Resgatar Código de Convite', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insere o código de convite fornecido pelo teu amigo para receberes 5 Cristais Mágicos 🔮 de boas-vindas!',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'QM-XXXXX',
                hintStyle: TextStyle(color: Colors.grey.shade600, letterSpacing: 2),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);

              final message = await auth.applyReferralCode(code);
              if (context.mounted && message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: message.contains('sucesso') ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Resgatar (+5 🔮)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _buyVipWithCrystals(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    if (user == null) return;

    if (user.crystals < 50) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('🔮 ', style: TextStyle(fontSize: 22)),
              Text('Cristais Insuficientes', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Text(
            'Precisas de 50 Cristais 🔮 para desbloquear o status VIP.\nTens atualmente ${user.crystals} Cristais.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('👑 ', style: TextStyle(fontSize: 22)),
            Text('Desbloquear VIP', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Desejas gastar 50 Cristais 🔮 para ativar permanentemente o teu Passe VIP Meu Quiz +?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.buyVip();
              
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF10B981),
                      content: Text('🎉 Parabéns! O teu Status VIP foi ativado permanentemente! 👑'),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text('Erro ao ativar VIP. Tenta novamente mais tarde.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar (50 🔮)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeCard(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF818CF8), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resgatar Código Promocional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ganhe cristais via desenvolvedor ou eventos',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPromoCodeDialog(context, auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Resgatar Código',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoCodeDialog(BuildContext context, AuthProvider auth) {
    final TextEditingController controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF131127),
          title: const Text('Código Promocional', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Insira o código fornecido pelo desenvolvedor.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: VIP100',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setState(() => isLoading = true);
                      
                      final msg = await auth.redeemPromoCode(controller.text);
                      
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            backgroundColor: msg != null && msg.contains('resgatado')
                                ? const Color(0xFF10B981)
                                : Colors.redAccent,
                            content: Text(msg ?? 'Erro.'),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Resgatar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Widgets utilitÃ¡rios reutilizÃ¡veis
// ============================================================

/// Widget de moedas no header
class _CoinsWidget extends StatelessWidget {
  final int coins;
  const _CoinsWidget({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _StoreColors.gold.withValues(alpha: 0.15),
            _StoreColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _StoreColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: _StoreColors.gold, size: 18),
          const SizedBox(width: 6),
          Text(
            _formatCoins(coins),
            style: const TextStyle(
              color: _StoreColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int c) {
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}k';
    return '$c';
  }
}

/// Chip de categoria
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : _StoreColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : _StoreColors.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (gradient as LinearGradient)
                        .colors
                        .first
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : _StoreColors.textSecondary,
                size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _StoreColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Estado vazio
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              color: _StoreColors.textSecondary.withValues(alpha: 0.5),
              size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: _StoreColors.textSecondary.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ============================================================
//  Card de Banner
// ============================================================
class _BannerCard extends StatefulWidget {
  final StoreItem item;
  final bool isPurchased;
  final StoreProvider store;
  final Future<void> Function() onBuy;
  final VoidCallback onEquip;

  const _BannerCard({
    required this.item,
    required this.isPurchased,
    required this.store,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  Future<void> _buy() async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    await widget.onBuy();
    if (mounted) setState(() => _isBuying = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isActive = authProvider.currentUser?.activeBannerId == widget.item.id;

    // Não precisamos de gradiente, apenas da imagem
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _StoreColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? _StoreColors.accent : _StoreColors.cardBorder,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: _StoreColors.accentGlow,
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview do banner real
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LocalAssetImage(
                        imageUrl: ApiConfig.resolveAssetUrl(widget.item.value, isThumb: true) ?? '',
                        fit: BoxFit.cover,
                      ),

                      // PadrÃ£o geomÃ©trico decorativo
                      CustomPaint(painter: _GeometricPatternPainter()),
                      // Ãcone central
                      const Center(
                        child: Icon(Icons.image_rounded,
                            color: Colors.white54, size: 40),
                      ),
                      // Badge "EQUIPADO"
                      if (isActive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _StoreColors.success,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _StoreColors.success
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'EQUIPADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      // Badge "POSSUÍDO" (nÃ£o equipado)
                      if (widget.isPurchased && !isActive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _StoreColors.accent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'POSSUÍDO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info e botÃ£o
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        color: _StoreColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.description,
                      style: const TextStyle(
                          color: _StoreColors.textSecondary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: widget.isPurchased
                          ? ElevatedButton(
                              onPressed: isActive ? null : widget.onEquip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Colors.grey.shade800
                                    : _StoreColors.accent,
                                disabledBackgroundColor: Colors.grey.shade800,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              child: Text(
                                isActive ? 'Equipado âœ“' : 'Equipar',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.grey.shade500
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isBuying ? null : _buy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _StoreColors.gold.withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                        color: _StoreColors.gold
                                            .withValues(alpha: 0.4))),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              child: _isBuying
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _StoreColors.gold))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.monetization_on_rounded,
                                            color: _StoreColors.gold, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.item.price}',
                                          style: const TextStyle(
                                            color: _StoreColors.gold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
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
        ),
      ),
    );
  }
}

// ============================================================
//  Card de Frase Provocativa
// ============================================================
class _PhraseCard extends StatefulWidget {
  final StoreItem item;
  final bool isPurchased;
  final StoreProvider store;
  final Future<void> Function() onBuy;
  final VoidCallback onEquip;

  const _PhraseCard({
    required this.item,
    required this.isPurchased,
    required this.store,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  bool _isBuying = false;

  Future<void> _buy() async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    await widget.onBuy();
    if (mounted) setState(() => _isBuying = false);
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final isActive = storeProvider.isItemEquipped(widget.item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _StoreColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _StoreColors.accent : _StoreColors.cardBorder,
        ),
        boxShadow: isActive
            ? [
                const BoxShadow(
                  color: _StoreColors.phraseGlow,
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Ícone decorativo com gradiente
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _StoreColors.phraseGradStart,
                  _StoreColors.phraseGradEnd
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _StoreColors.phraseGradStart.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${widget.item.value}"',
                  style: const TextStyle(
                    color: _StoreColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.name,
                  style: const TextStyle(
                      color: _StoreColors.textSecondary, fontSize: 11),
                ),
                if (widget.isPurchased)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _StoreColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _StoreColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Possuído',
                        style: TextStyle(
                            color: _StoreColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botão de acção
          widget.isPurchased
              ? ElevatedButton(
                  onPressed: isActive ? null : widget.onEquip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isActive ? Colors.grey.shade800 : _StoreColors.accent,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(isActive ? 'Equipado' : 'Equipar',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              : GestureDetector(
                  onTap: _isBuying ? null : _buy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _StoreColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _StoreColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: _isBuying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _StoreColors.gold))
                        : Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: _StoreColors.gold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.item.price}',
                                style: const TextStyle(
                                  color: _StoreColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
}

// ============================================================
//  Card de Emoji / Emote
// ============================================================
class _EmoteCard extends StatefulWidget {
  final StoreItem item;
  final bool isPurchased;
  final StoreProvider store;
  final Future<void> Function() onBuy;
  final VoidCallback onEquip;

  const _EmoteCard({
    required this.item,
    required this.isPurchased,
    required this.store,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  State<_EmoteCard> createState() => _EmoteCardState();
}

class _EmoteCardState extends State<_EmoteCard> {
  bool _isBuying = false;

  Future<void> _buy() async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    await widget.onBuy();
    if (mounted) setState(() => _isBuying = false);
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final isActive = storeProvider.isItemEquipped(widget.item.id);

    return Container(
      decoration: BoxDecoration(
        color: _StoreColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.amberAccent : _StoreColors.cardBorder,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji Container
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [Colors.amber.shade700, Colors.deepOrange.shade600]
                    : [const Color(0xFF232D42), const Color(0xFF161F30)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.item.value,
              style: const TextStyle(fontSize: 34),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.amberAccent : _StoreColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          widget.isPurchased
              ? SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: isActive ? null : widget.onEquip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActive ? Colors.grey.shade800 : const Color(0xFF6366F1),
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      isActive ? 'Equipado' : 'Equipar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _isBuying ? null : _buy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _StoreColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _StoreColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: _isBuying
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _StoreColors.gold))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: _StoreColors.gold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.item.price}',
                                style: const TextStyle(
                                  color: _StoreColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
}

// ============================================================
//  Card de Título
// ============================================================
class _TitleCard extends StatelessWidget {
  final TitleModel title;
  final bool isEarned;
  final StoreProvider store;
  final VoidCallback? onEquip;

  const _TitleCard({
    required this.title,
    required this.isEarned,
    required this.store,
    this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isActive = authProvider.currentUser?.activeTitleId == title.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _StoreColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _StoreColors.gold.withValues(alpha: 0.6)
              : (isEarned
                  ? _StoreColors.gold.withValues(alpha: 0.2)
                  : _StoreColors.cardBorder),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                const BoxShadow(
                  color: _StoreColors.goldGlow,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Row(
        children: [
          // Ãcone
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: isEarned
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _StoreColors.titleGradStart,
                        _StoreColors.titleGradEnd
                      ],
                    )
                  : null,
              color: isEarned ? null : _StoreColors.cardBorder,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color:
                            _StoreColors.titleGradStart.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isEarned ? Icons.workspace_premium_rounded : Icons.lock_rounded,
              color: isEarned ? Colors.white : _StoreColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.name,
                        style: TextStyle(
                          color: isEarned
                              ? _StoreColors.gold
                              : _StoreColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _StoreColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _StoreColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: const Text('ACTIVO',
                            style: TextStyle(
                                color: _StoreColors.gold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title.description,
                  style: const TextStyle(
                      color: _StoreColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                _buildConditionChip(title),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // BotÃ£o ou Ã­cone de cadeado
          if (isEarned && onEquip != null)
            ElevatedButton(
              onPressed: isActive ? null : onEquip,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActive ? Colors.grey.shade800 : _StoreColors.gold,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                isActive ? 'âœ“' : 'Equipar',
                style: TextStyle(
                  color: isActive ? Colors.grey.shade500 : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else if (!isEarned)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _StoreColors.cardBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: _StoreColors.textSecondary, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildConditionChip(TitleModel title) {
    final condMap = {
      'GAMES_PLAYED': (
        'Jogar ${title.conditionValue}x',
        Icons.sports_esports_rounded
      ),
      'WINS': ('Vencer ${title.conditionValue}x', Icons.emoji_events_rounded),
      'LEVEL': ('Nível ${title.conditionValue}', Icons.trending_up_rounded),
    };
    final cond = condMap[title.conditionType];
    if (cond == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _StoreColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _StoreColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cond.$2, size: 11, color: _StoreColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            cond.$1,
            style: const TextStyle(
                color: _StoreColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Shimmer Card (estado de carregamento)
// ============================================================
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.3 + (_anim.value * 0.4);
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(
                const Color(0xFF1A2235), const Color(0xFF2A3A55), _anim.value),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _StoreColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _StoreColors.cardBorder.withValues(alpha: opacity),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color:
                            _StoreColors.cardBorder.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 70,
                      decoration: BoxDecoration(
                        color: _StoreColors.cardBorder
                            .withValues(alpha: opacity * 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            _StoreColors.cardBorder.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
//  Painter de padrÃ£o geomÃ©trico para os banners
// ============================================================
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Linhas diagonais decorativas
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // CÃ­rculo central decorativo
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        size.height * 0.55, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
//  Card de Avatar
// ============================================================
class _AvatarCard extends StatefulWidget {
  final StoreItem item;
  final bool isPurchased;
  final StoreProvider store;
  final Future<void> Function() onBuy;
  final VoidCallback onEquip;

  const _AvatarCard({
    required this.item,
    required this.isPurchased,
    required this.store,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  Future<void> _buy() async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    await widget.onBuy();
    if (mounted) setState(() => _isBuying = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isActive = authProvider.currentUser?.activeAvatarId == widget.item.id;

    final colorPair = CosmeticsConfig.getAvatarColors(widget.item.id);

    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _StoreColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? const Color(0xFF8B5CF6) : _StoreColors.cardBorder,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [const BoxShadow(color: Color(0x448B5CF6), blurRadius: 16, spreadRadius: 2)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Avatar circular preview
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorPair[0].withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: CosmeticAvatar(
                      radius: 40,
                      avatarUrl: ApiConfig.resolveAssetUrl(widget.item.value),
                      username: authProvider.currentUser?.username ?? '?',
                      activeAvatarId: widget.item.id,
                      isVip: authProvider.currentUser?.isVip ?? false,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _StoreColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        color: _StoreColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.description,
                      style: const TextStyle(
                          color: _StoreColors.textSecondary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: widget.isPurchased
                          ? ElevatedButton(
                              onPressed: isActive ? null : widget.onEquip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Colors.grey.shade800
                                    : const Color(0xFF8B5CF6),
                                disabledBackgroundColor: Colors.grey.shade800,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              child: Text(
                                isActive ? 'Equipado' : 'Equipar',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _isBuying ? null : _buy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _StoreColors.gold,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              icon: _isBuying
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.monetization_on_rounded,
                                      color: Colors.white, size: 14),
                              label: Text(
                                _isBuying ? '' : '${widget.item.price}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Card de Moldura (Frame)
// ============================================================
class _FrameCard extends StatefulWidget {
  final StoreItem item;
  final bool isPurchased;
  final StoreProvider store;
  final Future<void> Function() onBuy;
  final VoidCallback onEquip;

  const _FrameCard({
    required this.item,
    required this.isPurchased,
    required this.store,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  State<_FrameCard> createState() => _FrameCardState();
}

class _FrameCardState extends State<_FrameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  Future<void> _buy() async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    await widget.onBuy();
    if (mounted) setState(() => _isBuying = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isActive = authProvider.currentUser?.activeFrameId == widget.item.id;

    final colorPair = CosmeticsConfig.getFrameColors(widget.item.id) ?? [Colors.grey, Colors.grey];

    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _StoreColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? colorPair[0] : _StoreColors.cardBorder,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: colorPair[0].withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Frame preview — círculo com moldura colorida
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorPair[0].withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: CosmeticAvatar(
                      radius: 40,
                      avatarUrl: authProvider.currentUser?.avatar,
                      username: authProvider.currentUser?.username ?? '?',
                      activeFrameId: widget.item.id,
                      isVip: authProvider.currentUser?.isVip ?? false,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _StoreColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        color: _StoreColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.description,
                      style: const TextStyle(
                          color: _StoreColors.textSecondary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: widget.isPurchased
                          ? ElevatedButton(
                              onPressed: isActive ? null : widget.onEquip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Colors.grey.shade800
                                    : colorPair[0],
                                disabledBackgroundColor: Colors.grey.shade800,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              child: Text(
                                isActive ? 'Equipada' : 'Equipar',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _isBuying ? null : _buy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _StoreColors.gold,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                              ),
                              icon: _isBuying
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.monetization_on_rounded,
                                      color: Colors.white, size: 14),
                              label: Text(
                                _isBuying ? '' : '${widget.item.price}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Card de Extra / Consumível
// ============================================================
class _ExtraCard extends StatefulWidget {
  final StoreItem item;
  final bool isPurchased;
  final StoreProvider store;
  final Future<void> Function() onBuy;
  final VoidCallback onConsume;

  const _ExtraCard({
    required this.item,
    required this.isPurchased,
    required this.store,
    required this.onBuy,
    required this.onConsume,
  });

  @override
  State<_ExtraCard> createState() => _ExtraCardState();
}

class _ExtraCardState extends State<_ExtraCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  Future<void> _buy() async {
    if (_isBuying) return;
    setState(() => _isBuying = true);
    await widget.onBuy();
    if (mounted) setState(() => _isBuying = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnergyRefill = widget.item.type == 'ENERGY_REFILL';
    final iconData = isEnergyRefill ? Icons.bolt_rounded : Icons.auto_awesome_rounded;
    final gradientColors = isEnergyRefill
        ? [const Color(0xFF10B981), const Color(0xFF0EA5E9)]
        : [const Color(0xFFEAB308), const Color(0xFFF97316)];
    final label = isEnergyRefill ? 'Recarga de Energia' : 'XP Boost';
    final description = isEnergyRefill
        ? 'Restaura sua energia para 100 instantaneamente.'
        : 'Dobra o XP ganho na próxima partida.';

    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _StoreColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isPurchased
                  ? gradientColors[0].withValues(alpha: 0.6)
                  : _StoreColors.cardBorder,
              width: widget.isPurchased ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPurchased
                    ? gradientColors[0].withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do consumível
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(iconData, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.item.name.isNotEmpty
                                ? widget.item.name
                                : label,
                            style: const TextStyle(
                              color: _StoreColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (widget.isPurchased) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: gradientColors[0].withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: gradientColors[0].withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'NO INVENTÁRIO',
                                style: TextStyle(
                                  color: gradientColors[0],
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.description.isNotEmpty
                            ? widget.item.description
                            : description,
                        style: const TextStyle(
                            color: _StoreColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Botões
                      Row(
                        children: [
                          if (!widget.isPurchased)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isBuying ? null : _buy,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _StoreColors.gold,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 0,
                                ),
                                icon: _isBuying
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.monetization_on_rounded,
                                        color: Colors.white, size: 14),
                                label: Text(
                                  _isBuying ? '' : '${widget.item.price} moedas',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onConsume,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gradientColors[0],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 0,
                                ),
                                icon: Icon(iconData,
                                    color: Colors.white, size: 16),
                                label: Text(
                                  isEnergyRefill ? 'Usar Agora ⚡' : 'Ativar Boost ⭐',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
