# Como Testar a Integração com Backend

## 📋 Pré-requisitos

### 1. Backend em Execução
Certifique-se de que seu backend esteja rodando em `http://localhost:8080`

### 2. Dependências Instaladas
```bash
flutter pub get
```

## 🧪 Tipos de Teste

### 1. Teste Manual com App
Execute o app e teste o fluxo completo:

```bash
flutter run
```

#### Fluxo de Teste Completo:

1. **Login/Cadastro**
   - Abra a tela de login (`/login`)
   - Teste cadastro com dados válidos
   - Teste login com usuário existente
   - Verifique validações de formulário

2. **Criação de Sala**
   - Use a tela simplificada: `CreateRoomSimpleScreen`
   - Teste diferentes configurações
   - Verifique se a sala é criada no backend

3. **Entrada em Sala**
   - Teste entrar com código de sala
   - Verifique se jogadores aparecem na sala

### 2. Teste da API Diretamente

Crie um arquivo de teste para os services:

```dart
// test/services_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quizmaster_pro/services/api_service.dart';
import 'package:quizmaster_pro/services/auth_service.dart';
import 'package:quizmaster_pro/models/user_model.dart';

void main() {
  group('API Integration Tests', () {
    late ApiService apiService;
    late AuthService authService;

    setUp(() {
      apiService = ApiService();
      authService = AuthService(apiService);
    });

    tearDown(() {
      apiService.dispose();
    });

    test('Deve criar usuário com sucesso', () async {
      final request = CreateUserRequest(
        username: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      final user = await authService.createUser(request);
      
      expect(user.username, equals(request.username));
      expect(user.email, equals(request.email));
      expect(user.fullName, equals(request.fullName));
    });

    test('Deve fazer login com sucesso', () async {
      // Primeiro criar um usuário
      final request = CreateUserRequest(
        username: 'login_test_${DateTime.now().millisecondsSinceEpoch}',
        email: 'login@example.com',
        fullName: 'Login Test',
      );

      final createdUser = await authService.createUser(request);
      
      // Depois fazer login
      final loginUser = await authService.login(createdUser.username);
      
      expect(loginUser.id, equals(createdUser.id));
      expect(loginUser.username, equals(createdUser.username));
    });
  });
}
```

### 3. Teste com Postman/Insomnia

Use sua collection Postman para testar os endpoints diretamente:

1. **Teste a sequência completa:**
   - Criar usuários
   - Fazer login
   - Criar sala
   - Entrar na sala
   - Iniciar jogo

### 4. Widget Tests

Teste os widgets que usam os providers:

```dart
// test/widget_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quizmaster_pro/providers/auth_provider.dart';
import 'package:quizmaster_pro/services/auth_service.dart';
import 'package:quizmaster_pro/services/api_service.dart';
import 'package:quizmaster_pro/screens/login_screen.dart';

void main() {
  group('Widget Integration Tests', () {
    testWidgets('Login screen deve exibir formulários', (tester) async {
      final apiService = ApiService();
      final authService = AuthService(apiService);
      final authProvider = AuthProvider(authService);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Verificar se os campos estão presentes
      expect(find.byType(TextFormField), findsNWidgets(2)); // Username + Email quando em modo cadastro
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Não tem uma conta? Cadastre-se'), findsOneWidget);
    });
  });
}
```

## 🔧 Configuração para Testes

### 1. Mock do Backend (Opcional)

Para testes unitários, você pode mockar as respostas:

```dart
// test/mocks/mock_api_service.dart
import 'package:quizmaster_pro/services/api_service.dart';

class MockApiService extends ApiService {
  @override
  Future<Map<String, dynamic>> post(String endpoint, [Map<String, dynamic>? body]) async {
    // Mock responses baseado no endpoint
    if (endpoint == '/api/users') {
      return {
        'id': 'mock-user-id',
        'username': body?['username'] ?? 'mock-user',
        'email': body?['email'] ?? 'mock@example.com',
        'fullName': body?['fullName'] ?? 'Mock User',
        'createdAt': DateTime.now().toIso8601String(),
      };
    }
    
    if (endpoint.startsWith('/api/auth/login')) {
      return {
        'id': 'mock-user-id',
        'username': 'mock-user',
        'email': 'mock@example.com',
        'fullName': 'Mock User',
      };
    }
    
    return super.post(endpoint, body);
  }
}
```

### 2. Configuração de Teste no main_test.dart

```dart
// test/main_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quizmaster_pro/main.dart';
import 'mocks/mock_api_service.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('App deve inicializar com providers', (tester) async {
      await tester.pumpWidget(const QuizMasterApp());
      
      // Verificar se a tela inicial carrega
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
```

## 🚀 Scripts de Teste Automatizado

Adicione no `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

### Executar Testes

```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/services_test.dart

# Com coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📝 Checklist de Teste

### ✅ Autenticação
- [ ] Cadastro com dados válidos
- [ ] Cadastro com dados inválidos (validações)
- [ ] Login com usuário existente
- [ ] Login com usuário inexistente
- [ ] Logout

### ✅ Salas
- [ ] Criar sala com configurações válidas
- [ ] Criar sala com dados inválidos
- [ ] Entrar em sala existente
- [ ] Entrar em sala inexistente
- [ ] Configurar equipes
- [ ] Marcar como pronto
- [ ] Iniciar jogo (apenas host)

### ✅ Jogo
- [ ] Carregar perguntas
- [ ] Submeter respostas
- [ ] Ver leaderboard em tempo real
- [ ] Finalizar jogo
- [ ] Ver resultados finais

### ✅ Estados e Erros
- [ ] Loading states funcionando
- [ ] Mensagens de erro apropriadas
- [ ] Navegação entre telas
- [ ] Persistência de estado

## 🐛 Debug e Logs

Para debugar problemas:

1. **Ativar logs detalhados:**
```dart
// No api_service.dart
print('Request: $endpoint');
print('Body: $body');
print('Response: ${response.body}');
```

2. **Verificar conexão com backend:**
```bash
curl http://localhost:8080/api/users
```

3. **Monitor de rede:**
Use o Flutter Inspector para monitorar requests HTTP.

## ⚡ Teste Rápido

Para um teste rápido da integração:

1. Execute o backend
2. Execute `flutter run`
3. Vá para `CreateRoomSimpleScreen`
4. Preencha os dados e crie uma sala
5. Verifique se aparece no backend/banco de dados

Se funcionar, a integração básica está OK!
