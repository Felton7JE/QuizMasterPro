import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../utils/snackbar_utils.dart';
import 'package:quizmaster_pro/widgets/loading_logo.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  Timer? _debounce;
  bool _isChecking = false;
  bool? _isAvailable;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNicknameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() {
        _isAvailable = null;
        _errorMessage = '';
      });
      return;
    }

    if (nickname.length < 3) {
      setState(() {
        _isAvailable = false;
        _errorMessage = 'Mínimo de 3 caracteres';
      });
      return;
    }

    if (nickname.contains('@')) {
      setState(() {
        _isAvailable = false;
        _errorMessage = 'Caractere @ não permitido';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final authProvider = context.read<AuthProvider>();
      final isAvailable = await authProvider.checkUsername(nickname);
      
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isAvailable = isAvailable;
          if (!isAvailable) {
            _errorMessage = 'Nome de usuário indisponível';
          }
        });
      }
    });
  }

  Future<void> _handleConfirm() async {
    final nickname = _nicknameController.text.trim();
    if (_isAvailable != true || nickname.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUsername(nickname);
    
    if (mounted) {
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;

        if (!mounted) return;

        AppSnackBar.showSuccess(context, 'Bem-vindo, $nickname!');
        if (!hasSeenTutorial) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      } else {
        AppSnackBar.showError(context, authProvider.error ?? 'Erro ao atualizar nome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.face,
                size: 80,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 24),
              const Text(
                'Escolha seu Nickname',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Como você quer ser chamado no MeuQuiz+? (Esse nome será visível para os outros jogadores).',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              TextField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                  suffixIcon: _buildSuffixIcon(),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isAvailable == true && !authProvider.isLoading) ? _handleConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: LoadingLogo(size: 60),
                        )
                      : const Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget? _buildSuffixIcon() {
    if (_isChecking) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: LoadingLogo(size: 60),
        ),
      );
    }
    
    if (_isAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (_isAvailable == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    
    return null;
  }
}
