import 'app_config.dart';

class ApiConfig {
  static String get baseUrl => AppConfig.baseUrl;

  /// Constrói o URL completo de um asset estático servido pelo backend.
  /// Se o [value] já for um URL absoluto (começa com http/https), retorna-o tal como está.
  /// Se for um caminho relativo (ex: "images/avatars/ninja.png"), prefixar com [baseUrl].
  static String? resolveAssetUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    // Caminho relativo: servido pelo Spring Boot static resources
    return '$baseUrl/$value';
  }
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // VIP Selo da Temporada 1
  static String get vipSealUrl => '$baseUrl/assets/temporada1/selo_vip_temporada1.png';

  // Endpoints da API
  static const String usersEndpoint = '/api/users';
  static const String authEndpoint = '/api/auth';
  static const String roomsEndpoint = '/api/rooms';
  static const String gamesEndpoint = '/api/games';
  
  // Configurações do jogo
  static const int defaultQuestionTime = 25;
  static const int defaultQuestionCount = 10;
  static const int defaultMaxPlayers = 6;
  
  // Categorias disponíveis
  static const List<String> availableCategories = [
    'MATH',
    'SCIENCE',
    'GEOGRAPHY',
    'HISTORY',
    'PORTUGUESE',
    'ENGLISH',
    'MIXED',
  ];
  
  // Configurações de polling (para atualizações em tempo real)
  static const Duration roomPollingInterval = Duration(seconds: 2);
  static const Duration gamePollingInterval = Duration(seconds: 1);
  static const Duration leaderboardPollingInterval = Duration(seconds: 3);

  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
