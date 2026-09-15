import 'package:flutter/material.dart';

class AdvancedSettingsSection extends StatelessWidget {
  final bool showAdvanced;
  final bool allowSpectators;
  final bool enableChat;
  final bool showRealTimeRanking;
  final bool allowReconnection;

  final VoidCallback onToggleShowAdvanced;
  final ValueChanged<bool> onAllowSpectatorsChanged;
  final ValueChanged<bool> onEnableChatChanged;
  final ValueChanged<bool> onShowRealTimeRankingChanged;
  final ValueChanged<bool> onAllowReconnectionChanged;

  const AdvancedSettingsSection({
    super.key,
    required this.showAdvanced,
    required this.allowSpectators,
    required this.enableChat,
    required this.showRealTimeRanking,
    required this.allowReconnection,
    required this.onToggleShowAdvanced,
    required this.onAllowSpectatorsChanged,
    required this.onEnableChatChanged,
    required this.onShowRealTimeRankingChanged,
    required this.onAllowReconnectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configurações Avançadas',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: onToggleShowAdvanced,
              child: Text(
                showAdvanced ? 'Ocultar' : 'Mostrar',
                style: const TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
        if (showAdvanced) ...[
          SizedBox(height: isSmallScreen ? 12 : 16),
          if (isSmallScreen) ...[
            // Em telas pequenas, empilha verticalmente
            _buildSwitchTile('Permitir Espectadores', allowSpectators, onAllowSpectatorsChanged, isSmallScreen),
            const SizedBox(height: 12),
            _buildSwitchTile('Chat Habilitado', enableChat, onEnableChatChanged, isSmallScreen),
            const SizedBox(height: 12),
            _buildSwitchTile('Ranking em Tempo Real', showRealTimeRanking, onShowRealTimeRankingChanged, isSmallScreen),
            const SizedBox(height: 12),
            _buildSwitchTile('Permitir Reconexão', allowReconnection, onAllowReconnectionChanged, isSmallScreen),
          ] else ...[
            // Em telas maiores, mantém grade 2x2
            Row(
              children: [
                Expanded(
                  child: _buildSwitchTile('Permitir Espectadores', allowSpectators, onAllowSpectatorsChanged, isSmallScreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSwitchTile('Chat Habilitado', enableChat, onEnableChatChanged, isSmallScreen),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSwitchTile('Ranking em Tempo Real', showRealTimeRanking, onShowRealTimeRankingChanged, isSmallScreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSwitchTile('Permitir Reconexão', allowReconnection, onAllowReconnectionChanged, isSmallScreen),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
