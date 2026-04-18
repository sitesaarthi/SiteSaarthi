import 'package:flutter/material.dart';

class AppLocale extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(String langCode) {
    _locale = Locale(langCode);
    notifyListeners();
  }
}
 