import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/core/auth_provider.dart';
import '../../widgets/core/animated_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for widget bindings to complete and show splash for at least 3.5 seconds
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.checkAndSilentLogin();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      final currentUser = authProvider.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;

      if (!mounted) return;

      if (currentUser != null && currentUser.username.contains('@')) {
        Navigator.pushReplacementNamed(context, '/nickname_setup');
      } else if (!hasSeenTutorial) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSplash(size: 250),
          ],
        ),
      ),
    );
  }
}
