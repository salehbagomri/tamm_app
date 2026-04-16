import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform utilities — provides web-safe alternatives to dart:io checks
class PlatformUtils {
  /// Whether the app is running on the web
  static bool get isWeb => kIsWeb;

  /// Check if an error is a network connectivity error.
  /// Replaces `on SocketException` which doesn't work on web.
  static bool isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('xmlhttprequest error') ||
        msg.contains('clientexception');
  }
}
