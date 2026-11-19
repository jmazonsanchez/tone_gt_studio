import 'package:flutter/material.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Screen displayed while Tone GT Studio performs the mandatory initial synchronization
/// of preset names and effect chain order from Boss GT-1B hardware via OTG or Bluetooth.
/// Blocks user interaction until 100% of presets and chain lines are loaded.
class SyncLoadingScreen extends StatelessWidget {
  final MidiService midi;
  final PatchService patchService;
  final VoidCallback onEnterDemoMode;

  const SyncLoadingScreen({
    super.key,
    required this.midi,
    required this.patchService,
    required this.onEnterDemoMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final size = MediaQuery.of(context).size;
    final isHorizontal = size.width > size.height;
    final progress = patchService.syncProgress.clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: isHorizontal
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 4, child: _buildBranding(colors)),
                          const SizedBox(width: 32),
                          Expanded(flex: 5, child: _buildProgressPanel(context, colors, progress, percent)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBranding(colors),
                          const SizedBox(height: 22),
                          _buildProgressPanel(context, colors, progress, percent),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(AppColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logoToneStudio.png',
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF00ADB5), Color(0xFF3B82F6)]),
            ),
            child: const Icon(Icons.album_rounded, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        _buildConnectionBadge(colors),
        const SizedBox(height: 10),
        Text(
          'Sincronizando Pedalera',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Consultando la línea de conexión y el orden de efectos de cada preset...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildConnectionBadge(AppColorScheme colors) {
    final isBle = midi.connectionType == ConnectionType.bluetoothBle;
    final icon = isBle ? Icons.bluetooth : Icons.usb;
    final label = isBle ? 'Bluetooth BLE' : 'USB OTG';
    final accent = isBle ? const Color(0xFF3B82F6) : const Color(0xFF00ADB5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            '$label Conectado',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel(
    BuildContext context,
    AppColorScheme colors,
    double progress,
    int percent,
  ) {
    final statusText = patchService.syncStatusText.isNotEmpty
        ? patchService.syncStatusText
        : 'Consultando memoria de la Boss GT-1B...';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESO DE SINCRONIZACIÓN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00ADB5)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: colors.isDark ? const Color(0xFF222230) : const Color(0xFFE2E8F0),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.01, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF00ADB5), Color(0xFF3B82F6)]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF14141E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF00ADB5))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: onEnterDemoMode,
              icon: Icon(Icons.visibility_rounded, size: 15, color: colors.textSecondary),
              label: Text('Modo Demo', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () => patchService.cancelSync(),
              icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF00ADB5)),
              label: Text(
                'Omitir y abrir interfaz',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
