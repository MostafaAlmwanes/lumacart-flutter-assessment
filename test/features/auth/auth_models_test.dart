import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  test('StoreUser round-trips through JSON', () {
    final StoreUser decoded = StoreUser.fromJson(testUser.toJson());

    expect(decoded, testUser);
    expect(decoded.displayName, 'Test User');
    expect(decoded.address.formatted, 'Teststraat 12, 1000 AA Amsterdam');
  });

  test('AuthSession round-trips without losing account metadata', () {
    final AuthSession decoded = AuthSession.fromJson(testSession.toJson());

    expect(decoded, testSession);
    expect(decoded.token?.value, 'token');
  });
}
