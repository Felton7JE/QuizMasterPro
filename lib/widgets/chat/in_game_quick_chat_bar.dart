import 'package:quizmaster_pro/widgets/core/loading_logo.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/store_item.dart';
import '../../providers/core/auth_provider.dart';
import '../../providers/economy/store_provider.dart';

/// Mini-Barra rápida e ultra-fluida de Reações (Emojis & Frases) durante as partidas.
/// Permite enviar mensagens e emojis com apenas 1 toque (<0.3s) sem obstruir o jogo.
class InGameQuickChatBar extends StatefulWidget {
  final Function(String text, int? itemId) onSelect;
  final int cooldownSecondsRemaining;
  final int totalCooldownSeconds;
  final VoidCallback? onOpenFullSheet;

  const InGameQuickChatBar({
    super.key,
    required this.onSelect,
    this.cooldownSecondsRemaining = 0,
    this.totalCooldownSeconds = 5,
    this.onOpenFullSheet,
  });

  @override
  State<InGameQuickChatBar> createState() => _InGameQuickChatBarState();
}

class _InGameQuickChatBarState extends State<InGameQuickChatBar>
    with SingleTickerProviderStateMixin {
  // 0 = Emojis, 1 = Frases
  int _selectedTab = 0;
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  static const List<Map<String, String>> _defaultEmojis = [
    {'name': 'Raio', 'value': '⚡'},
    {'name': 'Alvo', 'value': '🎯'},
    {'name': 'Fogo', 'value': '🔥'},
    {'name': 'Rindo', 'value': '😂'},
    {'name': 'Óculos', 'value': '😎'},
    {'name': 'Coroa', 'value': '👑'},
    {'name': 'Caveira', 'value': '💀'},
    {'name': 'Cérebro', 'value': '🧠'},
    {'name': 'Foguete', 'value': '🚀'},
    {'name': 'Diamante', 'value': '💎'},
    {'name': 'Palmas', 'value': '👏'},
    {'name': 'Chocado', 'value': '😱'},
  ];

  static const List<String> _defaultPhrases = [
    'Boa sorte! 🍀',
    'Muito fácil! 😎',
    'GG! 🏆',
    'Essa foi por pouco! 😱',
    'Boa jogada! 👏',
    'Ops... 😂',
    'Tás pronto? 🔥',
    'Não desistas! 💪',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();
    final user = auth.currentUser;
    final isCoolingDown = widget.cooldownSecondsRemaining > 0;

    // Buscar itens do inventário
    final purchasedEmotes = store.purchasedItems
        .where((i) => i.type == 'EMOTE' || i.type == 'EMOJI')
        .toList();
    final purchasedPhrases = store.purchasedItems
        .where((i) => i.type == 'TEXT_PHRASE')
        .toList();

    // Identificar itens equipados
    StoreItem? equippedEmote;
    if (user?.activeEmoteId != null) {
      try {
        equippedEmote = purchasedEmotes.firstWhere(
          (i) => i.id == user!.activeEmoteId,
        );
      } catch (_) {}
    }

    StoreItem? equippedPhrase;
    if (user?.activePhraseId != null) {
      try {
        equippedPhrase = purchasedPhrases.firstWhere(
          (i) => i.id == user!.activePhraseId,
        );
      } catch (_) {}
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Barra Expandida
        RepaintBoundary(
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141A29),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho de Abas (Emojis vs Frases)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildTabButton(
                              index: 0,
                              label: 'Emojis',
                              icon: '⚡',
                              isSelected: _selectedTab == 0,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              index: 1,
                              label: 'Frases',
                              icon: '💬',
                              isSelected: _selectedTab == 1,
                            ),
                          ],
                        ),
                        if (widget.onOpenFullSheet != null)
                          InkWell(
                            onTap: widget.onOpenFullSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Mais',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Lista horizontal de itens rápidos
                    SizedBox(
                      height: 48,
                      child: _selectedTab == 0
                          ? _buildEmojiRow(
                              equippedEmotes: store.equippedEmotes,
                              fallbackEquippedEmote: equippedEmote,
                              ownedEmotes: purchasedEmotes,
                              isCoolingDown: isCoolingDown,
                            )
                          : _buildPhraseRow(
                              equippedPhrases: store.equippedPhrases,
                              fallbackEquippedPhrase: equippedPhrase,
                              ownedPhrases: purchasedPhrases,
                              isCoolingDown: isCoolingDown,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Botão Gatilho / Mini Floating Pill
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCoolingDown
                      ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCoolingDown
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCoolingDown
                            ? Colors.black
                            : const Color(0xFF6366F1))
                        .withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCoolingDown) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: LoadingLogo(size: 60),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.cooldownSecondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    // Ícone dinâmico do item equipado ou genérico
                    Text(
                      equippedEmote?.value ?? '⚡',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isExpanded ? 'Fechar' : 'Reagir',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required String icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiRow({
    required List<StoreItem> equippedEmotes,
    required StoreItem? fallbackEquippedEmote,
    required List<StoreItem> ownedEmotes,
    required bool isCoolingDown,
  }) {
    final List<Widget> items = [];

    // 1. Emojis equipados
    if (equippedEmotes.isNotEmpty) {
      for (var emote in equippedEmotes) {
        items.add(
          _buildEmojiChip(
            emoji: emote.value,
            isEquipped: true,
            itemId: emote.id,
            isCoolingDown: isCoolingDown,
          ),
        );
      }
    } else if (fallbackEquippedEmote != null) {
      items.add(
        _buildEmojiChip(
          emoji: fallbackEquippedEmote.value,
          isEquipped: true,
          itemId: fallbackEquippedEmote.id,
          isCoolingDown: isCoolingDown,
        ),
      );
    } else {
      // Padrão se nenhum estiver equipado
      for (var def in _defaultEmojis.take(5)) {
        items.add(
          _buildEmojiChip(
            emoji: def['value']!,
            isEquipped: false,
            itemId: null,
            isCoolingDown: isCoolingDown,
          ),
        );
      }
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, index) => items[index],
    );
  }

  Widget _buildEmojiChip({
    required String emoji,
    required bool isEquipped,
    required int? itemId,
    required bool isCoolingDown,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCoolingDown
            ? null
            : () {
                widget.onSelect(emoji, itemId);
                _toggleExpanded();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEquipped
                ? Colors.amber.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEquipped
                  ? Colors.amberAccent
                  : Colors.white.withValues(alpha: 0.15),
              width: isEquipped ? 1.8 : 1.0,
            ),
            boxShadow: isEquipped
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildPhraseRow({
    required List<StoreItem> equippedPhrases,
    required StoreItem? fallbackEquippedPhrase,
    required List<StoreItem> ownedPhrases,
    required bool isCoolingDown,
  }) {
    final List<Widget> items = [];

    // 1. Frases equipadas
    if (equippedPhrases.isNotEmpty) {
      for (var phrase in equippedPhrases) {
        items.add(
          _buildPhraseChip(
            phrase: phrase.value,
            isEquipped: true,
            itemId: phrase.id,
            isCoolingDown: isCoolingDown,
          ),
        );
      }
    } else if (fallbackEquippedPhrase != null) {
      items.add(
        _buildPhraseChip(
          phrase: fallbackEquippedPhrase.value,
          isEquipped: true,
          itemId: fallbackEquippedPhrase.id,
          isCoolingDown: isCoolingDown,
        ),
      );
    } else {
      // Padrão se nenhuma estiver equipada
      for (var p in _defaultPhrases.take(4)) {
        items.add(
          _buildPhraseChip(
            phrase: p,
            isEquipped: false,
            itemId: null,
            isCoolingDown: isCoolingDown,
          ),
        );
      }
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, index) => items[index],
    );
  }

  Widget _buildPhraseChip({
    required String phrase,
    required bool isEquipped,
    required int? itemId,
    required bool isCoolingDown,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCoolingDown
            ? null
            : () {
                widget.onSelect(phrase, itemId);
                _toggleExpanded();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEquipped
                ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEquipped
                  ? const Color(0xFF818CF8)
                  : Colors.white.withValues(alpha: 0.15),
              width: isEquipped ? 1.8 : 1.0,
            ),
            boxShadow: isEquipped
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          child: Text(
            phrase,
            style: TextStyle(
              color: isEquipped ? const Color(0xFFE0E7FF) : Colors.white,
              fontWeight: isEquipped ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
