import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço central de áudio da app.
/// Usa dois AudioPlayers independentes para música e um pool para SFX:
/// - _musicPlayer: música de fundo em loop contínuo
/// - _sfxPlayers: efeitos sonoros que tocam por cima da música
class AppAudioService extends ChangeNotifier with WidgetsBindingObserver {
  // Player de música
  final AudioPlayer _musicPlayer = AudioPlayer();
  
  // Pool de players para SFX para não cortarem uns aos outros
  static const int _sfxPoolSize = 5;
  final List<AudioPlayer> _sfxPlayers = List.generate(_sfxPoolSize, (_) => AudioPlayer());
  int _currentSfxIndex = 0;

  // Estado atual
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _vibrationEnabled = true;
  double _musicVolume = 0.20; // 20% por padrão
  double _sfxVolume = 0.70;   // 70% por padrão
  String? _currentMusicAsset;
  String? _lastMusicAsset;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // Caminhos dos assets de som
  static const String _musicMenu = 'sons/jg_menu.wav';
  static const String _musicGame = 'sons/jogo_normal.wav';
  static const String _musicBoss = 'sons/jogo_boss.wav';
  static const String _sfxCorrect = 'sons/pergunta_certo.wav';
  static const String _sfxWrong = 'sons/pergunta_erro.wav';
  static const String _sfxLevelUp = 'sons/nivel.wav';
  static const String _sfxClick = 'sons/clicks.wav';
  static const String _sfxPurchase = 'sons/compras,conquistas, etc.wav';
  static const String _sfxTimer = 'sons/timer.wav';

  AppAudioService() {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_musicEnabled && _currentMusicAsset != null) {
        _musicPlayer.resume();
      }
    }
  }

  Future<void> _init() async {
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
    await AudioPlayer.global.setAudioContext(audioContext);

    await loadSettings();
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    for (var player in _sfxPlayers) {
      await player.setReleaseMode(ReleaseMode.stop);
    }
  }

  /// Carrega as preferências guardadas
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    _sfxEnabled = prefs.getBool('sfxEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _musicVolume = prefs.getDouble('musicVolume') ?? 0.20;
    _sfxVolume = prefs.getDouble('sfxVolume') ?? 0.70;

    await _musicPlayer.setVolume(_musicVolume);
    for (var player in _sfxPlayers) {
      await player.setVolume(_sfxVolume);
    }
    notifyListeners();
  }

  // ─── Controlos de Música ───────────────────────────────────────────────────

  Future<void> playMenuMusic() async => _playMusic(_musicMenu);
  Future<void> playGameMusic() async => _playMusic(_musicGame);
  Future<void> playBossMusic() async => _playMusic(_musicBoss);

  Future<void> _playMusic(String asset) async {
    if (!_musicEnabled) return;
    if (_currentMusicAsset == asset) {
      if (_musicPlayer.state != PlayerState.playing) {
        await _musicPlayer.resume();
      }
      return; // Já a tocar esta música
    }
    _currentMusicAsset = asset;
    try {
      await _musicPlayer.stop(); // Garante que a anterior pare
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource(asset));
    } catch (e) {
      if (kDebugMode) debugPrint('🔇 AudioService: Erro ao tocar música: $e');
    }
  }

  Future<void> stopMusic() async {
    _lastMusicAsset = _currentMusicAsset;
    _currentMusicAsset = null;
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async => _musicPlayer.pause();
  Future<void> resumeMusic() async {
    if (_musicEnabled) await _musicPlayer.resume();
  }

  // ─── Efeitos Sonoros ───────────────────────────────────────────────────────

  Future<void> playSfxCorrect() async => _playSfx(_sfxCorrect, volume: _sfxVolume);
  Future<void> playSfxWrong() async => _playSfx(_sfxWrong, volume: _sfxVolume * 0.85);
  Future<void> playSfxLevelUp() async => _playSfx(_sfxLevelUp, volume: (_sfxVolume * 1.2).clamp(0.0, 1.0));
  Future<void> playSfxClick() async => _playSfx(_sfxClick, volume: _sfxVolume * 0.55);
  Future<void> playSfxPurchase() async => _playSfx(_sfxPurchase, volume: _sfxVolume);
  Future<void> playSfxTimer() async => _playSfx(_sfxTimer, volume: _sfxVolume * 0.60);

  Future<void> _playSfx(String asset, {double? volume}) async {
    if (!_sfxEnabled) return;
    try {
      final player = _sfxPlayers[_currentSfxIndex];
      _currentSfxIndex = (_currentSfxIndex + 1) % _sfxPoolSize;
      
      await player.setVolume(volume ?? _sfxVolume);
      await player.play(AssetSource(asset));
    } catch (e) {
      if (kDebugMode) debugPrint('🔇 AudioService: Erro ao tocar SFX: $e');
    }
  }

  // ─── Configurações (chamadas pelas Definições) ────────────────────────────

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', value);
    if (!value) {
      _lastMusicAsset = _currentMusicAsset;
      await _musicPlayer.stop();
      _currentMusicAsset = null;
    } else {
      if (_lastMusicAsset != null) {
        _playMusic(_lastMusicAsset!);
      } else {
        playMenuMusic();
      }
    }
    notifyListeners();
  }

  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfxEnabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    notifyListeners();
  }

  void triggerVibration({bool heavy = false}) {
    if (_vibrationEnabled) {
      if (heavy) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value;
    await _musicPlayer.setVolume(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', value);
    notifyListeners();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value;
    for (var player in _sfxPlayers) {
      await player.setVolume(value);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfxVolume', value);
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _musicPlayer.dispose();
    for (var player in _sfxPlayers) {
      player.dispose();
    }
    super.dispose();
  }
}
