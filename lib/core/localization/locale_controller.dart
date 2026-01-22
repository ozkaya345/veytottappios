import 'package:flutter/widgets.dart';

import '../../data/services/local_locale_store.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> init() async {
    _locale = await LocalLocaleStore.loadLocale();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;

    if (locale == null) {
      await LocalLocaleStore.clearLocale();
    } else {
      await LocalLocaleStore.saveLocale(locale);
    }

    notifyListeners();
  }
}
