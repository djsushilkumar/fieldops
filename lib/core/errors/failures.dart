abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection detected.', String? code])
      : super(code: code);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server encountered an unexpected error.', String? code])
      : super(code: code);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'You are not authorized to perform this operation.', String? code])
      : super(code: code);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested resource was not found.', String? code])
      : super(code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}
