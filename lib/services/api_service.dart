import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static String? token;
  
  
  static String? resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        final uri = Uri.parse(url);
        final baseUri = Uri.parse(baseUrl);
        if (uri.host == '10.0.2.2' || uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return uri.replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          ).toString();
        }
      } catch (_) {}
      return url;
    }
    final path = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$path';
  }
  
  final http.Client _client;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Headers padrão
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // GET request que retorna Map
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      // ignore: avoid_print
      debugPrint('🟡 DEBUG ApiService: GET para $endpoint');
      
      final uri = Uri.parse('$baseUrl$endpoint');
      
      // ignore: avoid_print
      debugPrint('🟡 DEBUG ApiService: URI completa: $uri');
      // ignore: avoid_print
      debugPrint('🟡 DEBUG ApiService: Headers: $_headers');
      debugPrint('🟡 DEBUG ApiService: Token presente? ${token != null}');
      
      final response = await _client.get(uri, headers: _headers);
      
      // ignore: avoid_print
      debugPrint('🟡 DEBUG ApiService: Status Code: ${response.statusCode}');
      // ignore: avoid_print
      debugPrint('🟡 DEBUG ApiService: Response Body: ${response.body}');
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      // ignore: avoid_print
      debugPrint('❌ ERRO ApiService: SocketException - $e');
      throw ApiException('Sem conexão com a internet');
    } on HttpException catch (e) {
      // ignore: avoid_print
      debugPrint('❌ ERRO ApiService: HttpException - $e');
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      // ignore: avoid_print
      debugPrint('❌ ERRO ApiService: Erro inesperado - $e');
      throw ApiException('Erro inesperado: $e');
    }
  }

  // GET request que retorna a string pura
  Future<String> getRaw(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw ApiException('Erro ${response.statusCode}');
    } catch (e) {
      throw ApiException('Erro na requisição: $e');
    }
  }

  // GET request que retorna List (NOVO)
  Future<List<dynamic>> getList(String endpoint) async {
    try {
      debugPrint('🟡 DEBUG ApiService: GET LIST para $endpoint');
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('🟡 DEBUG ApiService: URI completa: $uri');
      
      final response = await _client.get(uri, headers: _headers);
      
      debugPrint('🟡 DEBUG ApiService: Status Code: ${response.statusCode}');
      debugPrint('🟡 DEBUG ApiService: Response Body: ${response.body}');
      
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
    debugPrint('🟡 DEBUG ApiService: POST para $endpoint');
    debugPrint('🟡 DEBUG ApiService: Body: $body');
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('🟡 DEBUG ApiService: URI completa: $uri');
      
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      debugPrint('🟡 DEBUG ApiService: Headers enviados no POST: $_headers');
      debugPrint('🟡 DEBUG ApiService: Status Code: ${response.statusCode}');
      debugPrint('🟡 DEBUG ApiService: Response Body: ${response.body}');
      
      return _handleResponse(response);
    } on SocketException {
      debugPrint('🔴 DEBUG ApiService: SocketException - Sem conexão com a internet');
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      debugPrint('🔴 DEBUG ApiService: HttpException - Erro de comunicação com o servidor');
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      debugPrint('🔴 DEBUG ApiService: Erro inesperado: $e');
      throw ApiException('Erro inesperado: $e');
    }
  }

  // POST request que retorna List e aceita List como body
  Future<List<dynamic>> postList(String endpoint, [dynamic body]) async {
    debugPrint('🟡 DEBUG ApiService: POST LIST para $endpoint');
    debugPrint('🟡 DEBUG ApiService: Body: $body');
    
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('🟡 DEBUG ApiService: URI completa: $uri');
      
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      debugPrint('🟡 DEBUG ApiService: Status Code: ${response.statusCode}');
      debugPrint('🟡 DEBUG ApiService: Response Body: ${response.body}');
      
      return _handleListResponse(response);
    } on SocketException {
      debugPrint('🔴 DEBUG ApiService: SocketException - Sem conexão com a internet');
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      debugPrint('🔴 DEBUG ApiService: HttpException - Erro de comunicação com o servidor');
      throw ApiException('Erro de comunicação com o servidor');
    } catch (e) {
      debugPrint('🔴 DEBUG ApiService: Erro inesperado: $e');
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

  Future<void> reportBug(String description, String? userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/bugs');
      final body = {'description': description, 'userId': userId};
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode >= 400) {
        throw ApiException('Falha ao reportar bug: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Erro ao reportar bug: $e');
    }
  }



  // Handle response que retorna Map
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    // ignore: avoid_print
    debugPrint('🟡 DEBUG ApiService: _handleResponse - Status: $statusCode');
    // ignore: avoid_print
    debugPrint('🟡 DEBUG ApiService: _handleResponse - Body length: ${response.body.length}');
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          // ignore: avoid_print
          debugPrint('🟡 DEBUG ApiService: JSON decodificado com sucesso');
          // ignore: avoid_print
          debugPrint('🟡 DEBUG ApiService: Tipo da resposta: ${decoded.runtimeType}');
          if (decoded is Map) {
            // ignore: avoid_print
            debugPrint('🟡 DEBUG ApiService: Chaves da resposta: ${decoded.keys.toList()}');
          }
          return decoded;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('🟡 DEBUG ApiService: Falha ao decodificar JSON, retornando texto puro');
          return {'message': response.body};
        }
      }
      // ignore: avoid_print
      debugPrint('🟡 DEBUG ApiService: Resposta vazia, retornando {}');
      return {};
    } else {
      // ignore: avoid_print
      debugPrint('❌ ERRO ApiService: Status code de erro: $statusCode');
      
      String errorMessage = 'Erro $statusCode';
      
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
        // ignore: avoid_print
        debugPrint('❌ ERRO ApiService: Mensagem de erro: $errorMessage');
      } catch (e) {
        // Se não conseguir decodificar, usa a mensagem padrão
        // ignore: avoid_print
        debugPrint('❌ ERRO ApiService: Não foi possível decodificar erro: $e');
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
          throw ApiException(errorMessage != 'Erro 500' ? errorMessage : 'Erro interno do servidor');
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
          throw ApiException(errorMessage != 'Erro 500' ? errorMessage : 'Erro interno do servidor');
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
