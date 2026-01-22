import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/firebase_bootstrap.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.oobCode});

  final String oobCode;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  String? _emailHint;

  @override
  void initState() {
    super.initState();
    _prefetchEmailHint();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _prefetchEmailHint() async {
    try {
      await FirebaseBootstrap.init();
      final email = await FirebaseAuth.instance.verifyPasswordResetCode(
        widget.oobCode,
      );
      if (!mounted) return;
      setState(() => _emailHint = email);
    } catch (_) {
      // ignore: Eğer kod geçersizse submit sırasında da yakalanacak.
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final newPassword = _newPasswordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await FirebaseBootstrap.init();
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: newPassword,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre güncellendi. Giriş yapabilirsiniz.'),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final code = e.code;
      final message = switch (code) {
        'expired-action-code' => 'Bağlantının süresi dolmuş. Tekrar deneyin.',
        'invalid-action-code' => 'Bağlantı geçersiz. Tekrar deneyin.',
        'weak-password' => 'Şifre çok zayıf (en az 6 karakter).',
        _ => 'Şifre güncellenemedi: ${e.message ?? code}',
      };
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Şifre güncellenemedi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şifre'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.black,
                    Color.alphaBlend(
                      cs.primary.withValues(alpha: 0.35),
                      Colors.black,
                    ),
                    cs.primary.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: 420,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_emailHint != null) ...[
                          Text(
                            'Hesap: $_emailHint',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: cs.primary,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: cs.primary,
                              ),
                            ),
                            filled: true,
                            fillColor: Color.alphaBlend(
                              cs.primary.withValues(alpha: 0.06),
                              Colors.black,
                            ),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Şifre gerekli';
                            if (v.length < 6) return 'En az 6 karakter olmalı';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre (Tekrar)',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: cs.primary,
                            ),
                            filled: true,
                            fillColor: Color.alphaBlend(
                              cs.primary.withValues(alpha: 0.06),
                              Colors.black,
                            ),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Şifre gerekli';
                            if (v != _newPasswordController.text.trim()) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) =>
                              _isLoading ? null : _submit(),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Kaydet'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
