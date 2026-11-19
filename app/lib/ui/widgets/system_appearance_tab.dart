import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Modal tab for configuring visual appearance and Light/Dark mode.
class SystemAppearanceTab extends StatelessWidget {
  const SystemAppearanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeService? themeService;
    try {
      themeService = context.watch<ThemeService>();
    } catch (_) {
      themeService = null;
    }

    final colors = AppTheme.of(context);
    final activeMode = themeService?.mode ?? AppThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(colors),
          const SizedBox(height: 14),
          _buildThemeOptions(context, colors, themeService, activeMode),
          const SizedBox(height: 14),
          _buildPalettePreview(colors),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, size: 22, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEMA VISUAL DE TONESTUDIO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Elige el modo visual que mejor se adapte a tu entorno de interpretación o estudio.',
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(
    BuildContext context,
    AppColorScheme colors,
    ThemeService? service,
    AppThemeMode activeMode,
  ) {
    return Column(
      children: [
        _buildModeCard(
          colors: colors,
          isSelected: activeMode == AppThemeMode.dark,
          icon: Icons.dark_mode_rounded,
          iconColor: const Color(0xFF00ADB5),
          title: 'MODO OSCURO (DARK STUDIO)',
          badge: 'RECOMENDADO EN VIVO',
          description: 'Fondo oscuro carbón de alto contraste. Reduce el deslumbramiento en escenario y resalta los LEDs.',
          onTap: () => service?.setThemeMode(AppThemeMode.dark),
        ),
        const SizedBox(height: 10),
        _buildModeCard(
          colors: colors,
          isSelected: activeMode == AppThemeMode.light,
          icon: Icons.light_mode_rounded,
          iconColor: const Color(0xFFFF9800),
          title: 'MODO CLARO (LIGHT STUDIO)',
          badge: 'ESTUDIO / LUZ DIURNA',
          description: 'Fondo plata y blanco nítido. Mayor legibilidad bajo luz ambiental intensa o monitores externos.',
          onTap: () => service?.setThemeMode(AppThemeMode.light),
        ),
        const SizedBox(height: 10),
        _buildModeCard(
          colors: colors,
          isSelected: activeMode == AppThemeMode.system,
          icon: Icons.brightness_auto_rounded,
          iconColor: const Color(0xFF9C27B0),
          title: 'AUTOMÁTICO (SISTEMA)',
          badge: 'PREFERENCIA DEL DISPOSITIVO',
          description: 'Se sincroniza automáticamente con el modo claro u oscuro configurado en tu tablet o sistema.',
          onTap: () => service?.setThemeMode(AppThemeMode.system),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required AppColorScheme colors,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required String description,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? colors.primary : colors.borderSubtle;
    final cardBg = isSelected ? colors.cardActive : colors.cardBackground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1.0),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.12),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? colors.primary : colors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPalettePreview(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PALETA ACTIVA',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: colors.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildColorChip('Fondo', colors.background, colors.textPrimary),
              const SizedBox(width: 8),
              _buildColorChip('Superficie', colors.surface, colors.textPrimary),
              const SizedBox(width: 8),
              _buildColorChip('Primario', colors.primary, Colors.white),
              const SizedBox(width: 8),
              _buildColorChip('Acento', colors.accent, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(String label, Color color, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}
