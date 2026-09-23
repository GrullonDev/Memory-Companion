import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    final created = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    // En la app estos oyentes son las pantallas; aquí hay que sostenerlos.
    created.listen(localPlayerProvider, (_, _) {});
    created.listen(walletControllerProvider, (_, _) {});
    return created;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = buildContainer();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Espera a que el saldo propague desde SQLite hasta el controlador.
  Future<int> waitForBalance(int expected) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final balance = container.read(walletControllerProvider).value;
      if (balance == expected) return balance!;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail(
      'el saldo nunca llegó a $expected '
      '(quedó en ${container.read(walletControllerProvider).value})',
    );
  }

  Future<int> readStoredCoins() async {
    final row = await db.select(db.playerProfiles).getSingle();
    return row.totalCoins;
  }

  test('un jugador nuevo empieza sin monedas', () async {
    await container.read(localPlayerProvider.future);
    expect(await container.read(walletControllerProvider.future), 0);
  });

  test('ganar monedas las escribe en disco, no solo en pantalla', () async {
    await container.read(localPlayerProvider.future);

    await container.read(walletControllerProvider.notifier).add(120);

    expect(await waitForBalance(120), 120);
    expect(await readStoredCoins(), 120, reason: 'quedó persistido');
  });

  test('gastar descuenta de verdad', () async {
    await container.read(localPlayerProvider.future);
    final wallet = container.read(walletControllerProvider.notifier);

    await wallet.add(200);
    await waitForBalance(200);

    expect(await wallet.spend(50), isTrue);

    expect(await waitForBalance(150), 150);
    expect(await readStoredCoins(), 150);
  });

  test('sin saldo suficiente no se gasta nada', () async {
    await container.read(localPlayerProvider.future);
    final wallet = container.read(walletControllerProvider.notifier);

    await wallet.add(30);
    await waitForBalance(30);

    expect(await wallet.spend(100), isFalse);

    expect(await readStoredCoins(), 30, reason: 'intacto');
  });

  test('un importe negativo se rechaza', () async {
    await container.read(localPlayerProvider.future);
    final wallet = container.read(walletControllerProvider.notifier);

    await wallet.add(50);
    await waitForBalance(50);

    expect(await wallet.spend(-10), isFalse);
    expect(await readStoredCoins(), 50);
  });

  test('el saldo sobrevive a cerrar y reabrir la app', () async {
    await container.read(localPlayerProvider.future);
    await container.read(walletControllerProvider.notifier).add(875);
    await waitForBalance(875);

    // Simula un arranque nuevo: contenedor distinto, misma base en disco.
    container.dispose();
    container = buildContainer();

    await container.read(localPlayerProvider.future);
    expect(await container.read(walletControllerProvider.future), 875);
  });
}
