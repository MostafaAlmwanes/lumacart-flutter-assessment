import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/auth/presentation/pages/sign_up_page.dart';
import '../../../helpers/fakes.dart';

void main() {
  testWidgets('shows field-level validation for an empty sign-up form', (
    WidgetTester tester,
  ) async {
    final AuthBloc bloc = AuthBloc(repository: FakeAuthRepository());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(home: SignUpPage()),
      ),
    );
    final Finder createAccount = find.widgetWithText(
      FilledButton,
      'Create account',
    );
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pump();

    expect(find.text('First name is required.'), findsOneWidget);
    expect(find.text('Last name is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Username is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Confirm your password.'), findsOneWidget);
    expect(find.text('Enter a valid street number.'), findsOneWidget);
  });
}
