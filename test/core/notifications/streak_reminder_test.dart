import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/core/notifications/reminder_notifier.dart';
import 'package:memory_companion/core/notifications/streak_reminder_controller.dart';
import 'package:memory_companion/core/notifications/streak_reminder_plan.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  group('StreakReminderPlanner', () {
    List<PlannedReminder> plan(String? last, int streak, DateTime now) =>
        StreakReminderPlanner.plan(
          lastPlayedDate: last,
          currentStreak: streak,
          now: now,
        );

    test('sin haber jugado nunca: invitaciones desde esta noche', () {
      final reminders = plan(null, 0, DateTime(2026, 9, 29, 10));
      expect(reminders, hasLength(3));
      expect(reminders.first.at, DateTime(2026, 9, 29, 20));
      expect(
        reminders.map((r) => r.kind),
        everyElement(ReminderKind.dailyInvite),
      );
      expect(reminders.map((r) => r.id), [1, 2, 3]);
    });

    test('jugó ayer: esta noche la racha está en peligro', () {
      final reminders = plan('2026-09-28', 5, DateTime(2026, 9, 29, 10));
      expect(reminders.first.kind, ReminderKind.streakAtRisk);
      expect(reminders.first.streak, 5);
      expect(reminders.first.at, DateTime(2026, 9, 29, 20));
      expect(reminders.first.kind.route, RoutePaths.dailyChallenge);
    });

    test('jugó hoy: esta noche no hay nada, mañana sí', () {
      final reminders = plan('2026-09-29', 5, DateTime(2026, 9, 29, 10));
      expect(reminders.first.at, DateTime(2026, 9, 30, 20));
      expect(reminders.first.kind, ReminderKind.streakAtRisk);
      expect(reminders.first.streak, 5);
      // Pasado mañana la racha ya se rompió: solo una invitación.
      expect(reminders[1].kind, ReminderKind.dailyInvite);
    });

    test('pasadas las 20:00 la primera es mañana', () {
      final reminders = plan('2026-09-28', 5, DateTime(2026, 9, 29, 21));
      expect(reminders.first.at, DateTime(2026, 9, 30, 20));
      expect(
        reminders.first.kind,
        ReminderKind.dailyInvite,
        reason: 'si no juega hoy, mañana la racha ya estará rota',
      );
    });

    test('tras varios días sin jugar, el mensaje invita a volver al mapa', () {
      final reminders = plan('2026-09-20', 0, DateTime(2026, 9, 29, 10));
      expect(reminders.map((r) => r.kind), everyElement(ReminderKind.comeBack));
      expect(reminders.first.kind.route, RoutePaths.levelMap);
    });

    test('con el reloj hacia atrás no programa nada y termina', () {
      expect(plan('2027-01-01', 3, DateTime(2026, 9, 29, 10)), isEmpty);
    });
  });

  group('StreakReminderController', () {
    late AppDatabase db;
    late ProviderContainer container;
    late _FakeNotifier notifier;
    late DateTime now;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      notifier = _FakeNotifier();
      now = DateTime(2026, 9, 29, 10);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerRepositoryProvider.overrideWith(
            (ref) => PlayerRepository(
              database: db,
              syncQueue: SyncQueue(database: db),
              clock: () => now,
            ),
          ),
          reminderNotifierProvider.overrideWithValue(notifier),
          reminderClockProvider.overrideWithValue(() => now),
          reminderLanguageProvider.overrideWithValue(() => 'en'),
        ],
      );
      container.listen(streakReminderControllerProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<List<ReminderMessage>> nextSchedule(int calls) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (notifier.scheduled.length < calls) {
        if (DateTime.now().isAfter(deadline)) fail('nunca se reprogramó');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return notifier.scheduled.last;
    }

    test(
      'al arrancar programa y el aviso que abrió la app queda pendiente',
      () async {
        notifier.launchPayload = RoutePaths.levelMap;
        await container.read(localPlayerProvider.future);
        await container.read(streakReminderControllerProvider.notifier).start();

        final first = await nextSchedule(1);
        expect(first.first.title, '🧠 Your daily challenge is waiting');
        expect(first.first.payload, RoutePaths.dailyChallenge);
        expect(
          container.read(pendingNotificationRouteProvider),
          RoutePaths.levelMap,
        );
      },
    );

    test('jugar hoy reprograma: esta noche se cancela', () async {
      final player = await container.read(localPlayerProvider.future);
      await container.read(streakReminderControllerProvider.notifier).start();
      final before = await nextSchedule(1);
      expect(before.first.at, DateTime(2026, 9, 29, 20));

      await container
          .read(playerRepositoryProvider)
          .registerPlayedToday(localId: player.localId);

      final after = await nextSchedule(2);
      expect(after.first.at, DateTime(2026, 9, 30, 20));
      expect(after.first.title, '🔥 Your 1-day streak is at risk!');
    });

    test('un toque solo acepta rutas conocidas', () async {
      await container.read(localPlayerProvider.future);
      await container.read(streakReminderControllerProvider.notifier).start();

      notifier.onTap!('/board/solo');
      expect(container.read(pendingNotificationRouteProvider), isNull);

      notifier.onTap!(RoutePaths.dailyChallenge);
      expect(
        container.read(pendingNotificationRouteProvider),
        RoutePaths.dailyChallenge,
      );
    });
  });
}

class _FakeNotifier implements ReminderNotifier {
  String? launchPayload;
  ValueChanged<String?>? onTap;
  final scheduled = <List<ReminderMessage>>[];

  @override
  Future<String?> initialize({required ValueChanged<String?> onTap}) async {
    this.onTap = onTap;
    return launchPayload;
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> replaceAll(
    List<ReminderMessage> reminders, {
    required String channelName,
  }) async {
    scheduled.add(reminders);
  }
}
