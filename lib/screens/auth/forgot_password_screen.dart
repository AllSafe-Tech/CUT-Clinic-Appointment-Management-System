import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final email = _email.text.trim();
    try {
      await ClinicService.sendPasswordResetCode(email);
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)),
      );
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CutColors.blue,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: CutLogo(height: 80)),
                    const SizedBox(height: 28),
                    Text('Forgot password?',
                        style: t.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800, color: CutColors.blue)),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the email you registered with. We will send you a '
                      'one-time code to reset your password.',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(label: 'Send reset code', busy: _busy, onPressed: _send),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Back to log in'),
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
}