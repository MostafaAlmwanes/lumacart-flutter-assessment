import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/utils/validators.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/auth/domain/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class AuthSessionRestoreRequested extends AuthEvent {
  const AuthSessionRestoreRequested();
}

class AuthSignInSubmitted extends AuthEvent {
  const AuthSignInSubmitted({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => <Object?>[username];

  @override
  bool get stringify => false;
}

class AuthSignUpSubmitted extends AuthEvent {
  const AuthSignUpSubmitted(this.input);

  final SignUpInput input;

  @override
  List<Object?> get props => <Object?>[input];

  @override
  bool get stringify => false;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

enum AuthStatus {
  initial,
  restoringSession,
  unauthenticated,
  submitting,
  authenticated,
  validationFailure,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.message,
    this.warning,
    this.fieldErrors = const <String, String>{},
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? message;
  final String? warning;
  final Map<String, String> fieldErrors;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    bool clearSession = false,
    String? message,
    bool clearMessage = false,
    String? warning,
    bool clearWarning = false,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      message: clearMessage ? null : message ?? this.message,
      warning: clearWarning ? null : warning ?? this.warning,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        session,
        message,
        warning,
        fieldErrors,
      ];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState()) {
    on<AuthEvent>(
      _onEvent,
      transformer: _sequential<AuthEvent>(),
    );
  }

  final AuthRepository _repository;

  Future<void> _onEvent(AuthEvent event, Emitter<AuthState> emit) async {
    if (event is AuthSessionRestoreRequested) {
      await _onRestore(event, emit);
    } else if (event is AuthSignInSubmitted) {
      await _onSignIn(event, emit);
    } else if (event is AuthSignUpSubmitted) {
      await _onSignUp(event, emit);
    } else if (event is AuthLogoutRequested) {
      await _onLogout(event, emit);
    }
  }

  Future<void> _onRestore(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.restoringSession));
    try {
      final AuthSession? session = await _repository.restoreSession();
      if (session == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      emit(AuthState(status: AuthStatus.authenticated, session: session));
    } on Object {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'The saved session could not be restored.',
      ));
    }
  }

  Future<void> _onSignIn(
    AuthSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.submitting || state.isAuthenticated) return;

    final Map<String, String> errors = <String, String>{};
    final String? usernameError = Validators.required(event.username, 'Username');
    final String? passwordError = Validators.required(event.password, 'Password');
    if (usernameError != null) errors['username'] = usernameError;
    if (passwordError != null) errors['password'] = passwordError;
    if (errors.isNotEmpty) {
      emit(AuthState(
        status: AuthStatus.validationFailure,
        fieldErrors: errors,
      ));
      return;
    }

    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final AuthResult result = await _repository.signIn(
        username: event.username,
        password: event.password,
      );
      emit(AuthState(
        status: AuthStatus.authenticated,
        session: result.session,
        warning: result.warning,
      ));
    } on Failure catch (failure) {
      emit(AuthState(status: AuthStatus.failure, message: failure.message));
    } on Object {
      emit(const AuthState(
        status: AuthStatus.failure,
        message: 'Sign in could not be completed.',
      ));
    }
  }

  Future<void> _onSignUp(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.submitting || state.isAuthenticated) return;

    final Map<String, String> errors = _signUpErrors(event.input);
    if (errors.isNotEmpty) {
      emit(AuthState(
        status: AuthStatus.validationFailure,
        fieldErrors: errors,
      ));
      return;
    }

    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final AuthResult result = await _repository.signUp(event.input);
      emit(AuthState(
        status: AuthStatus.authenticated,
        session: result.session,
        warning: result.warning,
      ));
    } on Failure catch (failure) {
      emit(AuthState(status: AuthStatus.failure, message: failure.message));
    } on Object {
      emit(const AuthState(
        status: AuthStatus.failure,
        message: 'Account creation could not be completed.',
      ));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on Failure catch (failure) {
      emit(AuthState(
        status: AuthStatus.unauthenticated,
        message: failure.message,
      ));
    } on Object {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'The session could not be fully cleared.',
      ));
    }
  }

  Map<String, String> _signUpErrors(SignUpInput input) {
    final Map<String, String> errors = <String, String>{};
    void add(String key, String? message) {
      if (message != null) errors[key] = message;
    }

    add('firstName', Validators.required(input.firstName, 'First name'));
    add('lastName', Validators.required(input.lastName, 'Last name'));
    add('email', Validators.email(input.email));
    add('username', Validators.username(input.username));
    add('password', Validators.password(input.password));
    if (input.confirmPassword.isEmpty) {
      errors['confirmPassword'] = 'Confirm your password.';
    } else if (input.password != input.confirmPassword) {
      errors['confirmPassword'] = 'Passwords do not match.';
    }
    add('phone', Validators.phone(input.phone));
    add('city', Validators.required(input.city, 'City'));
    add('street', Validators.required(input.street, 'Street'));
    if (input.streetNumber <= 0) {
      errors['streetNumber'] = 'Enter a valid street number.';
    }
    add('zipCode', Validators.required(input.zipCode, 'ZIP code'));
    return errors;
  }
}

EventTransformer<Event> _sequential<Event>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
