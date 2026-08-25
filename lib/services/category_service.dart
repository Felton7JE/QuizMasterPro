import 'package:flutter/foundation.dart';
import '../models/category_models.dart' as CategoryModels;
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService;

  CategoryService(this._apiService);

  Future<List<CategoryModels.Category>> getAllCategories() async {
    try {
      debugPrint('DEBUG CategoryService: Buscando todas as categorias...');
      final response = await _apiService.getList('/api/categories'); // MUDANÇA: usar getList
      
      debugPrint('DEBUG CategoryService: Response tipo: ${response.runtimeType}');
      debugPrint('DEBUG CategoryService: Lista com ${response.length} itens');
      
      // Processar cada item da lista
      final categories = <CategoryModels.Category>[];
      for (int i = 0; i < response.length; i++) {
        try {
          final categoryJson = response[i];
          debugPrint('DEBUG CategoryService: Processando item $i: $categoryJson');
          
          final category = CategoryModels.Category.fromJson(categoryJson as Map<String, dynamic>);
          categories.add(category);
          
          debugPrint('DEBUG CategoryService: Categoria $i processada: ${category.displayName}');
        } catch (e) {
          debugPrint('ERROR CategoryService: Erro ao processar categoria $i: $e');
          debugPrint('ERROR CategoryService: JSON da categoria: ${response[i]}');
          rethrow;
        }
      }
      
      debugPrint('DEBUG CategoryService: ${categories.length} categorias carregadas com sucesso');
      return categories;
    } catch (e, stackTrace) {
      debugPrint('ERROR CategoryService: Erro ao buscar categorias: $e');
      debugPrint('ERROR CategoryService: Stack trace: $stackTrace');
      rethrow;
    }
  }
}
