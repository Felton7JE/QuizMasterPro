import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/responsive_chip.dart';
import '../../../providers/category_provider.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';

class GameConfigSection extends StatelessWidget {
  final String selectedMode;
  final List<String> selectedTeamCategories;
  final String selectedCategory;
  final String teamAssignmentType;
  final String categoryAssignmentMode;
  final int maxPlayers;
  final String selectedDifficulty;
  final int questionTime;
  final int questionCount;
  final String selectedConnection;

  final ValueChanged<String> onTeamCategoryToggled;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onTeamAssignmentTypeChanged;
  final ValueChanged<String> onCategoryAssignmentModeChanged;
  final ValueChanged<int?> onMaxPlayersChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<int?> onQuestionTimeChanged;
  final ValueChanged<int?> onQuestionCountChanged;
  final ValueChanged<String> onConnectionChanged;
  final int entryFee;
  final ValueChanged<int?> onEntryFeeChanged;

  const GameConfigSection({
    super.key,
    required this.selectedMode,
    required this.selectedTeamCategories,
    required this.selectedCategory,
    required this.teamAssignmentType,
    required this.categoryAssignmentMode,
    required this.maxPlayers,
    required this.selectedDifficulty,
    required this.questionTime,
    required this.questionCount,
    required this.selectedConnection,
    required this.onTeamCategoryToggled,
    required this.onCategoryChanged,
    required this.onTeamAssignmentTypeChanged,
    required this.onCategoryAssignmentModeChanged,
    required this.onMaxPlayersChanged,
    required this.onDifficultyChanged,
    required this.onQuestionTimeChanged,
    required this.onQuestionCountChanged,
    required this.onConnectionChanged,
    required this.entryFee,
    required this.onEntryFeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações do Jogo',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        if (selectedMode == 'team') ...[
          Text(
            'Disciplinas para os Duelos',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
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
                Text(
                  'Selecione as disciplinas que serão utilizadas nos duelos (mínimo 2):',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTeamCategoriesWrap(context, isSmallScreen),
                const SizedBox(height: 16),
                Text(
                  'Como atribuir as disciplinas aos jogadores:',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAssignmentTypeSelector(isSmallScreen),
              ],
            ),
          ),
        ] else ...[
          Text(
            'Categorias',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildSingleCategoryWrap(context, isSmallScreen),
        ],
        SizedBox(height: isSmallScreen ? 12 : 16),

        if (selectedMode == 'team') ...[
          Text(
            'Configuração das Equipes',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: maxPlayers ~/ 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Jogadores por Equipe',
                    labelStyle: TextStyle(color: Colors.grey),
                    helperText: 'Cada equipe terá este número de jogadores',
                    helperStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E293B),
                  items: [2, 3, 4].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value jogadores'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      onMaxPlayersChanged(newValue * 2);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total: $maxPlayers jogadores',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        '2 equipes de ${maxPlayers ~/ 2}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
        ],

        if (isSmallScreen) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dificuldade',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Row(
                children: [
                  Expanded(child: ResponsiveChip(icon: Icons.sentiment_satisfied_alt, label: 'Fácil', isSelected: selectedDifficulty == 'easy', onTap: () => onDifficultyChanged('easy'))),
                  const SizedBox(width: 8),
                  Expanded(child: ResponsiveChip(icon: Icons.sentiment_neutral, label: 'Médio', isSelected: selectedDifficulty == 'medium', onTap: () => onDifficultyChanged('medium'))),
                  const SizedBox(width: 8),
                  Expanded(child: ResponsiveChip(icon: Icons.whatshot, label: 'Difícil', isSelected: selectedDifficulty == 'hard', onTap: () => onDifficultyChanged('hard'))),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: questionTime,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tempo por Pergunta (segundos)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
                dropdownColor: const Color(0xFF1E293B),
                items: [10, 15, 20, 30, 45, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value segundos'),
                  );
                }).toList(),
                onChanged: onQuestionTimeChanged,
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dificuldade',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Row(
                      children: [
                        Expanded(child: ResponsiveChip(icon: Icons.sentiment_satisfied_alt, label: 'Fácil', isSelected: selectedDifficulty == 'easy', onTap: () => onDifficultyChanged('easy'))),
                        const SizedBox(width: 8),
                        Expanded(child: ResponsiveChip(icon: Icons.sentiment_neutral, label: 'Médio', isSelected: selectedDifficulty == 'medium', onTap: () => onDifficultyChanged('medium'))),
                        const SizedBox(width: 8),
                        Expanded(child: ResponsiveChip(icon: Icons.whatshot, label: 'Difícil', isSelected: selectedDifficulty == 'hard', onTap: () => onDifficultyChanged('hard'))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: questionTime,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tempo por Pergunta (segundos)',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E293B),
                  items: [10, 15, 20, 30, 45, 60].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value segundos'),
                    );
                  }).toList(),
                  onChanged: onQuestionTimeChanged,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: isSmallScreen ? 12 : 16),

        if (isSmallScreen) ...[
          DropdownButtonFormField<int>(
            initialValue: questionCount,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Número de Perguntas',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
            dropdownColor: const Color(0xFF1E293B),
            items: [10, 15, 20, 25, 30].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value perguntas'),
              );
            }).toList(),
            onChanged: onQuestionCountChanged,
          ),
        ] else ...[
          DropdownButtonFormField<int>(
            initialValue: questionCount,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Número de Perguntas',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
            dropdownColor: const Color(0xFF1E293B),
            items: [10, 15, 20, 25, 30].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value perguntas'),
              );
            }).toList(),
            onChanged: onQuestionCountChanged,
          ),
        ],

        SizedBox(height: isSmallScreen ? 16 : 24),

        // APOSTA (Taxa de Entrada)
        Text(
          'Taxa de Entrada (Moedas)',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmallScreen ? 0 : 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: entryFee,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Grátis (0)')),
                DropdownMenuItem(value: 50, child: Text('50 moedas')),
                DropdownMenuItem(value: 100, child: Text('100 moedas')),
                DropdownMenuItem(value: 200, child: Text('200 moedas')),
                DropdownMenuItem(value: 500, child: Text('500 moedas')),
                DropdownMenuItem(value: 1000, child: Text('1000 moedas')),
              ],
              onChanged: onEntryFeeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentTypeSelector(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como formar as equipes:',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onTeamAssignmentTypeChanged('CHOOSE'),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: teamAssignmentType == 'CHOOSE' 
                ? const Color(0xFF6366F1).withValues(alpha: 0.2) 
                : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: teamAssignmentType == 'CHOOSE' 
                  ? const Color(0xFF6366F1) 
                  : const Color(0xFF4B5563),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_pin,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jogador Escolhe Equipe',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cada jogador escolhe sua equipe ao entrar na sala',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                if (teamAssignmentType == 'CHOOSE')
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF6366F1),
                    size: isSmallScreen ? 20 : 24,
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onTeamAssignmentTypeChanged('RANDOM'),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: teamAssignmentType == 'RANDOM' 
                ? const Color(0xFF10B981).withValues(alpha: 0.2) 
                : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: teamAssignmentType == 'RANDOM' 
                  ? const Color(0xFF10B981) 
                  : const Color(0xFF4B5563),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shuffle,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribuição Automática',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Host distribui as equipes manualmente quando decidir',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                if (teamAssignmentType == 'RANDOM')
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF10B981),
                    size: isSmallScreen ? 20 : 24,
                  ),
              ],
            ),
          ),
        ),
        Text(
          'Como atribuir as disciplinas:',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onCategoryAssignmentModeChanged('MANUAL'),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: categoryAssignmentMode == 'MANUAL' 
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) 
                : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: categoryAssignmentMode == 'MANUAL' 
                  ? const Color(0xFF8B5CF6) 
                  : const Color(0xFF4B5563),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_search,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jogador Escolhe Disciplina',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cada jogador escolhe sua disciplina (respeitando limites da equipe)',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                if (categoryAssignmentMode == 'MANUAL')
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF8B5CF6),
                    size: isSmallScreen ? 20 : 24,
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onCategoryAssignmentModeChanged('AUTO'),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: categoryAssignmentMode == 'AUTO' 
                ? const Color(0xFFF59E0B).withValues(alpha: 0.2) 
                : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: categoryAssignmentMode == 'AUTO' 
                  ? const Color(0xFFF59E0B) 
                  : const Color(0xFF4B5563),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.casino,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sorteio Automático',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistema distribui as disciplinas automaticamente de forma equilibrada',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                if (categoryAssignmentMode == 'AUTO')
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFFF59E0B),
                    size: isSmallScreen ? 20 : 24,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toUpperCase()) {
      case 'MATH': return Icons.calculate;
      case 'PORTUGUESE': return Icons.language;
      case 'HISTORY': return Icons.history_edu;
      case 'GEOGRAPHY': return Icons.public;
      case 'SCIENCE': return Icons.science;
      case 'ENGLISH': return Icons.chat;
      case 'MIXED': return Icons.category;
      default: return Icons.category;
    }
  }

  Widget _buildTeamCategoriesWrap(BuildContext context, bool isSmallScreen) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final categories = catProvider.categories;

    if (categories.isEmpty && catProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: LoadingLogo(size: 60),
        ),
      );
    }

    final list = categories;

    return Wrap(
      spacing: isSmallScreen ? 6 : 8,
      runSpacing: isSmallScreen ? 6 : 8,
      children: list.map((cat) {
        final keyName = cat.name.toLowerCase();
        final isSelected = selectedTeamCategories.map((c) => c.toLowerCase()).contains(keyName);
        return ResponsiveChip(
          icon: _getCategoryIcon(cat.name),
          label: cat.displayName,
          isSelected: isSelected,
          showCheckmark: true,
          onTap: () => onTeamCategoryToggled(keyName),
        );
      }).toList(),
    );
  }

  Widget _buildSingleCategoryWrap(BuildContext context, bool isSmallScreen) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final categories = catProvider.categories;

    final chips = <Widget>[];

    if (categories.isEmpty && catProvider.isLoading) {
      chips.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: LoadingLogo(size: 60),
        ),
      ));
    } else {
      final list = categories;

      for (final cat in list) {
        final keyName = cat.name.toLowerCase();
        chips.add(
          ResponsiveChip(
            icon: _getCategoryIcon(cat.name),
            label: cat.displayName,
            isSelected: selectedCategory.toLowerCase() == keyName,
            onTap: () => onCategoryChanged(keyName),
          ),
        );
      }
    }

    return Wrap(
      spacing: isSmallScreen ? 6 : 8,
      runSpacing: isSmallScreen ? 6 : 8,
      children: chips,
    );
  }
}
