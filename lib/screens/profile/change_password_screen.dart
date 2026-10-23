import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ClinicService.changePassword(
        currentPassword: _current.text,
        newPassword: _new.text,
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Password changed.')));
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: cutAppBar('Change password'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _current,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => Validators.required(v, 'Current password'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _new,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
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
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (v) =>
                          v != _new.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(label: 'Change password', busy: _busy, onPressed: _save),
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