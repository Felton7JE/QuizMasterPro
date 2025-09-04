import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button_responsive.dart';

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Primeiro, tenta pegar os detalhes da sala para verificar se ela existe e se precisa de senha
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      final userId = authProvider.currentUser?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // Tenta entrar na sala (por agora, a API não suporta verificação de senha)
      final success = await roomProvider.joinRoom(roomCode, userId);

      if (success && mounted) {
        // Navega para o lobby da sala 
        Navigator.pushReplacementNamed(
          context,
          '/team-lobby',
        );
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
    if (error.contains('404')) {
      return 'Sala não encontrada. Verifique o código.';
    } else if (error.contains('403')) {
      return 'Acesso negado. Sala pode estar cheia ou senha incorreta.';
    } else if (error.contains('400')) {
      return 'Código de sala inválido.';
    }
    return 'Erro ao entrar na sala. Tente novamente.';
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
                vertical: 2,
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
              SizedBox(width: 12),
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
          SizedBox(height: 8),
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
              SizedBox(width: 8),
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
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
                      SizedBox(width: 4),
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
              SizedBox(width: 8),
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
              SizedBox(width: 8),
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
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
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
              SizedBox(width: 8),
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
          SizedBox(width: 12),
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
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(width: 12),
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
