import 'package:equatable/equatable.dart';

enum FailureType {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  network,
  timeout,
  server,
  parsing,
  storage,
  unknown,
}

class Failure extends Equatable implements Exception {
  const Failure({
    required this.message,
    this.type = FailureType.unknown,
    this.statusCode,
    this.cause,
  });

  final String message;
  final FailureType type;
  final int? statusCode;
  final Object? cause;

  @override
  List<Object?> get props => <Object?>[message, type, statusCode];

  @override
  String toString() => 'Failure(type: $type, message: $message)';
}
