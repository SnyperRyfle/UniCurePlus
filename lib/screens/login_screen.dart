import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_api.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/primary_button.dart';

/// V16 - Log masuk (Login)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Masukkan nama pengguna dan kata laluan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await AuthSession.instance.login(
        username: _userCtrl.text,
        password: _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.white, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('FindProcurement+',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Log masuk',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Akaun pembekal UiTM eProcurement',
                    style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                const SizedBox(height: AppSpacing.xl),
                LabeledField(
                  label: 'Pengguna',
                  child: TextField(
                    controller: _userCtrl,
                    decoration:
                        const InputDecoration(hintText: 'Nama pengguna'),
                  ),
                ),
                LabeledField(
                  label: 'Kata laluan',
                  child: TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Kata laluan',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _isSubmitting ? 'Sedang log masuk...' : 'Log masuk',
                  onPressed: _isSubmitting ? null : _login,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {},
                  child: const Text('Lupa kata laluan'),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {},
                  child: const Text('Daftar pembekal baharu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
