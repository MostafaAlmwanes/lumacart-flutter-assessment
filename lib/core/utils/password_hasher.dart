import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:lumacart/core/constants/app_constants.dart';

class PasswordDigest {
  const PasswordDigest({
    required this.hashBase64,
    required this.saltBase64,
    required this.iterations,
  });

  final String hashBase64;
  final String saltBase64;
  final int iterations;
}

class PasswordHasher {
  PasswordHasher({Pbkdf2? algorithm})
      : _algorithm = algorithm ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: AppConstants.passwordHashIterations,
              bits: 256,
            );

  final Pbkdf2 _algorithm;

  Future<PasswordDigest> hash(String password) async {
    final Random random = Random.secure();
    final List<int> salt = List<int>.generate(
      16,
      (_) => random.nextInt(256),
      growable: false,
    );
    final SecretKey key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final List<int> bytes = await key.extractBytes();
    return PasswordDigest(
      hashBase64: base64Encode(bytes),
      saltBase64: base64Encode(salt),
      iterations: AppConstants.passwordHashIterations,
    );
  }

  Future<bool> verify({
    required String password,
    required String hashBase64,
    required String saltBase64,
    required int iterations,
  }) async {
    final Pbkdf2 algorithm = iterations == AppConstants.passwordHashIterations
        ? _algorithm
        : Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: iterations,
            bits: 256,
          );
    final SecretKey key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: base64Decode(saltBase64),
    );
    final List<int> actual = await key.extractBytes();
    final List<int> expected = base64Decode(hashBase64);
    if (actual.length != expected.length) return false;
    int difference = 0;
    for (int index = 0; index < actual.length; index++) {
      difference |= actual[index] ^ expected[index];
    }
    return difference == 0;
  }
}
