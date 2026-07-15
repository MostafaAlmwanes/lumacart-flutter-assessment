import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/network/api_client.dart';

void main() {
  test('maps a 401 response to an unauthorized failure', () {
    final RequestOptions request = RequestOptions(path: '/auth/login');
    final DioException error = DioException(
      requestOptions: request,
      response: Response<Object?>(
        requestOptions: request,
        statusCode: 401,
      ),
      type: DioExceptionType.badResponse,
    );

    final Failure failure = mapDioFailure(error);

    expect(failure.type, FailureType.unauthorized);
    expect(failure.statusCode, 401);
  });

  test('maps connection timeout to a timeout failure', () {
    final DioException error = DioException(
      requestOptions: RequestOptions(path: '/products'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(mapDioFailure(error).type, FailureType.timeout);
  });
}
