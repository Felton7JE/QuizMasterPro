class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
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
}
