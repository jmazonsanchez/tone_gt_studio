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

  connect(targetName) {
    if (!this.midiAccess) return false;

    this.selectedOutput = null;
    this.selectedInput = null;

    const lowerTarget = (targetName || "").toLowerCase();

    // 1. Search matching output
    for (let entry of this.midiAccess.outputs.entries()) {
      const output = entry[1];
      const outName = (output.name || "").toLowerCase();
      if (!targetName || outName.includes(lowerTarget) || outName.includes("gt-1") || outName.includes("gt-1b") || outName.includes("boss") || outName.includes("roland")) {
        this.selectedOutput = output;
        console.log("✅ Connected to MIDI Output:", output.name);
        break;
      }
    }

    // 2. Search matching input
    for (let entry of this.midiAccess.inputs.entries()) {
      const input = entry[1];
      const inName = (input.name || "").toLowerCase();
      if (!targetName || inName.includes(lowerTarget) || inName.includes("gt-1") || inName.includes("gt-1b") || inName.includes("boss") || inName.includes("roland")) {
        this.selectedInput = input;
        console.log("✅ Connected to MIDI Input:", input.name);

        input.onmidimessage = (event) => {
          if (this.messageCallback && event.data) {
            this.messageCallback(Array.from(event.data));
          }
        };
        break;
      }
    }

    // 3. Fallback to first available output if not found
    if (!this.selectedOutput && this.midiAccess.outputs.size > 0) {
      this.selectedOutput = this.midiAccess.outputs.values().next().value;
      console.log("ℹ️ Fallback connected to MIDI Output:", this.selectedOutput.name);
    }

    if (!this.selectedInput && this.midiAccess.inputs.size > 0) {
      this.selectedInput = this.midiAccess.inputs.values().next().value;
      this.selectedInput.onmidimessage = (event) => {
        if (this.messageCallback && event.data) {
          this.messageCallback(Array.from(event.data));
        }
      };
      console.log("ℹ️ Fallback connected to MIDI Input:", this.selectedInput.name);
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
