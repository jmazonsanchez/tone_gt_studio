import 'dart:convert';
import '../models/effect_block.dart';
import '../models/effect_parameter.dart';
import '../models/patch.dart';

/// Serializer for Boss Tone Studio LiveSet (.tsl) and JSON backup files.
class TslSerializer {
  static const String deviceName = 'GT-1B';
  static const String fileVersion = '1.0.0';

  /// Export a list of patches as a Boss Tone Studio LiveSet (.tsl) JSON string.
  static String exportLiveSet({
    required String liveSetName,
    required List<Patch> patches,
  }) {
    final patchList = <Map<String, dynamic>>[];

    for (int i = 0; i < patches.length; i++) {
      final p = patches[i];
      final paramMap = <String, dynamic>{};

      for (final effect in p.effects) {
        paramMap['${effect.id}_sw'] = effect.isEnabled ? 1 : 0;
        for (final param in effect.parameters) {
          paramMap[param.id] = param.value;
        }
      }

      patchList.add({
        'name': p.name,
        'orderNumber': i + 1,
        'patchNo': p.displayNumber,
        'params': paramMap,
      });
    }

    final tslData = {
      'device': deviceName,
      'version': fileVersion,
      'liveSetData': {
        'name': liveSetName,
        'orderNumber': 1,
      },
      'patchList': patchList,
    };

    return const JsonEncoder.withIndent('  ').convert(tslData);
  }

  /// Import patches from a Boss Tone Studio LiveSet (.tsl) JSON string.
  static List<Patch> importLiveSet(String jsonContent, {required List<Patch> templatePatches}) {
    final Map<String, dynamic> data = jsonDecode(jsonContent);

    final device = data['device'];
    if (device != null && device != deviceName) {
      throw FormatException('Dispositivo incompatible: $device (se esperaba $deviceName)');
    }

    final list = data['patchList'] as List<dynamic>?;
    if (list == null) return [];

    final result = <Patch>[];
    for (int i = 0; i < list.length; i++) {
      final pData = list[i] as Map<String, dynamic>;
      final name = pData['name'] as String? ?? 'Imported Patch';
      final params = pData['params'] as Map<String, dynamic>? ?? {};

      // Template base to preserve proper addresses and effect category mappings
      final template = templatePatches[i % templatePatches.length];
      final clonedEffects = <EffectBlock>[];

      for (final eff in template.effects) {
        final swKey = '${eff.id}_sw';
        final isEnabled = params.containsKey(swKey) ? (params[swKey] != 0) : eff.isEnabled;

        final clonedParams = <EffectParameter>[];
        for (final p in eff.parameters) {
          final val = params.containsKey(p.id) ? (params[p.id] as num).toInt() : p.value;
          clonedParams.add(p.copyWith(value: val));
        }

        clonedEffects.add(eff.copyWith(isEnabled: isEnabled, parameters: clonedParams));
      }

      result.add(Patch(
        index: i,
        name: name,
        effects: clonedEffects,
      ));
    }

    return result;
  }

  /// Export a single patch as portable JSON.
  static String exportSinglePatch(Patch patch) {
    final paramMap = <String, dynamic>{};
    for (final effect in patch.effects) {
      paramMap['${effect.id}_sw'] = effect.isEnabled ? 1 : 0;
      for (final param in effect.parameters) {
        paramMap[param.id] = param.value;
      }
    }

    final data = {
      'device': deviceName,
      'version': fileVersion,
      'patch': {
        'index': patch.index,
        'name': patch.name,
        'displayNumber': patch.displayNumber,
        'params': paramMap,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import a single patch from portable JSON.
  static Patch importSinglePatch(String jsonContent, Patch templatePatch) {
    final Map<String, dynamic> data = jsonDecode(jsonContent);
    final patchData = data['patch'] as Map<String, dynamic>? ?? data;

    final name = patchData['name'] as String? ?? templatePatch.name;
    final params = patchData['params'] as Map<String, dynamic>? ?? {};

    final clonedEffects = <EffectBlock>[];
    for (final eff in templatePatch.effects) {
      final swKey = '${eff.id}_sw';
      final isEnabled = params.containsKey(swKey) ? (params[swKey] != 0) : eff.isEnabled;

      final clonedParams = <EffectParameter>[];
      for (final p in eff.parameters) {
        final val = params.containsKey(p.id) ? (params[p.id] as num).toInt() : p.value;
        clonedParams.add(p.copyWith(value: val));
      }

      clonedEffects.add(eff.copyWith(isEnabled: isEnabled, parameters: clonedParams));
    }

    return templatePatch.copyWith(name: name, effects: clonedEffects);
  }
}
