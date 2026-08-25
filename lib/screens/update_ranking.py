import re

with open('d:/ProjectQuiz/QuizMasterPro/lib/screens/ranking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace imports
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';\nimport '../providers/auth_provider.dart';")

# Extract everything before _topPlayers
start_idx = content.find("  final List<Map<String, dynamic>> _topPlayers = [")

# Extract everything after _allPlayers
end_idx = content.find("  @override\n  Widget build(BuildContext context) {")

replacement = """  List<Map<String, dynamic>> _topPlayers = [];
  List<Map<String, dynamic>> _allPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRanking();
  }

  Future<void> _fetchRanking() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final data = await authProvider.getRanking(period: _selectedFilter);
      
      final mappedData = data.map((item) {
        return {
          'rank': item['position'] ?? 0,
          'name': item['username'] ?? 'User',
          'points': item['totalPoints'] ?? 0,
          'accuracy': item['accuracy']?.toInt() ?? 0,
          'games': item['gamesPlayed'] ?? 0,
          'streak': 0, // Not provided by backend yet
          'level': 1, // Not provided by backend yet
          'avatar': item['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=40&h=40&fit=crop&crop=face',
          'change': 0,
          'badges': item['activeTitleName'] != null ? [item['activeTitleName']] : [],
          'bannerUrl': item['activeBannerUrl'],
          'isCurrentUser': item['userId'] == authProvider.user?.id,
        };
      }).toList();

      setState(() {
        _topPlayers = mappedData.take(3).toList();
        if (mappedData.length > 3) {
          _allPlayers = mappedData.skip(3).toList();
        } else {
          _allPlayers = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar ranking: $e');
      setState(() => _isLoading = false);
    }
  }

"""

new_content = content[:start_idx] + replacement + content[end_idx:]

# Find where _selectedFilter is updated, and call _fetchRanking
new_content = new_content.replace(
    "setState(() => _selectedFilter = filter);",
    "setState(() {\\n      _selectedFilter = filter;\\n      _fetchRanking();\\n    });"
)

# Add CircularProgressIndicator to body
body_start = new_content.find("      body: SingleChildScrollView(")
if body_start != -1:
    body_replacement = """      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView("""
    new_content = new_content.replace("      body: SingleChildScrollView(", body_replacement)


with open('d:/ProjectQuiz/QuizMasterPro/lib/screens/ranking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done")
