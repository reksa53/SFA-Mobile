import 'dart:ui';

import 'package:dio/dio.dart';

import '../../../core/network/api_service.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_email.text.contains('@') || _password.text.isEmpty) {
      _showMessage('Email atau password belum benar');
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.instance.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on DioException catch (e) {
      _showMessage(_errorMessage(e));
    } catch (_) {
      _showMessage('Terjadi kesalahan, coba lagi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Email atau password salah';
      case 422:
        return e.response?.data['message'] ?? 'Data tidak valid';
      case null:
        return 'Tidak bisa terhubung ke server';
      default:
        return 'Server error (${e.response?.statusCode})';
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/core/constants/images/login_bg.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: const Alignment(0, 0.1),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Gmail :'),
                  _GlassField(
                    controller: _email,
                    hint: 'xxxxx@gmail.com',
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  const _Label('Password'),
                  _GlassField(
                    controller: _password,
                    hint: '12345678',
                    obscure: true,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.rose,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboard,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          onSubmitted: onSubmitted,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white24,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}
