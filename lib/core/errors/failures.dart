abstract class Failure {
  const Failure();
}

class DatabaseFailure extends Failure {
  final String message;
  const DatabaseFailure(this.message);

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  final String message;
  const NetworkFailure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  final String message;
  const ServerFailure(this.message);

  @override
  String toString() => message;
}

class CacheFailure extends Failure {
  final String message;
  const CacheFailure(this.message);

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  final String message;
  const ValidationFailure(this.message);

  @override
  String toString() => message;
}

class AuthenticationFailure extends Failure {
  final String message;
  const AuthenticationFailure(this.message);

  @override
  String toString() => message;
}
