import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { es, en }

class LanguageNotifier extends StateNotifier<AppLanguage> {
  static const _key = 'app_language_code';

  LanguageNotifier() : super(AppLanguage.es) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'en') {
        state = AppLanguage.en;
      } else {
        state = AppLanguage.es;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, lang == AppLanguage.en ? 'en' : 'es');
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = state == AppLanguage.es ? AppLanguage.en : AppLanguage.es;
    await setLanguage(next);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class AppStrings {
  AppStrings._();

  static String tr(BuildContext context, WidgetRef ref, {required String es, required String en}) {
    final lang = ref.watch(languageProvider);
    return lang == AppLanguage.en ? en : es;
  }

  static String get(AppLanguage lang, {required String es, required String en}) {
    return lang == AppLanguage.en ? en : es;
  }
}
