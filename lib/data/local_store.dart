import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class LocalStore {
  static late Box _settings;
  static late Box _downloads;
  static late Box _cache;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox('settings');
    _downloads = await Hive.openBox('downloads');
    _cache = await Hive.openBox('cache');
  }

  static bool get offlineMode =>
      _settings.get('offlineMode', defaultValue: false) as bool;
  static set offlineMode(bool value) => _settings.put('offlineMode', value);

  static String get themeMode =>
      _settings.get('themeMode', defaultValue: 'system') as String;
  static set themeMode(String value) => _settings.put('themeMode', value);

  static List<int> get favoriteReciterIds =>
      (_settings.get('favorites', defaultValue: <int>[]) as List).cast<int>();

  static bool isFavoriteReciter(int reciterId) =>
      favoriteReciterIds.contains(reciterId);

  static Future<void> toggleFavoriteReciter(int reciterId) async {
    final list = favoriteReciterIds.toList();
    if (list.contains(reciterId)) {
      list.remove(reciterId);
    } else {
      list.add(reciterId);
    }
    await _settings.put('favorites', list);
  }

  static List<int> get favoriteRadioIds =>
      (_settings.get('radioFavorites', defaultValue: <int>[]) as List)
          .cast<int>();

  static Future<void> toggleFavoriteRadio(int radioId) async {
    final list = favoriteRadioIds.toList();
    if (list.contains(radioId)) {
      list.remove(radioId);
    } else {
      list.add(radioId);
    }
    await _settings.put('radioFavorites', list);
  }

  static String get storageLocation =>
      _settings.get('storageLocation', defaultValue: 'internal') as String;
  static set storageLocation(String value) =>
      _settings.put('storageLocation', value);

  static Future<void> saveRecitersCache(Map<String, dynamic> json) =>
      _cache.put('reciters', jsonEncode(json));

  static Map<String, dynamic>? get recitersCache {
    final raw = _cache.get('reciters') as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveRadiosCache(Map<String, dynamic> json) =>
      _cache.put('radios', jsonEncode(json));

  static Map<String, dynamic>? get radiosCache {
    final raw = _cache.get('radios') as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static String downloadKey(int moshafId, int surahNumber) =>
      '$moshafId-$surahNumber';

  static bool isDownloaded(int moshafId, int surahNumber) =>
      _downloads.containsKey(downloadKey(moshafId, surahNumber));

  static Map<dynamic, dynamic>? getDownload(int moshafId, int surahNumber) =>
      _downloads.get(downloadKey(moshafId, surahNumber))
          as Map<dynamic, dynamic>?;

  static Future<void> putDownload(
    int moshafId,
    int surahNumber,
    Map<String, dynamic> metadata,
  ) =>
      _downloads.put(downloadKey(moshafId, surahNumber), metadata);

  static Future<void> deleteDownload(int moshafId, int surahNumber) =>
      _downloads.delete(downloadKey(moshafId, surahNumber));

  static List<Map<dynamic, dynamic>> get allDownloads => _downloads.values
      .map((e) => Map<dynamic, dynamic>.from(e as Map))
      .toList();

  static Future<void> saveLastSession(Map<String, dynamic> json) =>
      _settings.put('lastSession', jsonEncode(json));

  static Map<String, dynamic>? get lastSession {
    final raw = _settings.get('lastSession') as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearLastSession() => _settings.delete('lastSession');
}
