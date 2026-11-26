import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'store.dart';

/// A short text in the family's languages. The catalogue carries EN and
/// 中文 for every field, plus Z52 for intros. The kit never renders Z52
/// itself — [forLanguage] simply hands the raw string to the host app,
/// which owns Z52 rendering.
class ZmongolLocalizedText {
  final String en;
  final String zh;
  final String? z52;

  const ZmongolLocalizedText({required this.en, required this.zh, this.z52});

  factory ZmongolLocalizedText.fromJson(Map<String, dynamic> json) =>
      ZmongolLocalizedText(
        en: json['en']?.toString() ?? '',
        zh: json['zh']?.toString() ?? '',
        z52: json['z52']?.toString(),
      );

  /// The text for a language code: "en", "zh" or "z52" (falling back to
  /// English when a field has no Z52 form).
  String forLanguage(String languageCode) {
    switch (languageCode) {
      case 'zh':
        return zh;
      case 'z52':
        return z52 ?? en;
      default:
        return en;
    }
  }
}

/// One app in the shared catalogue (`GET /config/apps`).
class ZmongolAppEntry {
  /// Catalogue id, e.g. "zmongol2", "ime", "zchat".
  final String id;
  final String name;
  final ZmongolLocalizedText category;
  final ZmongolLocalizedText intro;

  /// Store / download link per platform ("ios", "android", "macos",
  /// "windows"); null means coming soon on that platform.
  final Map<String, String?> links;

  /// Minimum supported version per platform — the version gate.
  final Map<String, String> minVersion;

  /// When true, a build below [minVersion] must update before use;
  /// when false, the update is only recommended.
  final bool forceUpdate;

  /// Catalogue ids this app recommends, in priority order.
  final List<String> recommendations;

  const ZmongolAppEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.intro,
    this.links = const {},
    this.minVersion = const {},
    this.forceUpdate = false,
    this.recommendations = const [],
  });

  factory ZmongolAppEntry.fromJson(Map<String, dynamic> json) {
    Map<String, String?> links = {};
    final rawLinks = json['links'];
    if (rawLinks is Map) {
      rawLinks.forEach(
          (k, v) => links[k.toString()] = v?.toString());
    }
    Map<String, String> minVersion = {};
    final rawMin = json['minVersion'];
    if (rawMin is Map) {
      rawMin.forEach(
          (k, v) => minVersion[k.toString()] = v?.toString() ?? '0.0.0');
    }
    return ZmongolAppEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category'] is Map
          ? ZmongolLocalizedText.fromJson(
              Map<String, dynamic>.from(json['category'] as Map))
          : const ZmongolLocalizedText(en: '', zh: ''),
      intro: json['intro'] is Map
          ? ZmongolLocalizedText.fromJson(
              Map<String, dynamic>.from(json['intro'] as Map))
          : const ZmongolLocalizedText(en: '', zh: ''),
      links: links,
      minVersion: minVersion,
      forceUpdate: json['forceUpdate'] == true,
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// The store link for a platform, or null when coming soon there.
  String? linkFor(String platform) => links[platform];
}

/// The parsed app catalogue.
class ZmongolCatalogue {
  final int version;
  final String? updatedAt;
  final List<ZmongolAppEntry> apps;

  const ZmongolCatalogue(
      {this.version = 0, this.updatedAt, this.apps = const []});

  factory ZmongolCatalogue.fromJson(Map<String, dynamic> json) {
    final rawApps = json['apps'];
    return ZmongolCatalogue(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt']?.toString(),
      apps: rawApps is List
          ? rawApps
              .whereType<Map>()
              .map((a) =>
                  ZmongolAppEntry.fromJson(Map<String, dynamic>.from(a)))
              .toList()
          : const [],
    );
  }

  static ZmongolCatalogue parse(String jsonString) =>
      ZmongolCatalogue.fromJson(
          Map<String, dynamic>.from(jsonDecode(jsonString) as Map));

  ZmongolAppEntry? byId(String id) {
    for (final app in apps) {
      if (app.id == id) return app;
    }
    return null;
  }

  /// The resolved recommendation targets for an app, in the catalogue's
  /// priority order. The app itself is never included, even if the
  /// server data lists it.
  List<ZmongolAppEntry> recommendationsFor(String appId) {
    final self = byId(appId);
    if (self == null) return const [];
    final result = <ZmongolAppEntry>[];
    for (final targetId in self.recommendations) {
      if (targetId == appId) continue;
      final target = byId(targetId);
      if (target != null) result.add(target);
    }
    return result;
  }

  /// The version gate for one app + platform.
  ZmongolUpdateStatus updateRequired(
      String appId, String platform, String currentVersion) {
    final entry = byId(appId);
    if (entry == null) return ZmongolUpdateStatus.none;
    final min = entry.minVersion[platform];
    if (min == null) return ZmongolUpdateStatus.none;
    if (compareVersions(currentVersion, min) >= 0) {
      return ZmongolUpdateStatus.none;
    }
    return entry.forceUpdate
        ? ZmongolUpdateStatus.forced
        : ZmongolUpdateStatus.recommended;
  }
}

/// Result of the version gate in [ZmongolCatalogue.updateRequired].
enum ZmongolUpdateStatus { none, recommended, forced }

/// Compares dotted version strings numerically ("1.10.0" > "1.9.0").
/// Build suffixes ("+12") are ignored. Returns a negative number when
/// [a] is older, 0 when equal, a positive number when [a] is newer.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a);
  final pb = parts(b);
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

/// The platform key used by the catalogue for the current device:
/// "ios" (iPhone and iPad), "android", "macos" or "windows".
String zmongolCurrentPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.windows:
      return 'windows';
    default:
      return 'ios';
  }
}

/// Client for `GET /config/apps`, with an on-device cache.
///
/// The catalogue is cached in shared_preferences for 24 hours; a fresh
/// cache is served without network, and a stale cache is used when a
/// refresh fails (offline). Call [catalogue] once at startup, then use
/// the synchronous helpers ([recommendationsFor], [updateRequired])
/// against the loaded value.
class ZmongolConfig {
  final ZmongolApiClient _api;
  final ZmongolKeyValueStore _store;
  final Duration freshness;
  final DateTime Function() _now;

  static const String _cacheKey = 'zmongol_kit.config_json';
  static const String _cacheAtKey = 'zmongol_kit.config_fetched_at';

  ZmongolCatalogue? _loaded;

  ZmongolConfig({
    String baseUrl = kZmongolDefaultBaseUrl,
    http.Client? httpClient,
    ZmongolKeyValueStore? store,
    this.freshness = const Duration(hours: 24),
    DateTime Function()? now,
  })  : _api = ZmongolApiClient(baseUrl: baseUrl, client: httpClient),
        _store = store ?? SharedPreferencesStore(),
        _now = now ?? DateTime.now;

  /// The most recently loaded catalogue, if any.
  ZmongolCatalogue? get loadedCatalogue => _loaded;

  /// Loads the catalogue: fresh cache first, network second, stale
  /// cache as the offline fallback. Throws only when there is no cache
  /// at all and the fetch fails.
  Future<ZmongolCatalogue> catalogue({bool forceRefresh = false}) async {
    final cached = await _readCache();
    if (!forceRefresh &&
        cached != null &&
        _now().difference(cached.fetchedAt) < freshness) {
      return _loaded = cached.catalogue;
    }
    try {
      final response = await _api.get('/config/apps', auth: false);
      if (response.statusCode != 200) {
        throw ZmongolApiException(
            response.statusCode, 'Could not load the app catalogue',
            body: response.body);
      }
      final parsed = ZmongolCatalogue.parse(response.body);
      await _writeCache(response.body);
      return _loaded = parsed;
    } catch (_) {
      if (cached != null) return _loaded = cached.catalogue;
      rethrow;
    }
  }

  /// Resolved recommendation targets for the host app.
  Future<List<ZmongolAppEntry>> recommendationsFor(String appId) async =>
      (await catalogue()).recommendationsFor(appId);

  /// The version gate for the host app on a platform.
  Future<ZmongolUpdateStatus> updateRequired(
          String appId, String platform, String currentVersion) async =>
      (await catalogue()).updateRequired(appId, platform, currentVersion);

  Future<({ZmongolCatalogue catalogue, DateTime fetchedAt})?>
      _readCache() async {
    try {
      final raw = await _store.getString(_cacheKey);
      final at = await _store.getString(_cacheAtKey);
      if (raw == null || at == null) return null;
      final fetchedAt = DateTime.tryParse(at);
      if (fetchedAt == null) return null;
      return (catalogue: ZmongolCatalogue.parse(raw), fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String raw) async {
    try {
      await _store.setString(_cacheKey, raw);
      await _store.setString(_cacheAtKey, _now().toIso8601String());
    } catch (_) {
      // Caching is best-effort.
    }
  }
}
