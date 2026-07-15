import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lumacart/app/app.dart';
import 'package:lumacart/app/di/app_dependencies.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final AppDependencies dependencies = await AppDependencies.initialize();
    runApp(LumaCartApp(dependencies: dependencies));
  } on Object {
    runApp(const _BootstrapFailureApp());
  }
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.storage_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'LumaCart could not open its local data.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Restart the app or retry. Your password and token are never shown here.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => unawaited(bootstrap()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
