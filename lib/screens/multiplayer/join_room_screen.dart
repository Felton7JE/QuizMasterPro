import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game/room_provider.dart';
import '../../providers/core/auth_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/core/custom_button_responsive.dart';
import '../../widgets/core/app_logo_text.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pré-preenche o username se o usuário estiver logado
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.username != null) {
      _usernameController.text = authProvider.currentUser!.username;
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final roomCode = _roomCodeController.text.trim().toUpperCase();

      // Primeiro, busca os dados da sala sem entrar
      final roomPreview = await roomProvider.getRoomPreview(roomCode);
      
      setState(() {
        _isLoading = false;
      });

      if (roomPreview != null) {
        _showRoomPreviewDialog(roomPreview, roomCode);
      } else {
        setState(() {
          _error = 'Não foi possível carregar os detalhes da sala.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  void _showRoomPreviewDialog(RoomModel room, String roomCode) {
    final hasPassword = room.isPasswordProtected;
    final tempPasswordController = TextEditingController(text: _passwordController.text.trim());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Text(
                    'Detalhes da Sala',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (hasPassword) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text('Privada', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Host: ${room.hostName ?? 'Desconhecido'}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Modo: ${room.gameMode.toString().split('.').last}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Perguntas: ${room.questionCount}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  if (hasPassword) ...[
                    TextFormField(
                      controller: tempPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Senha da Sala',
                        labelStyle: const TextStyle(color: Colors.amber),
                        prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.amber),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Text('💰 ', style: TextStyle(fontSize: 20)),
                        Expanded(
                          child: Text(
                            'Custo de Entrada: ${room.entryFee ?? 0} moedas',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fechar o modal
                  },
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final passToUse = tempPasswordController.text.trim();
                    _passwordController.text = passToUse;
                    Navigator.of(context).pop(); // Fechar o modal
                    _executeJoinRoom(roomCode, password: passToUse.isNotEmpty ? passToUse : null);
                  },
                  child: const Text('Entrar na Partida', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeJoinRoom(String roomCode, {String? password}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      final pass = password ?? (_passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null);
      final success = await roomProvider.joinRoom(roomCode, userId, password: pass);

      if (success && mounted) {
        final gameMode = roomProvider.currentRoom?.gameMode;
        
        if (gameMode == GameMode.DUEL) {
          Navigator.pushReplacementNamed(context, '/duel-lobby');
        } else if (gameMode == GameMode.KAHOOT) {
          Navigator.pushReplacementNamed(context, '/kahoot-lobby');
        } else {
          // Navega para o lobby da sala de equipe
          Navigator.pushReplacementNamed(context, '/team-lobby');
        }
      } else if (!success && mounted) {
        setState(() {
          _error = roomProvider.error ?? 'Erro ao entrar na sala.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _formatError(String error) {
    if (error.contains('Senha incorreta')) {
      return '🔒 Senha incorreta! Verifique a senha com o criador da sala.';
    } else if (error.contains('Energia insuficiente')) {
      return '⚡ Energia insuficiente para entrar na partida.';
    } else if (error.contains('404') || error.contains('não encontrada')) {
      return 'Sala não encontrada. Verifique o código.';
    } else if (error.contains('cheia')) {
      return 'A sala já está cheia.';
    } else if (error.contains('403')) {
      return 'Acesso negado. A sala pode ser privada ou estar cheia.';
    } else if (error.contains('400')) {
      return 'Código de sala inválido.';
    }
    return error.replaceAll('Exception:', '').replaceAll('RuntimeException:', '').trim();
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        setState(() {
          _roomCodeController.text = clipboardData!.text!.trim().toUpperCase();
        });
      }
    } catch (e) {
      // Ignora erros de clipboard
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
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/menu',
              (route) => false,
            ),
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
              // Header
              _buildHeader(isSmallScreen),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Código da Sala
              _buildRoomCodeSection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Senha (opcional)
              _buildPasswordSection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Nome do Jogador
              _buildUsernameSection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Instruções
              _buildInstructions(isSmallScreen),
              SizedBox(height: isSmallScreen ? 32 : 40),

              // Botão de Entrar
              _buildJoinButton(isSmallScreen),

              // Erro
              if (_error != null) ...[
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildErrorMessage(isSmallScreen),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.meeting_room,
                color: Colors.white,
                size: isSmallScreen ? 28 : 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Entrar numa Sala',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Digite o código da sala para entrar na partida',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCodeSection(bool isSmallScreen) {
    return Container(
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
              Icon(
                Icons.qr_code,
                color: const Color(0xFF10B981),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Código da Sala',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _pasteFromClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.paste,
                        color: const Color(0xFF10B981),
                        size: isSmallScreen ? 14 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Colar',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          TextFormField(
            controller: _roomCodeController,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 2,
              ),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite o código da sala';
              }
              if (value.trim().length != 6) {
                return 'O código deve ter 6 caracteres';
              }
              return null;
            },
            inputFormatters: [
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            onChanged: (value) {
              setState(() {
                _roomCodeController.text = value.toUpperCase();
                _roomCodeController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _roomCodeController.text.length),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(bool isSmallScreen) {
    return Container(
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
              Icon(
                Icons.lock_outline,
                color: const Color(0xFFF59E0B),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Senha (Opcional)',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Digite a senha se a sala for privada',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameSection(bool isSmallScreen) {
    return Container(
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
              Icon(
                Icons.person,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Nome do Jogador',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Como você quer ser chamado?',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite seu nome';
              }
              if (value.trim().length < 2) {
                return 'Nome deve ter pelo menos 2 caracteres';
              }
              if (value.trim().length > 20) {
                return 'Nome deve ter no máximo 20 caracteres';
              }
              return null;
            },
            inputFormatters: [
              LengthLimitingTextInputFormatter(20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Como funciona',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildInstructionItem('1', 'Peça o código da sala para o host', isSmallScreen),
          _buildInstructionItem('2', 'Digite o código de 6 caracteres', isSmallScreen),
          _buildInstructionItem('3', 'Informe a senha se a sala for privada', isSmallScreen),
          _buildInstructionItem('4', 'Aguarde na sala até o jogo começar', isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 24 : 28,
            height: isSmallScreen ? 24 : 28,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading ? 'Entrando...' : 'Entrar na Sala',
        onPressed: _isLoading ? () {} : () => _joinRoom(),
        isPrimary: true,
        isLarge: true,
      ),
    );
  }

  Widget _buildErrorMessage(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
