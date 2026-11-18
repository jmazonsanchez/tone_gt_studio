/// Verified Memory address constants for Boss GT-1B System Exclusive communication.
/// Captured directly from GT-1B hardware traffic and verified via docs/gt1b_addressmap.json.
class Gt1bAddresses {
  // Commands & Mode Switches
  static const List<int> editorCommunicationMode = [0x7F, 0x00, 0x00, 0x01];
  static const List<int> runningMode = [0x7F, 0x00, 0x00, 0x02]; // 00 = Play, 01 = Tuner
  static const List<int> tunerSingleModePitch = [0x7F, 0x00, 0x05, 0x00];

  // Patch Selection in Setup Buffer (2 bytes: High Byte, Low Byte)
  static const List<int> currentPatchNo = [0x00, 0x01, 0x00, 0x00];

  // Temporary Patch Edit Buffer - Exact Effect Switches
  static const List<int> compSwitch = [0x60, 0x00, 0x00, 0x20];
  static const List<int> odDsSwitch = [0x60, 0x00, 0x00, 0x30];
  static const List<int> preampSwitch = [0x60, 0x00, 0x00, 0x50];
  static const List<int> fx1Switch = [0x60, 0x00, 0x01, 0x40];
  static const List<int> fx2Switch = [0x60, 0x00, 0x03, 0x4C];
  static const List<int> delaySwitch = [0x60, 0x00, 0x05, 0x60];
  static const List<int> chorusSwitch = [0x60, 0x00, 0x06, 0x00];
  static const List<int> reverbSwitch = [0x60, 0x00, 0x06, 0x10];
  static const List<int> eqSwitch = [0x60, 0x00, 0x01, 0x30];
}
