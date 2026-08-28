import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/utils/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterLocalization.instance.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}
