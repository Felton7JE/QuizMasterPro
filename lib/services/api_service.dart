import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  
  final http.Client _client = http.Client();

  // Headers padrão
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET request que retorna Map
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.get(uri, headers: _headers);
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  // GET request que retorna List (NOVO)
  Future<List<dynamic>> getList(String endpoint) async {
    try {
      print('🟡 DEBUG ApiService: GET LIST para $endpoint');
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🟡 DEBUG ApiService: URI completa: $uri');
      
      final response = await _client.get(uri, headers: _headers);
      
      print('🟡 DEBUG ApiService: Status Code: ${response.statusCode}');
      print('🟡 DEBUG ApiService: Response Body: ${response.body}');
      
      return _handleListResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(String endpoint, [Map<String, dynamic>? body]) async {
    print('🟡 DEBUG ApiService: POST para $endpoint');
    print('🟡 DEBUG ApiService: Body: $body');
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🟡 DEBUG ApiService: URI completa: $uri');
      
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      print('🟡 DEBUG ApiService: Status Code: ${response.statusCode}');
      print('🟡 DEBUG ApiService: Response Body: ${response.body}');
      
      return _handleResponse(response);
    } on SocketException {
      print('🔴 DEBUG ApiService: SocketException - Sem conexão com a internet');
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      print('🔴 DEBUG ApiService: HttpException - Erro de comunicação com o servidor');
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      print('🔴 DEBUG ApiService: Erro inesperado: $e');
      throw ApiException('Erro inesperado: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.delete(uri, headers: _headers);
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  // Handle response que retorna Map
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw ApiException('Resposta inválida do servidor');
        }
      }
      return {};
    } else {
      String errorMessage = 'Erro $statusCode';
      
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (e) {
        // Se não conseguir decodificar, usa a mensagem padrão
      }
      
      switch (statusCode) {
        case 400:
          throw ApiException('Dados inválidos: $errorMessage');
        case 401:
          throw ApiException('Não autorizado');
        case 403:
          throw ApiException('Acesso negado');
        case 404:
          throw ApiException('Recurso não encontrado');
        case 409:
          throw ApiException('Conflito: $errorMessage');
        case 500:
          throw ApiException('Erro interno do servidor');
        default:
          throw ApiException(errorMessage);
      }
    }
  }

  // Handle response que retorna List (NOVO)
  List<dynamic> _handleListResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            return decoded;
          } else {
            throw ApiException('Resposta não é uma lista');
          }
        } catch (e) {
          throw ApiException('Resposta inválida do servidor: $e');
        }
      }
      return [];
    } else {
      String errorMessage = 'Erro $statusCode';
      
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (e) {
        // Se não conseguir decodificar, usa a mensagem padrão
      }
      
      switch (statusCode) {
        case 400:
          throw ApiException('Dados inválidos: $errorMessage');
        case 401:
          throw ApiException('Não autorizado');
        case 403:
          throw ApiException('Acesso negado');
        case 404:
          throw ApiException('Recurso não encontrado');
        case 409:
          throw ApiException('Conflito: $errorMessage');
        case 500:
          throw ApiException('Erro interno do servidor');
        default:
          throw ApiException(errorMessage);
      }
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
