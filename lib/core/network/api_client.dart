import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lumacart/core/constants/api_paths.dart';
import 'package:lumacart/core/constants/app_constants.dart';
import 'package:lumacart/core/errors/failure.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiPaths.baseUrl,
                connectTimeout: AppConstants.connectTimeout,
                sendTimeout: AppConstants.sendTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                headers: const <String, String>{
                  Headers.acceptHeader: Headers.jsonContentType,
                  Headers.contentTypeHeader: Headers.jsonContentType,
                },
              ),
            ) {
    if (kDebugMode) {
      _dio.interceptors.add(_SafeDebugInterceptor());
    }
  }

  final Dio _dio;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      final Response<Object?> response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<Object?> post(String path, {Object? data}) async {
    try {
      final Response<Object?> response = await _dio.post<Object?>(
        path,
        data: data,
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}

Failure mapDioFailure(DioException error) {
  final int? status = error.response?.statusCode;
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return Failure(
      message: 'The request timed out. Check your connection and try again.',
      type: FailureType.timeout,
      cause: error,
    );
  }
  if (error.type == DioExceptionType.connectionError ||
      (error.type == DioExceptionType.unknown && error.response == null)) {
    return Failure(
      message: 'Unable to reach the store. Check your connection and retry.',
      type: FailureType.network,
      cause: error,
    );
  }
  if (status == 401) {
    return Failure(
      message: 'The username or password is incorrect.',
      type: FailureType.unauthorized,
      statusCode: status,
      cause: error,
    );
  }
  if (status == 403) {
    return Failure(
      message: 'This action is not permitted.',
      type: FailureType.forbidden,
      statusCode: status,
      cause: error,
    );
  }
  if (status == 404) {
    return Failure(
      message: 'The requested store data was not found.',
      type: FailureType.notFound,
      statusCode: status,
      cause: error,
    );
  }
  if (status != null && status >= 500) {
    return Failure(
      message: 'The store service is temporarily unavailable.',
      type: FailureType.server,
      statusCode: status,
      cause: error,
    );
  }
  return Failure(
    message: 'The request could not be completed.',
    type: FailureType.unknown,
    statusCode: status,
    cause: error,
  );
}

class _SafeDebugInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '${options.method} ${options.uri.replace(queryParameters: const <String, String>{})}',
      name: 'LumaCart.Network',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      '${response.statusCode} ${response.requestOptions.path}',
      name: 'LumaCart.Network',
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    developer.log(
      '${error.response?.statusCode ?? 'network'} ${error.requestOptions.path}',
      name: 'LumaCart.Network',
    );
    handler.next(error);
  }
}
