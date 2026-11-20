// Web MIDI Bridge for tone_gt_studio
// Provides direct access to Boss GT-1B via Chrome Web MIDI API (SysEx enabled)

window.toneMidiBridge = {
  midiAccess: null,
  selectedOutput: null,
  selectedInput: null,
  messageCallback: null,
  disconnectCallback: null,

  setDisconnectCallback(callback) {
    this.disconnectCallback = callback;
  },

  setMessageCallback(callback) {
    this.messageCallback = callback;
  },

  _isPortSelected(port) {
    if (!port) return false;
    const isOut = this.selectedOutput && port.id === this.selectedOutput.id;
    const isIn = this.selectedInput && port.id === this.selectedInput.id;
    return isOut || isIn || this._isMatchingPort(port.name || "", "gt-1");
  },

  _handleStateChange(e) {
    if (e.port.state !== "disconnected") return;
    if (this._isPortSelected(e.port)) {
      this.selectedOutput = null;
      this.selectedInput = null;
      if (this.disconnectCallback) this.disconnectCallback();
    }
  },

  async requestAccess() {
    if (!navigator.requestMIDIAccess) {
      console.warn("Web MIDI is not supported in this browser.");
      return false;
    }

    try {
      this.midiAccess = await navigator.requestMIDIAccess({ sysex: true });
      this.midiAccess.onstatechange = (e) => this._handleStateChange(e);
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
    if (!portName) return false;
    const lower = portName.toLowerCase();

    // Explicitly reject virtual/dummy system ports that are not hardware devices
    if (lower.includes("through") ||
        lower.includes("wavetable") ||
        lower.includes("timer") ||
        lower.includes("announce")) {
      return false;
    }

    if (target) {
      const targetLower = target.toLowerCase();
      if (lower.includes(targetLower)) return true;
    }

    return lower.includes("gt-1b") ||
           lower.includes("gt-1") ||
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
    // Never fallback to an arbitrary port (e.g. Midi Through) when device is not connected!
    return null;
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

    if (!this.selectedOutput || !this.selectedInput) {
      if (this.selectedInput) {
        this.selectedInput.onmidimessage = null;
        this.selectedInput = null;
      }
      this.selectedOutput = null;
      console.warn("⚠️ No compatible Boss GT-1B MIDI device found for target:", targetName);
      return false;
    }

    console.log("✅ Connected to MIDI Output:", this.selectedOutput.name);
    this._bindInput(this.selectedInput);
    console.log("✅ Connected to MIDI Input:", this.selectedInput.name);

    return true;
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
    if (this.disconnectCallback) {
      this.disconnectCallback();
    }
  }
};

// Safe LocalStorage Bridge for tone_gt_studio persistence
window.toneStorageBridge = {
  getItem: function(key) {
    try {
      return localStorage.getItem(key);
    } catch (e) {
      console.warn("Storage getItem error:", e);
      return null;
    }
  },
  setItem: function(key, value) {
    try {
      localStorage.setItem(key, value);
      return true;
    } catch (e) {
      console.warn("Storage setItem error:", e);
      return false;
    }
  },
  removeItem: function(key) {
    try {
      localStorage.removeItem(key);
      return true;
    } catch (e) {
      return false;
    }
  },
  clear: function() {
    try {
      localStorage.clear();
      return true;
    } catch (e) {
      return false;
    }
  },
  getAllKeys: function() {
    try {
      return Object.keys(localStorage);
    } catch (e) {
      return [];
    }
  }
};
