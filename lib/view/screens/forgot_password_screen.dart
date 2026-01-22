import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ottapp/l10n/app_localizations.dart';

import '../../core/navigation/app_routes.dart';
import '../../data/services/firebase_bootstrap.dart';
import '../../data/services/local_login_store.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  bool _isLoading = false;
  bool _hasActiveSession = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');

    // Eğer kullanıcı zaten giriş yaptıysa (uygulama hesabı "tanıyorsa"),
    // e-posta linki göndermeden doğrudan şifre değiştirme ekranına yönlendireceğiz.
    final currentUser = FirebaseAuth.instance.currentUser;
    _hasActiveSession = currentUser != null;
    if (_hasActiveSession) {
      final email = currentUser?.email?.trim();
      if ((email ?? '').isNotEmpty && _emailController.text.trim().isEmpty) {
        _emailController.text = email!;
      }
    }

    if (_emailController.text.trim().isEmpty) {
      _prefillRememberedEmail();
    }
  }

  Future<void> _prefillRememberedEmail() async {
    final email = await LocalLoginStore.loadRememberedEmail();
    if (!mounted) return;

    if (email != null && _emailController.text.trim().isEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _goToChangePassword() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseBootstrap.init();

      final user = FirebaseAuth.instance.currentUser;
      final typedEmail = _emailController.text.trim().toLowerCase();
      final userEmail = user?.email?.trim().toLowerCase();

      if (user == null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Güvenlik için önce giriş yapmalısın.')),
        );
        return;
      }

      // Oturum açık ama başka bir mail yazıldıysa güvenlik için engelleyelim.
      if ((userEmail ?? '').isNotEmpty && typedEmail != userEmail) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Bu işlem sadece giriş yapılan hesap için yapılabilir.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      nav.pushReplacementNamed(AppRoutes.security);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final onBackground = Colors.white.withValues(alpha: 0.82);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
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
                      primary.withValues(alpha: 0.35),
                      Colors.black,
                    ),
                    primary.withValues(alpha: 0.22),
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
                        Text(
                          _hasActiveSession
                              ? 'Hesabını tanıdık. Şifre değişikliği için devam et.'
                              : 'Güvenlik için şifre değiştirmek üzere önce giriş yapmalısın.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: onBackground),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          style: TextStyle(color: onBackground),
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            labelStyle: TextStyle(color: onBackground),
                            floatingLabelStyle: TextStyle(color: onBackground),
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: primary,
                            ),
                            filled: true,
                            fillColor: Color.alphaBlend(
                              primary.withValues(alpha: 0.06),
                              Colors.black,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primary.withValues(alpha: 0.35),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                width: 1.5,
                              ).copyWith(color: primary),
                            ),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return l10n.emailRequired;
                            if (!v.contains('@')) return l10n.enterValidEmail;
                            return null;
                          },
                          onFieldSubmitted: (_) =>
                              _isLoading ? null : _goToChangePassword(),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_hasActiveSession) {
                                    _goToChangePassword();
                                  } else {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed(AppRoutes.login);
                                  }
                                },
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
                              : Text(
                                  _hasActiveSession
                                      ? 'Şifre Değiştir'
                                      : l10n.signIn,
                                ),
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
