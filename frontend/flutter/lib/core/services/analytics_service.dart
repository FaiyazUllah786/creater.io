import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logEvent(String name,
      {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  static Future<void> logLogin(String loginMethod) async {
    await _analytics.logLogin(loginMethod: loginMethod);
  }

  static Future<void> logSignUp(String signUpMethod) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
  }
}
