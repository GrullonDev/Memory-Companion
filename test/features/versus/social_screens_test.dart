import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/repository/social_repository.dart';
import 'package:memory_companion/features/friends/widget/invite_friends_card.dart';
import 'package:memory_companion/features/friends/widget/social_network_card.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/game_context/service/nearby_radio.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/duel_page.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';
import 'package:memory_companion/features/versus/widget/duel_presence_bar.dart';
import 'package:memory_companion/features/versus/widget/opponent_mirror.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_screen.dart';
import 'package:memory_companion/features/versus/repository/duel_repository.dart';
import 'package:memory_companion/features/versus/versus_screen.dart';

final _alice = PlayerProfile(
  localId: 'local-alice',
  cloudUid: 'alice',
  displayName: 'Alice',
  avatarSeed: 0,
  totalXp: 1200,
  totalCoins: 50,
  gamesWon: 3,
  totalMoves: 40,
  currentStreak: 1,
  longestStreak: 2,
  lastPlayedDate: null,
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
  version: 1,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await FlutterLocalization.instance.ensureInitialized();
    FlutterLocalization.instance.init(
      mapLocales: const [
        MapLocale('es', AppLocale.es),
        MapLocale('en', AppLocale.en),
      ],
      initLanguageCode: 'en',
    );
  });

  late SocialRepository social;
  late DuelRepository duels;

  setUp(() {
    final firestore = FakeFirebaseFirestore();
    social = SocialRepository(firestore: firestore);
    duels = DuelRepository(firestore: firestore);
  });

  Future<void> publish(String uid, String name) => social.publishProfile(
    uid: uid,
    displayName: name,
    avatarSeed: 0,
    level: 1,
    totalXp: 800,
    friendCode: FriendCode.fromUid(uid),
  );

  Future<void> befriend(String uid, String name) async {
    await publish(uid, name);
    await social.sendRequest(from: 'alice', to: uid);
    await social.sendRequest(from: uid, to: 'alice');
  }

  /// Lets Firestore's fake streams deliver, then draws a few frames.
  /// Not `pumpAndSettle`: the Versus cards float forever.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps [home] with Alice as the local player. The duel route is a
  /// placeholder, so starting a duel does not deal a real board.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    String? uid = 'alice',
  }) async {
    // Tall, so nothing the tests tap sits under the bottom navigation.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPlayerProvider.overrideWith((ref) => Stream.value(_alice)),
          socialUidProvider.overrideWith((ref) async => uid),
          socialRepositoryProvider.overrideWithValue(social),
          duelRepositoryProvider.overrideWithValue(duels),
          duelRandomProvider.overrideWithValue(Random(1)),
          versusOnlineProvider.overrideWithValue(true),
          nearbyRadioProvider.overrideWithValue(_SilentRadio()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          home: home,
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(
              body: Text(
                settings.name == RoutePaths.duel
                    ? 'duel:${(settings.arguments as Duel).opponentUid}'
                    : '${settings.name}',
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('Versus sin cuenta invita a crearla; la Tienda no aparece', (
    tester,
  ) async {
    await pump(tester, const VersusScreen(), uid: null);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Opponent'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget, reason: 'se juega sin cuenta');
    expect(find.text('Versus'), findsOneWidget, reason: 'pestaña Versus');
    expect(find.text('Shop'), findsNothing, reason: 'la Tienda está oculta');
  });

  testWidgets('Versus contra un amigo: iniciar el duelo abre el tablero', (
    tester,
  ) async {
    await tester.runAsync(() => befriend('bob', 'Bob'));
    await pump(tester, const VersusScreen());

    expect(find.text('Bob'), findsOneWidget);
    await tester.tap(find.text('PLAY'));
    await settle(tester);
    await tester.tap(find.text('Find an online opponent'));
    await settle(tester);

    expect(find.text('duel:bob'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Versus sin amigos muestra el oponente por encontrar', (
    tester,
  ) async {
    await pump(tester, const VersusScreen());
    expect(find.text('Opponent'), findsOneWidget);
    expect(find.text('Go to Friends'), findsNothing);
    expect(find.text('PLAY'), findsOneWidget);
  });

  // La pantalla de Amigos entera no se monta: su cabecera usa google_fonts,
  // que en un test intenta descargar la fuente y falla sin red. Se prueba la
  // tarjeta con la lista, que es donde está la interacción.
  testWidgets('Amigos: aceptar, retar y agregar por código', (tester) async {
    Friend friend(String uid, String name, FriendRelation relation) => Friend(
      uid: uid,
      friendshipId: 'alice_$uid',
      name: name,
      status: FriendStatus.online,
      relation: relation,
    );
    final accepted = <String>[];
    final challenged = <String>[];
    final added = <String>[];

    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        home: Scaffold(
          body: ListView(
            children: [
              InviteFriendsCard(friendCode: FriendCode.fromUid('alice')),
              SocialNetworkCard(
                state: FriendsState(
                  uid: 'alice',
                  friendCode: FriendCode.fromUid('alice'),
                  friends: [friend('bob', 'Bob', FriendRelation.friend)],
                  incoming: [friend('carol', 'Carol', FriendRelation.incoming)],
                  outgoing: [friend('dave', 'Dave', FriendRelation.outgoing)],
                ),
                onAdd: (code) async {
                  added.add(code);
                  return true;
                },
                onAccept: (f) => accepted.add(f.uid),
                onRemove: (_) {},
                onChallenge: (f) => challenged.add(f.uid),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final code = FriendCode.fromUid('alice');
    expect(
      find.byWidgetPredicate((w) => w is SelectableText && w.data == code),
      findsOneWidget,
    );
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(find.byTooltip('Accept'));
    await tester.tap(find.byTooltip('Challenge'));
    expect(accepted, ['carol']);
    expect(challenged, ['bob']);

    await tester.enterText(find.byType(TextField), 'ab-c 12');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'ABC12',
      reason: 'solo letras y números',
    );
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(added, ['ABC12']);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('la serie se sigue en vivo hasta la victoria', (tester) async {
    const mine = DuelScore(score: 640, seconds: 52, moves: 11);
    const theirs = DuelScore(score: 500, seconds: 40, moves: 10);
    late Duel duel;
    await tester.runAsync(() async {
      await befriend('bob', 'Bob');
      duel = await duels.create(
        challengerUid: 'bob',
        opponentUid: 'alice',
        friendshipId: 'alice_bob',
        seed: 9,
        categoryId: GameCategories.classic.id,
        languageCode: 'en',
        game: DuelGame.digits,
      );
      for (var round = 0; round < 3; round++) {
        await duels.submitRound(
          duelId: duel.id,
          uid: 'alice',
          round: round,
          score: mine,
        );
      }
    });
    await pump(tester, DuelPage(duel: duel));

    expect(find.text('Waiting for Bob'), findsOneWidget);
    expect(find.text('Has not played yet'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);

    // Bob juega mientras Alice mira: su avance aparece ronda a ronda.
    await tester.runAsync(
      () => duels.submitRound(
        duelId: duel.id,
        uid: 'bob',
        round: 0,
        score: theirs,
      ),
    );
    await settle(tester);
    expect(find.text('1 - 0'), findsOneWidget);
    expect(find.text('Played 1 of 3 rounds'), findsOneWidget);

    await tester.runAsync(
      () => duels.submitRound(
        duelId: duel.id,
        uid: 'bob',
        round: 1,
        score: theirs,
      ),
    );
    await settle(tester);
    expect(find.text('Victory!'), findsOneWidget);
    expect(find.text('2 - 0'), findsOneWidget);
    expect(find.text('Rematch'), findsOneWidget);
    expect(find.text('Not needed'), findsOneWidget, reason: 'ronda 3');
  });

  testWidgets('jugar una ronda la muestra bajo el cara a cara', (tester) async {
    late Duel duel;
    await tester.runAsync(() async {
      await befriend('bob', 'Bob');
      duel = await duels.create(
        challengerUid: 'alice',
        opponentUid: 'bob',
        friendshipId: 'alice_bob',
        seed: 9,
        categoryId: GameCategories.classic.id,
        languageCode: 'en',
        game: DuelGame.digits,
      );
    });
    await pump(tester, DuelPage(duel: duel));
    expect(find.text('Duel in progress'), findsOneWidget);

    await tester.tap(find.text('Play round 1'));
    await settle(tester);

    expect(find.byType(DuelPresenceBar), findsOneWidget);
    expect(find.text('Round 1 of 3'), findsOneWidget);
    expect(find.byType(DigitsScreen), findsOneWidget);
    expect(find.byType(OpponentMirror), findsOneWidget);
    expect(find.text('Not playing right now'), findsOneWidget);

    // Bob acierta en su teléfono: Alice lo ve al instante en el suyo.
    await tester.runAsync(
      () => duels.reportProgress(
        duelId: duel.id,
        uid: 'bob',
        progress: const DuelProgress(
          round: 0,
          score: 30,
          solved: 1,
          total: 5,
          event: DuelEvent.hit,
          seq: 1,
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Bob got one right!'), findsOneWidget);
    expect(find.text('30 pts'), findsWidgets, reason: 'espejo y barra');
    expect(find.text('1/5'), findsOneWidget, reason: 'anillo del espejo');
    expect(tester.takeException(), isNull);
  });
}

/// Bluetooth that never hears anyone.
class _SilentRadio implements NearbyRadio {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Set<String>?> scan(Duration duration) async => const {};

  @override
  Future<void> startAdvertising(String friendCode) async {}

  @override
  Future<void> stopAdvertising() async {}
}
