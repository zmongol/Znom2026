import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zmongol_kit/zmongol_kit.dart';

import 'fake_http.dart';

String fixtureJson() =>
    File('test/fixtures/config_apps.json').readAsStringSync();

ZmongolCatalogue craftedCatalogue() => ZmongolCatalogue.fromJson({
      'version': 1,
      'apps': [
        {
          'id': 'host',
          'name': 'Host',
          'category': {'en': 'Test', 'zh': '测试'},
          'intro': {'en': 'Host app.', 'zh': '主应用。'},
          'links': {'ios': 'https://example.com/host'},
          'minVersion': {'ios': '1.0.0'},
          'forceUpdate': false,
          // Recommends itself (bad server data), a link-less app, and a
          // live app — in that order.
          'recommendations': ['host', 'nolink', 'live'],
        },
        {
          'id': 'nolink',
          'name': 'NoLink',
          'category': {'en': 'Test', 'zh': '测试'},
          'intro': {'en': 'Not out yet.', 'zh': '尚未发布。'},
          'links': {'ios': null},
          'minVersion': {'ios': '1.0.0'},
          'forceUpdate': false,
          'recommendations': <String>[],
        },
        {
          'id': 'live',
          'name': 'Live',
          'category': {'en': 'Test', 'zh': '测试'},
          'intro': {'en': 'Out now.', 'zh': '已发布。'},
          'links': {'ios': 'https://example.com/live'},
          'minVersion': {'ios': '1.0.0'},
          'forceUpdate': false,
          'recommendations': <String>[],
        },
      ],
    });

ZmongolPromo promoWith(MemoryKeyValueStore store) {
  final config = ZmongolConfig(
    httpClient: FakeHttpClient(
        (request) async => jsonResponse(const {'version': 1, 'apps': []})),
    store: MemoryKeyValueStore(),
  );
  return ZmongolPromo(config: config, store: store);
}

void main() {
  group('card candidate selection (live fixture)', () {
    final catalogue = ZmongolCatalogue.parse(fixtureJson());

    test('skips targets with no live link on this platform', () {
      // Zmedee recommends Zocr first, but Zocr has no iOS link yet;
      // Znom does.
      final candidate = ZmongolPromo.cardCandidate(catalogue, 'zmedee',
          platform: 'ios');
      expect(candidate?.id, 'znom');
    });

    test('dismissed targets are excluded', () {
      final candidate = ZmongolPromo.cardCandidate(catalogue, 'zmedee',
          platform: 'ios', dismissed: {'znom'});
      expect(candidate, isNull);
    });

    test('first live recommendation wins', () {
      final candidate = ZmongolPromo.cardCandidate(catalogue, 'zmongol2',
          platform: 'ios');
      expect(candidate?.id, 'mongolian');
    });

    test('no live link anywhere → no card', () {
      // Zchat recommends the IME, whose Windows link is null.
      final candidate = ZmongolPromo.cardCandidate(catalogue, 'zchat',
          platform: 'windows');
      expect(candidate, isNull);
    });
  });

  group('selection rules (crafted catalogue)', () {
    final catalogue = craftedCatalogue();

    test('the section lists every target except the host itself', () {
      expect(catalogue.recommendationsFor('host').map((a) => a.id),
          ['nolink', 'live']);
    });

    test('the card skips link-less targets but the section keeps them',
        () {
      final candidate = ZmongolPromo.cardCandidate(catalogue, 'host',
          platform: 'ios');
      expect(candidate?.id, 'live');
      expect(
          catalogue
              .recommendationsFor('host')
              .map((a) => a.id)
              .contains('nolink'),
          isTrue);
    });

    test('dismissing the only live target leaves no card', () {
      final candidate = ZmongolPromo.cardCandidate(catalogue, 'host',
          platform: 'ios', dismissed: {'live'});
      expect(candidate, isNull);
    });
  });

  group('dismissal persistence', () {
    test('dismissed targets survive a fresh promo instance', () async {
      final store = MemoryKeyValueStore();
      final promo = promoWith(store);
      expect(await promo.dismissedFor('host'), isEmpty);

      await promo.dismiss('host', 'live');
      await promo.dismiss('host', 'nolink');
      await promo.dismiss('other', 'live');

      final fresh = promoWith(store);
      expect(await fresh.dismissedFor('host'), {'live', 'nolink'});
      expect(await fresh.dismissedFor('other'), {'live'});
    });
  });

  group('promo events', () {
    test('events go to the injected sink with app/kind/target', () async {
      final seen = <Map<String, String>>[];
      final promo = ZmongolPromo(
        config: ZmongolConfig(
          httpClient: FakeHttpClient((request) async =>
              jsonResponse(const {'version': 1, 'apps': []})),
          store: MemoryKeyValueStore(),
        ),
        store: MemoryKeyValueStore(),
        eventSink: ({required app, required kind, required target}) async {
          seen.add({'app': app, 'kind': kind, 'target': target});
        },
      );
      await promo.reportEvent(app: 'host', kind: 'tap', target: 'live');
      expect(seen, [
        {'app': 'host', 'kind': 'tap', 'target': 'live'}
      ]);
    });
  });
}
