import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:quizmaster_pro/services/api_service.dart';

void main() {
  group('ApiService - Tratamento de Erros de Internet e Backend', () {
    test('Deve lançar Exception ao receber um Erro 500 (Internal Server Error)', () async {
      // Cria um MockClient que SEMPRE responde com Erro 500
      final mockClient = MockClient((request) async {
        return http.Response('Server is burning!', 500);
      });

      // Injeta o cliente falso no ApiService
      final apiService = ApiService(client: mockClient);

      // Espera que o método get() atire uma Exception e não quebre o app silenciosamente
      expect(
        () async => await apiService.get('/api/test-endpoint'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Erro interno do servidor'))),
      );
    });

    test('Deve retornar Map quando a API responde com Sucesso 200', () async {
      // Cria um MockClient que responde com sucesso
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Success!', 'data': [1, 2, 3]}), 200);
      });

      final apiService = ApiService(client: mockClient);
      
      final result = await apiService.get('/api/test-endpoint');

      expect(result['message'], 'Success!');
      expect(result['data'], isA<List>());
      expect(result['data'].length, 3);
    });
    
    test('Deve lançar Exception ao receber um Erro 404 (Not Found)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);

      expect(
        () async => await apiService.get('/api/test-endpoint'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Recurso não encontrado'))),
      );
    });
  });
}
