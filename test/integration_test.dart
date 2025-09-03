import 'package:flutter_test/flutter_test.dart';
import 'package:quizmaster_pro/services/api_service.dart';
import 'package:quizmaster_pro/services/auth_service.dart';
import 'package:quizmaster_pro/services/room_service.dart';
import 'package:quizmaster_pro/models/user_model.dart';
import 'package:quizmaster_pro/models/room_model.dart';

void main() {
  group('Backend Integration Tests', () {
    late ApiService apiService;
    late AuthService authService;
    late RoomService roomService;
    late String testUserId;

    setUpAll(() {
      apiService = ApiService();
      authService = AuthService(apiService);
      roomService = RoomService(apiService);
    });

    tearDownAll(() {
      apiService.dispose();
    });

    test('1. Deve criar usuário com sucesso', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final request = CreateUserRequest(
        username: 'test_user_$timestamp',
        email: 'test$timestamp@example.com',
        fullName: 'Test User $timestamp',
      );

      final user = await authService.createUser(request);
      testUserId = user.id;
      
      expect(user.username, equals(request.username));
      expect(user.email, equals(request.email));
      expect(user.fullName, equals(request.fullName));
      expect(user.id, isNotEmpty);
      
      print('✅ Usuário criado: ${user.id}');
    });

    test('2. Deve fazer login com sucesso', () async {
      final user = await authService.getUserById(testUserId);
      final loginUser = await authService.login(user.username);
      
      expect(loginUser.id, equals(user.id));
      expect(loginUser.username, equals(user.username));
      
      print('✅ Login realizado: ${loginUser.username}');
    });

    test('3. Deve criar sala com sucesso', () async {
      final request = CreateRoomRequest(
        roomName: 'Test Room ${DateTime.now().millisecondsSinceEpoch}',
        gameMode: GameMode.TEAM,
        difficulty: Difficulty.MEDIUM,
        maxPlayers: 6,
        questionTime: 25,
        questionCount: 10,
        categories: ['MATH', 'SCIENCE'],
        assignmentType: 'CHOOSE',
        allowSpectators: false,
        enableChat: true,
        showRealTimeRanking: true,
        allowReconnection: true,
      );

      final room = await roomService.createRoom(request, testUserId);
      
      expect(room.roomName, equals(request.roomName));
      expect(room.hostId, equals(testUserId));
      expect(room.roomCode, hasLength(6));
      expect(room.status, equals(RoomStatus.WAITING));
      
      print('✅ Sala criada: ${room.roomCode}');
    });

    test('4. Deve obter estatísticas do usuário', () async {
      final stats = await authService.getUserStats(testUserId);
      
      expect(stats, isNotNull);
      expect(stats, isA<Map<String, dynamic>>());
      
      print('✅ Estatísticas obtidas: $stats');
    });

    test('5. Deve obter ranking', () async {
      final ranking = await authService.getRanking();
      
      expect(ranking, isA<List<Map<String, dynamic>>>());
      
      print('✅ Ranking obtido: ${ranking.length} jogadores');
    });
  });

  group('Error Handling Tests', () {
    late ApiService apiService;
    late AuthService authService;

    setUpAll(() {
      apiService = ApiService();
      authService = AuthService(apiService);
    });

    tearDownAll(() {
      apiService.dispose();
    });

    test('Deve falhar ao criar usuário com dados inválidos', () async {
      final request = CreateUserRequest(
        username: '', // Username vazio deve falhar
        email: 'invalid-email', // Email inválido
        fullName: '',
      );

      expect(
        () async => await authService.createUser(request),
        throwsA(isA<Exception>()),
      );
      
      print('✅ Validação de erro funcionando');
    });

    test('Deve falhar ao fazer login com usuário inexistente', () async {
      expect(
        () async => await authService.login('usuario_inexistente_123456'),
        throwsA(isA<Exception>()),
      );
      
      print('✅ Erro de login funcionando');
    });
  });
}
