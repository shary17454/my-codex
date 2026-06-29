import 'package:ask_people/app/di/providers.dart';
import 'package:ask_people/features/auth/presentation/controllers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@askpeople.local');
  final _passwordController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isDemoMode = ref.watch(firebaseInitializationErrorProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isDemoMode) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('وضع تجربة محلي: لن يتم الاتصال بـ Firebase.'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'أدخل البريد الإلكتروني';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('دخول'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('إنشاء حساب جديد'),
            ),
            if (state.hasError && !isDemoMode) ...[
              const SizedBox(height: 12),
              Text(
                'تعذر تسجيل الدخول. تحقق من البيانات وحاول مرة أخرى.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isDemoMode = ref.read(firebaseInitializationErrorProvider) != null;
    if (isDemoMode) {
      context.go('/interests');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/interests');
    }
  }
}
