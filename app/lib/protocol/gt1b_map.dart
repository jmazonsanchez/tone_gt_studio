// ARCHIVO GENERADO AUTOMÁTICAMENTE POR tools/gen_catalog.py - NO EDITAR A MANO
// Mapa de direcciones de memoria oficial Boss GT-1B

class Gt1bMap {
  // Comandos y Handshake
  static const List<int> editorCommunicationMode = [0x7F, 0x00, 0x00, 0x01];
  static const List<int> editorCommunicationLevel = [0x7F, 0x00, 0x00, 0x00];
  static const List<int> runningMode = [0x7F, 0x00, 0x00, 0x02]; // 00=Play, 01=Tuner
  static const List<int> tunerSingleModePitch = [0x7F, 0x00, 0x05, 0x00];
  static const List<int> patchWrite = [0x7F, 0x00, 0x01, 0x04];
  static const List<int> patchCopy = [0x7F, 0x00, 0x01, 0x00];

  // Presets y Setup
  static const List<int> currentPatchNo = [0x00, 0x01, 0x00, 0x00];
  static const List<int> userPatchListTop = [0x10, 0x00, 0x00, 0x00];
  static const List<int> presetPatchListTop = [0x20, 0x00, 0x00, 0x00];

  // Buffer Temporal (Parches Activos)
  static const List<int> temporaryBase = [0x60, 0x00, 0x00, 0x00];
  static const List<int> patchName = [0x60, 0x00, 0x00, 0x00]; // 16 bytes

  // Switches Directos de Efectos (ON/OFF)
  static const List<int> compSwitch = [0x60, 0x00, 0x00, 0x20];
  static const List<int> odDsSwitch = [0x60, 0x00, 0x00, 0x30];
  static const List<int> preampSwitch = [0x60, 0x00, 0x00, 0x50];
  static const List<int> eqSwitch = [0x60, 0x00, 0x01, 0x30];
  static const List<int> fx1Switch = [0x60, 0x00, 0x01, 0x40];
  static const List<int> fx2Switch = [0x60, 0x00, 0x03, 0x4C];
  static const List<int> delaySwitch = [0x60, 0x00, 0x05, 0x60];
  static const List<int> chorusSwitch = [0x60, 0x00, 0x06, 0x00];
  static const List<int> reverbSwitch = [0x60, 0x00, 0x06, 0x10];
  static const List<int> pedalFxSwitch = [0x60, 0x00, 0x06, 0x20];
  static const List<int> pedalFxWahPosition = [0x60, 0x00, 0x06, 0x27];
  static const List<int> footVolumeLevel = [0x60, 0x00, 0x06, 0x33];
  static const List<int> ns1Switch = [0x60, 0x00, 0x06, 0x63];
  static const List<int> ns1Threshold = [0x60, 0x00, 0x06, 0x64];
  static const List<int> ns1Release = [0x60, 0x00, 0x06, 0x65];

  // Cadena de Efectos (Memory Edit)
  static const List<int> fxChainBase = [0x60, 0x00, 0x07, 0x20]; // 20 bytes
}
