import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/midi_service.dart';
import 'services/patch_service.dart';
import 'services/storage/app_database.dart';
import 'services/theme_service.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_pedalboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await AppDatabase.instance.init();
  runApp(const ToneGtStudioApp());
}

class ToneGtStudioApp extends StatelessWidget {
  const ToneGtStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppDatabase>.value(value: AppDatabase.instance),
        ChangeNotifierProvider(create: (_) => ThemeService(database: AppDatabase.instance)),
        ChangeNotifierProvider(create: (_) => MidiService(database: AppDatabase.instance)),
        ChangeNotifierProxyProvider<MidiService, PatchService>(
          create: (ctx) => PatchService(ctx.read<MidiService>(), database: AppDatabase.instance),
          update: (_, midi, previous) => previous ?? PatchService(midi, database: AppDatabase.instance),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'ToneStudio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            ),
            home: const HomePedalboardScreen(),
          );
        },
      ),
    );
  }
}
