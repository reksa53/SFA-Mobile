import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../widgets/auth_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      return 'Email dan password wajib diisi';
    }
    if (!_email.text.contains('@')) return 'Format email tidak valid';
    return null;
  }

  void _submit() {
    setState(() => _error = _validate());
    if (_error != null) return;
    // TODO: AuthRepository.login(...), lalu arahkan sesuai role lewat router.
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Email',
            controller: _email,
            hint: 'xxxxx@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Password',
            controller: _password,
            hint: '••••••••',
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              icon: Icon(_hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.error),
          ],
          const SizedBox(height: 28),
          FilledButton(onPressed: _submit, child: const Text('LOGIN')),
        ],
      ),
    );
  }
}