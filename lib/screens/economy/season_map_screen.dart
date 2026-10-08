import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../providers/economy/season_provider.dart';
import '../../providers/game/room_provider.dart';
import '../../models/room_model.dart';
import '../../models/season_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../services/asset_manager_service.dart';
import '../../widgets/core/local_asset_image.dart';
import '../../utils/snackbar_utils.dart';
import 'package:quizmaster_pro/widgets/core/loading_logo.dart';

class SeasonMapScreen extends StatefulWidget {
  const SeasonMapScreen({super.key});

  @override
  State<SeasonMapScreen> createState() => _SeasonMapScreenState();
}

class _SeasonMapScreenState extends State<SeasonMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isStartingGame = false;
  bool _needsResourceDownload = false;
  bool _isCheckingResources = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

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

  Difficulty _getDifficultyForLevel(int levelNumber, bool isBoss) {
    if (isBoss) return Difficulty.HARD;
    if (levelNumber <= 10) return Difficulty.EASY;
    if (levelNumber <= 20) return Difficulty.MEDIUM;
    return Difficulty.HARD;
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
      addResolved(season.lockedNodeIconUrl);
      addResolved(season.currentNodeIconUrl);
      addResolved(season.completedNodeIconUrl);
      for (final reward in season.rewards) {
        addResolved(reward.freeRewardImageUrl);
        addResolved(reward.premiumRewardImageUrl);
        addResolved(reward.bossImageUrl);
      }

      bool missingAny = false;
      for (final url in urls) {
        final path = await assetManager.getLocalPath(url);
        if (path == null && !assetManager.hasFailed(url)) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.download_for_offline_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Recursos da Temporada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Baixe o plano de fundo e ícones do mapa.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigoAccent,
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
            child: const Text('Baixar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startSeasonGame(
      int levelNumber, SeasonResponse data, bool isBoss) async {
    if (data.exclusiveCategoryId == null) return;
    if (_isStartingGame) return;

    setState(() => _isStartingGame = true);

    final auth = context.read<AuthProvider>();
    final roomProv = context.read<RoomProvider>();
    final userId = auth.currentUser?.id;

    if (userId == null) {
      setState(() => _isStartingGame = false);
      return;
    }

    // Criar sala para a temporada
    final created = await roomProv.createRoom(
      roomName: 'Temporada Lvl $levelNumber',
      gameMode: GameMode.CLASSIC,
      difficulty: _getDifficultyForLevel(levelNumber, isBoss),
      maxPlayers: 1,
      questionTime: 15,
      questionCount: 10,
      categoryIds: [data.exclusiveCategoryId!],
      assignmentType: 'CHOOSE',
      categoryAssignmentMode: 'AUTO',
      allowSpectators: false,
      enableChat: false,
      showRealTimeRanking: false,
      allowReconnection: false,
      hostId: int.parse(userId),
    );

    if (!created) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao iniciar fase da temporada.');
        setState(() => _isStartingGame = false);
      }
      return;
    }

    await roomProv.setPlayerReady(userId);
    final started = await roomProv.startGame(userId);

    if (!started) {
      if (mounted) {
        setState(() => _isStartingGame = false);
      }
      return;
    }

    final gameId =
        roomProv.lastStartedGameId?.toString() ?? await roomProv.getGameId();

    if (!mounted) return;

    if (gameId != null) {
      setState(() => _isStartingGame = false);
      Navigator.pushReplacementNamed(
        context,
        '/quiz-countdown',
        arguments: {
          'gameId': gameId,
          'playerCategory': '', // Empty string to avoid category leak and backend 0 questions issue
          'isSolo': true,
          'isSeason': true, // Usaremos isto para dar pontos extra no final!
          'levelNumber': levelNumber,
        },
      );
    } else {
      setState(() => _isStartingGame = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonProv = context.watch<SeasonProvider>();
    final data = seasonProv.seasonData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/menu', (route) => false),
        ),
        title: const Row(
          children: [
            Icon(Icons.map_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jornada da Temporada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (data != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Lvl ${data.currentLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.bolt_rounded,
                      color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${data.seasonPoints} PTs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: seasonProv.isLoading
          ? const Center(
              child: LoadingLogo(size: 60),
            )
          : seasonProv.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar mapa: ${seasonProv.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final auth = context.read<AuthProvider>();
                          if (auth.currentUser != null) {
                            context
                                .read<SeasonProvider>()
                                .fetchSeasonProgress(auth.currentUser!.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : data == null
                  ? const Center(
                      child: Text('Nenhuma temporada ativa.',
                          style: TextStyle(color: Colors.white)),
                    )
                  : _buildMapPath(context, data),
    );
  }

  Widget _buildMapPath(BuildContext context, SeasonResponse data) {
    // A temporada tem sempre 30 níveis fixos no passe
    const int totalLevels = 30;
    final String? bgUrl = ApiService.resolveImageUrl(data.mapBackgroundUrl);
    final Map<String, String>? authHeaders = ApiService.token != null
        ? {'Authorization': 'Bearer ${ApiService.token}'}
        : null;

    final assetManager = context.read<AssetManagerService>();
    final bgPath = bgUrl != null ? assetManager.getLocalPathSync(bgUrl) : null;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Stack(
      children: [
        // Background do mapa com placeholder (cor sólida enquanto carrega)
        if (bgUrl != null)
          Positioned.fill(
            child: bgPath != null
                ? Image.file(
                    File(bgPath),
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                  )
                : CachedNetworkImage(
                    imageUrl: bgUrl,
                    httpHeaders: authHeaders,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                    placeholder: (context, url) =>
                        Container(color: const Color(0xFF0F172A)),
                  ),
          ),
        SingleChildScrollView(
          reverse: true,
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.only(
                top: 100, bottom: 40, left: 20, right: 20),
            child: Center(
              child: Column(
                children: List.generate(totalLevels, (index) {
                  // index 0 = nível 30 (topo), index 29 = nível 1 (fundo, onde começa o reverse scroll)
                  final levelNumber = totalLevels - index;

                  // Lógica de nós
                  final isCompleted = levelNumber < data.currentLevel;
                  final isCurrent = levelNumber == data.currentLevel;
                  final isLocked = levelNumber > data.currentLevel;

                  // Calcular offset Sinuoso (curva do mapa)
                  final double offset = math.sin((levelNumber * 0.8)) * 90;

                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: Offset(offset, 0),
                          child: _buildLevelNode(context, levelNumber,
                              isCompleted, isCurrent, isLocked, data),
                        ),
                        if (index < totalLevels - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Transform.translate(
                              offset: Offset(offset * 0.5, 0),
                              child: Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.orange
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ), // Container
        ), // SingleChildScrollView
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          child: _buildDownloadBanner(),
        ),
        if (_isStartingGame)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: LoadingLogo(size: 60),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLevelNode(BuildContext context, int levelNumber,
      bool isCompleted, bool isCurrent, bool isLocked, SeasonResponse data) {
    SeasonReward? reward;
    for (var r in data.rewards) {
      if (r.levelRequired == levelNumber) {
        reward = r;
        break;
      }
    }

    final bool isBoss = (reward?.isBossLevel ?? false) ||
        (reward?.bossImageUrl != null) ||
        (levelNumber % 5 == 0);
    final String? bossImageUrl =
        ApiService.resolveImageUrl(reward?.bossImageUrl);
    final String? bossName = reward?.bossName;

    final String? lockedIconUrl =
        ApiService.resolveImageUrl(data.lockedNodeIconUrl);
    final String? currentIconUrl =
        ApiService.resolveImageUrl(data.currentNodeIconUrl);
    final String? completedIconUrl =
        ApiService.resolveImageUrl(data.completedNodeIconUrl);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Fase bloqueada! Passe de nível na temporada para abrir.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showSeasonLevelDetailsModal(
            levelNumber: levelNumber,
            data: data,
            isBoss: isBoss,
            bossName: bossName,
            bossImageUrl: bossImageUrl,
            reward: reward,
            isCompleted: isCompleted,
          );
        }
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final scale = isCurrent ? 1.0 + (_animController.value * 0.08) : 1.0;

          return Transform.scale(
            scale: scale,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Círculo principal do nó
                    Container(
                      width: isBoss ? 82 : 68,
                      height: isBoss ? 82 : 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isBoss
                            ? (isCurrent
                                ? const LinearGradient(colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFF991B1B)
                                  ])
                                : isCompleted
                                    ? const LinearGradient(colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706)
                                      ])
                                    : const LinearGradient(colors: [
                                        Color(0xFF334155),
                                        Color(0xFF1E293B)
                                      ]))
                            : isCompleted
                                ? const LinearGradient(colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669)
                                  ])
                                : isCurrent
                                    ? const LinearGradient(colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF1D4ED8)
                                      ])
                                    : const LinearGradient(colors: [
                                        Color(0xFF334155),
                                        Color(0xFF1E293B)
                                      ]),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: (isBoss
                                          ? Colors.redAccent
                                          : Colors.blueAccent)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                )
                              ]
                            : isBoss && isCompleted
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.amber.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                        border: Border.all(
                          color: isBoss
                              ? (isCurrent
                                  ? Colors.redAccent
                                  : isCompleted
                                      ? Colors.amberAccent
                                      : Colors.white24)
                              : (isCurrent
                                  ? Colors.white
                                  : isCompleted
                                      ? Colors.greenAccent
                                      : Colors.white24),
                          width: isCurrent ? 3.5 : 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildNodeContent(
                          isBoss: isBoss,
                          bossImageUrl: bossImageUrl,
                          levelNumber: levelNumber,
                          isLocked: isLocked,
                          isCurrent: isCurrent,
                          isCompleted: isCompleted,
                          lockedIconUrl: lockedIconUrl,
                          currentIconUrl: currentIconUrl,
                          completedIconUrl: completedIconUrl,
                        ),
                      ),
                    ),

                    // Emblema de Boss no topo
                    if (isBoss)
                      Positioned(
                        top: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: isCurrent
                                ? const LinearGradient(colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626)
                                  ])
                                : isCompleted
                                    ? const LinearGradient(colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706)
                                      ])
                                    : const LinearGradient(colors: [
                                        Color(0xFF475569),
                                        Color(0xFF334155)
                                      ]),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.workspace_premium_rounded
                                    : Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isCompleted ? 'DERROTADO' : 'BOSS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xE60F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBoss
                          ? (isCurrent
                              ? Colors.redAccent.withValues(alpha: 0.8)
                              : isCompleted
                                  ? Colors.amber
                                  : Colors.white24)
                          : (isCurrent
                              ? Colors.blueAccent.withValues(alpha: 0.8)
                              : isCompleted
                                  ? Colors.greenAccent.withValues(alpha: 0.6)
                                  : Colors.white12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBoss && bossName != null
                            ? bossName
                            : 'Fase $levelNumber',
                        style: TextStyle(
                          color: isBoss
                              ? (isCurrent
                                  ? Colors.redAccent
                                  : isCompleted
                                      ? Colors.amberAccent
                                      : Colors.white)
                              : (isCurrent
                                  ? Colors.white
                                  : isCompleted
                                      ? Colors.greenAccent
                                      : Colors.white70),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isLocked
                            ? 'Bloqueado'
                            : isCurrent
                                ? (isBoss ? 'Batalhar!' : 'Jogar!')
                                : 'Concluído ⭐',
                        style: TextStyle(
                          color: isLocked
                              ? Colors.white38
                              : isCurrent
                                  ? (isBoss
                                      ? Colors.redAccent
                                      : Colors.amberAccent)
                                  : Colors.greenAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNodeContent({
    required bool isBoss,
    required String? bossImageUrl,
    required int levelNumber,
    required bool isLocked,
    required bool isCurrent,
    required bool isCompleted,
    required String? lockedIconUrl,
    required String? currentIconUrl,
    required String? completedIconUrl,
  }) {
    final Map<String, String>? authHeaders = ApiService.token != null
        ? {'Authorization': 'Bearer ${ApiService.token}'}
        : null;

    // 1. Se for Chefão (Boss)
    if (isBoss) {
      if (bossImageUrl != null && bossImageUrl.isNotEmpty) {
        return Stack(
          alignment: Alignment.center,
          children: [
            isLocked
                ? ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Colors.black54, BlendMode.darken),
                    child: SizedBox(
                      width: 82,
                      height: 82,
                      child: LocalAssetImage(
                        imageUrl: bossImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : SizedBox(
                    width: 82,
                    height: 82,
                    child: LocalAssetImage(
                      imageUrl: bossImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
            if (isLocked)
              lockedIconUrl != null
                  ? SizedBox(
                      width: 34,
                      height: 34,
                      child: LocalAssetImage(
                          imageUrl: lockedIconUrl, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.lock_rounded,
                      color: Colors.white70, size: 28),
            if (isCompleted)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.black87, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.greenAccent, size: 18),
                ),
              ),
          ],
        );
      }
      return Center(
        child: isLocked
            ? const Icon(Icons.lock_rounded, color: Colors.white54, size: 32)
            : const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
      );
    }

    // 2. Fases Comuns (Não-Boss)
    if (isLocked) {
      if (lockedIconUrl != null && lockedIconUrl.isNotEmpty) {
        return Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: LocalAssetImage(imageUrl: lockedIconUrl, fit: BoxFit.cover),
          ),
        );
      }
      return const Center(
          child: Icon(Icons.lock_rounded, color: Colors.white54, size: 28));
    }

    if (isCompleted) {
      if (completedIconUrl != null && completedIconUrl.isNotEmpty) {
        return Center(
          child: SizedBox(
            width: 42,
            height: 42,
            child:
                LocalAssetImage(imageUrl: completedIconUrl, fit: BoxFit.cover),
          ),
        );
      }
      return const Center(
          child:
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 32));
    }

    // isCurrent
    if (currentIconUrl != null && currentIconUrl.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: LocalAssetImage(imageUrl: currentIconUrl, fit: BoxFit.cover),
          ),
          Text(
            '$levelNumber',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                    color: Colors.black, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        '$levelNumber',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showSeasonLevelDetailsModal({
    required int levelNumber,
    required SeasonResponse data,
    required bool isBoss,
    required String? bossName,
    required String? bossImageUrl,
    required SeasonReward? reward,
    required bool isCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Cabeçalho da Fase
              Row(
                children: [
                  if (isBoss && bossImageUrl != null && bossImageUrl.isNotEmpty)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: LocalAssetImage(
                          imageUrl: bossImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          isBoss ? Colors.redAccent : const Color(0xFF3B82F6),
                      child: Icon(
                        isBoss
                            ? Icons.shield_rounded
                            : (isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.sports_esports_rounded),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBoss
                              ? 'Fase $levelNumber - ${bossName ?? "Chefão"}'
                              : 'Fase $levelNumber - ${data.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isBoss
                                    ? Colors.redAccent.withValues(alpha: 0.2)
                                    : Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isBoss
                                      ? Colors.redAccent
                                      : Colors.blueAccent,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isBoss
                                    ? 'CHEFÃO'
                                    : (isCompleted
                                        ? 'CONCLUÍDO'
                                        : 'EM ANDAMENTO'),
                                style: TextStyle(
                                  color: isBoss
                                      ? Colors.redAccent
                                      : (isCompleted
                                          ? Colors.greenAccent
                                          : const Color(0xFF60A5FA)),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '10 Perguntas • 15s',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 14),

              // Detalhes do Oponente
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isBoss
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    if (isBoss &&
                        bossImageUrl != null &&
                        bossImageUrl.isNotEmpty)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: bossImageUrl,
                            httpHeaders: ApiService.token != null
                                ? {
                                    'Authorization':
                                        'Bearer ${ApiService.token}'
                                  }
                                : null,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => const SizedBox.shrink(),
                            errorWidget: (c, u, e) => const Icon(
                                Icons.shield_rounded,
                                color: Colors.redAccent),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            isBoss ? Colors.redAccent : const Color(0xFF6366F1),
                        child: Icon(
                          isBoss
                              ? Icons.shield_rounded
                              : Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBoss
                                ? (bossName ?? 'Chefão da Temporada')
                                : 'Bot Competitivo da Temporada',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isBoss
                                ? 'Boss de Capítulo (Desafio Máximo!)'
                                : 'Duelo 1v1 valendo pontos no Passe',
                            style: TextStyle(
                              color: isBoss ? Colors.redAccent : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isBoss)
                      Row(
                        children: List.generate(3, (idx) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),

              // Recompensas da Fase (Se houver)
              if (reward != null &&
                  (reward.freeRewardType != 'NONE' ||
                      (reward.premiumRewardType != null &&
                          reward.premiumRewardType != 'NONE'))) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_giftcard_rounded,
                            color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prêmio ao passar este Nível:',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reward.premiumRewardValue ??
                                  reward.freeRewardValue ??
                                  'Recompensas do Passe',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botão de Iniciar Duelo / Desafiar Boss
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startSeasonGame(levelNumber, data, isBoss);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBoss
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor:
                        (isBoss ? Colors.redAccent : Colors.greenAccent)
                            .withValues(alpha: 0.4),
                  ),
                  icon: Icon(
                    isBoss ? Icons.flash_on_rounded : Icons.play_arrow_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                  label: Text(
                    isBoss
                        ? 'DESAFIAR BOSS'
                        : (isCompleted ? 'JOGAR NOVAMENTE' : 'INICIAR DUELO'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
