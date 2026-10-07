import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button_responsive.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/category_provider.dart';
import '../models/room_model.dart';
import '../utils/snackbar_utils.dart';
import 'create_room/widgets/basic_info_section.dart';
import 'create_room/widgets/mode_selection_section.dart';
import 'create_room/widgets/game_config_section.dart';
import 'create_room/widgets/advanced_settings_section.dart';
import '../widgets/app_logo_text.dart';

class CreateRoomScreen extends StatefulWidget {
  final String? initialMode;
  final String? invitedFriendId;

  const CreateRoomScreen({super.key, this.initialMode, this.invitedFriendId});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late String _selectedMode;
  String _selectedCategory = '';
  String _selectedDifficulty = 'medium';
  String _selectedConnection = 'online';
  int _maxPlayers = 8;
  int _questionTime = 15;
  int _questionCount = 10;
  bool _allowSpectators = true;
  bool _enableChat = true;
  bool _showRealTimeRanking = true;
  bool _allowReconnection = true;
  int _entryFee = 0; // Taxa de aposta (0 = grátis)
  bool _showAdvanced = false;
  bool _isCreatingRoom = false;

  // Para modo equipe - seleção múltipla de disciplinas
  List<String> _selectedTeamCategories = [];
  String _teamAssignmentType = 'CHOOSE'; // CHOOSE = jogador escolhe, RANDOM = distribuição automática
  String _categoryAssignmentMode = 'MANUAL'; // MANUAL = jogador escolhe disciplina, AUTO = automático

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode ?? 'team';
    if (widget.initialMode == 'duel') {
      _maxPlayers = 2;
    }
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
    final catProvider = Provider.of<CategoryProvider>(context);
    if (!catProvider.isLoading && catProvider.categories.isNotEmpty) {
      if (_selectedCategory.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCategory = catProvider.categories.first.name.toLowerCase());
        });
      }
      if (_selectedTeamCategories.isEmpty && catProvider.categories.length >= 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
            _selectedTeamCategories = [
              catProvider.categories[0].name.toLowerCase(),
              catProvider.categories[1].name.toLowerCase()
            ];
          });
          }
        });
      }
    }
    // Recebe o modo de jogo selecionado no menu
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['gameMode'] != null) {
      _selectedMode = args['gameMode'];
    }
  }

  Future<void> _createRoom() async {
    debugPrint('🔴 DEBUG CreateRoomScreen: ===== INÍCIO CRIAÇÃO DE SALA =====');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 DEBUG CreateRoomScreen: FALHA - Validação do formulário');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();

    if (authProvider.currentUser == null) {
      debugPrint('🔴 DEBUG CreateRoomScreen: FALHA - Usuário não logado');
      AppSnackBar.showError(context, 'Você precisa estar logado para criar uma sala');
      return;
    }

    setState(() => _isCreatingRoom = true);

    try {
      debugPrint('🔴 DEBUG CreateRoomScreen: Preparando dados da sala...');
      
      // MUDANÇA: Converter categorias locais para IDs usando CategoryProvider
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      List<int> categoryIds = [];
      
      if (_selectedMode == 'team') {
        for (final catName in _selectedTeamCategories) {
          final category = categoryProvider.getCategoryByName(catName) ??
                           categoryProvider.getCategoryByDisplayName(catName);
          if (category != null) {
            categoryIds.add(category.id);
          }
        }
      } else {
        if (_selectedCategory.toLowerCase() == 'mixed') {
          // Se for misto, adiciona todas as categorias ativas disponíveis ou a categoria MIXED
          final mixedCat = categoryProvider.getCategoryByName('MIXED');
          if (mixedCat != null) {
            categoryIds.add(mixedCat.id);
          } else if (categoryProvider.categories.isNotEmpty) {
            categoryIds.addAll(categoryProvider.categories.map((c) => c.id));
          }
        } else {
          final category = categoryProvider.getCategoryByName(_selectedCategory) ??
                           categoryProvider.getCategoryByDisplayName(_selectedCategory);
          if (category != null) {
            categoryIds.add(category.id);
          }
        }
      }

      // Se ainda não encontrou nenhuma, usa a primeira disponível como fallback seguro
      if (categoryIds.isEmpty && categoryProvider.categories.isNotEmpty) {
        categoryIds.add(categoryProvider.categories.first.id);
      }

      if (categoryIds.isEmpty) {
        if (mounted) {
          setState(() => _isCreatingRoom = false);
          AppSnackBar.showError(context, 'Erro: Nenhuma categoria carregada do servidor.');
        }
        return;
      }

      final roomName = _roomNameController.text.trim();
      final hostId = int.parse(authProvider.currentUser!.id.toString());
      
      debugPrint('🔴 DEBUG CreateRoomScreen: roomName: "$roomName"');
      debugPrint('🔴 DEBUG CreateRoomScreen: hostId: $hostId');
      debugPrint('🔴 DEBUG CreateRoomScreen: selectedMode: $_selectedMode');
      debugPrint('🔴 DEBUG CreateRoomScreen: categoryIds: $categoryIds'); // MUDANÇA
      debugPrint('🔴 DEBUG CreateRoomScreen: assignmentType: ${_teamAssignmentType.toUpperCase()}');
      
      final success = await roomProvider.createRoom(
        roomName: roomName,
        password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
        gameMode: _selectedMode == 'team' ? GameMode.TEAM : (_selectedMode == 'duel' ? GameMode.DUEL : (_selectedMode == 'kahoot' ? GameMode.KAHOOT : GameMode.CLASSIC)),
        difficulty: _mapDifficultyToApi(_selectedDifficulty),
        maxPlayers: _selectedMode == 'duel' ? 2 : _maxPlayers,
        questionTime: _questionTime,
        questionCount: _questionCount,
        categoryIds: categoryIds, // MUDANÇA: usar categoryIds
        assignmentType: _teamAssignmentType, // Já está correto (CHOOSE ou RANDOM)
        categoryAssignmentMode: _categoryAssignmentMode, // Nova propriedade
        allowSpectators: _allowSpectators,
        enableChat: _enableChat,
        showRealTimeRanking: _showRealTimeRanking,
        allowReconnection: _allowReconnection,
        entryFee: _entryFee > 0 ? _entryFee : null,
        hostId: hostId,
      );

      debugPrint('🔴 DEBUG CreateRoomScreen: Resultado: success = $success');
      debugPrint('🔴 DEBUG CreateRoomScreen: RoomProvider currentRoom: ${roomProvider.currentRoom}');

      if (mounted) {
        if (success && roomProvider.currentRoom != null) {
          debugPrint('🔴 DEBUG CreateRoomScreen: SUCESSO - Sala criada! Navegando...');
          
          AppSnackBar.showSuccess(context, 'Sala criada com sucesso!');
          
          if (_selectedMode == 'team') {
            debugPrint('🔴 DEBUG CreateRoomScreen: Navegando para team-lobby...');
            Navigator.pushReplacementNamed(context, '/team-lobby');
          } else if (_selectedMode == 'duel') {
            debugPrint('🔴 DEBUG CreateRoomScreen: Navegando para duel-lobby...');
            Navigator.pushReplacementNamed(context, '/duel-lobby');
          } else if (_selectedMode == 'kahoot') {
            debugPrint('🔴 DEBUG CreateRoomScreen: Navegando para kahoot-lobby...');
            Navigator.pushReplacementNamed(context, '/kahoot-lobby');
          } else {
            debugPrint('🔴 DEBUG CreateRoomScreen: Navegando para team-lobby...');
            Navigator.pushReplacementNamed(context, '/team-lobby');
          }
        } else {
          debugPrint('🔴 DEBUG CreateRoomScreen: FALHA - Erro ao criar sala: ${roomProvider.error}');
          AppSnackBar.showError(context, roomProvider.error ?? 'Erro ao criar sala');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 DEBUG CreateRoomScreen: EXCEÇÃO CAPTURADA: $e');
      debugPrint('🔴 DEBUG CreateRoomScreen: Stack trace: $stackTrace');
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
      }
      debugPrint('🔴 DEBUG CreateRoomScreen: ===== FIM CRIAÇÃO DE SALA =====');
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
        title: AppLogoText(fontSize: isSmallScreen ? 18 : 20),
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
              BasicInfoSection(
                roomNameController: _roomNameController,
                passwordController: _passwordController,
                maxPlayers: _maxPlayers,
                selectedMode: _selectedMode,
                onMaxPlayersChanged: (val) {
                  if (val != null) setState(() => _maxPlayers = val);
                },
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Selected Game Mode Display
              ModeSelectionSection(
                selectedMode: _selectedMode,
                onEditMode: () => Navigator.pop(context),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Game Configuration
              GameConfigSection(
                selectedMode: _selectedMode,
                selectedTeamCategories: _selectedTeamCategories,
                selectedCategory: _selectedCategory,
                teamAssignmentType: _teamAssignmentType,
                categoryAssignmentMode: _categoryAssignmentMode,
                maxPlayers: _maxPlayers,
                selectedDifficulty: _selectedDifficulty,
                questionTime: _questionTime,
                questionCount: _questionCount,
                selectedConnection: _selectedConnection,
                entryFee: _entryFee,
                onEntryFeeChanged: (val) => setState(() => _entryFee = val ?? 0),
                onTeamCategoryToggled: (cat) {
                  setState(() {
                    if (_selectedTeamCategories.contains(cat)) {
                      if (_selectedTeamCategories.length > 2) _selectedTeamCategories.remove(cat);
                    } else {
                      if (_selectedTeamCategories.length < 4) _selectedTeamCategories.add(cat);
                    }
                  });
                },
                onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                onTeamAssignmentTypeChanged: (type) => setState(() => _teamAssignmentType = type),
                onCategoryAssignmentModeChanged: (mode) => setState(() => _categoryAssignmentMode = mode),
                onMaxPlayersChanged: (val) {
                  if (val != null) setState(() => _maxPlayers = val);
                },
                onDifficultyChanged: (diff) => setState(() => _selectedDifficulty = diff),
                onQuestionTimeChanged: (val) {
                  if (val != null) setState(() => _questionTime = val);
                },
                onQuestionCountChanged: (val) {
                  if (val != null) setState(() => _questionCount = val);
                },
                onConnectionChanged: (conn) => setState(() => _selectedConnection = conn),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Advanced Settings
              AdvancedSettingsSection(
                showAdvanced: _showAdvanced,
                allowSpectators: _allowSpectators,
                enableChat: _enableChat,
                showRealTimeRanking: _showRealTimeRanking,
                allowReconnection: _allowReconnection,
                onToggleShowAdvanced: () => setState(() => _showAdvanced = !_showAdvanced),
                onAllowSpectatorsChanged: (val) => setState(() => _allowSpectators = val),
                onEnableChatChanged: (val) => setState(() => _enableChat = val),
                onShowRealTimeRankingChanged: (val) => setState(() => _showRealTimeRanking = val),
                onAllowReconnectionChanged: (val) => setState(() => _allowReconnection = val),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Form Actions
              _buildFormActions(),
            ],
          ),
        ),
      ),
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


