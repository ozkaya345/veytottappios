import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifying = false;
  String? _message;

  String? _verificationId;
  int? _forceResendToken;

  bool get _supportsPhoneVerification {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  void _setMessage(String? value) {
    if (!mounted) return;
    setState(() {
      _message = value;
    });
  }

  Future<void> _changePassword() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Oturum bulunamadı',
        );
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-email',
          message:
              'Bu hesapta e-posta yok. Şifre değişimi için e-posta giriş gerekli.',
        );
      }

      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      if (currentPassword.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-password',
          message: 'Mevcut şifre boş olamaz',
        );
      }
      if (newPassword.trim().length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Yeni şifre en az 6 karakter olmalı',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      _setMessage('Şifre güncellendi');
    } on FirebaseAuthException catch (e) {
      _setMessage(e.message ?? 'İşlem başarısız');
    } catch (_) {
      _setMessage('Beklenmedik bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendResetEmail() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-email',
          message: 'Hesaba bağlı e-posta yok',
        );
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _setMessage('Şifre sıfırlama e-postası gönderildi');
    } on FirebaseAuthException catch (e) {
      _setMessage(e.message ?? 'İşlem başarısız');
    } catch (_) {
      _setMessage('Beklenmedik bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendSmsCode() async {
    if (!_supportsPhoneVerification) {
      _setMessage(
        'Telefon doğrulama şu an sadece Android/iOS üzerinde destekleniyor.',
      );
      return;
    }
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Oturum bulunamadı',
        );
      }

      final phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Telefon numarası boş olamaz',
        );
      }
      if (!phoneNumber.startsWith('+')) {
        throw FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Telefon numarasını ülke koduyla girin (örn. +90...)',
        );
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _forceResendToken,
        verificationCompleted: (credential) async {
          try {
            await user.linkWithCredential(credential);
            _setMessage('Telefon doğrulandı ve hesaba bağlandı');
          } on FirebaseAuthException catch (e) {
            _setMessage(e.message ?? 'Telefon bağlanamadı');
          } catch (_) {
            _setMessage('Beklenmedik bir hata oluştu');
          }
        },
        verificationFailed: (e) {
          _setMessage(e.message ?? 'SMS gönderilemedi');
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _forceResendToken = resendToken;
          });
          _setMessage('SMS kodu gönderildi');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } on FirebaseAuthException catch (e) {
      _setMessage(e.message ?? 'SMS gönderilemedi');
    } catch (_) {
      _setMessage('Beklenmedik bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _verifySmsCode() async {
    if (!_supportsPhoneVerification) {
      _setMessage(
        'Telefon doğrulama şu an sadece Android/iOS üzerinde destekleniyor.',
      );
      return;
    }
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Oturum bulunamadı',
        );
      }

      final verificationId = _verificationId;
      if (verificationId == null || verificationId.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-verification',
          message: 'Önce SMS kodu gönderin',
        );
      }

      final smsCode = _smsController.text.trim();
      if (smsCode.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-code',
          message: 'Kod boş olamaz',
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await user.linkWithCredential(credential);
      _setMessage('Telefon doğrulandı ve hesaba bağlandı');
    } on FirebaseAuthException catch (e) {
      _setMessage(e.message ?? 'Kod doğrulanamadı');
    } catch (_) {
      _setMessage('Beklenmedik bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final supportsPhoneVerification = _supportsPhoneVerification;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Güvenlik'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: supportsPhoneVerification
          ? ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _sendSmsCode,
                          icon: const Icon(Icons.sms),
                          label: _isVerifying
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('SMS Gönder'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _verifySmsCode,
                          icon: const Icon(Icons.verified),
                          label: _isVerifying
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Doğrula'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.75, 1.0],
                  colors: [
                    Colors.black,
                    primary.withValues(alpha: 0.35),
                    primary.withValues(alpha: 0.70),
                    primary,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Şifre Değiştir',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Mevcut Şifre',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Yeni Şifre',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _changePassword,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Güncelle'),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _sendResetEmail,
                                  child: const Text(
                                    'Şifre Sıfırlama E-postası Gönder',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_message != null) Text(_message!),
                            const Divider(height: 96),
                            Text(
                              '2FA (Telefon Doğrulama)',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              supportsPhoneVerification
                                  ? 'Telefon numaranızı doğrulayarak hesabınıza ek bir güvenlik katmanı ekleyin.'
                                  : 'Telefon doğrulama bu platformda desteklenmiyor (şimdilik sadece Android/iOS).',
                            ),
                            if (supportsPhoneVerification) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefon Numarası (örn. +90...)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _smsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'SMS Kod',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
