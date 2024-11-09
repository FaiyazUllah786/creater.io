import 'dart:async';
import 'package:creatorio/features/auth/repository/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../common/utils.dart';

class TokensController extends ChangeNotifier {
  final userRepository = UserRepository();
  final storage = const FlutterSecureStorage();
  Timer? _tokenMonitorTimer;

  bool _isLogout = false;
  bool _isWaiting = false;
  bool _isValidTokens = false;

  bool get isLogout => _isLogout;
  bool get isWaiting => _isWaiting;
  bool get isValidTokens => _isValidTokens;

  TokensController() {
    startTokenMonitor();
  }

  void startTokenMonitor() {
    _tokenMonitorTimer = Timer.periodic(
      const Duration(minutes: 30),
      (timer) async {
        await checkTokenStatus();
      },
    );
  }

  void stopTokenMonitor() {
    _tokenMonitorTimer?.cancel();
  }

  Future<void> checkTokenStatus() async {
    if (kDebugMode) print("Checking token status");
    if (_isWaiting) return;

    _isWaiting = true;
    notifyListeners();

    final accessToken = await storage.read(key: "accessToken");
    final refreshToken = await storage.read(key: "refreshToken");

    if (accessToken != null) {
      final expiresIn = parseTimeStamp(JwtDecoder.decode(accessToken)['exp']);
      final now = DateTime.now();

      if (now.isAfter(expiresIn) || expiresIn.difference(now).inMinutes < 5) {
        final success = await userRepository.refreshTokens();
        _isValidTokens = success;
      } else {
        _isValidTokens = true;
      }
    } else if (refreshToken != null) {
      final success = await userRepository.refreshTokens();
      _isValidTokens = success;
    } else {
      _isValidTokens = false;
    }

    _isWaiting = false;
    notifyListeners();
    if (kDebugMode)
      _isValidTokens ? print("Token is valid") : print("Token is invalid");
  }

  Future<void> handleLogout() async {
    await storage.deleteAll();
    _isLogout = true;
    notifyListeners();
  }
}
