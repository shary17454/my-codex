import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_session.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  String? _error;
  bool _obscureLogin = true;
  bool _obscureRegister = true;

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    super.dispose();
  }

  String _dioMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        if (message is List) return message.map((e) => e.toString()).join('\n');
        return message.toString();
      }
      if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
        return 'تعذّر الاتصال بالخادم';
      }
      return 'فشل الطلب (${error.response?.statusCode ?? 'بدون رمز'})';
    }
    return error.toString();
  }

  Future<void> _submitLogin() async {
    setState(() => _error = null);
    final email = _loginEmail.text.trim();
    final password = _loginPassword.text;
    if (email.isEmpty || password.length < 8) {
      setState(() => _error = 'أدخل بريدًا صحيحًا وكلمة مرور من 8 أحرف على الأقل');
      return;
    }
    try {
      await ref.read(authSessionProvider.notifier).login(email: email, password: password);
      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _dioMessage(error));
    }
  }

  Future<void> _submitRegister() async {
    setState(() => _error = null);
    final name = _registerName.text.trim();
    final email = _registerEmail.text.trim();
    final password = _registerPassword.text;
    if (name.isEmpty || email.isEmpty || password.length < 8) {
      setState(() => _error = 'أكمل الاسم والبريد وكلمة مرور من 8 أحرف على الأقل');
      return;
    }
    try {
      await ref.read(authSessionProvider.notifier).register(
            email: email,
            password: password,
            displayName: name,
          );
      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _dioMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الحساب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: auth.isAuthenticated ? _LoggedInView(auth: auth) : _buildForms(auth.loading),
      ),
    );
  }

  Widget _buildForms(bool loading) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'تسجيل الدخول'),
            Tab(text: 'إنشاء حساب'),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _AuthForm(
                loading: loading,
                onSubmit: _submitLogin,
                submitLabel: 'دخول',
                children: [
                  TextField(
                    controller: _loginEmail,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _loginPassword,
                    obscureText: _obscureLogin,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
                        icon: Icon(_obscureLogin ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                ],
              ),
              _AuthForm(
                loading: loading,
                onSubmit: _submitRegister,
                submitLabel: 'إنشاء حساب',
                children: [
                  TextField(
                    controller: _registerName,
                    decoration: const InputDecoration(labelText: 'الاسم الظاهر', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _registerEmail,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _registerPassword,
                    obscureText: _obscureRegister,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureRegister = !_obscureRegister),
                        icon: Icon(_obscureRegister ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.children,
    required this.onSubmit,
    required this.submitLabel,
    required this.loading,
  });

  final List<Widget> children;
  final VoidCallback onSubmit;
  final String submitLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...children,
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(submitLabel),
        ),
      ],
    );
  }
}

class _LoggedInView extends ConsumerWidget {
  const _LoggedInView({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = auth.user?.displayName?.isNotEmpty == true ? auth.user!.displayName! : 'مستخدم رواية';
    final email = auth.user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(name.isNotEmpty ? String.fromCharCode(name.runes.first) : 'ر', style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 16),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(email, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => context.go('/home'),
            child: const Text('متابعة إلى الرئيسية'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).logout();
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
