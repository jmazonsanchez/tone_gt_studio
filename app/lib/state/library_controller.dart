import 'package:flutter/foundation.dart';
import '../domain/models/patch_model.dart';
import '../sync/sync_engine.dart';

/// Controlador para la gestión y lectura de los 198 presets (U01-U99 y P01-P99) (H9, H11).
class LibraryController extends ChangeNotifier {
  final SyncEngine syncEngine;

  final Map<PatchRef, String> _patchNames = {};
  bool _isLoading = false;
  double _progress = 0.0;
  String _statusText = '';

  bool get isLoading => _isLoading;
  double get progress => _progress;
  String get statusText => _statusText;

  LibraryController({required this.syncEngine}) {
    _initializeEmptySlots();
  }

  void _initializeEmptySlots() {
    // 99 Presets de Usuario (U01 a U99)
    for (int i = 1; i <= 99; i++) {
      final ref = PatchRef(bank: PatchBank.user, number: i);
      _patchNames[ref] = 'Patch ${ref.displayNumber}';
    }
    // 99 Presets de Fábrica (P01 a P99)
    for (int i = 1; i <= 99; i++) {
      final ref = PatchRef(bank: PatchBank.preset, number: i);
      _patchNames[ref] = 'Preset ${ref.displayNumber}';
    }
  }

  List<PatchRef> get userPatches =>
      _patchNames.keys.where((k) => k.bank == PatchBank.user).toList()..sort((a, b) => a.number.compareTo(b.number));

  List<PatchRef> get presetPatches =>
      _patchNames.keys.where((k) => k.bank == PatchBank.preset).toList()..sort((a, b) => a.number.compareTo(b.number));

  String getName(PatchRef ref) => _patchNames[ref] ?? ref.displayNumber;

  void updatePatchName(PatchRef ref, String name) {
    _patchNames[ref] = name;
    notifyListeners();
  }

  /// Carga en segundo plano los 198 nombres reales desde la Boss GT-1B.
  Future<void> syncAllLibraryNames() async {
    if (_isLoading) return;
    _isLoading = true;
    _progress = 0.0;
    _statusText = 'Leyendo presets de la GT-1B...';
    notifyListeners();

    try {
      final allRefs = [...userPatches, ...presetPatches];
      final total = allRefs.length;

      for (int i = 0; i < total; i++) {
        final ref = allRefs[i];
        _progress = (i + 1) / total;
        _statusText = 'Leyendo ${ref.displayNumber} ($i/$total)...';
        notifyListeners();

        final name = await syncEngine.readPatchName(ref);
        if (name != null && name.isNotEmpty) {
          _patchNames[ref] = name;
        }

        // Breve pausa para no saturar el bus MIDI (H4)
        await Future.delayed(const Duration(milliseconds: 25));
      }

      _statusText = '¡Presets cargados!';
    } finally {
      _isLoading = false;
      _progress = 1.0;
      notifyListeners();
    }
  }
}
