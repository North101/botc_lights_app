import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/providers.dart';
import '/view/default_scaffold.dart';
import '/view/device_list_page.dart';

void main() async {
  runApp(MaterialApp(
      title: 'BotC Lights',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 63, 25, 66),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DefaultLoadingScaffold()
  ));

  final sharedPreferences = await SharedPreferences.getInstance();
  return runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BotC Lights',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 63, 25, 66),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DeviceListPage(),
    );
  }
}
