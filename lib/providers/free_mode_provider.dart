import 'package:flutter/material.dart';
import '../services/solo_service.dart';

class FreeModeProvider with ChangeNotifier {
  final SoloService _soloService;

  List<dynamic> _currentQuestions = [];
  List<int> _seenIds = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get currentQuestions => _currentQuestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FreeModeProvider(this._soloService);

  void resetSession() {
    _currentQuestions = [];
    _seenIds = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMoreQuestions({int limit = 10}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newQuestions = await _soloService.getFreeModeQuestions(_seenIds, limit);
      _currentQuestions.addAll(newQuestions);
      
      for (var q in newQuestions) {
        if (q['id'] != null) {
          _seenIds.add(q['id'] as int);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove question after answering to keep list short
  void popQuestion() {
    if (_currentQuestions.isNotEmpty) {
      _currentQuestions.removeAt(0);
      notifyListeners();
    }
  }
}
