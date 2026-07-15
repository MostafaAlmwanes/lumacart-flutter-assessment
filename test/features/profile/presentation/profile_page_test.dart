import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/profile/presentation/pages/profile_page.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  testWidgets('renders signed-in profile data without token or password', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository()
      ..restoredSession = testSession;
    final AuthBloc bloc = AuthBloc(repository: repository)
      ..add(const AuthSessionRestoreRequested());
    await bloc.stream.firstWhere((AuthState state) => state.isAuthenticated);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pump();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('@test_user'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);
    expect(find.textContaining('password'), findsNothing);
  });
}
