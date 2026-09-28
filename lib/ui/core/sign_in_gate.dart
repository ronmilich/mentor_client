import 'package:flutter/material.dart';
import '../../data/repositories/productivity_repository.dart';
import '../../data/services/api_client.dart';
import 'app_theme.dart';

class SignInGate extends StatefulWidget {
  const SignInGate({
    super.key,
    required this.repository,
    required this.title,
    required this.child,
  });
  final ProductivityRepository repository;
  final String title;
  final Widget child;
  @override
  State<SignInGate> createState() => _SignInGateState();
}

class _SignInGateState extends State<SignInGate> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.signIn(email.text, password.text);
      password.clear();
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ApiException
              ? e.message
              : 'Unable to sign in. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) {
      if (widget.repository.signedIn) return widget.child;
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                const FeatureBanner(
                  title: 'A little progress, every day.',
                  subtitle:
                      'Sign in to keep your tasks and reflections together.',
                  icon: Icons.auto_awesome,
                ),
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter your email.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: password,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter your password.'
                            : null,
                        onFieldSubmitted: (_) {
                          if (!busy) login();
                        },
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: busy ? null : login,
                        child: Text(busy ? 'Signing in…' : 'Sign in'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Nested pages stop displaying the previous account after sign-out.
class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.repository, required this.child});
  final ProductivityRepository repository;
  final Widget child;
  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late final owner = widget.repository.userId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) {
      if (widget.repository.signedIn && widget.repository.userId == owner) {
        return widget.child;
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Session ended')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Go back and sign in to continue.'),
          ),
        ),
      );
    },
  );
}
