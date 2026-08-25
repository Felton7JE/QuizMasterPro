import 'package:flutter/material.dart';

class ModeSelectionSection extends StatelessWidget {
  final String selectedMode;
  final VoidCallback onEditMode;

  const ModeSelectionSection({
    super.key,
    required this.selectedMode,
    required this.onEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    // Mapear o modo para suas informações de exibição
    Map<String, Map<String, dynamic>> modeInfo = {
      'team': {
        'icon': Icons.group,
        'title': 'Modo Equipe',
        'description': 'Duelos paralelos por disciplina entre equipes',
        'color': const Color(0xFF6366F1),
      },
      'duel': {
        'icon': Icons.flash_on,
        'title': 'Duelo 1v1',
        'description': 'Confronto direto entre 2 jogadores',
        'color': const Color(0xFFEF4444),
      },
      'kahoot': {
        'icon': Icons.emoji_emotions,
        'title': 'Estilo Kahoot',
        'description': 'Todos respondem simultaneamente',
        'color': const Color(0xFF10B981),
      },
    };

    final currentMode = modeInfo[selectedMode] ?? modeInfo['team']!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Modo de Jogo Selecionado',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: onEditMode,
              child: Text(
                'Alterar',
                style: TextStyle(
                  color: const Color(0xFF6366F1),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: currentMode['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentMode['color'],
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: currentMode['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      currentMode['icon'],
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 32,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentMode['title'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentMode['description'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: currentMode['color'],
                    size: isSmallScreen ? 20 : 24,
                  ),
                ],
              ),
              if (selectedMode == 'team') ...[
                SizedBox(height: isSmallScreen ? 12 : 16),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: currentMode['color'],
                            size: isSmallScreen ? 16 : 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Como funciona:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Cada jogador de uma equipe enfrenta um jogador da equipe adversária\n'
                        '• Cada duelo acontece em uma disciplina específica\n'
                        '• Todos os duelos ocorrem simultaneamente\n'
                        '• A equipe com mais vitórias individuais vence',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.grey[300],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
