import 'package:lumacart/features/auth/domain/auth_models.dart';

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthResult> signIn({
    required String username,
    required String password,
  });

  Future<AuthResult> signUp(SignUpInput input);

  Future<StoreUser> getUser(int id);

  Future<void> signOut();
}
