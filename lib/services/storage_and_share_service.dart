import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageAndShareService {
  static const String _favsKey = 'bd_epaper_favorites';
  static const String _lastReadKey = 'bd_epaper_last_read';
  static const String _themeModeKey = 'bd_epaper_theme_mode';

  static Future<Set<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favsKey);
      if (list != null) {
        return list.toSet();
      }
    } catch (_) {}
    return {};
  }

  static Future<void> setFavorites(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favsKey, ids.toList());
    } catch (_) {}
  }

  static Future<String?> getLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastReadKey);
    } catch (_) {}
    return null;
  }

  static Future<void> setLastRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastReadKey, id);
    } catch (_) {}
  }

  static Future<String> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeModeKey) ?? 'system';
    } catch (_) {}
    return 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode);
    } catch (_) {}
  }

  static Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
}
