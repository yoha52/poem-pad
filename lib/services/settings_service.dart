import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/strings.dart';
import '../repositories/poem_repository.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyFontSize = 'settings_font_size';
  static const String _keyShowPills = 'settings_show_pills';
  static const String _keyDefaultSort = 'settings_default_sort';
  static const String _keyLanguage = 'settings_language';
  static const String _keyAccentIndex = 'settings_accent_index';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 16.0;
  bool _showSyllablePills = true;
  PoemSortOption _defaultSort = PoemSortOption.lastEdited;
  AppLanguage _language = AppLanguage.amharic;
  int _accentColorIndex = 0;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get showSyllablePills => _showSyllablePills;
  PoemSortOption get defaultSort => _defaultSort;
  AppLanguage get language => _language;
  AppStrings get strings => AppStrings(_language);
  int get accentColorIndex => _accentColorIndex;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_keyThemeMode) ?? 'system';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _fontSize = prefs.getDouble(_keyFontSize) ?? 16.0;
    _showSyllablePills = prefs.getBool(_keyShowPills) ?? true;
    _accentColorIndex = prefs.getInt(_keyAccentIndex) ?? 0;

    final sortIndex = prefs.getInt(_keyDefaultSort) ?? 0;
    if (sortIndex >= 0 && sortIndex < PoemSortOption.values.length) {
      _defaultSort = PoemSortOption.values[sortIndex];
    }

    final langStr = prefs.getString(_keyLanguage) ?? 'amharic';
    _language = langStr == 'english' ? AppLanguage.english : AppLanguage.amharic;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  Future<void> setShowSyllablePills(bool show) async {
    _showSyllablePills = show;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPills, show);
  }

  Future<void> setAccentColorIndex(int index) async {
    _accentColorIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentIndex, index);
  }

  Future<void> setDefaultSort(PoemSortOption sort) async {
    _defaultSort = sort;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultSort, sort.index);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang.name);
  }
}
