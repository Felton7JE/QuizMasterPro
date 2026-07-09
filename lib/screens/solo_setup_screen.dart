import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/category_provider.dart';
import '../models/room_model.dart';
import '../models/category_models.dart' as CategoryModels;

class SoloSetupScreen extends StatefulWidget {
  const SoloSetupScreen({super.key});

  @override
  State<SoloSetupScreen> createState() => _SoloSetupScreenState();
}

class _SoloSetupScreenState extends State<SoloSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Difficulty _difficulty = Difficulty.MEDIUM;
  int _questionCount = 10;
  int _questionTime = 20;
  CategoryModels.Category? _selectedCategory;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catProv = context.read<CategoryProvider>();
      // Força o carregamento mesmo que já tenha categorias em cache
      await catProv.forceLoadCategories();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startSoloGame() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    final auth = context.read<AuthProvider>();
    final roomProv = context.read<RoomProvider>();

    final userId = auth.currentUser?.id;
    if (userId == null) {
      _showError('Utilizador nao autenticado. Por favor, inicia sessao.');
      setState(() => _isStarting = false);
      return;
    }

    final List<int> categoryIds =
        _selectedCategory != null ? [_selectedCategory!.id] : [];

    // 1. Criar sala CLASSIC
    final created = await roomProv.createRoom(
      roomName: 'Solo - ${auth.currentUser?.username ?? 'Jogador'}',
      gameMode: GameMode.CLASSIC,
      difficulty: _difficulty,
      maxPlayers: 1,
      questionTime: _questionTime,
      questionCount: _questionCount,
      categoryIds: categoryIds,
      assignmentType: 'CHOOSE',
      categoryAssignmentMode: 'AUTO',
      allowSpectators: false,
      enableChat: false,
      showRealTimeRanking: false,
      allowReconnection: false,
      hostId: userId,
    );

    if (!created) {
      _showError(roomProv.error ?? 'Erro ao criar sala. Tente novamente.');
      setState(() => _isStarting = false);
      return;
    }

    // 2. Marcar como pronto
    await roomProv.setPlayerReady(userId);

    // 3. Iniciar o jogo
    final started = await roomProv.startGame(userId);
    if (!started) {
      _showError(roomProv.error ?? 'Erro ao iniciar jogo.');
      setState(() => _isStarting = false);
      return;
    }

    // 4. Obter gameId
    final gameId =
        roomProv.lastStartedGameId?.toString() ?? await roomProv.getGameId();
    if (gameId == null) {
      _showError('Nao foi possivel obter o ID do jogo.');
      setState(() => _isStarting = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isStarting = false);

    // 5. Navegar para o quiz
    Navigator.pushReplacementNamed(
      context,
      '/quiz-game',
      arguments: {
        'gameId': gameId,
        'playerCategory': _selectedCategory?.name,
        'isSolo': true,
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo Solo',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Treina ao teu ritmo, sem pressao',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Categoria'),
                const SizedBox(height: 12),
                Consumer<CategoryProvider>(
                  builder: (context, catProv, _) {
                    if (catProv.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6366F1)),
                      );
                    }
                    final cats = catProv.categories;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildCategoryChip(null, 'Aleatoria'),
                        ...cats.map((c) => _buildCategoryChip(c, c.displayName)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('Dificuldade'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDiffBtn(Difficulty.EASY, 'Facil', const Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    _buildDiffBtn(Difficulty.MEDIUM, 'Medio', const Color(0xFFF59E0B)),
                    const SizedBox(width: 10),
                    _buildDiffBtn(Difficulty.HARD, 'Dificil', const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('Numero de Perguntas: $_questionCount'),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF6366F1),
                    inactiveTrackColor: const Color(0xFF334155),
                    thumbColor: const Color(0xFF6366F1),
                    overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _questionCount.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    onChanged: (v) =>
                        setState(() => _questionCount = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('5',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('30',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('Tempo por Pergunta: ${_questionTime}s'),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF8B5CF6),
                    inactiveTrackColor: const Color(0xFF334155),
                    thumbColor: const Color(0xFF8B5CF6),
                    overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _questionTime.toDouble(),
                    min: 10,
                    max: 60,
                    divisions: 10,
                    onChanged: (v) =>
                        setState(() => _questionTime = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('10s',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('60s',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isStarting ? null : _startSoloGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      disabledBackgroundColor: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isStarting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              ),
                              SizedBox(width: 12),
                              Text('A preparar jogo...',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 28),
                              SizedBox(width: 8),
                              Text('Jogar Agora',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );

  Widget _buildCategoryChip(CategoryModels.Category? cat, String label) {
    final isSelected =
        cat == null ? _selectedCategory == null : _selectedCategory?.id == cat.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFF334155),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildDiffBtn(Difficulty diff, String label, Color color) {
    final isSelected = _difficulty == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = diff),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF334155),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}
