import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/game_context/model/nearby_player.dart';
import 'package:memory_companion/features/game_context/repository/place_repository.dart';
import 'package:memory_companion/features/game_context/service/game_context_capturer.dart';
import 'package:memory_companion/features/game_context/service/location_source.dart';
import 'package:memory_companion/features/game_context/service/nearby_beacon.dart';
import 'package:memory_companion/features/game_context/service/nearby_radio.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';
import 'package:memory_companion/features/settings/repository/display_settings_repository.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

class _FakeLocation implements LocationSource {
  _FakeLocation(this.here);

  Coordinates? here;
  int reads = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Coordinates?> current() async {
    reads++;
    return here;
  }
}

class _FakeRadio implements NearbyRadio {
  _FakeRadio(this.heard);

  Set<String>? heard;
  int scans = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Set<String>?> scan(Duration duration) async {
    scans++;
    return heard;
  }

  @override
  Future<void> startAdvertising(String friendCode) async {}

  @override
  Future<void> stopAdvertising() async {}
}

void main() {
  late AppDatabase db;
  late PlaceRepository places;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    places = PlaceRepository(database: db);
  });

  tearDown(() => db.close());

  group('NearbyBeacon', () {
    test('el código de amigo viaja dentro del UUID y vuelve igual', () {
      final code = FriendCode.fromUid('ana-uid');
      final uuid = NearbyBeacon.uuidFor(code);
      expect(uuid, startsWith(NearbyBeacon.prefix));
      expect(uuid, hasLength(36));
      expect(NearbyBeacon.codeFrom(uuid.toUpperCase()), code);
    });

    test('ignora UUIDs de otras apps', () {
      expect(
        NearbyBeacon.codeFrom('0000180d-0000-1000-8000-00805f9b34fb'),
        isNull,
      );
      expect(
        NearbyBeacon.codeFrom('${NearbyBeacon.prefix}303030303030'),
        isNull,
        reason: '"000000" no es un código válido',
      );
    });
  });

  group('PlaceRepository', () {
    test('agrupa lo cercano y separa lo lejano', () async {
      final home = await places.resolve(18.47860, -69.93120);
      // A unos 50 m: la misma casa.
      expect(await places.resolve(18.47900, -69.93120), home);
      // A más de un kilómetro: otro lugar.
      final park = await places.resolve(18.49000, -69.93120);
      expect(park, isNot(home));

      await places.rename(park, '  Parque  ');
      final all = await places.readAll();
      expect([for (final p in all) p.name], [null, 'Parque']);

      await places.rename(park, ' ');
      expect((await places.readAll()).last.isNamed, isFalse);
    });
  });

  group('GameContextCapturer', () {
    GameContextCapturer capturer({
      required DisplayPreferences preferences,
      required _FakeLocation location,
      required _FakeRadio radio,
    }) => GameContextCapturer(
      preferences: () async => preferences,
      location: location,
      places: places,
      radio: radio,
      ownCode: () async => 'MEMEME',
      friendNamesByCode: () async => {'ANA234': 'Ana'},
      scanDuration: Duration.zero,
    );

    test('con todo apagado no toca la ubicación ni el Bluetooth', () async {
      final location = _FakeLocation((latitude: 1, longitude: 1));
      final radio = _FakeRadio({'ANA234'});
      final context = await capturer(
        preferences: DisplayPreferences.defaults,
        location: location,
        radio: radio,
      ).capture();

      expect(context.placeId, isNull);
      expect(context.nearby, isNull);
      expect(location.reads, 0);
      expect(radio.scans, 0);
    });

    test(
      'guarda el lugar y a quién había cerca, sin contarse a sí mismo',
      () async {
        final context = await capturer(
          preferences: const DisplayPreferences(
            contextLocation: true,
            contextNearby: true,
          ),
          location: _FakeLocation((latitude: 10, longitude: 10)),
          radio: _FakeRadio({'ZZZ234', 'MEMEME', 'ANA234'}),
        ).capture();

        expect(context.placeId, isNotNull);
        expect(context.nearby, const [
          NearbyPlayer(code: 'ANA234', name: 'Ana'),
          NearbyPlayer(code: 'ZZZ234'),
        ]);
      },
    );

    test('sin señal no inventa nada: null, no una lista vacía', () async {
      final context = await capturer(
        preferences: const DisplayPreferences(
          contextLocation: true,
          contextNearby: true,
        ),
        location: _FakeLocation(null),
        radio: _FakeRadio(null),
      ).capture();
      expect(context.placeId, isNull);
      expect(context.nearby, isNull);

      final alone = await capturer(
        preferences: const DisplayPreferences(contextNearby: true),
        location: _FakeLocation(null),
        radio: _FakeRadio({'MEMEME'}),
      ).capture();
      expect(alone.nearby, isEmpty, reason: 'buscó y no había nadie');
    });
  });

  test('el reporter guarda la partida con su contexto', () async {
    await DisplaySettingsRepository(database: db).setContextLocation(true);
    final stats = StatsRepository(database: db);
    final reporter = MinigameResultReporter(
      repository: stats,
      clock: () => DateTime(2026, 9, 24, 10),
      context: GameContextCapturer(
        preferences: () => DisplaySettingsRepository(database: db).read(),
        location: _FakeLocation((latitude: 5, longitude: 5)),
        places: places,
        radio: _FakeRadio(null),
        ownCode: () async => null,
        friendNamesByCode: () async => const {},
      ),
    );

    await reporter.report(
      const MemoryGameModule(),
      const MinigameResult(
        variantId: 'classic',
        itemCount: 6,
        itemsSolved: 6,
        attempts: 8,
        errors: 1,
        hintsUsed: 0,
        secondsElapsed: 40,
        timeLimitSeconds: 90,
        timed: true,
        won: true,
        score: 700,
      ),
    );

    final [game] = await stats.recentGames();
    expect(game.placeId, (await places.readAll()).single.id);
    expect(game.nearby, isNull);
    expect(game.date, DateTime(2026, 9, 24, 10));
  });
}
