import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/core/utils/password_hasher.dart';

void main() {
  test('hashes with a random salt and verifies the correct password', () async {
    final PasswordHasher hasher = PasswordHasher();
    final PasswordDigest first = await hasher.hash('secure123');
    final PasswordDigest second = await hasher.hash('secure123');

    expect(first.hashBase64, isNotEmpty);
    expect(first.saltBase64, isNot(second.saltBase64));
    expect(
      await hasher.verify(
        password: 'secure123',
        hashBase64: first.hashBase64,
        saltBase64: first.saltBase64,
        iterations: first.iterations,
      ),
      isTrue,
    );
    expect(
      await hasher.verify(
        password: 'wrong-password',
        hashBase64: first.hashBase64,
        saltBase64: first.saltBase64,
        iterations: first.iterations,
      ),
      isFalse,
    );
  });
}
