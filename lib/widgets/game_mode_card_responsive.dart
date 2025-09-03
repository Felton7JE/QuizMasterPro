import 'package:flutter/material.dart';

class GameModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String players;
  final String duration;
  final String categories;
  final String? badge;
  final VoidCallback onTap;

  const GameModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.players,
    required this.duration,
    required this.categories,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6366F1),
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8, 
                      vertical: isSmallScreen ? 2 : 4
                    ),
                    decoration: BoxDecoration(
                      color: badge == 'Popular' ? const Color(0xFFF59E0B) : 
                             badge == 'Novo' ? const Color(0xFF10B981) : 
                             const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 8 : 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              description,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey,
                height: 1.4,
              ),
              maxLines: isSmallScreen ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildModeStats(players, duration, categories, isSmallScreen),
            SizedBox(height: isSmallScreen ? 12 : 16),
            if (isSmallScreen)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Jogar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Criar Sala',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeStats(String players, String duration, String categories, bool isSmallScreen) {
    return Column(
      children: [
        _buildStatRow('👥', players, isSmallScreen),
        SizedBox(height: isSmallScreen ? 2 : 4),
        _buildStatRow('⏱️', duration, isSmallScreen),
        SizedBox(height: isSmallScreen ? 2 : 4),
        _buildStatRow('🎯', categories, isSmallScreen),
      ],
    );
  }

  Widget _buildStatRow(String emoji, String text, bool isSmallScreen) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 10 : 12)),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

