import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button_responsive.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/category_provider.dart';
import '../models/room_model.dart';
import '../utils/snackbar_utils.dart';
import '../services/question_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedMode = 'team';
  String _selectedCategory = 'mixed';
  String _selectedDifficulty = 'medium';
  String _selectedConnection = 'online';
  int _maxPlayers = 8;
  int _questionTime = 15;
  int _questionCount = 10;
  bool _allowSpectators = true;
  bool _enableChat = true;
  bool _showRealTimeRanking = true;
  bool _allowReconnection = true;
  bool _showAdvanced = false;
  bool _isCreatingRoom = false;

  // Para modo equipe - seleção múltipla de disciplinas
  List<String> _selectedTeamCategories = ['math', 'portuguese'];
  String _teamAssignmentType = 'CHOOSE'; // CHOOSE = jogador escolhe, RANDOM = distribuição automática
  String _categoryAssignmentMode = 'MANUAL'; // MANUAL = jogador escolhe disciplina, AUTO = automático

  @override
  void initState() {
    super.initState();
    // Valor padrão para facilitar os testes
    _roomNameController.text = "Quiz em Equipe - Teste";
    
    // Carregar categorias ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Recebe o modo de jogo selecionado no menu
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['gameMode'] != null) {
      _selectedMode = args['gameMode'];
    }
  }

  Future<void> _createRoom() async {
    print('🔴 DEBUG CreateRoomScreen: ===== INÍCIO CRIAÇÃO DE SALA =====');
    
    if (!_formKey.currentState!.validate()) {
      print('🔴 DEBUG CreateRoomScreen: FALHA - Validação do formulário');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();

    if (authProvider.currentUser == null) {
      print('🔴 DEBUG CreateRoomScreen: FALHA - Usuário não logado');
      AppSnackBar.showError(context, 'Você precisa estar logado para criar uma sala');
      return;
    }

    setState(() => _isCreatingRoom = true);

    try {
      print('🔴 DEBUG CreateRoomScreen: Preparando dados da sala...');
      
      // MUDANÇA: Converter categorias locais para IDs usando CategoryProvider
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      List<int> categoryIds;
      
      if (_selectedMode == 'team') {
        categoryIds = _selectedTeamCategories.map((catName) {
          final apiCategoryName = _mapCategoryToApi(catName);
          final category = categoryProvider.getCategoryByName(apiCategoryName);
          return category?.id ?? 0; // 0 como fallback (deve ser tratado como erro)
        }).where((id) => id != 0).toList();
      } else {
        final apiCategoryName = _mapCategoryToApi(_selectedCategory);
        final category = categoryProvider.getCategoryByName(apiCategoryName);
        categoryIds = category != null ? [category.id] : [];
      }

      if (categoryIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao processar categorias selecionadas')),
          );
        }
        return;
      }

      final roomName = _roomNameController.text.trim();
      final hostId = authProvider.currentUser!.id;
      
      print('🔴 DEBUG CreateRoomScreen: roomName: "$roomName"');
      print('🔴 DEBUG CreateRoomScreen: hostId: $hostId');
      print('🔴 DEBUG CreateRoomScreen: selectedMode: $_selectedMode');
      print('🔴 DEBUG CreateRoomScreen: categoryIds: $categoryIds'); // MUDANÇA
      print('🔴 DEBUG CreateRoomScreen: assignmentType: ${_teamAssignmentType.toUpperCase()}');
      
      final success = await roomProvider.createRoom(
        roomName: roomName,
        password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
        gameMode: _selectedMode == 'team' ? GameMode.TEAM : GameMode.INDIVIDUAL,
        difficulty: _mapDifficultyToApi(_selectedDifficulty),
        maxPlayers: _maxPlayers,
        questionTime: _questionTime,
        questionCount: _questionCount,
        categoryIds: categoryIds, // MUDANÇA: usar categoryIds
        assignmentType: _teamAssignmentType, // Já está correto (CHOOSE ou RANDOM)
        categoryAssignmentMode: _categoryAssignmentMode, // Nova propriedade
        allowSpectators: _allowSpectators,
        enableChat: _enableChat,
        showRealTimeRanking: _showRealTimeRanking,
        allowReconnection: _allowReconnection,
        hostId: hostId,
      );

      print('🔴 DEBUG CreateRoomScreen: Resultado: success = $success');
      print('🔴 DEBUG CreateRoomScreen: RoomProvider currentRoom: ${roomProvider.currentRoom}');

      if (mounted) {
        if (success && roomProvider.currentRoom != null) {
          print('🔴 DEBUG CreateRoomScreen: SUCESSO - Sala criada! Navegando...');
          
          AppSnackBar.showSuccess(context, 'Sala criada com sucesso!');
          
          if (_selectedMode == 'team') {
            print('🔴 DEBUG CreateRoomScreen: Navegando para team-lobby...');
            Navigator.pushReplacementNamed(
              context, 
              '/team-lobby',
              arguments: {
                'roomCode': roomProvider.currentRoom!.roomCode,
                'roomName': roomProvider.currentRoom!.roomName,
                'categories': roomProvider.currentRoom!.categories,
                'difficulty': roomProvider.currentRoom!.difficulty.value.toLowerCase(),
                'maxPlayers': roomProvider.currentRoom!.maxPlayers,
                'questionTime': roomProvider.currentRoom!.questionTime,
                'questionCount': roomProvider.currentRoom!.questionCount,
                'assignmentType': roomProvider.currentRoom!.assignmentType ?? 'CHOOSE',
                'hostName': roomProvider.currentRoom!.hostName,
                'currentPlayers': roomProvider.currentRoom!.currentPlayers ?? 0,
                'allowSpectators': roomProvider.currentRoom!.allowSpectators,
                'enableChat': roomProvider.currentRoom!.enableChat,
                'showRealTimeRanking': roomProvider.currentRoom!.showRealTimeRanking,
                'allowReconnection': roomProvider.currentRoom!.allowReconnection,
                'isHost': true,
              },
            );
          } else {
            print('🔴 DEBUG CreateRoomScreen: Navegando para quiz-countdown...');
            // Para outros modos, navegar para tela apropriada
            Navigator.pushReplacementNamed(context, '/quiz-countdown');
          }
        } else {
          print('🔴 DEBUG CreateRoomScreen: FALHA - Erro ao criar sala: ${roomProvider.error}');
          AppSnackBar.showError(context, roomProvider.error ?? 'Erro ao criar sala');
        }
      }
    } catch (e, stackTrace) {
      print('🔴 DEBUG CreateRoomScreen: EXCEÇÃO CAPTURADA: $e');
      print('🔴 DEBUG CreateRoomScreen: Stack trace: $stackTrace');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
      }
      print('🔴 DEBUG CreateRoomScreen: ===== FIM CRIAÇÃO DE SALA =====');
    }
  }

  String _mapCategoryToApi(String localCategory) {
    switch (localCategory) {
      case 'math':
        return 'MATH';
      case 'portuguese':
        return 'PORTUGUESE';  // Corrigido: era LITERATURE, agora PORTUGUESE
      case 'science':
        return 'SCIENCE';
      case 'geography':
        return 'GEOGRAPHY';
      case 'history':
        return 'HISTORY';
      case 'sports':
        return 'MIXED';       // Corrigido: SPORTS não existe, usando MIXED
      case 'entertainment':
        return 'MIXED';       // Corrigido: ENTERTAINMENT não existe, usando MIXED
      case 'technology':
        return 'MIXED';       // Corrigido: TECHNOLOGY não existe, usando MIXED
      case 'english':
        return 'ENGLISH';     // Adicionado: categoria que existe no backend
      case 'mixed':
        return 'MIXED';       // Adicionado: categoria que existe no backend
      default:
        return 'MATH';
    }
  }

  Difficulty _mapDifficultyToApi(String localDifficulty) {
    switch (localDifficulty) {
      case 'easy':
        return Difficulty.EASY;
      case 'medium':
        return Difficulty.MEDIUM;
      case 'hard':
        return Difficulty.HARD;
      default:
        return Difficulty.MEDIUM;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Text(
              'QuizMaster',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : 6, 
                vertical: 2
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pro',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isSmallScreen)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/menu'),
              child: const Text(
                'Voltar ao Menu',
                style: TextStyle(color: Color(0xFF6366F1)),
              ),
            )
          else
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/menu'),
              icon: const Icon(
                Icons.home,
                color: Color(0xFF6366F1),
              ),
            ),
          SizedBox(width: isSmallScreen ? 8 : 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Text(
                'Criar Nova Sala',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                'Configure sua sala e convide seus amigos para jogar',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Room Basic Info
              _buildBasicInfoSection(),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Selected Game Mode Display
              _buildSelectedModeSection(),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Game Configuration
              _buildGameConfigSection(),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Advanced Settings
              _buildAdvancedSettingsSection(),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Form Actions
              _buildFormActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _roomNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nome da Sala',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'Ex: Sala dos Amigos',
                hintStyle: TextStyle(color: Colors.grey),
                helperText: 'Escolha um nome único e fácil de lembrar',
                helperStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite um nome para a sala';
                }
                if (value.length < 3) {
                  return 'O nome deve ter pelo menos 3 caracteres';
                }
                return null;
              },
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            if (isSmallScreen) ...[
              // Em telas pequenas, empilha verticalmente
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Senha (Opcional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Deixe vazio para sala pública',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _maxPlayers,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Máximo de Jogadores',
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
                items: [2, 4, 6, 8, 12, 20].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value jogadores'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _maxPlayers = newValue;
                    });
                  }
                },
              ),
            ] else ...[
              // Em telas maiores, mantém lado a lado
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Senha (Opcional)',
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: 'Deixe vazio para sala pública',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _maxPlayers,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Máximo de Jogadores',
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
                      items: [2, 4, 6, 8, 12, 20].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value jogadores'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _maxPlayers = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSelectedModeSection() {
    return Builder(
      builder: (context) {
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

        final currentMode = modeInfo[_selectedMode] ?? modeInfo['team']!;
        
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
                  onPressed: () => Navigator.pop(context),
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
                            SizedBox(height: 4),
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
                  if (_selectedMode == 'team') ...[
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
                              SizedBox(width: 8),
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
                          SizedBox(height: 8),
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
      },
    );
  }

  Widget _buildGameConfigSection() {
    return Builder(
      builder: (context) {
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
            
            // Categories - ajustado para modo equipe
            if (_selectedMode == 'team') ...[
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
                    SizedBox(height: 12),
                    Wrap(
                      spacing: isSmallScreen ? 6 : 8,
                      runSpacing: isSmallScreen ? 6 : 8,
                      children: [
                        _buildTeamCategoryChip('math', '🔢', 'Matemática'),
                        _buildTeamCategoryChip('portuguese', '📚', 'Português'),
                        _buildTeamCategoryChip('history', '🏛️', 'História'),
                        _buildTeamCategoryChip('geography', '🌍', 'Geografia'),
                        _buildTeamCategoryChip('science', '🔬', 'Ciências'),
                        _buildTeamCategoryChip('english', '🇺🇸', 'Inglês'),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Tipo de atribuição das disciplinas
                    Text(
                      'Como atribuir as disciplinas aos jogadores:',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildAssignmentTypeSelector(),
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
              Wrap(
                spacing: isSmallScreen ? 6 : 8,
                runSpacing: isSmallScreen ? 6 : 8,
                children: [
                  _buildCategoryChip('mixed', '🎯', 'Mistas'),
                  _buildCategoryChip('math', '🔢', 'Matemática'),
                  _buildCategoryChip('portuguese', '📚', 'Português'),
                  _buildCategoryChip('history', '🏛️', 'História'),
                  _buildCategoryChip('geography', '🌍', 'Geografia'),
                  _buildCategoryChip('science', '🔬', 'Ciências'),
                ],
              ),
            ],
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Configurações específicas para modo equipe
            if (_selectedMode == 'team') ...[
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
                      value: _maxPlayers ~/ 2, // Divide por 2 para mostrar jogadores por equipe
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
                          setState(() {
                            _maxPlayers = newValue * 2; // Total = 2 equipes
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total: $_maxPlayers jogadores',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            '2 equipes de ${_maxPlayers ~/ 2}',
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

            // Difficulty and Time
            if (isSmallScreen) ...[
              // Em telas pequenas, empilha verticalmente
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
                      _buildDifficultyChip('easy', '😊', 'Fácil'),
                      const SizedBox(width: 8),
                      _buildDifficultyChip('medium', '😐', 'Médio'),
                      const SizedBox(width: 8),
                      _buildDifficultyChip('hard', '😤', 'Difícil'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _questionTime,
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
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _questionTime = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
              // Em telas maiores, mantém lado a lado
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
                            _buildDifficultyChip('easy', '😊', 'Fácil'),
                            const SizedBox(width: 8),
                            _buildDifficultyChip('medium', '😐', 'Médio'),
                            const SizedBox(width: 8),
                            _buildDifficultyChip('hard', '😤', 'Difícil'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _questionTime,
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
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _questionTime = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Question Count and Connection
            if (isSmallScreen) ...[
              // Em telas pequenas, empilha verticalmente
              DropdownButtonFormField<int>(
                value: _questionCount,
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
                items: [5, 10, 15, 20, 25].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value perguntas'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _questionCount = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de Conexão',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Row(
                    children: [
                      _buildConnectionChip('online', '🌐', 'Online'),
                      const SizedBox(width: 8),
                      _buildConnectionChip('hotspot', '📶', 'Hotspot'),
                    ],
                  ),
                ],
              ),
            ] else ...[
              // Em telas maiores, mantém lado a lado
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _questionCount,
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
                      items: [5, 10, 15, 20, 25].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value perguntas'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _questionCount = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo de Conexão',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Row(
                          children: [
                            _buildConnectionChip('online', '🌐', 'Online'),
                            const SizedBox(width: 8),
                            _buildConnectionChip('hotspot', '📶', 'Hotspot'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String category, String emoji, String name) {
    final isSelected = _selectedCategory == category;
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12, 
              vertical: isSmallScreen ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentTypeSelector() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
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
            
            // Opção 1: Jogador escolhe equipe
            GestureDetector(
              onTap: () {
                setState(() {
                  _teamAssignmentType = 'CHOOSE'; // Corrigido
                });
              },
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _teamAssignmentType == 'CHOOSE' 
                    ? const Color(0xFF6366F1).withOpacity(0.2) 
                    : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _teamAssignmentType == 'CHOOSE' 
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
                            'Jogador Escolhe Equipe', // Corrigido
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
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
                    if (_teamAssignmentType == 'CHOOSE')
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF6366F1),
                        size: isSmallScreen ? 20 : 24,
                      ),
                  ],
                ),
              ),
            ),
            
            // Opção 2: Distribuição automática
            GestureDetector(
              onTap: () {
                setState(() {
                  _teamAssignmentType = 'RANDOM';
                });
              },
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _teamAssignmentType == 'RANDOM' 
                    ? const Color(0xFF10B981).withOpacity(0.2) 
                    : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _teamAssignmentType == 'RANDOM' 
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
                          SizedBox(height: 4),
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
                    if (_teamAssignmentType == 'RANDOM')
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF10B981),
                        size: isSmallScreen ? 20 : 24,
                      ),
                  ],
                ),
              ),
            ),

            // Nova seção: Como atribuir disciplinas
            Text(
              'Como atribuir as disciplinas:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Opção 1: Jogador escolhe disciplina
            GestureDetector(
              onTap: () {
                setState(() {
                  _categoryAssignmentMode = 'MANUAL';
                });
              },
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _categoryAssignmentMode == 'MANUAL' 
                    ? const Color(0xFF8B5CF6).withOpacity(0.2) 
                    : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _categoryAssignmentMode == 'MANUAL' 
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
                          SizedBox(height: 4),
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
                    if (_categoryAssignmentMode == 'MANUAL')
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF8B5CF6),
                        size: isSmallScreen ? 20 : 24,
                      ),
                  ],
                ),
              ),
            ),

            // Opção 2: Sorteio automático
            GestureDetector(
              onTap: () {
                setState(() {
                  _categoryAssignmentMode = 'AUTO';
                });
              },
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: _categoryAssignmentMode == 'AUTO' 
                    ? const Color(0xFFF59E0B).withOpacity(0.2) 
                    : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _categoryAssignmentMode == 'AUTO' 
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
                          SizedBox(height: 4),
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
                    if (_categoryAssignmentMode == 'AUTO')
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
      },
    );
  }

  Widget _buildTeamCategoryChip(String category, String emoji, String name) {
    final isSelected = _selectedTeamCategories.contains(category);
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (_selectedTeamCategories.length > 2) { // Mínimo 2 disciplinas
                  _selectedTeamCategories.remove(category);
                }
              } else {
                if (_selectedTeamCategories.length < 4) { // Máximo 4 disciplinas
                  _selectedTeamCategories.add(category);
                }
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12, 
              vertical: isSmallScreen ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.check_circle,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyChip(String difficulty, String emoji, String name) {
    final isSelected = _selectedDifficulty == difficulty;
    return Expanded(
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 600;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDifficulty = difficulty;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 16 : 18)),
                  SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionChip(String connection, String emoji, String name) {
    final isSelected = _selectedConnection == connection;
    return Expanded(
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 600;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedConnection = connection;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 16 : 18)),
                  SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Builder(
      builder: (context) {
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
                  onPressed: () {
                    setState(() {
                      _showAdvanced = !_showAdvanced;
                    });
                  },
                  child: Text(
                    _showAdvanced ? 'Ocultar' : 'Mostrar',
                    style: const TextStyle(color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
            if (_showAdvanced) ...[
              SizedBox(height: isSmallScreen ? 12 : 16),
              if (isSmallScreen) ...[
                // Em telas pequenas, empilha verticalmente
                _buildSwitchTile('Permitir Espectadores', _allowSpectators, (value) {
                  setState(() {
                    _allowSpectators = value;
                  });
                }),
                const SizedBox(height: 12),
                _buildSwitchTile('Chat Habilitado', _enableChat, (value) {
                  setState(() {
                    _enableChat = value;
                  });
                }),
                const SizedBox(height: 12),
                _buildSwitchTile('Ranking em Tempo Real', _showRealTimeRanking, (value) {
                  setState(() {
                    _showRealTimeRanking = value;
                  });
                }),
                const SizedBox(height: 12),
                _buildSwitchTile('Permitir Reconexão', _allowReconnection, (value) {
                  setState(() {
                    _allowReconnection = value;
                  });
                }),
              ] else ...[
                // Em telas maiores, mantém grade 2x2
                Row(
                  children: [
                    Expanded(
                      child: _buildSwitchTile('Permitir Espectadores', _allowSpectators, (value) {
                        setState(() {
                          _allowSpectators = value;
                        });
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchTile('Chat Habilitado', _enableChat, (value) {
                        setState(() {
                          _enableChat = value;
                        });
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSwitchTile('Ranking em Tempo Real', _showRealTimeRanking, (value) {
                        setState(() {
                          _showRealTimeRanking = value;
                        });
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchTile('Permitir Reconexão', _allowReconnection, (value) {
                        setState(() {
                          _allowReconnection = value;
                        });
                      }),
                    ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
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
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormActions() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        if (isSmallScreen) {
          // Em telas pequenas, empilha verticalmente
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isCreatingRoom ? 'Criando...' : 'Criar Sala',
                  onPressed: _isCreatingRoom ? () {} : () => _createRoom(),
                  isPrimary: true,
                  isLarge: true,
                ),
              ),
              const SizedBox(height: 12),
              // Botão de teste de conexão
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    print('🟡 DEBUG CreateRoomScreen: Testando conexão com backend...');
                    try {
                      await context.read<RoomProvider>().testConnection();
                      print('🟡 DEBUG CreateRoomScreen: Conexão OK');
                      AppSnackBar.showSuccess(context, 'Conexão com backend OK!');
                    } catch (e) {
                      print('🟡 DEBUG CreateRoomScreen: Erro de conexão: $e');
                      AppSnackBar.showError(context, 'Erro de conexão: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Testar Conexão Backend'),
                ),
              ),
              // DEBUG: quick start-game button (visible only in debug mode)
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
                        final questionService = Provider.of<QuestionService>(context, listen: false);
                        final hostIdStr = authProvider.currentUser?.id;
                        final hostId = hostIdStr != null ? int.tryParse(hostIdStr) : null;
                        final roomCode = roomProvider.currentRoom?.roomCode ?? '';
                        if (hostId == null || roomCode.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuário ou sala não encontrados')),
                          );
                          return;
                        }
                        try {
                          // Call provider.startGame which stores the raw response in lastStartedGameResponse
                          final ok = await roomProvider.startGame(hostIdStr!);
                          final raw = roomProvider.lastStartedGameResponse;
                          print('DEBUG CreateRoomScreen: startGame() returned: ok=$ok, raw=$raw');

                          // Try to get gameId from raw response and fetch current-question for the host
                          final int? gameId = raw != null && raw['gameId'] != null ? int.tryParse(raw['gameId'].toString()) : null;
                          if (gameId != null) {
                            try {
                              final currentQ = await questionService.getCurrentQuestionForPlayer(gameId, hostId);
                              print('DEBUG CreateRoomScreen: current-question = $currentQ');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('DEBUG current-question: ${currentQ['id'] ?? currentQ}')),
                                );
                              }
                            } catch (e) {
                              print('DEBUG CreateRoomScreen: erro ao buscar current-question: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao buscar pergunta atual: $e')),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('DEBUG startGame response: ${raw ?? 'null'}')),
                              );
                            }
                          }
                        } catch (e) {
                          print('DEBUG CreateRoomScreen: startGame exception: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao iniciar jogo: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Iniciar Jogo (DEBUG)'),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  isPrimary: false,
                  isLarge: true,
                ),
              ),
            ],
          );
        } else {
          // Em telas maiores, mantém lado a lado
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                      isPrimary: false,
                      isLarge: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _isCreatingRoom ? 'Criando...' : 'Criar Sala',
                      onPressed: _isCreatingRoom ? () {} : () => _createRoom(),
                      isPrimary: true,
                      isLarge: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botão de teste de conexão
              ElevatedButton(
                onPressed: () async {
                  print('🟡 DEBUG CreateRoomScreen: Testando conexão com backend...');
                  try {
                    await context.read<RoomProvider>().testConnection();
                    print('🟡 DEBUG CreateRoomScreen: Conexão OK');
                    AppSnackBar.showSuccess(context, 'Conexão com backend OK!');
                  } catch (e) {
                    print('🟡 DEBUG CreateRoomScreen: Erro de conexão: $e');
                    AppSnackBar.showError(context, 'Erro de conexão: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Testar Conexão Backend'),
              ),
              // DEBUG button for larger screens
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
                        final questionService = Provider.of<QuestionService>(context, listen: false);
                      final hostIdStr = authProvider.currentUser?.id;
                      final hostId = hostIdStr != null ? int.tryParse(hostIdStr) : null;
                      final roomCode = roomProvider.currentRoom?.roomCode ?? '';
                      if (hostId == null || roomCode.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuário ou sala não encontrados')),
                        );
                        return;
                      }
                      try {
                        final ok = await roomProvider.startGame(hostIdStr!);
                        final raw = roomProvider.lastStartedGameResponse;
                        print('DEBUG CreateRoomScreen: startGame() returned: ok=$ok, raw=$raw');

                        final int? gameId = raw != null && raw['gameId'] != null ? int.tryParse(raw['gameId'].toString()) : null;
                        if (gameId != null) {
                          try {
                            final currentQ = await questionService.getCurrentQuestionForPlayer(gameId, hostId);
                            print('DEBUG CreateRoomScreen: current-question = $currentQ');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('DEBUG current-question: ${currentQ['id'] ?? currentQ}')),
                              );
                            }
                          } catch (e) {
                            print('DEBUG CreateRoomScreen: erro ao buscar current-question: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao buscar pergunta atual: $e')),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('DEBUG startGame response: ${raw ?? 'null'}')),
                            );
                          }
                        }
                      } catch (e) {
                        print('DEBUG CreateRoomScreen: startGame exception: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao iniciar jogo: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Iniciar Jogo (DEBUG)'),
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
