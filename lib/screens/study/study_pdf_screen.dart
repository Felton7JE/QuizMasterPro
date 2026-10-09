import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import '../../services/study_quiz_service.dart';
import '../../widgets/core/loading_logo.dart';
import './study_quiz_game_screen.dart';

class StudyPdfScreen extends StatefulWidget {
  final Uint8List? pdfBytes;
  final String? pdfPath;
  final String fileName;

  const StudyPdfScreen({
    super.key,
    this.pdfBytes,
    this.pdfPath,
    required this.fileName,
  });

  @override
  State<StudyPdfScreen> createState() => _StudyPdfScreenState();
}

class _StudyPdfScreenState extends State<StudyPdfScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  OverlayEntry? _overlayEntry;
  String? _selectedText;
  bool _isLoading = false;

  void _showSelectionMenu(PdfTextSelectionChangedDetails details) {
    if (details.selectedText == null || details.selectedText!.isEmpty) {
      _hideSelectionMenu();
      return;
    }
    _selectedText = details.selectedText;

    _hideSelectionMenu(); // Esconde o menu existente, se houver
    
    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Ajusta a posição para não sair do ecrã
        double top = details.globalSelectedRegion!.top - 60;
        if (top < kToolbarHeight + 20) top = details.globalSelectedRegion!.bottom + 10;
        
        return Positioned(
          top: top,
          left: details.globalSelectedRegion!.left,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1E293B),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.quiz, color: Colors.blueAccent, size: 20),
                    label: const Text('Gerar Quiz', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      _hideSelectionMenu();
                      _pdfViewerController.clearSelection();
                      _generateQuizFromSelection();
                    },
                  ),
                  Container(width: 1, height: 20, color: Colors.grey[700]),
                  TextButton.icon(
                    icon: const Icon(Icons.menu_book, color: Colors.greenAccent, size: 20),
                    label: const Text('Resumir', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      _hideSelectionMenu();
                      _pdfViewerController.clearSelection();
                      _generateSummaryFromSelection();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  void _hideSelectionMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  Future<void> _generateQuizFromSelection() async {
    if (_selectedText == null) return;
    
    if (_selectedText!.length > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleciona um texto menor (máx. 4000 caracteres) para não gastar muitos créditos.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final studyService = Provider.of<StudyQuizService>(context, listen: false);
      final quiz = await studyService.generateQuiz(
        title: 'Quiz de Estudo (Excerto)',
        content: _selectedText!,
        questionCount: 5,
        difficulty: 'MEDIO',
        sourceFileName: widget.fileName,
        sourceType: 'PDF_SELECTION',
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudyQuizGameScreen(quiz: quiz),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar quiz: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _generateSummaryFromSelection() async {
    // Aqui podíamos ter um ecrã só de leitura do resumo,
    // mas por agora chamamos a mesma API de geração e focamos no Flashcards/Resumo.
    if (_selectedText == null) return;
    
    if (_selectedText!.length > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleciona um texto menor (máx. 4000 caracteres) para não gastar muitos créditos.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final studyService = Provider.of<StudyQuizService>(context, listen: false);
      final quiz = await studyService.generateQuiz(
        title: 'Resumo (Excerto)',
        content: _selectedText!,
        questionCount: 3, // Pede poucas perguntas, foco nos flashcards e resumo
        difficulty: 'FACIL',
        sourceFileName: widget.fileName,
        sourceType: 'PDF_SELECTION',
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudyQuizGameScreen(quiz: quiz),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar resumo: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,

      ),
      body: Stack(
        children: [
          if (widget.pdfBytes != null)
            SfPdfViewer.memory(
              widget.pdfBytes!,
              controller: _pdfViewerController,
              onTextSelectionChanged: _showSelectionMenu,
              canShowScrollHead: false,
            )
          else if (widget.pdfPath != null)
            SfPdfViewer.file(
              File(widget.pdfPath!),
              controller: _pdfViewerController,
              onTextSelectionChanged: _showSelectionMenu,
              canShowScrollHead: false,
            )
          else
            const Center(child: Text('Nenhum PDF selecionado.')),
             
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingLogo(size: 80),
                    SizedBox(height: 24),
                    Text(
                      'A IA está a ler e a preparar o conteúdo...\nIsto pode demorar alguns segundos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
