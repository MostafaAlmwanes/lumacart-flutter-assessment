import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/auth/presentation/pages/sign_in_page.dart';
import '../../../helpers/fakes.dart';

void main() {
  testWidgets('shows specific validation messages for empty login fields', (
    WidgetTester tester,
  ) async {
    final AuthBloc bloc = AuthBloc(repository: FakeAuthRepository());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(home: SignInPage()),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Username is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('password visibility control toggles obscureText', (
    WidgetTester tester,
  ) async {
    final AuthBloc bloc = AuthBloc(repository: FakeAuthRepository());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(home: SignInPage()),
      ),
    );
    TextField password = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password.obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    password = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password.obscureText, isFalse);
  });
}
