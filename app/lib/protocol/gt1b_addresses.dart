/// Memory address constants for Boss GT-1B System Exclusive communication.
/// Reference: docs/gt1b_addressmap.json
class Gt1bAddresses {
  // Commands & System
  static const List<int> tunerSingleModePitch = [0x7F, 0x00, 0x05, 0x00];
  static const List<int> editorCommunicationMode = [0x7F, 0x00, 0x00, 0x01];
  static const List<int> patchCopy = [0x7F, 0x00, 0x01, 0x00];
  static const List<int> patchWrite = [0x7F, 0x00, 0x01, 0x04];

  // Temporary Patch Edit Buffer (Addresses start with 60 00 ...)
  static const List<int> patchNameStart = [0x60, 0x00, 0x00, 0x00]; // 16 bytes ASCII

  // Effect Switch Addresses in Temporary Buffer
  static const List<int> compSwitch = [0x60, 0x00, 0x01, 0x00];
  static const List<int> odDsSwitch = [0x60, 0x00, 0x02, 0x00];
  static const List<int> preampSwitch = [0x60, 0x00, 0x03, 0x00];
  static const List<int> fx1Switch = [0x60, 0x00, 0x04, 0x00];
  static const List<int> fx2Switch = [0x60, 0x00, 0x05, 0x00];
  static const List<int> delaySwitch = [0x60, 0x00, 0x06, 0x00];
  static const List<int> chorusSwitch = [0x60, 0x00, 0x07, 0x00];
  static const List<int> reverbSwitch = [0x60, 0x00, 0x08, 0x00];
}
