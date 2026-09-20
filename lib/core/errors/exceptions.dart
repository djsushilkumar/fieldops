class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred', String? code])
      : super(code: code);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed', String? code])
      : super(code: code);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Local cache failure', String? code])
      : super(code: code);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized action', String? code])
      : super(code: code);
}
