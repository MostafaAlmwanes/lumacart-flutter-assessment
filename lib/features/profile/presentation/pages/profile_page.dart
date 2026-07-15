import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthSession? session = context.select<AuthBloc, AuthSession?>(
      (AuthBloc bloc) => bloc.state.session,
    );
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final StoreUser user = session.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Center(
            child: Semantics(
              image: true,
              label: '${user.displayName} avatar',
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: const AssetImage(
                  'assets/generated/avatar_placeholder.png',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '@${user.username}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email.isEmpty ? 'Not provided' : user.email,
          ),
          _ProfileTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user.phone.isEmpty ? 'Not provided' : user.phone,
          ),
          _ProfileTile(
            icon: Icons.home_outlined,
            label: 'Address',
            value: user.address.formatted.isEmpty
                ? 'Not provided'
                : user.address.formatted,
          ),
          const SizedBox(height: AppSpacing.lg),
          ExpansionTile(
            title: const Text('Developer details'),
            leading: const Icon(Icons.developer_mode_outlined),
            children: <Widget>[
              ListTile(
                title: const Text('Account source'),
                subtitle: Text(
                  session.accountType == AccountType.api
                      ? 'Fake Store API account'
                      : 'Locally registered account',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => unawaited(_confirmLogout(context)),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text('Your current and saved carts remain on this device.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
