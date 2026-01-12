import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  // 2FA - Telefon doğrulama alanları
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  String? _verificationId;
  int? _forceResendToken;
  bool _isVerifying = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
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
          message: 'Hesaba bağlı e-posta yok',
        );
      }
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());
      setState(() {
        _message = 'Şifre başarıyla güncellendi';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'İşlem başarısız';
      });
    } catch (_) {
      setState(() {
        _message = 'Beklenmedik bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSmsCode() async {
    setState(() {
      _isVerifying = true;
      _message = null;
    });
    try {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-phone',
          message: 'Telefon numarası boş olamaz',
        );
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _forceResendToken,
        verificationCompleted: (credential) async {
          // Otomatik doğrulama durumunda doğrudan bağlayabiliriz.
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              await user.linkWithCredential(credential);
              setState(() {
                _message = 'Telefon doğrulandı ve hesaba bağlandı';
              });
            } catch (_) {}
          }
          setState(() => _isVerifying = false);
        },
        verificationFailed: (e) {
          setState(() {
            _message = e.message ?? 'Doğrulama başarısız';
            _isVerifying = false;
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _forceResendToken = resendToken;
            _message = 'SMS kodu gönderildi';
            _isVerifying = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          setState(() => _isVerifying = false);
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'İşlem başarısız';
        _isVerifying = false;
      });
    } catch (_) {
      setState(() {
        _message = 'Beklenmedik bir hata oluştu';
        _isVerifying = false;
      });
    }
  }

  Future<void> _verifySmsCode() async {
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
      if (_verificationId == null) {
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
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      // MFA için resmi API desteği yoksa linkWithCredential ile bağlarız.
      await user.linkWithCredential(credential);
      setState(() {
        _message = 'Telefon doğrulandı ve hesaba bağlandı';
        _isVerifying = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'Kod doğrulanamadı';
        _isVerifying = false;
      });
    } catch (_) {
      setState(() {
        _message = 'Beklenmedik bir hata oluştu';
        _isVerifying = false;
      });
    }
  }

  Future<void> _sendResetEmail() async {
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
      setState(() {
        _message = 'Şifre sıfırlama e-postası gönderildi';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message ?? 'İşlem başarısız';
      });
    } catch (_) {
      setState(() {
        _message = 'Beklenmedik bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Güvenlik'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Şifre Değiştir', style: theme.textTheme.titleLarge),
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
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
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
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _isLoading ? null : _sendResetEmail,
                          child: const Text('Şifre Sıfırlama E-postası Gönder'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_message != null) Text(_message!),
                    const Divider(height: 32),
                    Text(
                      '2FA (Telefon Doğrulama)',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Telefon numaranızı doğrulayarak hesabınıza ek bir güvenlik katmanı ekleyin.',
                    ),
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
                    Row(
                      children: [
                        ElevatedButton.icon(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _smsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'SMS Kod',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _verifySmsCode,
                          icon: const Icon(Icons.verified),
                          label: const Text('Doğrula'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
