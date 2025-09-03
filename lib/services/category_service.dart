import '../models/category_models.dart' as CategoryModels;
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService;

  CategoryService(this._apiService);

  Future<List<CategoryModels.Category>> getAllCategories() async {
    try {
      print('DEBUG CategoryService: Buscando todas as categorias...');
      final response = await _apiService.getList('/api/categories'); // MUDANÇA: usar getList
      
      print('DEBUG CategoryService: Response tipo: ${response.runtimeType}');
      print('DEBUG CategoryService: Lista com ${response.length} itens');
      
      // Processar cada item da lista
      final categories = <CategoryModels.Category>[];
      for (int i = 0; i < response.length; i++) {
        try {
          final categoryJson = response[i];
          print('DEBUG CategoryService: Processando item $i: $categoryJson');
          
          final category = CategoryModels.Category.fromJson(categoryJson as Map<String, dynamic>);
          categories.add(category);
          
          print('DEBUG CategoryService: Categoria $i processada: ${category.displayName}');
        } catch (e) {
          print('ERROR CategoryService: Erro ao processar categoria $i: $e');
          print('ERROR CategoryService: JSON da categoria: ${response[i]}');
          rethrow;
        }
      }
      
      print('DEBUG CategoryService: ${categories.length} categorias carregadas com sucesso');
      return categories;
    } catch (e, stackTrace) {
      print('ERROR CategoryService: Erro ao buscar categorias: $e');
      print('ERROR CategoryService: Stack trace: $stackTrace');
      rethrow;
    }
  }
}
