abstract class Failure {
  const Failure();
}

class DatabaseFailure extends Failure {
  final String message;
  const DatabaseFailure(this.message);
}

class AuthFailure extends Failure {
  final String message;
  const AuthFailure(this.message);
}

class NetworkFailure extends Failure {
  final String message;
  const NetworkFailure(this.message);
}

class ServerFailure extends Failure {
  final String message;
  const ServerFailure(this.message);
}

class CacheFailure extends Failure {
  final String message;
  const CacheFailure(this.message);
}

class ValidationFailure extends Failure {
  final String message;
  const ValidationFailure(this.message);
}

class AuthenticationFailure extends Failure {
  final String message;
  const AuthenticationFailure(this.message);
}
