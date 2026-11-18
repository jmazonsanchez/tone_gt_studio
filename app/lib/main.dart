import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/midi_service.dart';
import 'services/patch_service.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_pedalboard_screen.dart';

void main() {
  runApp(const ToneGtStudioApp());
}

class ToneGtStudioApp extends StatelessWidget {
  const ToneGtStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MidiService()),
        ChangeNotifierProxyProvider<MidiService, PatchService>(
          create: (ctx) => PatchService(ctx.read<MidiService>()),
          update: (_, midi, previous) => previous ?? PatchService(midi),
        ),
      ],
      child: MaterialApp(
        title: 'tone_gt_studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePedalboardScreen(),
      ),
    );
  }
}
