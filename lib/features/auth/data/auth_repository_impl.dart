import 'package:lumacart/core/constants/api_paths.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/network/api_client.dart';
import 'package:lumacart/core/storage/local_store.dart';
import 'package:lumacart/core/utils/json_parsing.dart';
import 'package:lumacart/core/utils/password_hasher.dart';
import 'package:lumacart/features/auth/data/secure_session_store.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/auth/domain/auth_repository.dart';
import 'package:uuid/uuid.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required LocalStore localStore,
    required SecureSessionStore sessionStore,
    PasswordHasher? passwordHasher,
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _localStore = localStore,
        _sessionStore = sessionStore,
        _passwordHasher = passwordHasher ?? PasswordHasher(),
        _uuid = uuid ?? const Uuid();

  final ApiClient _apiClient;
  final LocalStore _localStore;
  final SecureSessionStore _sessionStore;
  final PasswordHasher _passwordHasher;
  final Uuid _uuid;

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final AuthSession? session = await _sessionStore.read();
      if (session == null || session.accountType == AccountType.api) {
        return session;
      }
      final LocalAccount? account = _accounts()
          .where(
            (LocalAccount item) =>
                session.accountKey == 'local:${item.localId}',
          )
          .firstOrNull;
      if (account == null) {
        await _sessionStore.clear();
        return null;
      }
      return AuthSession(
        accountKey: session.accountKey,
        user: account.user,
        accountType: AccountType.local,
        signedInAt: session.signedInAt,
      );
    } on Failure {
      try {
        await _sessionStore.clear();
      } on Failure {
        // The invalid session still resolves safely to signed out.
      }
      return null;
    }
  }

  @override
  Future<StoreUser> getUser(int id) async {
    if (id <= 0) {
      throw const Failure(
        message: 'A valid user ID is required.',
        type: FailureType.validation,
      );
    }
    final StoreUser user = StoreUser.fromJson(
      await _apiClient.get(ApiPaths.user(id)),
    );
    if (user.id <= 0 || user.username.isEmpty) {
      throw const Failure(
        message: 'The user profile response was incomplete.',
        type: FailureType.parsing,
      );
    }
    return user;
  }

  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) async {
    final String normalizedUsername = username.trim().toLowerCase();
    final LocalAccount? localAccount = _accounts().where(
      (LocalAccount account) =>
          account.user.username.toLowerCase() == normalizedUsername,
    ).firstOrNull;

    if (localAccount != null) {
      final bool valid = await _passwordHasher.verify(
        password: password,
        hashBase64: localAccount.passwordHash,
        saltBase64: localAccount.passwordSalt,
        iterations: localAccount.hashIterations,
      );
      if (!valid) {
        throw const Failure(
          message: 'The username or password is incorrect.',
          type: FailureType.unauthorized,
        );
      }
      final AuthSession session = AuthSession(
        accountKey: 'local:${localAccount.localId}',
        user: localAccount.user,
        accountType: AccountType.local,
        signedInAt: DateTime.now().toUtc(),
      );
      await _sessionStore.write(session);
      return AuthResult(session: session);
    }

    final Object? loginResponse = await _apiClient.post(
      ApiPaths.login,
      data: <String, Object?>{
        'username': username.trim(),
        'password': password,
      },
    );
    final AuthToken token = AuthToken.fromJson(loginResponse);
    if (!token.isValid) {
      throw const Failure(
        message: 'The store returned an invalid authentication response.',
        type: FailureType.parsing,
      );
    }

    final Object? usersResponse = await _apiClient.get(ApiPaths.users);
    final List<StoreUser> users = listValue(usersResponse)
        .map(StoreUser.fromJson)
        .where((StoreUser user) => user.username.isNotEmpty)
        .toList(growable: false);
    final StoreUser? user = users.where(
      (StoreUser item) =>
          item.username.toLowerCase() == normalizedUsername,
    ).firstOrNull;
    if (user == null) {
      throw const Failure(
        message: 'Authentication succeeded, but the user profile was not found.',
        type: FailureType.notFound,
      );
    }

    final AuthSession session = AuthSession(
      accountKey: 'api:${user.id}',
      user: user,
      accountType: AccountType.api,
      signedInAt: DateTime.now().toUtc(),
      token: token,
    );
    await _sessionStore.write(session);
    return AuthResult(session: session);
  }

  @override
  Future<AuthResult> signUp(SignUpInput input) async {
    final String normalizedUsername = input.username.trim().toLowerCase();
    final String normalizedEmail = input.email.trim().toLowerCase();
    final List<LocalAccount> existing = _accounts();
    if (existing.any(
      (LocalAccount account) =>
          account.user.username.toLowerCase() == normalizedUsername,
    )) {
      throw const Failure(
        message: 'That username is already registered on this device.',
        type: FailureType.conflict,
      );
    }
    if (existing.any(
      (LocalAccount account) =>
          account.user.email.toLowerCase() == normalizedEmail,
    )) {
      throw const Failure(
        message: 'That email is already registered on this device.',
        type: FailureType.conflict,
      );
    }

    int simulatedRemoteId = 0;
    String? warning;
    try {
      final Object? response = await _apiClient.post(
        ApiPaths.users,
        data: input.toApiJson(),
      );
      simulatedRemoteId = intValue(mapValue(response)['id']);
    } on Failure {
      warning = 'Your account was created on this device, but the store '
          'service could not be reached.';
    }

    final PasswordDigest digest = await _passwordHasher.hash(input.password);
    final String localId = _uuid.v4();
    final StoreUser user = input.toUser(id: simulatedRemoteId);
    final LocalAccount account = LocalAccount(
      localId: localId,
      user: user,
      passwordHash: digest.hashBase64,
      passwordSalt: digest.saltBase64,
      hashIterations: digest.iterations,
      createdAt: DateTime.now().toUtc(),
    );
    await _saveAccounts(<LocalAccount>[...existing, account]);

    final AuthSession session = AuthSession(
      accountKey: 'local:$localId',
      user: user,
      accountType: AccountType.local,
      signedInAt: DateTime.now().toUtc(),
    );
    await _sessionStore.write(session);
    return AuthResult(session: session, warning: warning);
  }

  @override
  Future<void> signOut() => _sessionStore.clear();

  List<LocalAccount> _accounts() {
    final Object? raw = _localStore.readApp<Object?>(StorageKeys.localAccounts);
    return listValue(raw)
        .map(LocalAccount.fromJson)
        .where((LocalAccount account) =>
            account.localId.isNotEmpty &&
            account.user.username.isNotEmpty &&
            account.passwordHash.isNotEmpty &&
            account.passwordSalt.isNotEmpty &&
            account.hashIterations > 0)
        .toList(growable: false);
  }

  Future<void> _saveAccounts(List<LocalAccount> accounts) {
    return _localStore.writeApp(
      StorageKeys.localAccounts,
      accounts.map((LocalAccount account) => account.toJson()).toList(),
    );
  }
}

