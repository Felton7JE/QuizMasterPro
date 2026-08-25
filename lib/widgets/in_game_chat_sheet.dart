import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/store_item.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';

/// Modal bottom sheet para escolher e enviar emojis e frases em tempo real durante o jogo.
class InGameChatSheet extends StatefulWidget {
  final Function(String text, int? itemId) onSelectPhrase;
  final int cooldownSecondsRemaining;

  const InGameChatSheet({
    super.key,
    required this.onSelectPhrase,
    this.cooldownSecondsRemaining = 0,
  });

  @override
  State<InGameChatSheet> createState() => _InGameChatSheetState();
}

class _InGameChatSheetState extends State<InGameChatSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();
    final user = auth.currentUser;

    List<StoreItem> equippedPhrases = store.equippedPhrases;
    if (equippedPhrases.isEmpty && user?.activePhraseId != null) {
      final allItems = [...store.purchasedItems, ...store.availableItems];
      try {
        final fallback = allItems.firstWhere(
          (i) => i.id == user!.activePhraseId && i.type == 'TEXT_PHRASE',
        );
        equippedPhrases = [fallback];
      } catch (_) {}
    }

    List<StoreItem> equippedEmotes = store.equippedEmotes;
    if (equippedEmotes.isEmpty && user?.activeEmoteId != null) {
      final allItems = [...store.purchasedItems, ...store.availableItems];
      try {
        final fallback = allItems.firstWhere(
          (i) => i.id == user!.activeEmoteId && (i.type == 'EMOTE' || i.type == 'EMOJI'),
        );
        equippedEmotes = [fallback];
      } catch (_) {}
    }

    final isCoolingDown = widget.cooldownSecondsRemaining > 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141927),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle e cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Color(0xFF81ECEC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reações & Frases',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Provoca e reage com os teus adversários!',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCoolingDown)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.cooldownSecondsRemaining}s',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF6366F1),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text('Emojis (${equippedEmotes.length}/10)'),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text('Frases (${equippedPhrases.length}/5)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Conteúdo das Abas
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Aba 1: Emojis
                _buildEmojisTab(
                  context: context,
                  equippedEmotes: equippedEmotes,
                  isCoolingDown: isCoolingDown,
                ),

                // Aba 2: Frases
                _buildPhrasesTab(
                  context: context,
                  equippedPhrases: equippedPhrases,
                  isCoolingDown: isCoolingDown,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojisTab({
    required BuildContext context,
    required List<StoreItem> equippedEmotes,
    required bool isCoolingDown,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader(
              title: '⭐ Emojis Equipados',
              color: Color(0xFFFFD700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${equippedEmotes.length}/10',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1.0,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            if (index < equippedEmotes.length) {
              final emote = equippedEmotes[index];
              return _EmojiSlotTile(
                emoji: emote.value,
                isDisabled: isCoolingDown,
                onTap: () {
                  if (!isCoolingDown) {
                    Navigator.pop(context);
                    widget.onSelectPhrase(emote.value, emote.id);
                  }
                },
              );
            } else {
              return _EmptyEmojiSlot(slotNumber: index + 1);
            }
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            equippedEmotes.isEmpty
                ? 'Equipa até 10 emojis no teu Perfil ou Loja para usares em jogo.'
                : 'Toca no emoji para reagir instantaneamente.',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPhrasesTab({
    required BuildContext context,
    required List<StoreItem> equippedPhrases,
    required bool isCoolingDown,
  }) {
    if (equippedPhrases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 44,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nenhuma Frase Equipada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Podes equipar até 5 frases no Perfil ou na Loja para usares durante o jogo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _SectionHeader(
          title: '⭐ Frases Equipadas (${equippedPhrases.length}/5)',
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: equippedPhrases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final phrase = equippedPhrases[index];
            return _PhraseCard(
              phraseText: phrase.value,
              title: phrase.name,
              rarity: phrase.rarity,
              isEquipped: true,
              isDisabled: isCoolingDown,
              onTap: () {
                if (!isCoolingDown) {
                  Navigator.pop(context);
                  widget.onSelectPhrase(phrase.value, phrase.id);
                }
              },
            );
          },
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'Toca na frase para enviar aos outros jogadores.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _EmojiSlotTile extends StatelessWidget {
  final String emoji;
  final bool isDisabled;
  final VoidCallback onTap;

  const _EmojiSlotTile({
    required this.emoji,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A2318),
                Color(0xFF1E2640),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled
                  ? Colors.white12
                  : const Color(0xFFFFD700).withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

class _EmptyEmojiSlot extends StatelessWidget {
  final int slotNumber;

  const _EmptyEmojiSlot({required this.slotNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
          width: 1.0,
        ),
      ),
      child: Text(
        '$slotNumber',
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final String phraseText;
  final String title;
  final String rarity;
  final bool isEquipped;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PhraseCard({
    required this.phraseText,
    required this.title,
    required this.rarity,
    required this.isEquipped,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isEquipped
                ? const Color(0xFF2E2415)
                : const Color(0xFF1E2640),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEquipped
                  ? const Color(0xFFFFD700)
                  : (isDisabled
                      ? Colors.white10
                      : const Color(0xFF6C5CE7).withValues(alpha: 0.4)),
              width: isEquipped ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF81ECEC),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"$phraseText"',
                      style: TextStyle(
                        color: isDisabled ? Colors.white38 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•  ${rarity.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF81ECEC),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
                  ),
                  child: const Text(
                    'EQUIPADO',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
