import 'package:flutter/material.dart';
import 'package:memory_companion/features/capture_moment/pages/capture_moment_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Companion',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const CaptureMomentPage(),
    );
  }
}
