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
