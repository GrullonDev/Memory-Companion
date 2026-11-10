import 'package:flutter/material.dart';

import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/core/firebase/provider_retry.dart';
import 'package:memory_companion/utils/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterLocalization.instance.ensureInitialized();

  final database = AppDatabase();

  runApp(
    ProviderScope(
      retry: appProviderRetry,
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const MyApp(),
    ),
  );
}
