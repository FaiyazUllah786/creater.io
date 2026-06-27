abstract class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException([this.message = "", this.prefix]);

  @override
  String toString() {
    return "${prefix ?? 'AppException'}: $message";
  }
}

class NetworkException extends AppException {
  NetworkException([String message = "A network error occurred."])
      : super(message, "Network Error");
}

class ServerException extends AppException {
  final int statusCode;
  ServerException(this.statusCode,
      [String message = "Server returned an error."])
      : super(message, "Server Error");
}

class AuthException extends AppException {
  AuthException([String message = "Authentication failed."])
      : super(message, "Authentication Error");
}

class DataParsingException extends AppException {
  DataParsingException([String message = "Failed to parse data."])
      : super(message, "Data Parsing Error");
}
