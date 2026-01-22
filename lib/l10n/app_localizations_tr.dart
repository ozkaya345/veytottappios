// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get loginWelcomeTitle => 'Hoş Geldiniz!';

  @override
  String get loginEmailOrUsernameLabel => 'E-posta veya Kullanıcı Adı';

  @override
  String get loginEmailOrUsernameRequired => 'E-posta/kullanıcı adı gerekli';

  @override
  String get rememberMe => 'Beni hatırla';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get forgotPassword => 'Şifremi Unuttum';

  @override
  String get forgotPasswordSoon =>
      'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get pleaseSignUpFirst => 'Önce kayıt olun';

  @override
  String get emailNotFound => 'E-posta bulunamadı';

  @override
  String get continueWithGoogle => 'Google ile Devam Et';

  @override
  String get continueWithGoogleTodo => 'Google ile devam et';

  @override
  String get noAccountQuestion => 'Hesabınız yok mu?';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get registerCreateAccountTitle => 'Yeni Bir Hesap Oluştur';

  @override
  String get fullNameLabel => 'Ad Soyad';

  @override
  String get fullNameRequired => 'Ad soyad gerekli';

  @override
  String get emailAddressLabel => 'E-posta Adresi';

  @override
  String get emailRequired => 'E-posta gerekli';

  @override
  String get enterValidEmail => 'Geçerli bir e-posta girin';

  @override
  String get termsText =>
      'Kullanım Şartları ve Gizlilik\nPolitikasını okudum, onaylıyorum.';

  @override
  String get acceptTermsToContinue => 'Devam etmek için şartları onaylayın';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get alreadyMemberQuestion => 'Zaten üye misiniz?';

  @override
  String get homeWelcome => 'Hoş geldiniz';

  @override
  String get homeNewStatus => 'Yeni Durum Ekle';

  @override
  String get homeTrackStatus => 'Trans Takip';

  @override
  String get personnelTitle => 'Personel';
}
