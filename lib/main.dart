import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizmaster_pro/screens/multiplayer/create_room_screen.dart';
import './screens/auth/splash_screen.dart';
import './screens/home/home_screen.dart';
import './screens/home/menu_screen.dart';
import './screens/multiplayer/team_lobby_screen.dart';
import './screens/multiplayer/duel_lobby_screen.dart';
import './screens/multiplayer/kahoot_lobby_screen.dart';
import './screens/multiplayer/kahoot_game_screen.dart';
import './screens/multiplayer/quiz_countdown_screen.dart';
import './screens/multiplayer/quiz_game_screen.dart';
import './screens/multiplayer/quiz_results_screen.dart';
import './screens/profile/ranking_screen.dart';
import './screens/auth/login_screen.dart';
import './screens/auth/nickname_screen.dart';
import './screens/multiplayer/join_room_screen.dart';
import './screens/solo/solo_setup_screen.dart';
import './screens/solo/survival_game_screen.dart';
import './screens/solo/time_attack_game_screen.dart';
import './screens/solo/free_mode_results_screen.dart';
import './services/api_service.dart';
import './services/auth_service.dart';
import './services/room_service.dart';
import './services/game_service.dart';
import './services/category_service.dart';
import './services/question_service.dart';
import './services/mission_service.dart';
import './services/store_service.dart';
import './services/solo_service.dart';
import './services/season_service.dart';
import './services/study_quiz_service.dart';
import './providers/core/auth_provider.dart';
import './providers/game/room_provider.dart';
import './providers/game/game_provider.dart';
import './providers/game/category_provider.dart';
import './providers/game/question_provider.dart';
import './providers/study/study_quiz_provider.dart';
import './providers/core/websocket_provider.dart';
import './providers/core/network_provider.dart';
import './widgets/core/offline_banner_wrapper.dart';
import './providers/economy/mission_provider.dart';
import './providers/economy/store_provider.dart';
import './providers/solo/solo_provider.dart';
import './providers/economy/season_provider.dart';
import './providers/solo/free_mode_provider.dart';
import './providers/social/friendship_provider.dart';
import './services/friendship_service.dart';
import './services/app_audio_service.dart';
import './screens/social/social_screen.dart';

import './screens/economy/quests_screen.dart';
import './screens/economy/store_screen.dart';
import './screens/profile/profile_screen.dart';
import './screens/home/settings_screen.dart';
import './screens/solo/solo_map_screen.dart';
import './screens/solo/solo_quiz_game_screen.dart';
import './screens/solo/boss_battle_screen.dart';
import './screens/economy/season_pass_screen.dart';
import './screens/economy/season_map_screen.dart';
import './screens/study/study_mode_screen.dart';
import './screens/economy/resource_download_screen.dart';
import './services/asset_manager_service.dart';
import './screens/modes/solo_modes_screen.dart';
import './screens/modes/online_modes_screen.dart';
import './screens/modes/study_modes_screen.dart';
import './screens/auth/onboarding_screen.dart';

void main() {
  runApp(const MeuQuizApp());
}

class MeuQuizApp extends StatelessWidget {
  const MeuQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, apiService) => apiService.dispose(),
        ),
        ChangeNotifierProvider<AppAudioService>(
          create: (_) => AppAudioService(),
        ),
        Provider<MissionService>(
          create: (_) => MissionService(),
          dispose: (_, missionService) => missionService.dispose(),
        ),
        Provider<StoreService>(
          create: (_) => StoreService(),
        ),
        Provider<FriendshipService>(
          create: (_) => FriendshipService(ApiService()),
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
        ProxyProvider<ApiService, QuestionService>(
          update: (_, apiService, __) => QuestionService(apiService),
        ),
        ProxyProvider<ApiService, SoloService>(
          update: (_, apiService, __) => SoloService(apiService),
        ),
        ProxyProvider<ApiService, SeasonService>(
          update: (_, apiService, __) => SeasonService(apiService),
        ),
        Provider<StudyQuizService>(
          create: (_) => StudyQuizService(),
        ),
        ChangeNotifierProvider<AssetManagerService>(
          create: (_) => AssetManagerService()..initialize(),
        ),
        
        // Providers
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (_, authService, previous) => previous ?? AuthProvider(authService),
        ),
        ChangeNotifierProxyProvider2<MissionService, AuthProvider, MissionProvider>(
          create: (context) => MissionProvider(
            context.read<MissionService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, missionService, authProvider, previous) => 
            previous ?? MissionProvider(missionService, authProvider),
        ),
        ChangeNotifierProxyProvider2<StoreService, AuthProvider, StoreProvider>(
          create: (context) => StoreProvider(
            context.read<StoreService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, storeService, authProvider, previous) => 
            previous ?? StoreProvider(storeService, authProvider),
        ),
        ChangeNotifierProxyProvider<RoomService, RoomProvider>(
          create: (context) => RoomProvider(context.read<RoomService>()),
          update: (_, roomService, previous) => previous ?? RoomProvider(roomService),
        ),
        ChangeNotifierProxyProvider<GameService, GameProvider>(
          create: (context) => GameProvider(context.read<GameService>()),
          update: (_, gameService, previous) => previous ?? GameProvider(gameService),
        ),
        ChangeNotifierProxyProvider<CategoryService, CategoryProvider>(
          create: (context) => CategoryProvider(context.read<CategoryService>()),
          update: (_, categoryService, previous) => previous ?? CategoryProvider(categoryService),
        ),
        ChangeNotifierProxyProvider<QuestionService, QuestionProvider>(
          create: (context) => QuestionProvider(context.read<QuestionService>()),
          update: (_, questionService, previous) => previous ?? QuestionProvider(questionService),
        ),
        ChangeNotifierProxyProvider2<SoloService, AuthProvider, SoloProvider>(
          create: (context) => SoloProvider(
            context.read<SoloService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, soloService, authProvider, previous) => 
            previous ?? SoloProvider(soloService, authProvider),
        ),
        ChangeNotifierProxyProvider<SeasonService, SeasonProvider>(
          create: (context) => SeasonProvider(context.read<SeasonService>()),
          update: (_, seasonService, previous) => previous ?? SeasonProvider(seasonService),
        ),
        ChangeNotifierProxyProvider<SoloService, FreeModeProvider>(
          create: (context) => FreeModeProvider(context.read<SoloService>()),
          update: (_, soloService, previous) => previous ?? FreeModeProvider(soloService),
        ),
        ChangeNotifierProxyProvider<StudyQuizService, StudyQuizProvider>(
          create: (context) => StudyQuizProvider(service: context.read<StudyQuizService>()),
          update: (_, studyService, previous) => previous ?? StudyQuizProvider(service: studyService),
        ),
        ChangeNotifierProxyProvider<FriendshipService, FriendshipProvider>(
          create: (context) => FriendshipProvider(context.read<FriendshipService>()),
          update: (_, friendshipService, previous) => previous ?? FriendshipProvider(friendshipService),
        ),
        // WebSocket: ligação STOMP em tempo real
        ChangeNotifierProvider<WebSocketProvider>(
          create: (_) => WebSocketProvider(),
        ),
        ChangeNotifierProvider<NetworkProvider>(
          create: (_) => NetworkProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Meu Quiz +',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return OfflineBannerWrapper(
            child: child ?? const SizedBox(),
          );
        },
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
          '/': (context) => const SplashScreen(),
          '/intro': (context) => const HomeScreen(),
          '/solo_modes': (context) => const SoloModesScreen(),
          '/online_modes': (context) => const OnlineModesScreen(),
          '/study_modes': (context) => const StudyModesScreen(),
          '/menu': (context) => const MenuScreen(),
          '/nickname_setup': (context) => const NicknameScreen(),
          '/create-room': (context) => const CreateRoomScreen(),
          '/join-room': (context) => const JoinRoomScreen(),
          '/team-lobby': (context) => const TeamLobbyScreen(),
          '/duel-lobby': (context) => const DuelLobbyScreen(),
          '/kahoot-lobby': (context) => const KahootLobbyScreen(),
          '/kahoot-game': (context) => const KahootGameScreen(),
          '/quiz-countdown': (context) => const QuizCountdownScreen(),
          '/quiz-game': (context) => const QuizGameScreen(),
          '/quiz-results': (context) => const QuizResultsScreen(),
          '/ranking': (context) => const RankingScreen(),
          '/login': (context) => const LoginScreen(),
          '/solo-setup': (context) => const SoloSetupScreen(),
          '/quests': (context) => const QuestsScreen(),
          '/store': (context) => const StoreScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/solo-map': (context) => const SoloMapScreen(),
          '/solo-game': (context) => const SoloQuizGameScreen(),
          '/boss-battle': (context) => const BossBattleScreen(),
          '/season-pass': (context) => const SeasonPassScreen(),
          '/season-map': (context) => const SeasonMapScreen(),
          '/study-mode': (context) => const StudyModeScreen(),
          '/survival-game': (context) => const SurvivalGameScreen(),
          '/time-attack-game': (context) => const TimeAttackGameScreen(),
          '/free-mode-results': (context) => const FreeModeResultsScreen(),
          '/resource-download': (context) => ResourceDownloadScreen(
                onDownloadComplete: () {
                  Navigator.pop(context);
                },
              ),
          '/social': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final initialTab = (args is int) ? args : 0;
            return SocialScreen(initialTabIndex: initialTab);
          },
          '/onboarding': (context) => const OnboardingScreen(),
        },
      ),
    );
  }
}
