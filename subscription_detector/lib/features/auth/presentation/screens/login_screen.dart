import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.text('appName')),
        actions: [
          _LanguageMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  localizations.text('login'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.text('authSubtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: localizations.text('email'),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return localizations.text('requiredField');
                              }
                              if (!email.contains('@')) {
                                return localizations.text('invalidEmail');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !isLoading,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: localizations.text('password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return localizations.text('requiredField');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: isLoading ? null : _signInWithEmail,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.login),
                            label: Text(localizations.text('login')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : ref.read(authControllerProvider.notifier).signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: Text(localizations.text('signInWithGoogle')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : ref.read(authControllerProvider.notifier).signInWithApple,
                  icon: const Icon(Icons.apple),
                  label: Text(localizations.text('signInWithApple')),
                ),
                if (authState.hasError) ...[
                  const SizedBox(height: 14),
                  Text(
                    authState.error.toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(authControllerProvider.notifier).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}

class _LanguageMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);

    return PopupMenuButton<Locale>(
      tooltip: localizations.text('language'),
      icon: const Icon(Icons.language),
      initialValue: locale,
      onSelected: ref.read(localeControllerProvider.notifier).setLocale,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('ar'),
          child: Text(localizations.text('arabic')),
        ),
        PopupMenuItem(
          value: const Locale('en'),
          child: Text(localizations.text('english')),
        ),
      ],
    );
  }
}
