import 'package:creatorio/common/navigator_key.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/core/network/auth_service.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:creatorio/splash_screen.dart';
import 'package:flutter/material.dart';

class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  @override
  void initState() {
    super.initState();

    _init();
  }

  Future<void> _init() async {
    await AuthService.initializeAuth();

    if (!mounted) return;

    final hasAccessToken = TokenManager.hasValidAccessToken();

    final hasRefreshToken =
        await SecureStorageService.getRefreshToken() != null;

    final isLoggedIn = hasAccessToken || hasRefreshToken;

    navigatorKey.currentState?.pushReplacementNamed(
      isLoggedIn ? '/home' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
