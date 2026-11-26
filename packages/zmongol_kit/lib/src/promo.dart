import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'account.dart';
import 'api_client.dart';
import 'config.dart';
import 'labels.dart';
import 'store.dart';

/// Sink for cross-promo events (`POST /promo/event`). The default sink
/// posts to the account service; hosts may inject their own (and tests
/// inject a recorder).
typedef ZmongolPromoEventSink = Future<void> Function({
  required String app,
  required String kind,
  required String target,
});

/// Cross-promotion between the family's apps, driven by the shared
/// catalogue.
///
/// Two surfaces:
///  - the permanent [MoreAppsSection] (Settings / About / home shelf),
///    which lists every recommended app — live ones with a Get action,
///    the rest as "Coming soon";
///  - the occasional card via [maybeShowPromoCard] — at most one per
///    [cardInterval], only for targets with a live link on this
///    platform, and never for a target the user dismissed with
///    "Don't show again" (persisted per target).
///
/// Impressions and taps are reported to the service as promo events.
class ZmongolPromo {
  final ZmongolConfig config;
  final ZmongolAccount? account;
  final Duration cardInterval;

  final ZmongolApiClient _api;
  final ZmongolKeyValueStore _store;
  final DateTime Function() _now;
  final ZmongolPromoEventSink? _eventSink;

  static const String _dismissedKey = 'zmongol_kit.promo.dismissed';
  static const String _lastCardKey = 'zmongol_kit.promo.last_card_at';

  ZmongolPromo({
    required this.config,
    this.account,
    String baseUrl = kZmongolDefaultBaseUrl,
    http.Client? httpClient,
    ZmongolKeyValueStore? store,
    DateTime Function()? now,
    this.cardInterval = const Duration(days: 3),
    this._eventSink,
  })  : _api = ZmongolApiClient(
          baseUrl: baseUrl,
          client: httpClient,
          tokenProvider: () async => await account?.accessToken(),
        ),
        _store = store ?? SharedPreferencesStore(),
        _now = now ?? DateTime.now;

  /// Every recommended target for the section — including ones that are
  /// still "Coming soon" on this platform.
  Future<List<ZmongolAppEntry>> sectionTargets(String currentAppId) =>
      config.recommendationsFor(currentAppId);

  /// The target an occasional card would promote: the first recommended
  /// app (catalogue order) that has a live link on [platform] and was
  /// not dismissed. Pure selection logic — also used by
  /// [maybeShowPromoCard].
  static ZmongolAppEntry? cardCandidate(
    ZmongolCatalogue catalogue,
    String currentAppId, {
    required String platform,
    Set<String> dismissed = const {},
  }) {
    for (final target in catalogue.recommendationsFor(currentAppId)) {
      if (dismissed.contains(target.id)) continue;
      if (target.linkFor(platform) == null) continue;
      return target;
    }
    return null;
  }

  /// The targets the user dismissed with "Don't show again" from inside
  /// [currentAppId].
  Future<Set<String>> dismissedFor(String currentAppId) async {
    try {
      final raw = await _store.getString(_dismissedKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded[currentAppId] is List) {
        return (decoded[currentAppId] as List)
            .map((e) => e.toString())
            .toSet();
      }
    } catch (_) {
      // Corrupt state reads as "nothing dismissed".
    }
    return {};
  }

  /// Permanently dismisses a target for the current app.
  Future<void> dismiss(String currentAppId, String targetId) async {
    final all = <String, List<String>>{};
    try {
      final raw = await _store.getString(_dismissedKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is List) {
              all[k.toString()] = v.map((e) => e.toString()).toList();
            }
          });
        }
      }
    } catch (_) {
      // Start over with an empty map.
    }
    final list = all.putIfAbsent(currentAppId, () => <String>[]);
    if (!list.contains(targetId)) list.add(targetId);
    await _store.setString(_dismissedKey, jsonEncode(all));
  }

  /// Fires a promo event; failures are swallowed — promotion must never
  /// break the host app.
  Future<void> reportEvent({
    required String app,
    required String kind,
    required String target,
  }) async {
    try {
      if (_eventSink != null) {
        await _eventSink(app: app, kind: kind, target: target);
        return;
      }
      await _api.post('/promo/event',
          jsonBody: {'app': app, 'kind': kind, 'target': target},
          auth: true);
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Opens a target's store page (firing the tap event first). Targets
  /// without a live, absolute link on this platform do nothing.
  Future<void> openTarget(
    String currentAppId,
    ZmongolAppEntry target, {
    String? platform,
  }) async {
    await reportEvent(app: currentAppId, kind: 'tap', target: target.id);
    final link = target.linkFor(platform ?? zmongolCurrentPlatform());
    if (link == null) return;
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler for the link: nothing more to do.
    }
  }

  /// Shows the occasional recommendation card when due.
  ///
  /// Returns true when a card was shown. A card is due when at least
  /// [cardInterval] passed since the last one and a suitable target
  /// exists (see [cardCandidate]). The impression is reported, the
  /// timestamp is recorded as the card appears, "Get" reports a tap and
  /// opens the store page, and "Don't show again" dismisses the target
  /// permanently for this app.
  Future<bool> maybeShowPromoCard(
    BuildContext context, {
    required String currentAppId,
    String? platform,
    ZmongolLabels labels = const ZmongolLabels(),
  }) async {
    final platformKey = platform ?? zmongolCurrentPlatform();
    try {
      final lastRaw = await _store.getString(_lastCardKey);
      final last = lastRaw == null ? null : DateTime.tryParse(lastRaw);
      if (last != null && _now().difference(last) < cardInterval) {
        return false;
      }
    } catch (_) {
      // Unreadable state: treat as never shown.
    }

    final ZmongolCatalogue catalogue;
    try {
      catalogue = await config.catalogue();
    } catch (_) {
      return false;
    }
    final dismissed = await dismissedFor(currentAppId);
    final candidate = cardCandidate(catalogue, currentAppId,
        platform: platformKey, dismissed: dismissed);
    if (candidate == null) return false;
    if (!context.mounted) return false;

    await _store.setString(_lastCardKey, _now().toIso8601String());
    await reportEvent(
        app: currentAppId, kind: 'impression', target: candidate.id);
    if (!context.mounted) return false;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ZmongolPromoCard(
          entry: candidate,
          labels: labels,
          onGet: () => Navigator.of(dialogContext).pop('get'),
          onNotNow: () => Navigator.of(dialogContext).pop('notnow'),
          onDontShowAgain: () =>
              Navigator.of(dialogContext).pop('never'),
        ),
      ),
    );
    if (action == 'get') {
      await openTarget(currentAppId, candidate, platform: platformKey);
    } else if (action == 'never') {
      await dismiss(currentAppId, candidate.id);
    }
    return true;
  }
}

/// The occasional recommendation card's content. Hosts that want their
/// own presentation can render this inside their own dialog/sheet, or
/// use [ZmongolPromo.maybeShowPromoCard] for the standard behaviour.
class ZmongolPromoCard extends StatelessWidget {
  final ZmongolAppEntry entry;
  final ZmongolLabels labels;
  final VoidCallback onGet;
  final VoidCallback onNotNow;
  final VoidCallback onDontShowAgain;

  const ZmongolPromoCard({
    super.key,
    required this.entry,
    this.labels = const ZmongolLabels(),
    required this.onGet,
    required this.onNotNow,
    required this.onDontShowAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labels.recommendedTitle,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
          Row(
            children: [
              ZmongolAppIconTile(entry: entry, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: theme.textTheme.titleMedium),
                    Text(entry.category.forLanguage(labels.languageCode),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(entry.intro.forLanguage(labels.languageCode),
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(onPressed: onNotNow, child: Text(labels.notNow)),
              TextButton(
                  onPressed: onDontShowAgain,
                  child: Text(labels.dontShowAgain)),
              FilledButton(onPressed: onGet, child: Text(labels.getApp)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The permanent "More Zmongol apps" section — drop it into Settings,
/// About, or a home shelf. Every recommended target is listed: live
/// ones carry the Get affordance, the rest read "Coming soon".
class MoreAppsSection extends StatelessWidget {
  final List<ZmongolAppEntry> targets;
  final ZmongolLabels labels;

  /// Platform key the links are resolved against ("ios", …).
  final String platform;
  final void Function(ZmongolAppEntry entry)? onTargetTap;

  const MoreAppsSection({
    super.key,
    required this.targets,
    this.labels = const ZmongolLabels(),
    required this.platform,
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(labels.moreAppsTitle,
              style: theme.textTheme.titleMedium),
        ),
        for (final entry in targets)
          ListTile(
            leading: ZmongolAppIconTile(entry: entry),
            title: Text(entry.name),
            subtitle: Text(
              entry.intro.forLanguage(labels.languageCode),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: entry.linkFor(platform) != null
                ? TextButton(
                    onPressed: () => onTargetTap?.call(entry),
                    child: Text(labels.getApp),
                  )
                : Text(labels.comingSoon,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
            onTap: entry.linkFor(platform) != null
                ? () => onTargetTap?.call(entry)
                : null,
          ),
      ],
    );
  }
}

/// A rounded square carrying the app's initial, in a colour derived
/// deterministically from its catalogue id — the kit ships no icon
/// assets, so this stands in for the real app icons.
class ZmongolAppIconTile extends StatelessWidget {
  final ZmongolAppEntry entry;
  final double size;

  const ZmongolAppIconTile({super.key, required this.entry, this.size = 44});

  static const List<Color> _palette = [
    Color(0xFF0272AB),
    Color(0xFF2E7D32),
    Color(0xFF6A4C93),
    Color(0xFFB26A00),
    Color(0xFF00695C),
    Color(0xFF8E2434),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[entry.id.hashCode.abs() % _palette.length];
    final initial =
        entry.name.isNotEmpty ? entry.name.characters.first : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
