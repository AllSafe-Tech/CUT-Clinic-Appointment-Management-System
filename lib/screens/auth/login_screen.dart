import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onBack});

  /// Goes back to the Get Started page. When null no back arrow is shown.
  final VoidCallback? onBack;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ClinicService.signIn(_email.text.trim(), _password.text);
      // AuthGate swaps this screen out on success.
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final form = Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: CutLogo(height: 96)),
          const SizedBox(height: 16),
          Text('CUT Clinic',
              textAlign: TextAlign.center,
              style: t.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: CutColors.blue)),
          Text('Appointment Management System',
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => Validators.required(v, 'Password'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          LoadingButton(label: 'Log in', busy: _busy, onPressed: _submit),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?", style: t.textTheme.bodyMedium),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const RegisterScreen())),
                child: const Text('Register',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Central University of Technology, Free State',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline)),
        ],
      ),
    );

    return PopScope(
      // The phone's back button also returns to Get Started.
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBack?.call();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: form,
                  ),
                ),
              ),
              if (widget.onBack != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: CutColors.blue.withAlpha(20),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Back to Get Started',
                      onPressed: _busy ? null : widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, color: CutColors.blue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}