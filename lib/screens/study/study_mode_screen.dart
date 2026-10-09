import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/study_quiz_model.dart';
import '../../models/user_model.dart';
import '../../providers/core/auth_provider.dart';
import '../../providers/study/study_quiz_provider.dart';
import '../../widgets/economy/crystal_balance_chip.dart';
import './study_flashcards_screen.dart';
import './study_quiz_game_screen.dart';
import './study_pdf_screen.dart';
import '../economy/store_screen.dart';
import './study_plans_list_screen.dart';
import 'package:quizmaster_pro/widgets/core/loading_logo.dart';

class StudyModeScreen extends StatefulWidget {
  const StudyModeScreen({super.key});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> with SingleTickerProviderStateMixin {
  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldAccent = Color(0xFF34D399);

  late TabController _tabController;
  Timer? _cooldownTicker;

  final List<Map<String, dynamic>> _myManuals = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _shareCodeController = TextEditingController();

  int _selectedQuestionCount = 10;
  String _selectedDifficulty = 'MÉDIO';

  static const List<Map<String, String>> studyPresets = [
    {
      'name': '🧬 Biologia & Genética',
      'topic': 'Biologia',
      'title': 'Revisão: Genética, Meiose e DNA',
      'sample':
          'A molécula de DNA contém as instruções genéticas usadas no desenvolvimento e funcionamento de todos os organismos vivos. A transcrição é o processo pelo qual a informação de uma fita de DNA é copiada para uma nova molécula de RNA mensageiro. Os ribossomos realizam a tradução do código genético em cadeias de polipeptídeos formando proteínas essenciais. As mutações genéticas podem ser benéficas, neutras ou deletérias dependendo do contexto ambiental.',
    },
    {
      'name': '🏛️ História & Geopolítica',
      'topic': 'História',
      'title': 'Exame: Revolução Industrial & Guerras',
      'sample':
          'A Revolução Industrial teve início na Grã-Bretanha no século XVIII, impulsionada pela invenção da máquina a vapor. Este período provocou uma transição massiva do trabalho artesanal para a produção mecanizada em fábricas, provocando intenso êxodo rural e rápido crescimento urbano. Mais tarde, as tensões imperialistas e alianças culminaram na Primeira Guerra Mundial em 1914.',
    },
    {
      'name': '📐 Matemática & Cálculo',
      'topic': 'Matemática',
      'title': 'Preparatório: Funções, Limites e Derivadas',
      'sample':
          'A derivada de uma função representa a taxa de variação instantânea em relação a uma variável independente. Geometricamente, a derivada corresponde ao declive da reta tangente à curva num determinado ponto. O Teorema Fundamental do Cálculo conecta a derivação com a integração definida, mostrando que são operações inversas essenciais.',
    },
    {
      'name': '💻 Programação & Tecnologia',
      'topic': 'Tecnologia',
      'title': 'Teste: Estruturas de Dados & Algoritmos',
      'sample':
          'A complexidade de tempo de um algoritmo é expressa na notação Big O para medir o desempenho à medida que a entrada cresce. Uma tabela hash oferece tempo de busca médio O(1), enquanto uma busca binária em vetor ordenado requer tempo O(log n). Árvores binárias balanceadas mantêm a altura logarítmica para inserções eficientes.',
    },
    {
      'name': '⚖️ Direito & Legislação',
      'topic': 'Direito',
      'title': 'Concurso: Princípios Constitucionais',
      'sample':
          'A Constituição Federal consagra os direitos e garantias fundamentais como cláusulas pétreas que não podem ser abolidas por emendas. O princípio da legalidade estabelece que ninguém será obrigado a fazer ou deixar de fazer algo senão em virtude de lei. O devido processo legal e o contraditório asseguram julgamentos justos.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final study = context.read<StudyQuizProvider>();
        if (study.isCooldownActive(auth.currentUser)) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _topicController.dispose();
    _shareCodeController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _titleController.text = preset['title']!;
      _contentController.text = preset['sample']!;
      _topicController.text = preset['topic']!;
    });
  }


  Future<void> _pickManualFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            _myManuals.add({
              'bytes': file.bytes,
              'path': file.path,
              'name': file.name,
              'size': file.size,
            });
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📄 ${result.files.length} manuais adicionados!'),
              backgroundColor: _emerald,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeManual(int index) {
    setState(() {
      _myManuals.removeAt(index);
    });
  }


  Future<void> _handleGenerate() async {
    final auth = context.read<AuthProvider>();
    final study = context.read<StudyQuizProvider>();

    if ((auth.currentUser?.crystals ?? 0) < StudyQuizProvider.generationCostCrystals &&
        (auth.currentUser?.coins ?? 0) < 50) {
      _showNotEnoughCrystalsDialog();
      return;
    }

    final title = _titleController.text.trim();
    final topic = _topicController.text.trim();

    CustomStudyQuiz? generatedQuiz;

    // Modo Tema / Texto
    final content = _contentController.text.trim();
    
    if (content.isEmpty && topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor digita um tema de estudo ou cola o texto da matéria.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    if (content.length > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, cola um texto menor (máx. 4000 caracteres) para poupar os teus créditos.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    generatedQuiz = await study.generateQuiz(
      title: title.isEmpty ? (topic.isNotEmpty ? 'Quiz: $topic' : 'Quiz de Estudo') : title,
      content: content.isNotEmpty ? content : 'Estudo focado no tema: $topic',
      questionCount: _selectedQuestionCount,
      difficulty: _selectedDifficulty,
      topic: topic.isNotEmpty ? topic : 'Geral',
      authProvider: auth,
    );

    if (generatedQuiz != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _emerald,
          content: Text('🎉 Quiz "${generatedQuiz.title}" gerado com ${generatedQuiz.questionCount} perguntas!'),
        ),
      );

      _tabController.animateTo(1);
    } else if (study.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(study.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleImportShared() async {
    final code = _shareCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digita o código do quiz (ex: STUDY-12345).'),
          backgroundColor: Colors.amberAccent,
        ),
      );
      return;
    }

    final study = context.read<StudyQuizProvider>();
    final quiz = await study.importSharedQuiz(code);

    if (quiz != null && mounted) {
      _shareCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _emerald,
          content: Text('✅ Quiz "${quiz.title}" importado com sucesso!'),
        ),
      );
      _tabController.animateTo(1);
    } else if (study.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(study.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showNotEnoughCrystalsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🔮 ', style: TextStyle(fontSize: 22)),
            Text('Cristais Insuficientes', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Para gerar quizzes inteligentes com a IA precisas de 5 Cristais Mágicos 🔮.\nPodes obter cristais ou assinar VIP na loja do jogo!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(color: Colors.indigoAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
            },
            child: const Text('Ir à Loja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showNotEnoughEnergyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚡ ', style: TextStyle(fontSize: 22)),
            Text('Energia Insuficiente', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Precisas de pelo menos 10 ⚡ de energia para jogar um quiz de estudo.\nAguarde a recarga natural de energia ou visite a loja!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(color: Colors.indigoAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _playQuiz(CustomStudyQuiz quiz) async {
    final auth = context.read<AuthProvider>();
    final study = context.read<StudyQuizProvider>();
    final user = auth.currentUser;

    if (user != null && user.energy < 10) {
      _showNotEnoughEnergyDialog();
      return;
    }

    // Consome 10 de energia para iniciar a sessão de estudo
    await study.consumeEnergy(auth);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudyQuizGameScreen(quiz: quiz),
        ),
      );
    }
  }

  Widget _buildQuotaAndCooldownCard(UserModel? user, StudyQuizProvider study, AuthProvider auth) {
    final isVip = user?.isVip ?? false;
    final maxQuizzes = study.getMaxDailyQuizzes(user);
    final usedQuizzes = study.getDailyQuizzesUsed(user);
    final isCooldown = study.isCooldownActive(user);
    final cooldownText = study.getFormattedCooldown(user);
    final hasReachedLimit = study.hasReachedDailyLimit(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVip
              ? const Color(0xFFFFD700).withValues(alpha: 0.5)
              : isCooldown
                  ? Colors.amber.withValues(alpha: 0.5)
                  : Colors.indigo.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      isVip ? '👑 VIP Ilimitado' : '⭐ Conta Padrão',
                      style: TextStyle(
                        color: isVip ? const Color(0xFFFFD700) : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (!isVip) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Ser VIP 👑',
                              style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Quizzes hoje: $usedQuizzes / $maxQuizzes',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: maxQuizzes > 0 ? (usedQuizzes / maxQuizzes).clamp(0.0, 1.0) : 0.0,
              minHeight: 6,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasReachedLimit ? Colors.redAccent : (isVip ? const Color(0xFFFFD700) : Colors.indigoAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status de Cooldown ou Limite
          if (hasReachedLimit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Teto diário de segurança atingido ($maxQuizzes/$maxQuizzes). Volta amanhã às 00:00!',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else if (isCooldown)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: LoadingLogo(size: 60),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⏳ Cooldown de segurança ativo: Próximo quiz em $cooldownText min.',
                      style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Text(
                  isVip ? 'Geração rápida disponível (0 🔮) • Cooldown: 3m' : 'Geração rápida disponível (5 🔮) • Cooldown: 6m',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyQuizProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.indigoAccent, size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Modo Estudo Inteligente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CrystalBalanceChip(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigoAccent,
          indicatorWeight: 3,
          labelColor: Colors.indigoAccent,
          unselectedLabelColor: Colors.grey.shade400,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.psychology_rounded), text: 'Criar com IA'),
            Tab(icon: Icon(Icons.folder_special_rounded), text: 'Meus Quizzes'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Planos'),
            Tab(icon: Icon(Icons.menu_book), text: 'Manuais'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildCreateTab(),
              _buildMyQuizzesTab(studyProvider),
              const StudyPlansListScreen(),
              _buildMyManualsTab(),
            ],
          ),
          if (studyProvider.isGenerating) _buildGeneratingOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABA 1: CRIAR COM IA (PDF OU TEMA/TEXTO)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCreateTab() {
    final auth = context.watch<AuthProvider>();
    final study = context.watch<StudyQuizProvider>();
    final user = auth.currentUser;
    final isVip = user?.isVip ?? false;
    final isCooldown = study.isCooldownActive(user);
    final hasReachedLimit = study.hasReachedDailyLimit(user);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Quotas Diárias e Cooldown
          _buildQuotaAndCooldownCard(user, study, auth),

          const SizedBox(height: 16),

          // Banner Explicativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.indigoAccent, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aprende mais rápido com o Tutor IA',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Carrega um PDF ou escolhe um tema. A IA cria o teste, flashcards 3D e explicações didáticas.',
                        style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Conteúdo de Entrada (Tema/Texto)
          _buildTextTopicSection(),

          const SizedBox(height: 20),

          // Configurações do Quiz: Dificuldade e Quantidade
          _buildQuizSettingsSection(),

          const SizedBox(height: 24),

          // Botão Gerar com IA com proteção de cooldown e limite
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (isCooldown || hasReachedLimit) ? _handleGenerate : _handleGenerate,
              icon: Icon(
                hasReachedLimit
                    ? Icons.block_rounded
                    : isCooldown
                        ? Icons.timer_rounded
                        : Icons.auto_awesome_rounded,
                color: Colors.white,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasReachedLimit
                      ? 'Teto Diário Atingido (Volta Amanhã)'
                      : isCooldown
                          ? 'Aguarde Cooldown (${study.getFormattedCooldown(user)})'
                          : isVip
                              ? 'Gerar Quiz com IA (Grátis 👑)'
                              : 'Gerar Quiz com IA (5 🔮)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasReachedLimit
                    ? Colors.red.shade800
                    : isCooldown
                        ? Colors.amber.shade800
                        : const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }



  Widget _buildTextTopicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modelos Prontos de Estudo (1 Clique)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: studyPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = studyPresets[index];
              return ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3)),
                label: Text(p['name']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () => _applyPreset(p),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _topicController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Tema ou Matéria',
            labelStyle: TextStyle(color: Colors.grey.shade400),
            hintText: 'Ex: Fisiologia Humana, Mitologia Grega...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Texto / Anotações (Opcional)',
            labelStyle: TextStyle(color: Colors.grey.shade400),
            hintText: 'Cole apontamentos de aula ou resumos para a IA focar neles...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Número de Questões',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '15-30 Qs recomendadas 🎯',
                style: TextStyle(color: Colors.indigoAccent.shade100, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [10, 15, 20, 25, 30].map((count) {
              final isSel = _selectedQuestionCount == count;
              final isRec = count == 15 || count == 20 || count == 30;
              return ChoiceChip(
                label: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSel ? Colors.white : Colors.grey.shade400,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSel,
                selectedColor: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFF0F172A),
                side: BorderSide(
                  color: isSel
                      ? Colors.indigoAccent
                      : isRec
                          ? Colors.indigo.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2),
                ),
                onSelected: (_) => setState(() => _selectedQuestionCount = count),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nível de Dificuldade',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['FÁCIL', 'MÉDIO', 'DIFÍCIL', 'CONCURSO'].map((diff) {
              final isSel = _selectedDifficulty == diff;
              return ChoiceChip(
                label: Text(diff, style: const TextStyle(fontSize: 11)),
                selected: isSel,
                selectedColor: Colors.indigoAccent,
                backgroundColor: const Color(0xFF0F172A),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : Colors.grey.shade400,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _selectedDifficulty = diff),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABA 2: MEUS QUIZZES & FLASHCARDS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMyQuizzesTab(StudyQuizProvider provider) {
    if (provider.isLoading) {
      return const Center(child: LoadingLogo(size: 60));
    }

    if (provider.quizzes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImportSection(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum quiz de estudo gerado',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cria o teu primeiro quiz com IA na aba "Criar com IA" usando PDF ou qualquer matéria!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.quizzes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildImportSection();
        }

        final quiz = provider.quizzes[index - 1];
        final isPdf = quiz.sourceType == 'PDF';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPdf ? Colors.red.withValues(alpha: 0.15) : Colors.indigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.auto_awesome_rounded,
                      color: isPdf ? Colors.redAccent : Colors.indigoAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quiz.questionCount} Questões • ${quiz.flashcards.length} Flashcards',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (quiz.shareCode != null)
                    IconButton(
                      tooltip: 'Partilhar Quiz de Estudo',
                      icon: const Icon(Icons.share_rounded, color: Colors.amberAccent, size: 20),
                      onPressed: () => _showShareModal(context, quiz),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                    onPressed: () => provider.deleteQuiz(quiz.id),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Botão Flashcards 3D
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudyFlashcardsScreen(quiz: quiz),
                          ),
                        );
                      },
                      icon: const Icon(Icons.style_rounded, size: 16, color: Colors.indigoAccent),
                      label: const Text('Flashcards', style: TextStyle(color: Colors.indigoAccent, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.indigoAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botão Jogar Quiz
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _playQuiz(quiz),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                      label: const Text('Jogar Quiz', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABA 3: IMPORTAR CÓDIGO (STUDY-XXXXX)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildImportSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_rounded, color: Colors.indigoAccent, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Importar Quiz de Colega',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _shareCodeController,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Cód. STUDY-12345',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleImportShared,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Carregar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: LoadingLogo(size: 60),
              ),
              const SizedBox(height: 20),
              const Text(
                'O Tutor IA está a analisar o conteúdo...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'A extrair conceitos, estruturar perguntas, gerar distratores e flashcards didáticos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareModal(BuildContext context, CustomStudyQuiz quiz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Partilhar Quiz de Estudo',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                quiz.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código de Acesso:',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quiz.shareCode ?? 'N/A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: quiz.shareCode ?? ''));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: _emerald,
                            content: Text('📋 Código ${quiz.shareCode} copiado! Envia para o teu amigo.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copiar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Teus amigos podem colar este código na aba "Importar Quiz" para estudar a mesma matéria!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABA 4: MEUS MANUAIS (LEITOR PDF)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMyManualsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Os Meus Manuais',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _pickManualFile,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Carrega os teus manuais PDF, lê e gera quizzes diretamente a partir do texto que selecionares.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _myManuals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_books_rounded, size: 64, color: Colors.indigoAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Ainda não tens manuais.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickManualFile,
                          icon: const Icon(Icons.upload_file, color: Colors.white),
                          label: const Text('Carregar Primeiro Manual', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _myManuals.length,
                    itemBuilder: (context, index) {
                      final manual = _myManuals[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.15),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.menu_book_rounded, size: 48, color: Colors.indigoAccent),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () => _removeManual(index),
                                      tooltip: 'Remover',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    manual['name'] ?? 'Documento',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${((manual['size'] as int) / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => StudyPdfScreen(
                                              pdfBytes: manual['bytes'] as Uint8List?,
                                              pdfPath: manual['path'] as String?,
                                              fileName: manual['name'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _emerald,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text('Abrir', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
