import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizmaster_pro/screens/create_room_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/team_lobby_screen.dart';
import 'screens/quiz_countdown_screen.dart';
import 'screens/quiz_game_screen.dart';
import 'screens/quiz_results_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/login_screen.dart';
import 'screens/join_room_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/room_service.dart';
import 'services/game_service.dart';
import 'services/category_service.dart';
import 'providers/auth_provider.dart';
import 'providers/room_provider.dart';
import 'providers/game_provider.dart';
import 'providers/category_provider.dart';

void main() {
  runApp(const QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  const QuizMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, apiService) => apiService.dispose(),
        ),
        ProxyProvider<ApiService, AuthService>(
          update: (_, apiService, __) => AuthService(apiService),
        ),
        ProxyProvider<ApiService, RoomService>(
          update: (_, apiService, __) => RoomService(apiService),
        ),
        ProxyProvider<ApiService, GameService>(
          update: (_, apiService, __) => GameService(apiService),
        ),
        ProxyProvider<ApiService, CategoryService>(
          update: (_, apiService, __) => CategoryService(apiService),
        ),
        
        // Providers
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (_, authService, __) => AuthProvider(authService),
        ),
        ChangeNotifierProxyProvider<RoomService, RoomProvider>(
          create: (context) => RoomProvider(context.read<RoomService>()),
          update: (_, roomService, __) => RoomProvider(roomService),
        ),
        ChangeNotifierProxyProvider<GameService, GameProvider>(
          create: (context) => GameProvider(context.read<GameService>()),
          update: (_, gameService, __) => GameProvider(gameService),
        ),
        ChangeNotifierProxyProvider<CategoryService, CategoryProvider>(
          create: (context) => CategoryProvider(context.read<CategoryService>()),
          update: (_, categoryService, __) => CategoryProvider(categoryService),
        ),
      ],
      child: MaterialApp(
        title: 'QuizMaster Pro',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          primaryColor: const Color(0xFF6366F1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          fontFamily: 'Inter',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/menu': (context) => const MenuScreen(),
          '/create-room': (context) => const CreateRoomScreen(),
          '/join-room': (context) => const JoinRoomScreen(),
          '/team-lobby': (context) => const TeamLobbyScreen(),
          '/quiz-countdown': (context) => const QuizCountdownScreen(),
          '/quiz-game': (context) => const QuizGameScreen(),
          '/quiz-results': (context) => const QuizResultsScreen(),
          '/ranking': (context) => const RankingScreen(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}

