import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/widgets/state_panels.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/auth/presentation/widgets/auth_scaffold.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{
    for (final String field in <String>[
      'firstName',
      'lastName',
      'email',
      'username',
      'password',
      'confirmPassword',
      'phone',
      'city',
      'street',
      'streetNumber',
      'zipCode',
    ])
      field: TextEditingController(),
  };
  bool _obscurePassword = true;

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create account',
      subtitle:
          'Your account stays available on this device, even after restarting the app.',
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (BuildContext context, AuthState state) {
          final bool submitting = state.status == AuthStatus.submitting;
          return AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.status == AuthStatus.failure &&
                    state.message != null) ...<Widget>[
                  InlineNotice(message: state.message!, isError: true),
                  const SizedBox(height: AppSpacing.md),
                ],
                LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    final bool stack = constraints.maxWidth < 420 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final Widget firstName = _field(
                      state,
                      keyName: 'firstName',
                      label: 'First name',
                      icon: Icons.badge_outlined,
                      enabled: !submitting,
                      autofillHints: const <String>[AutofillHints.givenName],
                    );
                    final Widget lastName = _field(
                      state,
                      keyName: 'lastName',
                      label: 'Last name',
                      icon: Icons.badge_outlined,
                      enabled: !submitting,
                      autofillHints: const <String>[AutofillHints.familyName],
                    );
                    if (stack) {
                      return Column(
                        children: <Widget>[
                          firstName,
                          const SizedBox(height: AppSpacing.md),
                          lastName,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: firstName),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: lastName),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _field(
                  state,
                  keyName: 'email',
                  label: 'Email',
                  icon: Icons.email_outlined,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                _field(
                  state,
                  keyName: 'username',
                  label: 'Username',
                  icon: Icons.person_outline,
                  enabled: !submitting,
                  autofillHints: const <String>[AutofillHints.newUsername],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _controllers['password'],
                  enabled: !submitting,
                  obscureText: _obscurePassword,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: state.fieldErrors['password'],
                    suffixIcon: IconButton(
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
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
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _controllers['confirmPassword'],
                  enabled: !submitting,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: state.fieldErrors['confirmPassword'],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _field(
                  state,
                  keyName: 'phone',
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  enabled: !submitting,
                  keyboardType: TextInputType.phone,
                  autofillHints: const <String>[AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _field(
                  state,
                  keyName: 'street',
                  label: 'Street',
                  icon: Icons.home_outlined,
                  enabled: !submitting,
                  autofillHints: const <String>[
                    AutofillHints.streetAddressLine1,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    final bool stack = constraints.maxWidth < 420 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final Widget streetNumber = _field(
                      state,
                      keyName: 'streetNumber',
                      label: 'Number',
                      icon: Icons.numbers,
                      enabled: !submitting,
                      keyboardType: TextInputType.number,
                    );
                    final Widget zipCode = _field(
                      state,
                      keyName: 'zipCode',
                      label: 'ZIP code',
                      icon: Icons.local_post_office_outlined,
                      enabled: !submitting,
                      autofillHints: const <String>[AutofillHints.postalCode],
                    );
                    if (stack) {
                      return Column(
                        children: <Widget>[
                          streetNumber,
                          const SizedBox(height: AppSpacing.md),
                          zipCode,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: streetNumber),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(flex: 2, child: zipCode),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _field(
                  state,
                  keyName: 'city',
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  enabled: !submitting,
                  autofillHints: const <String>[AutofillHints.addressCity],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: submitting ? null : () => context.go('/sign-in'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    AuthState state, {
    required String keyName,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) {
    return TextField(
      controller: _controllers[keyName],
      enabled: enabled,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        errorText: state.fieldErrors[keyName],
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final int number =
        int.tryParse(_controllers['streetNumber']!.text.trim()) ?? 0;
    context.read<AuthBloc>().add(
          AuthSignUpSubmitted(
            SignUpInput(
              firstName: _controllers['firstName']!.text,
              lastName: _controllers['lastName']!.text,
              email: _controllers['email']!.text,
              username: _controllers['username']!.text,
              password: _controllers['password']!.text,
              confirmPassword: _controllers['confirmPassword']!.text,
              phone: _controllers['phone']!.text,
              city: _controllers['city']!.text,
              street: _controllers['street']!.text,
              streetNumber: number,
              zipCode: _controllers['zipCode']!.text,
            ),
          ),
        );
  }
}
