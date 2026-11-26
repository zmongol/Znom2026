import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zmongol_kit/zmongol_kit.dart';

import 'fake_http.dart';

String fixtureJson() =>
    File('test/fixtures/config_apps.json').readAsStringSync();

void main() {
  group('catalogue parsing (live fixture)', () {
    final catalogue = ZmongolCatalogue.parse(fixtureJson());

    test('parses all 11 apps', () {
      expect(catalogue.apps, hasLength(11));
      expect(catalogue.byId('zmongol2')?.name, 'Zmongol2');
      expect(catalogue.byId('zbook')?.name, 'ZmongolBook');
      expect(catalogue.byId('missing'), isNull);
    });

    test('intros carry EN, ZH and raw Z52 strings', () {
      final intro = catalogue.byId('zmongol2')!.intro;
      expect(intro.en, contains('text editor'));
      expect(intro.zh, isNotEmpty);
      expect(intro.z52, isNotNull);
      expect(intro.forLanguage('z52'), intro.z52);
      expect(intro.forLanguage('zh'), intro.zh);
      expect(intro.forLanguage('en'), intro.en);
    });

    test('links: live where live, null where coming soon', () {
      expect(catalogue.byId('zmongol2')!.linkFor('ios'),
          'https://apps.apple.com/app/id1636073062');
      expect(catalogue.byId('ime')!.linkFor('android'),
          'downloads/zmongol-ime-android.apk');
      expect(catalogue.byId('zcag')!.linkFor('ios'), isNull);
      expect(catalogue.byId('zchat')!.linkFor('android'), isNull);
    });

    test('recommendations resolve in catalogue order', () {
      expect(catalogue.recommendationsFor('zmedee').map((a) => a.id),
          ['zocr', 'znom']);
      expect(catalogue.recommendationsFor('ime').map((a) => a.id),
          ['zmongol2', 'mongolian']);
      expect(catalogue.recommendationsFor('unknown'), isEmpty);
    });
  });

  group('version gate', () {
    ZmongolCatalogue crafted({required bool force}) =>
        ZmongolCatalogue.fromJson({
          'version': 1,
          'apps': [
            {
              'id': 'host',
              'name': 'Host',
              'category': {'en': 'Test', 'zh': '测试'},
              'intro': {'en': 'A test app.', 'zh': '测试应用。'},
              'links': {'ios': null},
              'minVersion': {'ios': '2.0.0'},
              'forceUpdate': force,
              'recommendations': <String>[],
            },
          ],
        });

    test('below min with forceUpdate → forced', () {
      expect(crafted(force: true).updateRequired('host', 'ios', '1.9.9'),
          ZmongolUpdateStatus.forced);
    });

    test('below min without forceUpdate → recommended', () {
      expect(crafted(force: false).updateRequired('host', 'ios', '1.0.0'),
          ZmongolUpdateStatus.recommended);
    });

    test('at or above min → none', () {
      final c = crafted(force: true);
      expect(c.updateRequired('host', 'ios', '2.0.0'),
          ZmongolUpdateStatus.none);
      expect(c.updateRequired('host', 'ios', '2.1.3'),
          ZmongolUpdateStatus.none);
    });

    test('unknown app or platform → none', () {
      final c = crafted(force: true);
      expect(c.updateRequired('nope', 'ios', '0.0.1'),
          ZmongolUpdateStatus.none);
      expect(c.updateRequired('host', 'windows', '0.0.1'),
          ZmongolUpdateStatus.none);
    });

    test('fixture gate: all minimums are 1.0.0, not forced', () {
      final catalogue = ZmongolCatalogue.parse(fixtureJson());
      expect(catalogue.updateRequired('zmongol2', 'ios', '0.9.0'),
          ZmongolUpdateStatus.recommended);
      expect(catalogue.updateRequired('zmongol2', 'ios', '1.0.0'),
          ZmongolUpdateStatus.none);
    });

    test('compareVersions is numeric, not lexicographic', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(compareVersions('1.0.0+42', '1.0.0'), 0);
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });
  });

  group('config client caching', () {
    test('fresh cache avoids a second fetch; stale cache survives '
        'a failed refresh', () async {
      var fetches = 0;
      var fail = false;
      final client = FakeHttpClient((request) async {
        fetches++;
        if (fail) throw Exception('offline');
        return jsonResponse(
            Map<String, dynamic>.from(jsonDecode(fixtureJson()) as Map));
      });
      final config = ZmongolConfig(
        httpClient: client,
        store: MemoryKeyValueStore(),
        now: () => DateTime(2026, 11, 26, 12),
      );

      final first = await config.catalogue();
      expect(first.apps, hasLength(11));
      expect(fetches, 1);

      final second = await config.catalogue();
      expect(second.apps, hasLength(11));
      expect(fetches, 1, reason: 'fresh cache must not refetch');

      fail = true;
      final third = await config.catalogue(forceRefresh: true);
      expect(third.apps, hasLength(11),
          reason: 'stale cache is the offline fallback');
      expect(fetches, 2);
    });
  });
}
