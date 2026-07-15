import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  blocTest<AuthBloc, AuthState>(
    'restores an authenticated session',
    build: () {
      repository.restoredSession = testSession;
      return AuthBloc(repository: repository);
    },
    act: (AuthBloc bloc) => bloc.add(const AuthSessionRestoreRequested()),
    expect: () => <Object>[
      const AuthState(status: AuthStatus.restoringSession),
      AuthState(status: AuthStatus.authenticated, session: testSession),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'returns safely to sign in when session restoration fails',
    build: () {
      repository.error = StateError('corrupt session');
      return AuthBloc(repository: repository);
    },
    act: (AuthBloc bloc) => bloc.add(const AuthSessionRestoreRequested()),
    expect: () => const <Object>[
      AuthState(status: AuthStatus.restoringSession),
      AuthState(
        status: AuthStatus.unauthenticated,
        message: 'The saved session could not be restored.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits field validation errors before sign in',
    build: () => AuthBloc(repository: repository),
    act: (AuthBloc bloc) => bloc.add(
      const AuthSignInSubmitted(username: '', password: ''),
    ),
    verify: (AuthBloc bloc) {
      expect(bloc.state.status, AuthStatus.validationFailure);
      expect(
        bloc.state.fieldErrors.keys,
        containsAll(<String>['username', 'password']),
      );
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits a user-safe failure for rejected login',
    build: () {
      repository.error = const Failure(
        message: 'The username or password is incorrect.',
        type: FailureType.unauthorized,
      );
      return AuthBloc(repository: repository);
    },
    act: (AuthBloc bloc) => bloc.add(
      const AuthSignInSubmitted(username: 'user', password: 'password'),
    ),
    expect: () => <Object>[
      const AuthState(status: AuthStatus.submitting),
      const AuthState(
        status: AuthStatus.failure,
        message: 'The username or password is incorrect.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'authenticates after a successful sign in',
    build: () {
      repository.signInResult = AuthResult(session: testSession);
      return AuthBloc(repository: repository);
    },
    act: (AuthBloc bloc) => bloc.add(
      const AuthSignInSubmitted(
        username: 'test_user',
        password: 'secure123',
      ),
    ),
    expect: () => <Object>[
      const AuthState(status: AuthStatus.submitting),
      AuthState(status: AuthStatus.authenticated, session: testSession),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'rejects sign-up when passwords do not match',
    build: () => AuthBloc(repository: repository),
    act: (AuthBloc bloc) => bloc.add(
      const AuthSignUpSubmitted(
        SignUpInput(
          firstName: 'Test',
          lastName: 'User',
          email: 'user@example.com',
          username: 'test_user',
          password: 'secure123',
          confirmPassword: 'different123',
          phone: '+31 20 123 4567',
          city: 'Amsterdam',
          street: 'Teststraat',
          streetNumber: 12,
          zipCode: '1000 AA',
        ),
      ),
    ),
    verify: (AuthBloc bloc) {
      expect(bloc.state.status, AuthStatus.validationFailure);
      expect(bloc.state.fieldErrors['confirmPassword'], 'Passwords do not match.');
    },
  );

  blocTest<AuthBloc, AuthState>(
    'clears the active session on logout',
    seed: () => AuthState(
      status: AuthStatus.authenticated,
      session: testSession,
    ),
    build: () => AuthBloc(repository: repository),
    act: (AuthBloc bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => const <Object>[
      AuthState(status: AuthStatus.unauthenticated),
    ],
    verify: (_) => expect(repository.signedOut, isTrue),
  );

  blocTest<AuthBloc, AuthState>(
    'creates an authenticated local session after valid sign-up',
    build: () {
      repository.signUpResult = AuthResult(session: testSession);
      return AuthBloc(repository: repository);
    },
    act: (AuthBloc bloc) => bloc.add(
      const AuthSignUpSubmitted(
        SignUpInput(
          firstName: 'Test',
          lastName: 'User',
          email: 'user@example.com',
          username: 'test_user',
          password: 'secure123',
          confirmPassword: 'secure123',
          phone: '+31 20 123 4567',
          city: 'Amsterdam',
          street: 'Teststraat',
          streetNumber: 12,
          zipCode: '1000 AA',
        ),
      ),
    ),
    expect: () => <Object>[
      const AuthState(status: AuthStatus.submitting),
      AuthState(status: AuthStatus.authenticated, session: testSession),
    ],
  );
}
