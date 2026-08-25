import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('musicEnabled') ?? true;
      _sfxEnabled = prefs.getBool('sfxEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _triggerVibration() {
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Terminar Sessão', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja sair da sua conta?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Apagar Conta', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
        content: const Text(
          'Tem certeza absoluta? Esta ação é IRREVERSÍVEL e apagará todo o seu progresso, itens comprados e histórico no jogo.', 
          style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              AppSnackBar.showInfo(context, 'A apagar conta...');
              
              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.deleteAccount();
              
              if (mounted && success) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              } else if (mounted) {
                AppSnackBar.showError(context, 'Erro ao apagar conta. Tente novamente.');
              }
            },
            child: const Text('Sim, Apagar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Row(
              children: [
                Icon(Icons.bug_report_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Relatar Bug', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Encontrou algum problema? Descreva-o abaixo para nos ajudar a melhorar o jogo.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Descreva o bug aqui...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (textController.text.trim().isEmpty) return;
                        setDialogState(() => isSubmitting = true);
                        try {
                          final userId = context.read<AuthProvider>().currentUser?.id;
                          await context.read<ApiService>().reportBug(
                            textController.text.trim(),
                            userId?.toString(),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Obrigado! O seu relatório foi enviado.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao enviar relatório: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16, height: 16, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Enviar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('ÁUDIO'),
          _buildSettingCard(
            children: [
              _buildSwitchTile(
                title: 'Música de fundo',
                icon: Icons.music_note_rounded,
                value: _musicEnabled,
                onChanged: (val) {
                  setState(() => _musicEnabled = val);
                  _saveSetting('musicEnabled', val);
                  _triggerVibration();
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'Efeitos sonoros',
                icon: Icons.volume_up_rounded,
                value: _sfxEnabled,
                onChanged: (val) {
                  setState(() => _sfxEnabled = val);
                  _saveSetting('sfxEnabled', val);
                  _triggerVibration();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('JOGABILIDADE'),
          _buildSettingCard(
            children: [
              _buildSwitchTile(
                title: 'Vibração',
                icon: Icons.vibration_rounded,
                value: _vibrationEnabled,
                onChanged: (val) {
                  setState(() => _vibrationEnabled = val);
                  _saveSetting('vibrationEnabled', val);
                  if (val) HapticFeedback.lightImpact(); // vibrate if just turned on
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('CONTA'),
          _buildSettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                title: const Text('Mudar Senha', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                onTap: _showChangePasswordDialog,
              ),
              _buildDivider(),
              ListTile(
                leading: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                title: const Text('Apagar Conta', style: TextStyle(color: Colors.redAccent)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                onTap: _handleDeleteAccount,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('SOBRE'),
          _buildSettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_rounded, color: Colors.white70),
                title: const Text('Relatar Bug', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                onTap: _showBugReportDialog,
              ),
              _buildDivider(),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                title: const Text('Tutorial / Como Jogar', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                onTap: _showTutorialDialog,
              ),
              _buildDivider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded, color: Colors.white70),
                title: const Text('Termos de Privacidade', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                onTap: _showPrivacyPolicy,
              ),
              _buildDivider(),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded, color: Colors.white70),
                title: Text('Versão do Aplicativo', style: TextStyle(color: Colors.white)),
                trailing: Text('1.0.0', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text(
              'Terminar Sessão',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Mudar Senha', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Senha actual',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nova senha',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Confirmar nova senha',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => errorMsg = null);
                        if (currentPasswordController.text.isEmpty ||
                            newPasswordController.text.isEmpty ||
                            confirmPasswordController.text.isEmpty) {
                          setDialogState(() => errorMsg = 'Preencha todos os campos.');
                          return;
                        }
                        if (newPasswordController.text.length < 6) {
                          setDialogState(() => errorMsg = 'A nova senha deve ter no mínimo 6 caracteres.');
                          return;
                        }
                        if (newPasswordController.text != confirmPasswordController.text) {
                          setDialogState(() => errorMsg = 'As senhas não coincidem.');
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        // Simula a API
                        await Future.delayed(const Duration(seconds: 2));
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Senha alterada com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16, height: 16, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Termos de Privacidade', style: TextStyle(color: Colors.white)),
        content: const SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              '1. Coleta de Dados\n'
              'Coletamos informações básicas como o seu nome de usuário, e-mail e estatísticas de jogo para fornecer a melhor experiência possível no MeuQuiz+.\n\n'
              '2. Uso das Informações\n'
              'As suas informações são utilizadas exclusivamente para o funcionamento do jogo, como o sistema de ranking global, partidas multiplayer e missões.\n\n'
              '3. Compartilhamento\n'
              'Não vendemos, trocamos ou transferimos as suas informações pessoais para terceiros.\n\n'
              '4. Segurança\n'
              'Implementamos uma variedade de medidas de segurança para manter a segurança das suas informações pessoais.\n\n'
              'Ao continuar a utilizar o jogo, você concorda com a nossa política de privacidade.',
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Como Jogar', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 Modo Clássico (Solo)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Joga sozinho ao teu próprio ritmo. Responde ao máximo de perguntas seguidas sem falhar para bateres o teu recorde!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 12),
                Text('⚔️ Duelo 1v1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Desafia um amigo ou um jogador aleatório. O jogador que responder mais rápido e acertar mais perguntas ganha!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 12),
                Text('🧑‍🤝‍🧑 Modo Kahoot (Em Tempo Real)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Um anfitrião cria a sala e todos os jogadores respondem à mesma pergunta simultaneamente no telemóvel. Quanto mais rápido, mais pontos!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 12),
                Text('🏆 Missões e Loja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Completa as missões diárias para ganhar moedas de ouro. Usa o ouro na loja para comprar Avatares, Molduras, Títulos e Banners exclusivos para decorar o teu perfil!', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido!', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      secondary: Icon(icon, color: Colors.white70),
      activeColor: const Color(0xFF6366F1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.05),
      height: 1,
      thickness: 1,
      indent: 56,
    );
  }
}
