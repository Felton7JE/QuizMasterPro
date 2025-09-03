# QuizMaster Pro - Integração com Backend

## Estrutura Criada

### Models (lib/models/)
- **user_model.dart**: Modelo para usuários com CreateUserRequest
- **room_model.dart**: Modelos para salas, jogadores e enums (GameMode, Difficulty, TeamColor, RoomStatus)
- **game_model.dart**: Modelos para jogos, perguntas, respostas e leaderboard

### Services (lib/services/)
- **api_service.dart**: Serviço base para comunicação HTTP com tratamento de erros
- **auth_service.dart**: Serviços de autenticação (login, cadastro, stats)
- **room_service.dart**: Serviços de sala (criar, entrar, configurar equipes)
- **game_service.dart**: Serviços de jogo (perguntas, respostas, leaderboard)

### Providers (lib/providers/)
- **auth_provider.dart**: Gerenciamento de estado de autenticação
- **room_provider.dart**: Gerenciamento de estado das salas
- **game_provider.dart**: Gerenciamento de estado dos jogos

### Utils (lib/utils/)
- **snackbar_utils.dart**: Utilitários para exibir mensagens
- **validation_utils.dart**: Validações de formulários
- **format_utils.dart**: Formatação de dados (tempo, pontuação, etc.)

### Config (lib/config/)
- **api_config.dart**: Configurações centralizadas da API

### Screens (lib/screens/)
- **login_screen.dart**: Tela de login/cadastro com integração
- **create_room_simple_screen.dart**: Tela simplificada para criar sala

## Como Usar

### 1. Configuração Inicial
O main.dart já foi configurado com todos os providers necessários.

### 2. Autenticação
```dart
// Login
final authProvider = context.read<AuthProvider>();
await authProvider.login(username);

// Cadastro
await authProvider.createUser(
  username: username,
  email: email,
  fullName: fullName,
);
```

### 3. Criação de Sala
```dart
final roomProvider = context.read<RoomProvider>();
await roomProvider.createRoom(
  roomName: roomName,
  gameMode: GameMode.TEAM,
  difficulty: Difficulty.MEDIUM,
  // ... outras configurações
  hostId: currentUser.id,
);
```

### 4. Jogo
```dart
final gameProvider = context.read<GameProvider>();

// Carregar perguntas
await gameProvider.loadGameQuestions(gameId, userId);

// Submeter resposta
await gameProvider.submitAnswer(
  gameId: gameId,
  userId: userId,
  questionId: questionId,
  selectedAnswer: answer,
  timeSpent: timeMs,
);

// Leaderboard em tempo real
await gameProvider.loadLiveLeaderboard(gameId);
```

## Endpoints Integrados

### Usuários
- POST /api/users (cadastro)
- POST /api/auth/login (login)
- GET /api/users/{id}/stats (estatísticas)
- GET /api/users/ranking (ranking global)

### Salas
- POST /api/rooms (criar sala)
- GET /api/rooms/{code} (detalhes da sala)
- POST /api/rooms/{code}/join (entrar na sala)
- POST /api/rooms/{code}/players/{id}/team (definir equipe)
- POST /api/rooms/{code}/players/{id}/ready (marcar como pronto)
- POST /api/rooms/{code}/start (iniciar jogo)

### Jogos
- GET /api/games/{id}/questions (obter perguntas)
- POST /api/games/{id}/answers (submeter resposta)
- GET /api/games/{id}/leaderboard/live (leaderboard em tempo real)
- GET /api/games/{id}/results (resultados finais)
- POST /api/games/{id}/finish (finalizar jogo)

## Próximos Passos

1. **Integrar nas telas existentes**: Substituir a lógica das telas atuais pelos providers
2. **WebSocket**: Implementar comunicação em tempo real para updates de sala/jogo
3. **Cache/Offline**: Adicionar cache local para melhor experiência
4. **Testes**: Criar testes unitários para services e providers

## Como Testar

### 🧪 Teste Rápido
1. **Inicie o backend** em `http://localhost:8080`
2. **Execute o app**: `flutter run`
3. **Navegue para**: `/test` (TestScreen)
4. **Teste o fluxo completo**: cadastro → login → criar sala

### 🔬 Testes Automatizados
```bash
# Windows
test_integration.bat

# Linux/Mac
chmod +x test_integration.sh
./test_integration.sh

# Ou diretamente
flutter test test/integration_test.dart
```

### 📱 Telas Disponíveis
- **`/test`**: Tela completa de teste da integração
- **`/login`**: Login/cadastro com validações
- **`/create-room-simple`**: Criação de sala simplificada

Veja o arquivo `TESTING_GUIDE.md` para instruções detalhadas de teste.

## Exemplo de Uso Completo

Veja `create_room_simple_screen.dart` e `login_screen.dart` para exemplos completos de integração.
