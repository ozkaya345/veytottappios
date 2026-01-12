import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ottapp/l10n/app_localizations.dart';

import '../../data/services/firebase_bootstrap.dart';
import '../../core/navigation/app_routes.dart';
import '../../presentation/widgets/buttons/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
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

    void showSnack(String message) {
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
                          l10n.registerCreateAccountTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: onBackground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _fullNameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          style: TextStyle(color: onBackground),
                          decoration: InputDecoration(
                            labelText: l10n.fullNameLabel,
                            labelStyle: TextStyle(color: onBackground),
                            floatingLabelStyle: TextStyle(color: onBackground),
                            hintStyle: TextStyle(
                              color: onBackground.withValues(alpha: 0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
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
                            if (value == null || value.trim().isEmpty) {
                              return l10n.fullNameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: TextStyle(color: onBackground),
                          decoration: InputDecoration(
                            labelText: l10n.emailAddressLabel,
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
                            if (v.isEmpty) return l10n.emailRequired;
                            if (!v.contains('@')) return l10n.enterValidEmail;
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
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
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (v) =>
                                  setState(() => _acceptedTerms = v ?? false),
                              side: BorderSide(
                                color: primary.withValues(alpha: 0.6),
                              ),
                              activeColor: primary,
                              checkColor: Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  l10n.termsText,
                                  style: TextStyle(
                                    color: onBackground.withValues(alpha: 0.9),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: l10n.createAccount,
                          fullWidth: true,
                          height: 52,
                          onPressed: () async {
                            final isValid =
                                _formKey.currentState?.validate() ?? false;
                            if (!isValid) return;
                            if (!_acceptedTerms) {
                              showSnack(l10n.acceptTermsToContinue);
                              return;
                            }

                            try {
                              await FirebaseBootstrap.init();
                            } catch (e) {
                              showSnack('Firebase başlatılamadı: $e');
                              return;
                            }

                            final fullName = _fullNameController.text.trim();
                            final email = _emailController.text.trim();
                            final password = _passwordController.text;

                            try {
                              final cred = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );

                              await cred.user?.updateDisplayName(
                                fullName.isEmpty ? null : fullName,
                              );

                              final uid = cred.user?.uid;
                              if (uid != null) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                        'fullName': fullName,
                                        'email': email,
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));
                                } catch (_) {}
                              }

                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.home);
                            } on FirebaseAuthException catch (e) {
                              final code = e.code;
                              if (code == 'email-already-in-use') {
                                showSnack('Bu e-posta zaten kayıtlı');
                              } else if (code == 'invalid-email') {
                                showSnack(l10n.enterValidEmail);
                              } else if (code == 'weak-password') {
                                showSnack('Şifre çok zayıf (en az 6 karakter)');
                              } else {
                                showSnack(
                                  'Kayıt başarısız: ${e.message ?? code}',
                                );
                              }
                            } catch (e) {
                              showSnack('Kayıt başarısız: $e');
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.alreadyMemberQuestion,
                              style: TextStyle(color: mutedText),
                            ),
                            const SizedBox(width: 6),
                            TextActionButton(
                              label: l10n.signIn,
                              onPressed: () => Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.login),
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
