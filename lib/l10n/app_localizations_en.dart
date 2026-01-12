// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginWelcomeTitle => 'Welcome!';

  @override
  String get loginEmailOrUsernameLabel => 'Email or Username';

  @override
  String get loginEmailOrUsernameRequired => 'Email/username is required';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get forgotPasswordSoon => 'Forgot password (coming soon)';

  @override
  String get signIn => 'Sign In';

  @override
  String get pleaseSignUpFirst => 'Please sign up first';

  @override
  String get emailNotFound => 'Email not found';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithGoogleTodo => 'Continue with Google (TODO)';

  @override
  String get noAccountQuestion => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get registerCreateAccountTitle => 'Create a New Account';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get emailAddressLabel => 'Email address';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get termsText =>
      'I have read and accept the Terms of Use and\nPrivacy Policy.';

  @override
  String get acceptTermsToContinue => 'Accept the terms to continue';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyMemberQuestion => 'Already a member?';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String get homeNewStatus => 'Add New Status';

  @override
  String get homeTrackStatus => 'Track Status';

  @override
  String get personnelTitle => 'Personnel';
}
