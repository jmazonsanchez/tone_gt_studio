// Web MIDI Bridge for tone_gt_studio
// Provides direct access to Boss GT-1B via Chrome Web MIDI API (SysEx enabled)

window.toneMidiBridge = {
  midiAccess: null,
  selectedOutput: null,
  selectedInput: null,
  messageCallback: null,

  async requestAccess() {
    if (!navigator.requestMIDIAccess) {
      console.warn("Web MIDI is not supported in this browser.");
      return false;
    }

    try {
      this.midiAccess = await navigator.requestMIDIAccess({ sysex: true });
      console.log("✅ Web MIDI access granted with SysEx support.");
      
      this.midiAccess.onstatechange = (e) => {
        console.log("MIDI state change:", e.port.name, e.port.state);
      };

      return true;
    } catch (err) {
      console.error("❌ Web MIDI access rejected or failed:", err);
      return false;
    }
  },

  getDevices() {
    if (!this.midiAccess) return [];
    const devices = [];
    const seen = new Set();

    for (let entry of this.midiAccess.outputs.entries()) {
      const output = entry[1];
      if (!seen.has(output.name)) {
        seen.add(output.name);
        devices.push({
          id: output.id,
          name: output.name,
          manufacturer: output.manufacturer || "Roland"
        });
      }
    }
    return devices;
  },

  _isMatchingPort(portName, target) {
    if (!target) return true;
    const lower = (portName || "").toLowerCase();
    const targetLower = target.toLowerCase();
    return lower.includes(targetLower) ||
           lower.includes("gt-1") ||
           lower.includes("gt-1b") ||
           lower.includes("boss") ||
           lower.includes("roland");
  },

  _findMatchingPort(map, targetName) {
    if (!map || map.size === 0) return null;
    for (let entry of map.entries()) {
      const port = entry[1];
      if (this._isMatchingPort(port.name, targetName)) {
        return port;
      }
    }
    return map.values().next().value || null;
  },

  _bindInput(input) {
    if (!input) return;
    input.onmidimessage = (event) => {
      if (this.messageCallback && event.data) {
        this.messageCallback(Array.from(event.data));
      }
    };
  },

  connect(targetName) {
    if (!this.midiAccess) return false;

    this.selectedOutput = this._findMatchingPort(this.midiAccess.outputs, targetName);
    this.selectedInput = this._findMatchingPort(this.midiAccess.inputs, targetName);

    if (this.selectedOutput) {
      console.log("✅ Connected to MIDI Output:", this.selectedOutput.name);
    }
    if (this.selectedInput) {
      this._bindInput(this.selectedInput);
      console.log("✅ Connected to MIDI Input:", this.selectedInput.name);
    }

    return this.selectedOutput !== null;
  },

  send(bytes) {
    if (!this.selectedOutput) {
      console.warn("⚠️ No active MIDI output selected");
      return false;
    }
    try {
      const uint8 = new Uint8Array(bytes);
      this.selectedOutput.send(uint8);
      return true;
    } catch (err) {
      console.error("❌ Error sending MIDI SysEx:", err);
      return false;
    }
  },

  disconnect() {
    if (this.selectedInput) {
      this.selectedInput.onmidimessage = null;
      this.selectedInput = null;
    }
    this.selectedOutput = null;
    console.log("MIDI disconnected");
  },

  setMessageCallback(cb) {
    this.messageCallback = cb;
  }
};
