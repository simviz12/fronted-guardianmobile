sealed class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No se pudo establecer conexión con el servidor. Verifica tu red.',
    super.code = 'NETWORK_ERROR',
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'El servidor tardó demasiado en responder.',
    super.code = 'TIMEOUT_ERROR',
  });
}

class ServerFailure extends Failure {
  final int? statusCode;
  final List<String> details;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
    this.details = const [],
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ocurrió un error inesperado al procesar la solicitud.',
    super.code = 'UNKNOWN_ERROR',
  });
}
