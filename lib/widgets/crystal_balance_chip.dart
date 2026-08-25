import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Widget de exibição elegante do saldo de Cristais 🔮 do jogador com atalho para a loja de cristais.
class CrystalBalanceChip extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showAddButton;

  const CrystalBalanceChip({
    super.key,
    this.onTap,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final crystals = auth.currentUser?.crystals ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _showGetCrystalsDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E1065),
                Color(0xFF581C87),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC084FC).withOpacity(0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withOpacity(0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔮',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 5),
              Text(
                '$crystals',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              if (showAddButton) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA855F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGetCrystalsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CrystalShopModal(),
    );
  }
}

/// Modal elegante para aquisição de Cristais Premium 🔮
class CrystalShopModal extends StatelessWidget {
  const CrystalShopModal({super.key});

  static const List<Map<String, dynamic>> crystalPacks = [
    {
      'crystals': 20,
      'bonus': 0,
      'price': '50 MT',
      'title': 'Bolsa de Cristais',
      'icon': '🔮',
      'isPopular': false,
    },
    {
      'crystals': 60,
      'bonus': 10,
      'price': '150 MT',
      'title': 'Baú de Estudante',
      'icon': '💎',
      'isPopular': true,
    },
    {
      'crystals': 150,
      'bonus': 35,
      'price': '300 MT',
      'title': 'Tesouro Mágico',
      'icon': '👑',
      'isPopular': false,
    },
    {
      'crystals': 400,
      'bonus': 120,
      'price': '600 MT',
      'title': 'Cofre do Grão-Mestre',
      'icon': '⚡',
      'isPopular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF131127),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFA855F7), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🔮', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cristais Mágicos 🔮',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Moeda exclusiva para IA de Estudo, Partilhas & VIP',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
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
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Saldo atual
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B0764).withOpacity(0.8),
                  const Color(0xFF1E1B4B).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('O teu saldo atual:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 2),
                    Text('Disponível para usar', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    const Text('🔮', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '${user?.crystals ?? 0}',
                      style: const TextStyle(
                        color: Color(0xFFE9D5FF),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Seção de Resgate de Código
          _buildPromoCodeSection(context),
          const SizedBox(height: 8),

          // Lista de Pacotes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: crystalPacks.length,
              itemBuilder: (ctx, i) {
                final pack = crystalPacks[i];
                final isPopular = pack['isPopular'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B38),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isPopular
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFA855F7).withOpacity(0.3),
                      width: isPopular ? 1.8 : 1.0,
                    ),
                    boxShadow: isPopular
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1065),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4)),
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
                          final success = await auth.addCrystals(added);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF10B981),
                                  content: Row(
                                    children: [
                                      const Text('🎉 ', style: TextStyle(fontSize: 18)),
                                      Text('Recebeste +$added Cristais com sucesso!'),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text('Erro ao adicionar cristais.'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        pack['price'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showRedeemDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E1065).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.card_giftcard_rounded, color: Color(0xFFE9D5FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Resgatar Código Promocional',
                style: TextStyle(
                  color: Color(0xFFE9D5FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF131127),
          title: const Text('Resgatar Código', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Insira o código fornecido pelo desenvolvedor ou ganho em eventos.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: MEUQUIZ50',
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
                      
                      final auth = ctx.read<AuthProvider>();
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
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
