import 'dart:async';

class AuthBootstrap {
  static Completer<void>? _completer;

  static bool get isBootstrapping => _completer != null;

  static Future<void>? get future => _completer?.future;

  static void start() {
    _completer ??= Completer<void>();
  }

  static void complete() {
    _completer?.complete();
    _completer = null;
  }

  static void completeError(dynamic error) {
    _completer?.completeError(error);
    _completer = null;
  }
}
