import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sfa_mobile/data/services/api_client.dart';
import 'package:sfa_mobile/ui/manager/manager_shell.dart';
import 'package:sfa_mobile/ui/sales/sales_shell.dart';

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
  bool _loading = false;
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

  String _errorMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final serverMessage = data is Map ? data['message'] as String? : null;

    switch (status) {
      case 401:
        return 'Email atau password salah';
      case 403:
        return serverMessage ?? 'Akun tidak punya akses';
      case 422:
        return serverMessage ?? 'Data tidak valid';
      case 429:
        return 'Terlalu banyak percobaan, coba lagi sebentar';
      case null:
        return 'Tidak bisa terhubung ke server';
      default:
        return 'Server error ($status)';
    }
  }

  Future<void> _submit() async {
    if (_loading) return;

    final validationError = _validate();
    setState(() => _error = validationError);
    if (validationError != null) return;

    setState(() => _loading = true);
    try {
      final role = await ApiClient.instance.login(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;

      final Widget? tujuan = switch (role) {
        'manager' => const ManagerShell(),
        'sales' => const SalesShell(),
        _ => null,
      };

      if (tujuan == null) {
        // Jangan tinggalkan token untuk role yang tidak dikenali.
        await ApiClient.instance.logout();
        if (mounted) setState(() => _error = 'Role akun tidak dikenali');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => tujuan),
      );
    } on DioException catch (e) {
      if (mounted) setState(() => _error = _errorMessage(e));
    } catch (_) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan, coba lagi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.error),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('LOGIN'),
          ),
        ],
      ),
    );
  }
}