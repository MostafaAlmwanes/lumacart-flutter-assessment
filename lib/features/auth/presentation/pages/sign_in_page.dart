import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/constants/app_constants.dart';
import 'package:lumacart/core/widgets/state_panels.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/auth/presentation/widgets/auth_scaffold.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to browse products and continue your saved carts.',
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (BuildContext context, AuthState state) {
          final bool submitting = state.status == AuthStatus.submitting;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!state.isAuthenticated && state.message != null) ...<Widget>[
                InlineNotice(message: state.message!, isError: true),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: _usernameController,
                enabled: !submitting,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.username],
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: state.fieldErrors['username'],
                ),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !submitting,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: state.fieldErrors['password'],
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: submitting ? null : _submit,
                child: AnimatedSwitcher(
                  duration:
                      reduceMotion ? Duration.zero : AppDurations.fast,
                  child: submitting
                      ? const SizedBox.square(
                          key: ValueKey<String>('loading'),
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Sign in',
                          key: ValueKey<String>('label'),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: submitting ? null : () => context.go('/sign-up'),
                child: const Text('Create an account'),
              ),
              const SizedBox(height: AppSpacing.lg),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Demo account'),
                subtitle: const Text('Fake Store API credentials'),
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.science_outlined),
                    title: const Text(AppConstants.demoUsername),
                    subtitle: const Text(AppConstants.demoPassword),
                    trailing: TextButton(
                      onPressed: () {
                        _usernameController.text = AppConstants.demoUsername;
                        _passwordController.text = AppConstants.demoPassword;
                      },
                      child: const Text('Use'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthSignInSubmitted(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
  }
}
