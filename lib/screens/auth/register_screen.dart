import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/privacy.dart';
import '../../core/validators.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _number = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _agree = false;
  bool _agreeError = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _number, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy notice'),
        content: const SingleChildScrollView(child: Text(privacyNotice)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    if (!_agree) setState(() => _agreeError = true);
    if (!valid || !_agree) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final signedIn = await ClinicService.signUp(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        studentNumber: _number.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
      );
      navigator.popUntil((r) => r.isFirst);
      if (!signedIn) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Account created. Confirm your email, then log in.'),
        ));
      }
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
      appBar: cutAppBar('Create account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: t.colorScheme.primaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_outlined),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('For registered CUT students only. '
                                  'We collect only what is needed to manage your appointments.'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'First name'),
                      validator: (v) => Validators.required(v, 'First name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (v) => Validators.required(v, 'Last name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _number,
                      keyboardType: TextInputType.number,
                      maxLength: 9,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'CUT student number',
                        counterText: '',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: Validators.studentNumber,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Cell number (for SMS)',
                        hintText: '0821234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _agree,
                      onChanged: (v) => setState(() {
                        _agree = v ?? false;
                        _agreeError = false;
                      }),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('I agree to the '),
                          GestureDetector(
                            onTap: _showPrivacy,
                            child: Text('privacy notice',
                                style: TextStyle(
                                    color: t.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                    if (_agreeError)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text('Please accept the privacy notice to continue.',
                            style: TextStyle(color: t.colorScheme.error, fontSize: 12)),
                      ),
                    const SizedBox(height: 12),
                    LoadingButton(label: 'Register', busy: _busy, onPressed: _submit),
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