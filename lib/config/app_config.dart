
class AppConfig {
  // Obter via --dart-define ou fallback inteligente
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _envWsUrl = String.fromEnvironment('WS_URL');

  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    // Fallback para Azure Cloud (Produção/Teste)
    return 'https://quizmasterpro-fxc2bweqa3eehkhr.austriaeast-01.azurewebsites.net';
  }

  static String get wsUrl {
    if (_envWsUrl.isNotEmpty) {
      return _envWsUrl;
    }
    // Se baseUrl começar com https://, usar wss://
    final base = baseUrl;
    if (base.startsWith('https://')) {
      final hostAndPort = base.substring('https://'.length);
      return 'wss://$hostAndPort/ws/websocket';
    } else if (base.startsWith('http://')) {
      final hostAndPort = base.substring('http://'.length);
      return 'ws://$hostAndPort/ws/websocket';
    }
    return 'ws://localhost:8080/ws/websocket';
  }

  static const String appName = 'Meu Quiz +';
  static const String appVersion = '1.0.0';
}
