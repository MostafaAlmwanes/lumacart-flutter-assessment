import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/utils/json_parsing.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';

class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<AuthSession?> read() async {
    try {
      final String? raw = await _storage.read(key: StorageKeys.secureSession);
      if (raw == null || raw.isEmpty) return null;
      final Object? decoded = jsonDecode(raw);
      final AuthSession session = AuthSession.fromJson(mapValue(decoded));
      final bool invalidIdentity =
          session.accountKey.isEmpty || session.user.username.isEmpty;
      final bool invalidApiSession = session.accountType == AccountType.api &&
          session.token?.isValid != true;
      final bool invalidAccountKey = session.accountType == AccountType.api
          ? !session.accountKey.startsWith('api:')
          : !session.accountKey.startsWith('local:');
      if (invalidIdentity || invalidApiSession || invalidAccountKey) {
        await clear();
        return null;
      }
      return session;
    } on Object catch (error) {
      try {
        await clear();
      } on Object {
        // The original read/parsing failure remains the useful failure.
      }
      throw Failure(
        message: 'The saved session was invalid and has been cleared.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }

  Future<void> write(AuthSession session) async {
    try {
      await _storage.write(
        key: StorageKeys.secureSession,
        value: jsonEncode(session.toJson()),
      );
    } on Object catch (error) {
      throw Failure(
        message: 'The secure session could not be saved.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: StorageKeys.secureSession);
    } on Object catch (error) {
      throw Failure(
        message: 'The secure session could not be cleared.',
        type: FailureType.storage,
        cause: error,
      );
    }
  }
}
