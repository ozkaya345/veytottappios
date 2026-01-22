import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ottapp/l10n/app_localizations.dart';

import '../../core/navigation/app_routes.dart';
import '../../data/services/firebase_bootstrap.dart';
import '../../data/services/local_login_store.dart';
import '../../presentation/widgets/buttons/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedEmail();
  }

  Future<void> _restoreRememberedEmail() async {
    final enabled = await LocalLoginStore.isRememberEmailEnabled();
    final email = await LocalLoginStore.loadRememberedEmail();

    if (!mounted) return;

    setState(() {
      _rememberEmail = enabled;
      if (email != null) {
        _emailOrUsernameController.text = email;
      }
    });
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final onBackground = Colors.white.withValues(alpha: 0.82);
    final mutedText = Colors.white.withValues(alpha: 0.65);

    void showTodoSnack(String message) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, _, __) =>
                              const SizedBox(height: 72),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.loginWelcomeTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: onBackground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _emailOrUsernameController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          style: TextStyle(color: onBackground),
                          decoration: InputDecoration(
                            labelText: l10n.loginEmailOrUsernameLabel,
                            labelStyle: TextStyle(color: onBackground),
                            floatingLabelStyle: TextStyle(color: onBackground),
                            hintStyle: TextStyle(
                              color: onBackground.withValues(alpha: 0.7),
                            ),
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
                            if (v.isEmpty) {
                              return l10n.loginEmailOrUsernameRequired;
                            }
                            if (!v.contains('@')) {
                              return l10n.enterValidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          style: TextStyle(color: onBackground),
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            labelStyle: TextStyle(color: onBackground),
                            floatingLabelStyle: TextStyle(color: onBackground),
                            hintStyle: TextStyle(
                              color: onBackground.withValues(alpha: 0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primary,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: primary,
                              ),
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
                            if (value == null || value.isEmpty) {
                              return l10n.passwordRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox.adaptive(
                              value: _rememberEmail,
                              activeColor: primary,
                              onChanged: (v) async {
                                final next = v ?? false;
                                setState(() => _rememberEmail = next);
                                await LocalLoginStore.setRememberEmail(
                                  enabled: next,
                                  email: next
                                      ? _emailOrUsernameController.text
                                      : null,
                                );
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final next = !_rememberEmail;
                                  setState(() => _rememberEmail = next);
                                  await LocalLoginStore.setRememberEmail(
                                    enabled: next,
                                    email: next
                                        ? _emailOrUsernameController.text
                                        : null,
                                  );
                                },
                                child: Text(
                                  l10n.rememberMe,
                                  style: TextStyle(color: mutedText),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextActionButton(
                          label: l10n.forgotPassword,
                          onPressed: () {
                            final v = _emailOrUsernameController.text.trim();
                            final initialEmail = v.contains('@') ? v : '';
                            Navigator.of(context).pushNamed(
                              AppRoutes.forgotPassword,
                              arguments: initialEmail,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          label: l10n.signIn,
                          fullWidth: true,
                          height: 52,
                          onPressed: () async {
                            final isValid =
                                _formKey.currentState?.validate() ?? false;
                            if (!isValid) return;

                            final email = _emailOrUsernameController.text
                                .trim();
                            final password = _passwordController.text;

                            await LocalLoginStore.setRememberEmail(
                              enabled: _rememberEmail,
                              email: email,
                            );

                            try {
                              await FirebaseBootstrap.init();
                            } catch (e) {
                              showTodoSnack('Firebase başlatılamadı: $e');
                              return;
                            }

                            try {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.home);
                            } on FirebaseAuthException catch (e) {
                              final code = e.code;
                              if (code == 'user-not-found') {
                                showTodoSnack(l10n.emailNotFound);
                              } else if (code == 'wrong-password') {
                                showTodoSnack('Şifre yanlış');
                              } else if (code == 'invalid-email') {
                                showTodoSnack(l10n.enterValidEmail);
                              } else {
                                showTodoSnack(
                                  'Giriş başarısız: ${e.message ?? code}',
                                );
                              }
                            } catch (e) {
                              showTodoSnack('Giriş başarısız: $e');
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.noAccountQuestion,
                              style: TextStyle(color: mutedText),
                            ),
                            const SizedBox(width: 6),
                            TextActionButton(
                              label: l10n.signUp,
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.register),
                            ),
                          ],
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
