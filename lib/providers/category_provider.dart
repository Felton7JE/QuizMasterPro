import 'package:flutter/foundation.dart';
import '../models/category_models.dart' as CategoryModels;
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;
  
  List<CategoryModels.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._categoryService);

  List<CategoryModels.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return; // Já carregadas

    _setLoading(true);
    try {
      print('DEBUG CategoryProvider: Carregando categorias...');
      _categories = await _categoryService.getAllCategories();
      _error = null;
      print('DEBUG CategoryProvider: ${_categories.length} categorias carregadas');
      
      // Debug: mostrar as categorias carregadas
      for (var cat in _categories) {
        print('DEBUG CategoryProvider: ID=${cat.id}, Name=${cat.name}, DisplayName=${cat.displayName}');
      }
    } catch (e) {
      print('ERROR CategoryProvider: Erro ao carregar categorias: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  CategoryModels.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  CategoryModels.Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (cat) => cat.name.toUpperCase() == name.toUpperCase()
      );
    } catch (e) {
      print('DEBUG CategoryProvider: Categoria não encontrada para name=$name');
      return null;
    }
  }

  // NOVO: Método para buscar por displayName também
  CategoryModels.Category? getCategoryByDisplayName(String displayName) {
    try {
      return _categories.firstWhere(
        (cat) => cat.displayName.toLowerCase() == displayName.toLowerCase()
      );
    } catch (e) {
      print('DEBUG CategoryProvider: Categoria não encontrada para displayName=$displayName');
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
