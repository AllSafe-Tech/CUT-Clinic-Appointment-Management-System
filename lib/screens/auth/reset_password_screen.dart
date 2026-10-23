import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      await ClinicService.sendPasswordResetCode(widget.email);
      if (!mounted) return;
      setState(() => _cooldown = 60);
      _startTimer();
      showInfo(context, 'A new code was sent to ${widget.email}.');
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ClinicService.resetPasswordWithCode(
        email: widget.email,
        code: _code.text,
        newPassword: _password.text,
      );
      navigator.popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(
        content: Text('Password updated. Log in with your new password.'),
      ));
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
                    const Center(child: CutLogo(height: 72)),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: const BoxDecoration(
                            color: CutColors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.vpn_key_rounded,
                            color: CutColors.gold, size: 34),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Reset password',
                        textAlign: TextAlign.center,
                        style: t.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800, color: CutColors.blue)),
                    const SizedBox(height: 8),
                    Text('Enter the code we emailed to ${widget.email} and choose a new password.',
                        textAlign: TextAlign.center,
                        style: t.textTheme.bodyMedium
                            ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Code from your email',
                        counterText: '',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      validator: (v) => RegExp(r'^\d{6,8}$').hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter the 6-digit code from the email',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'New password',
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
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(label: 'Reset password', busy: _busy, onPressed: _submit),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: (_busy || _cooldown > 0) ? null : _resend,
                      child: Text(_cooldown > 0
                          ? 'Resend code in ${_cooldown}s'
                          : 'Resend code'),
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