abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

class LocationFailure extends Failure {
  LocationFailure(String message) : super(message);
}