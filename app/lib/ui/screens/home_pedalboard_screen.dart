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

class HomePedalboardScreen extends StatefulWidget {
  const HomePedalboardScreen({super.key});

  @override
  State<HomePedalboardScreen> createState() => _HomePedalboardScreenState();
}

class _HomePedalboardScreenState extends State<HomePedalboardScreen> {
  bool _isDemoMode = false;

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiService>();
    final patchService = context.watch<PatchService>();
    final current = patchService.currentPatch;
    final screenWidth = MediaQuery.of(context).size.width;

    // Mobile-first responsive columns (2 on phone, 3 on tablet, 4 on wide screen)
    final int crossAxisCount = screenWidth > 950 ? 4 : (screenWidth > 600 ? 3 : 2);

    final bool isUnlocked = midi.isConnected || _isDemoMode;

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
      body: isUnlocked
          ? _buildUnlockedEditor(context, midi, patchService, current, crossAxisCount)
          : _buildConnectionGateway(context, midi),
    );
  }

  /// Step 1: Gateway Screen - Connect to the pedalboard before accessing options
  Widget _buildConnectionGateway(BuildContext context, MidiService midi) {
    final isConnecting = midi.connectionState == MidiConnectionState.connecting;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hardware Icon Card
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A26),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00ADB5).withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ADB5).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_input_hdmi,
                    size: 48,
                    color: Color(0xFF00ADB5),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Step 1 Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ADB5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00ADB5).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'PASO 1: CONECTAR A LA PEDALERA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Color(0xFF00ADB5),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Boss GT-1B Bass Studio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Para ver y editar tus efectos, sincronizar la línea de conexión (Memory Edit) y leer tus 99 presets originales, conecta la pedalera a tu dispositivo móvil o PC.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 32),

              // Connect via USB OTG Button
              ElevatedButton.icon(
                onPressed: isConnecting
                    ? null
                    : () async {
                        final ok = await midi.connect(type: ConnectionType.usbOtg);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '✅ Boss GT-1B conectada. Sincronizando presets, línea y pedales...'
                                  : '⚠️ No se detectó la Boss GT-1B. Conecta el cable USB OTG y reintenta.'),
                              backgroundColor: ok ? Colors.teal : Colors.deepOrange,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                icon: isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.usb, size: 22),
                label: Text(
                  isConnecting ? 'CONECTANDO...' : 'CONECTAR POR CABLE USB OTG',
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ADB5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
              ),

              const SizedBox(height: 12),

              // Connect via Bluetooth BLE Button
              OutlinedButton.icon(
                onPressed: isConnecting
                    ? null
                    : () async {
                        final ok = await midi.connect(type: ConnectionType.bluetoothBle);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '✅ Boss GT-1B conectada vía Bluetooth.'
                                  : '⚠️ No se detectó adaptador BLE MIDI.'),
                              backgroundColor: ok ? Colors.teal : Colors.deepOrange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.bluetooth, size: 20),
                label: const Text(
                  'CONECTAR VÍA BLUETOOTH BLE',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 28),

              // Demo mode option for inspection without hardware
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isDemoMode = true;
                    });
                  },
                  icon: const Icon(Icons.visibility, size: 16, color: Colors.white54),
                  label: const Text(
                    'Explorar en Modo Demo (Offline)',
                    style: TextStyle(fontSize: 12, color: Colors.white54, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full Unlocked Editor View
  Widget _buildUnlockedEditor(
    BuildContext context,
    MidiService midi,
    PatchService patchService,
    dynamic current,
    int crossAxisCount,
  ) {
    return Column(
      children: [
        // Demo Mode Notice Bar (if viewing in demo mode)
        if (_isDemoMode && !midi.isConnected)
          Container(
            color: Colors.deepPurple.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 15, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'Modo Demo (Offline) - Datos de muestra',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDemoMode = false;
                    });
                  },
                  child: const Text(
                    'VOLVER AL PASO 1',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00ADB5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

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

              // D. Boutique Mini-Pedals Section Header
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

              // E. Boutique Mini-Pedals Grid
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
    } else if (_isDemoMode) {
      badgeColor = Colors.purpleAccent;
      badgeText = 'DEMO OFFLINE';
      badgeIcon = Icons.visibility;
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
