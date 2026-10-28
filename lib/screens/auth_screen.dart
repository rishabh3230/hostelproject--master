import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/hms_service.dart';
import '../widgets/live_list.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final login = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool admin = false, busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    login.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<SessionProvider>().signIn(
        admin: admin,
        login: login.text,
        password: password.text,
      );
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AutofillGroup(
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.apartment, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'IERT Hostel',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Hostel Management System',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Student')),
                      ButtonSegment(value: true, label: Text('Admin')),
                    ],
                    selected: {admin},
                    onSelectionChanged: busy
                        ? null
                        : (value) => setState(() {
                            admin = value.single;
                            error = null;
                            login.clear();
                          }),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: login,
                    enabled: !busy,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: admin ? 'Admin email' : 'Roll number',
                    ),
                    keyboardType: admin
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Required'
                        : admin && !v!.contains('@')
                        ? 'Enter your email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    enabled: !busy,
                    autofillHints: const [AutofillHints.password],
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                    onFieldSubmitted: (_) => submit(),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  if (!admin)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'First login: use your registered 10-digit contact number as your password.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PasswordScreen extends StatefulWidget {
  final bool forced;
  const PasswordScreen({super.key, this.forced = false});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Change password'),
      actions: [
        TextButton(
          onPressed: () => context.read<SessionProvider>().signOut(),
          child: const Text('Sign out'),
        ),
      ],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.forced)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Set a private password before accessing your hostel account.',
                    ),
                  ),
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) =>
                      v == null ||
                          v.length < 10 ||
                          v.length > 128 ||
                          !RegExp(r'[A-Za-z]').hasMatch(v) ||
                          !RegExp(r'[0-9]').hasMatch(v)
                      ? 'Use 10–128 characters with letters and digits'
                      : v == current.text
                      ? 'Choose a different password'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (v) =>
                      v != next.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                AsyncButton(
                  label: 'Change password and sign out',
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      await context.read<SessionProvider>().changePassword(
                        current.text,
                        next.text,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
