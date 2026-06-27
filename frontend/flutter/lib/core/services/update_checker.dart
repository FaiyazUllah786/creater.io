import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  // In a real production app, this would be fetched from a backend endpoint
  // or Firebase Remote Config.
  static const String _minimumRequiredVersion = '1.0.0';

  static Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      return _isVersionLower(currentVersion, _minimumRequiredVersion);
    } catch (e) {
      debugPrint('Error checking update: $e');
      return false; // Fail safe: don't force update if we can't check
    }
  }

  static bool _isVersionLower(String currentVersion, String minVersion) {
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> minParts = minVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length && i < minParts.length; i++) {
      if (currentParts[i] < minParts[i]) return true;
      if (currentParts[i] > minParts[i]) return false;
    }
    return false;
  }
}
