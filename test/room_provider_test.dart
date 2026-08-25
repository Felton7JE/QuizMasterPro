import 'package:flutter_test/flutter_test.dart';
import 'package:quizmaster_pro/providers/room_provider.dart';
import 'package:quizmaster_pro/models/room_model.dart';
import 'package:quizmaster_pro/services/room_service.dart';

// Classe Falsa (Mock) do RoomService para não dependermos de internet
class MockRoomService implements RoomService {
  bool shouldThrowError = false;

  @override
  Future<RoomModel> joinRoom(String roomCode, String userId, {String? password}) async {
    if (shouldThrowError) {
      throw Exception('Sala não encontrada ou cheia');
    }
    
    // Retorna uma sala falsa simulada
    return RoomModel(
      id: '1',
      roomCode: roomCode,
      roomName: 'Sala de Teste',
      hostId: 'host_123',
      hostName: 'Host Teste',
      gameMode: GameMode.CLASSIC,
      difficulty: Difficulty.MEDIUM,
      status: RoomStatus.WAITING,
      maxPlayers: 10,
      questionTime: 10,
      questionCount: 5,
      allowSpectators: true,
      enableChat: true,
      showRealTimeRanking: true,
      allowReconnection: false,
      players: [
        PlayerInRoom(userId: userId, username: 'Jogador_Mock', fullName: 'Jogador Mock', isReady: true, isHost: false)
      ],
      categories: [],
      createdAt: DateTime.now(),
      categoryAssignmentMode: CategoryAssignmentMode.MANUAL,
    );
  }

  // Métodos obrigatórios não usados neste teste
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Testes de Estado - RoomProvider', () {
    late MockRoomService mockService;
    late RoomProvider roomProvider;

    setUp(() {
      mockService = MockRoomService();
      roomProvider = RoomProvider(mockService);
    });

    test('Deve popular currentRoom e players quando entrar numa sala com sucesso', () async {
      // Act (Ação)
      final success = await roomProvider.joinRoom('123456', 'user_777');

      // Assert (Validação)
      expect(success, true);
      expect(roomProvider.currentRoom, isNotNull);
      expect(roomProvider.currentRoom?.roomCode, '123456');
      expect(roomProvider.players.length, 1);
      expect(roomProvider.players.first.userId, 'user_777');
      expect(roomProvider.error, isNull);
    });

    test('Deve salvar mensagem de erro quando a API falhar', () async {
      // Arrange (Preparação)
      mockService.shouldThrowError = true;

      // Act (Ação)
      final success = await roomProvider.joinRoom('ERROR_CODE', 'user_777');

      // Assert (Validação)
      expect(success, false);
      expect(roomProvider.currentRoom, isNull);
      expect(roomProvider.players, isEmpty);
      expect(roomProvider.error, contains('Sala não encontrada ou cheia'));
    });
  });
}
