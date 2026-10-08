import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../providers/solo/solo_provider.dart';
import '../../services/solo_service.dart';
import 'package:quizmaster_pro/widgets/core/loading_logo.dart';

class SoloMapScreen extends StatefulWidget {
  const SoloMapScreen({super.key});

  @override
  State<SoloMapScreen> createState() => _SoloMapScreenState();
}

class _SoloMapScreenState extends State<SoloMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final ScrollController _scrollController = ScrollController();

  /// Altura fixa por nó — garante espaçamento 100% uniforme em todos os chunks
  static const double _nodeHeight = 110.0;

  /// Maps category name keywords to boss image asset paths
  static const Map<String, String> _bossImages = {
    'ciencias': 'assets/images/solo/boss_ciencias_v2.png',
    'ciência': 'assets/images/solo/boss_ciencias_v2.png',
    'ciências': 'assets/images/solo/boss_ciencias_v2.png',
    'science': 'assets/images/solo/boss_ciencias_v2.png',
    'geografia': 'assets/images/solo/boss_geografia_v2.png',
    'geography': 'assets/images/solo/boss_geografia_v2.png',
    'historia': 'assets/images/solo/boss_historia_v2.png',
    'história': 'assets/images/solo/boss_historia_v2.png',
    'history': 'assets/images/solo/boss_historia_v2.png',
    'ingles': 'assets/images/solo/boss_ingles_v2.png',
    'inglês': 'assets/images/solo/boss_ingles_v2.png',
    'english': 'assets/images/solo/boss_ingles_v2.png',
    'matematica': 'assets/images/solo/boss_matematica_v2.png',
    'matemática': 'assets/images/solo/boss_matematica_v2.png',
    'math': 'assets/images/solo/boss_matematica_v2.png',
    'portugues': 'assets/images/solo/boss_portugues_v2.png',
    'português': 'assets/images/solo/boss_portugues_v2.png',
    'portuguese': 'assets/images/solo/boss_portugues_v2.png',
  };

  /// Resolve the boss image for a given category
  String? _getBossImage(String? categoryName) {
    if (categoryName == null) return null;
    final lower = categoryName.toLowerCase().trim();
    for (final entry in _bossImages.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<SoloProvider>();
      if (prov.mapData == null) {
        await prov.fetchMapProgress();
      }
      // Scroll até ao nível atual do jogador após dados carregados
      if (mounted) {
        // Aguarda a renderização completa da scroll view
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _scrollToCurrentLevel(prov);
        });
      }
    });
  }

  /// Calcula a posição do nível atual e faz scroll até lá.
  /// O mapa tem os níveis mais altos no TOPO, então o nível 1 está no FUNDO.
  /// Cada nó tem altura [_nodeHeight]. O scroll máximo = nível 100 (topo).
  void _scrollToCurrentLevel(SoloProvider prov) {
    if (!_scrollController.hasClients) return;
    final totalLevels = prov.mapData?.levels.length ?? 100;
    final currentLevel = prov.mapData?.currentUnlockedLevel ?? 1;
    final maxExtent = _scrollController.position.maxScrollExtent;

    // Nível 1 está no fundo (maxExtent), nível 100 no topo (0).
    // Calculamos a posição proporcional invertida.
    final levelFromTop = totalLevels - currentLevel; // quantos níveis do topo
    final ratio = levelFromTop / (totalLevels > 1 ? totalLevels - 1 : 1);
    final targetOffset = (maxExtent * ratio).clamp(0.0, maxExtent);

    _scrollController.jumpTo(targetOffset);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final soloProv = context.watch<SoloProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false),
        ),
        title: const Row(
          children: [
            Icon(Icons.map_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jornada Solo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${user?.energy ?? 100}/100',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${soloProv.mapData?.totalStars ?? 0}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${user?.coins ?? 0}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fundo agora é renderizado juntamente com os níveis para alinhar com os pontos de brilho
          // ── Overlay escuro suave no topo para a AppBar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // ── Conteúdo dos níveis ──
          if (soloProv.isLoadingMap && soloProv.mapData == null)
            const Center(
              child: LoadingLogo(size: 60),
            )
          else if (soloProv.error != null && soloProv.mapData == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar mapa: ${soloProv.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => soloProv.fetchMapProgress(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          else
            Stack(
              children: [
                _buildMapPath(context, soloProv.mapData?.levels ?? []),
                if (soloProv.isLoadingMap)
                  const Positioned(
                    top: kToolbarHeight + 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: LoadingLogo(size: 60),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _getBiomeBackgroundForLevel(int startLevel) {
    if (startLevel == 1) return 'assets/images/solo/1.png'; // Início (Base)
    if (startLevel == 91) return 'assets/images/solo/5.png'; // Fim (Topo)
    
    // Tile Repetível no Meio
    if (startLevel <= 31) return 'assets/images/solo/2.png';
    if (startLevel <= 61) return 'assets/images/solo/3.png';
    return 'assets/images/solo/4.png';
  }

  Widget _buildMapPath(BuildContext context, List<SoloLevelDto> levels) {
    if (levels.isEmpty) {
      return const Center(
        child: Text('Sem níveis disponíveis.', style: TextStyle(color: Colors.white)),
      );
    }

    final List<Widget> chunks = [];
    final int totalChunks = (levels.length / 10).ceil();
    
    // Itera do chunk mais alto para o mais baixo (ordem visual no topo da tela)
    for (int i = totalChunks - 1; i >= 0; i--) {
      final startLevel = (i * 10) + 1;
      final String bg = _getBiomeBackgroundForLevel(startLevel);
      final int visualIndex = (totalChunks - 1) - i;
      
      final bool isFirstVisual = visualIndex == 0;
      const double overlap = 80.0;
      // Altura do chunk baseada na altura fixa por nó × 10 níveis
      const double chunkHeight = _nodeHeight * 10;
      final double layoutHeight = isFirstVisual ? chunkHeight : chunkHeight - overlap;

      // SOLUÇÃO MESTRA: O Gradiente de Sobreposição no Fundo
      Widget bgWidget = Container(
        width: double.infinity,
        height: chunkHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bg),
            fit: BoxFit.fill,
          ),
        ),
      );

      if (!isFirstVisual) {
        bgWidget = Align(
          alignment: Alignment.bottomCenter,
          heightFactor: layoutHeight / chunkHeight,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
                stops: [0.0, overlap / chunkHeight],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: bgWidget,
          ),
        );
      }

      // NODES: altura fixa por nó para espaçamento uniforme em todos os chunks
      Widget nodesWidget = SizedBox(
        height: chunkHeight,
        child: Column(
          children: List.generate(10, (index) {
            final int expectedLevelNumber = startLevel + 9 - index;
            final levelMatch = levels.where((l) => l.levelNumber == expectedLevelNumber).toList();

            if (levelMatch.isEmpty) {
              return const SizedBox(height: _nodeHeight);
            }

            final level = levelMatch.first;
            final isCurrent = level.unlocked && !level.completed;

            Widget nodeContent = _buildLevelNode(context, level, isCurrent);
            if (expectedLevelNumber == 1) {
              nodeContent = Transform.translate(
                offset: const Offset(0, -35),
                child: nodeContent,
              );
            }

            return SizedBox(
              height: _nodeHeight,
              child: Center(
                child: nodeContent,
              ),
            );
          }),
        ),
      );

      chunks.add(
        Stack(
          clipBehavior: Clip.none, // Permite que o fundo transborde para o chunk de cima
          children: [
            bgWidget,
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: chunkHeight,
              child: nodesWidget,
            ),
          ],
        )
      );
    }

    // O scroll inicial é feito em initState via _scrollToCurrentLevel()

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Container(
        color: const Color(0xFF030712),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 40),
            ...chunks,
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }


  Widget _buildLevelNode(BuildContext context, SoloLevelDto level, bool isCurrent) {
    final isBoss = level.isBossLevel;
    final bossImage = isBoss ? _getBossImage(level.categoryName) : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (level.unlocked) {
          _showLevelDetailsModal(context, level);
        } else {
          final totalStars = context.read<SoloProvider>().mapData?.totalStars ?? 0;
          if (level.requiredStarsToUnlock > totalStars) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Precisas de ${level.requiredStarsToUnlock} estrelas para abrir este capítulo! Tens $totalStars.'),
                backgroundColor: Colors.amber.shade800,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nível bloqueado! Completa os níveis anteriores.'),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final scale = isCurrent ? 1.0 + (_animController.value * 0.1) : 1.0;

          return Transform.scale(
            scale: scale,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ── Nó do nível ──
                    if (isBoss && bossImage != null)
                      // BOSS: Imagem do chefão da categoria
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: level.completed
                                ? const Color(0xFF10B981)
                                : isCurrent
                                    ? Colors.redAccent
                                    : Colors.white24,
                            width: isCurrent ? 3.5 : 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.6),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  )
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: level.unlocked
                              ? Image.asset(
                                  bossImage,
                                  fit: BoxFit.cover,
                                )
                              : ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  ),
                                  child: Image.asset(
                                    bossImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      )
                    else if (!level.unlocked)
                      // BLOQUEADO: Ícone de cadeado customizado
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/solo/icon_cadeado.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      // DESBLOQUEADO (nível normal): Ícone desbloqueado com número
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: level.completed
                                ? const Color(0xFF10B981)
                                : isCurrent
                                    ? Colors.amberAccent
                                    : Colors.white24,
                            width: isCurrent ? 3.5 : 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.6),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  )
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/solo/icon_desbloqueado.png',
                                fit: BoxFit.cover,
                                width: 66,
                                height: 66,
                              ),
                              Text(
                                '${level.levelNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      blurRadius: 4,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Emblema de Boss / Caveira
                    if (isBoss)
                      Positioned(
                        top: -12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: level.unlocked ? Colors.redAccent : Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'BOSS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Badge de Estrelas do Nível
                    if (level.completed && level.starsCount > 0)
                      Positioned(
                        bottom: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (starIdx) {
                              return Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: starIdx < level.starsCount
                                    ? Colors.amber
                                    : Colors.white24,
                              );
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  level.categoryDisplayName,
                  style: TextStyle(
                    color: level.unlocked ? Colors.white70 : Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLevelDetailsModal(BuildContext context, SoloLevelDto level) {
    final bossImage = level.isBossLevel ? _getBossImage(level.categoryName) : null;

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Avatar do nível no modal - usa imagem do boss se disponível
                  if (level.isBossLevel && bossImage != null)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(bossImage, fit: BoxFit.cover),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: level.isBossLevel ? Colors.redAccent : Colors.amber,
                      child: Icon(
                        level.isBossLevel ? Icons.shield_rounded : Icons.sports_esports_rounded,
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
                          'Nível ${level.levelNumber} - ${level.categoryDisplayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dificuldade: ${level.difficulty}',
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Detalhes do Oponente (BOT ou Boss)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: level.isBossLevel ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    if (level.isBossLevel && bossImage != null)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.asset(bossImage, fit: BoxFit.cover),
                        ),
                      )
                    else
                      CircleAvatar(
                        backgroundColor: Colors.indigoAccent,
                        child: Text(
                          ((level.bossName != null && level.bossName!.isNotEmpty) ? level.bossName![0] : 'B'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oponente: ${level.bossName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            level.isBossLevel
                                ? 'Boss de Capítulo (Desafio Máximo!)'
                                : 'Bot Competitivo',
                            style: TextStyle(
                              color: level.isBossLevel ? Colors.redAccent : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (level.isBossLevel)
                      Row(
                        children: List.generate(3, (idx) {
                          return Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: idx < level.bossLivesRemaining
                                ? Colors.red
                                : Colors.white24,
                          );
                        }),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentEnergy = context.read<SoloProvider>().mapData?.currentEnergy ?? 0;
                    if (currentEnergy < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sem energia! Aguarde recarregar.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    if (level.isBossLevel) {
                      Navigator.pushNamed(
                        context,
                        '/quiz-countdown',
                        arguments: {
                          'gameMode': 'BOSS_BATTLE',
                          'level': level,
                        },
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        '/quiz-countdown',
                        arguments: {
                          'gameMode': 'SOLO_MAP',
                          'levelNumber': level.levelNumber,
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: level.isBossLevel ? Colors.redAccent : const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                  label: Text(
                    level.isBossLevel ? 'DESAFIAR BOSS' : 'INICIAR DUELO',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing level modal: $e');
    }
  }
}
