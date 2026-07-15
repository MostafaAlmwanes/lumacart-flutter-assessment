import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/core/constants/api_paths.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/network/api_client.dart';
import 'package:lumacart/core/storage/local_store.dart';
import 'package:lumacart/features/auth/data/auth_repository_impl.dart';
import 'package:lumacart/features/auth/data/secure_session_store.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/test_fixtures.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockLocalStore extends Mock implements LocalStore {}

class _MockSecureSessionStore extends Mock implements SecureSessionStore {}

void main() {
  late _MockApiClient apiClient;
  late _MockLocalStore localStore;
  late _MockSecureSessionStore sessionStore;

  setUpAll(() {
    registerFallbackValue(testSession);
  });

  setUp(() {
    apiClient = _MockApiClient();
    localStore = _MockLocalStore();
    sessionStore = _MockSecureSessionStore();
    when(() => sessionStore.write(any())).thenAnswer((_) async {});
  });

  test('authenticates an API user and matches the full profile', () async {
    when(
      () => localStore.readApp<Object?>(StorageKeys.localAccounts),
    ).thenReturn(const <Object?>[]);
    when(
      () => apiClient.post(
        ApiPaths.login,
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => <String, Object?>{'token': 'safe-token'});
    when(() => apiClient.get(ApiPaths.users)).thenAnswer(
      (_) async => <Object?>[testUser.toJson()],
    );
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      apiClient: apiClient,
      localStore: localStore,
      sessionStore: sessionStore,
    );

    final AuthResult result = await repository.signIn(
      username: testUser.username,
      password: 'remote-password',
    );

    expect(result.session.accountType, AccountType.api);
    expect(result.session.user, testUser);
    expect(result.session.token?.value, 'safe-token');
    verify(() => sessionStore.write(any())).called(1);
  });

  test('fetches a typed user by ID', () async {
    when(() => apiClient.get(ApiPaths.user(testUser.id))).thenAnswer(
      (_) async => testUser.toJson(),
    );
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      apiClient: apiClient,
      localStore: localStore,
      sessionStore: sessionStore,
    );

    final StoreUser result = await repository.getUser(testUser.id);

    expect(result, testUser);
    verify(() => apiClient.get(ApiPaths.user(testUser.id))).called(1);
  });

  test('a locally signed-up account can sign in through a new repository', () async {
    Object? storedAccounts = const <Object?>[];
    when(
      () => localStore.readApp<Object?>(StorageKeys.localAccounts),
    ).thenAnswer((_) => storedAccounts);
    when(
      () => localStore.writeApp(
        StorageKeys.localAccounts,
        any(),
      ),
    ).thenAnswer((Invocation invocation) async {
      storedAccounts = invocation.positionalArguments[1];
    });
    when(
      () => apiClient.post(
        ApiPaths.users,
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => <String, Object?>{'id': 99});

    final AuthRepositoryImpl registrationRepository = AuthRepositoryImpl(
      apiClient: apiClient,
      localStore: localStore,
      sessionStore: sessionStore,
    );
    const SignUpInput input = SignUpInput(
      firstName: 'Local',
      lastName: 'User',
      email: 'local@example.com',
      username: 'local_user',
      password: 'secure123',
      confirmPassword: 'secure123',
      phone: '+31 20 123 4567',
      city: 'Amsterdam',
      street: 'Teststraat',
      streetNumber: 12,
      zipCode: '1000 AA',
    );

    final AuthResult registration = await registrationRepository.signUp(input);
    final String persisted = storedAccounts.toString();
    expect(registration.session.accountType, AccountType.local);
    expect(persisted, isNot(contains(input.password)));
    expect(persisted, contains('passwordHash'));
    expect(persisted, contains('passwordSalt'));

    final AuthRepositoryImpl restartedRepository = AuthRepositoryImpl(
      apiClient: apiClient,
      localStore: localStore,
      sessionStore: sessionStore,
    );
    final AuthResult login = await restartedRepository.signIn(
      username: input.username,
      password: input.password,
    );

    expect(login.session.accountType, AccountType.local);
    expect(login.session.user.username, input.username);
    verify(
      () => apiClient.post(
        ApiPaths.users,
        data: any(named: 'data'),
      ),
    ).called(1);
    verifyNever(
      () => apiClient.post(
        ApiPaths.login,
        data: any(named: 'data'),
      ),
    );
  });
}
