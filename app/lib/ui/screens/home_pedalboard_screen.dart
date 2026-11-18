import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import '../widgets/gt1b_panel_buttons.dart';
import '../widgets/memory_edit_chain_bar.dart';
import '../widgets/wah_expression_card.dart';
import '../widgets/mini_pedal_card.dart';
import '../widgets/effect_detail_modal.dart';
import '../widgets/patch_list_modal.dart';
import '../widgets/tuner_modal.dart';

class HomePedalboardScreen extends StatelessWidget {
  const HomePedalboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiService>();
    final patchService = context.watch<PatchService>();
    final current = patchService.currentPatch;
    final screenWidth = MediaQuery.of(context).size.width;

    // Mobile-first responsive columns (2 on phone, 3 on tablet, 4 on wide screen)
    final int crossAxisCount = screenWidth > 950 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141C),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.graphic_eq, color: Color(0xFF00ADB5), size: 22),
            SizedBox(width: 8),
            Text(
              'tone_gt_studio',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _buildConnectionBadge(context, midi),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Stage Preset Header (Large, High-Contrast for Mobile)
          _buildStagePatchHeader(context, patchService, current),

          // 2. Hardware Sync Progress Bar
          if (patchService.isSyncing)
            Container(
              color: const Color(0xFF00ADB5).withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ADB5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patchService.syncStatusText,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF00ADB5), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Scrollable Mobile Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                // A. Physical GT-1B Backlit Black Buttons Row
                Gt1bPanelButtons(
                  effects: current.effects,
                  onToggle: (effect) => patchService.toggleEffect(effect),
                ),

                const SizedBox(height: 14),

                // B. GT-1B [MEMORY EDIT] Effect Chain & Routing (Línea de Conexión)
                MemoryEditChainBar(
                  effects: current.effects,
                  onToggle: (effect) => patchService.toggleEffect(effect),
                  onMoveEffect: (from, to) => patchService.moveEffect(from, to),
                ),

                const SizedBox(height: 14),

                // C. Dedicated EXP / WAH Footswitch Card
                WahExpressionCard(
                  isWahActive: patchService.isWahActive,
                  wahPosition: patchService.wahPosition,
                  onToggleWah: () => patchService.toggleWah(),
                  onPositionChanged: (pos) => patchService.setWahPosition(pos),
                ),

                const SizedBox(height: 18),

                // C. Boutique Mini-Pedals Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dashboard_customize, size: 16, color: Color(0xFF00ADB5)),
                        SizedBox(width: 6),
                        Text(
                          'PEDALBOARD BOUTIQUE (GT-1B)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white60,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${current.effects.length} PEDALES',
                      style: const TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // D. Boutique Mini-Pedals Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.70, // Authentic boutique mini-pedal ratio
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: current.effects.length,
                  itemBuilder: (context, index) {
                    final effect = current.effects[index];
                    return MiniPedalCard(
                      effect: effect,
                      onToggle: () => patchService.toggleEffect(effect),
                      onOpenDetail: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => EffectDetailModal(effect: effect),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // 4. Mobile Sticky Bottom Action Bar
          _buildMobileBottomBar(context, patchService),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(BuildContext context, MidiService midi) {
    final connected = midi.isConnected;
    final isConnecting = midi.connectionState == MidiConnectionState.connecting;

    Color badgeColor = Colors.redAccent;
    String badgeText = 'CONECTAR';
    IconData badgeIcon = Icons.usb_off;

    if (connected) {
      badgeColor = const Color(0xFF00ADB5);
      badgeText = 'GT-1B CONECTADA';
      badgeIcon = Icons.usb;
    } else if (isConnecting) {
      badgeColor = Colors.amber;
      badgeText = 'CONECTANDO...';
      badgeIcon = Icons.sync;
    }

    return GestureDetector(
      onTap: () {
        if (connected) {
          midi.disconnect();
        } else {
          _showConnectionDialog(context, midi);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor, width: 1.2),
          boxShadow: connected
              ? [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isConnecting
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                : Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                color: badgeColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagePatchHeader(BuildContext context, PatchService patchService, dynamic current) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Previous Patch Button (Big mobile touch target)
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF242432),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: patchService.currentPatchIndex > 0 ? () => patchService.previousPatch() : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: Colors.white),
          ),

          // Central Patch Identifier & Name (Tappable to open 99 presets modal)
          Expanded(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const PatchListModal(),
                );
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          current.displayNumber,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00ADB5),
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF00ADB5), size: 26),
                      ],
                    ),
                    Text(
                      current.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Patch Button (Big mobile touch target)
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF242432),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: patchService.currentPatchIndex < 98 ? () => patchService.nextPatch() : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 22, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar(BuildContext context, PatchService patchService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF14141C),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Tuner / Mute Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                patchService.toggleTuner();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => TunerModal(
                    onClose: () {
                      patchService.toggleTuner();
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('AFINADOR / MUTE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222230),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.white24, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. Presets Library Button
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const PatchListModal(),
              );
            },
            icon: const Icon(Icons.library_music, size: 18),
            label: const Text('PRESETS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ADB5),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, MidiService midi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Conectar con Boss GT-1B', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.usb, color: Color(0xFF00ADB5), size: 28),
              title: const Text('Cable USB OTG (Recomendado)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Conexión directa por cable OTG tipo C/Micro-USB'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await midi.connect(type: ConnectionType.usbOtg);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '✅ Conectado con ${midi.connectedDeviceName}. Leyendo presets de tu pedalera...'
                          : '⚠️ No se pudo conectar con la Boss GT-1B. Verifica el cable USB y permisos MIDI.'),
                      backgroundColor: ok ? Colors.teal : Colors.deepOrange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.bluetooth, color: Colors.blueAccent, size: 28),
              title: const Text('Bluetooth Inalámbrico', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Puente ESP32-S3 / HC-06 BLE MIDI'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await midi.connect(type: ConnectionType.bluetoothBle);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '✅ Conectado vía Bluetooth: ${midi.connectedDeviceName}'
                          : '⚠️ No se detectó puente Bluetooth BLE activo.'),
                      backgroundColor: ok ? Colors.teal : Colors.deepOrange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
