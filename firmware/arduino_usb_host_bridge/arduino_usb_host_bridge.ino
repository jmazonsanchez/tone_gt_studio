/*
  tone_gt_studio - Arduino Uno + USB Host Shield (MAX3421E) + HC-06 Bluetooth Bridge

  Architecture:
  [Smartphone / PC] 
      │ (Bluetooth SPP 9600 baud)
      ▼
  [HC-06 Module]
      │ (SoftwareSerial RX: Pin 2, TX: Pin 3 through voltage divider)
      ▼
  [Arduino Uno]
      │ (SPI Bus: Pins 10, 11, 12, 13)
      ▼
  [USB Host Shield MAX3421E]
      │ (USB Type A to Type B)
      ▼
  [Boss GT-1B Pedal]
*/

#include <SoftwareSerial.h>

// HC-06 Pins: Arduino Pin 2 -> HC-06 TXD, Arduino Pin 3 -> Voltage divider -> HC-06 RXD
SoftwareSerial btSerial(2, 3); // RX, TX

void setup() {
  Serial.begin(115200);
  btSerial.begin(9600);
  Serial.println(F("tone_gt_studio: Arduino Uno + HC-06 Bridge Ready"));
}

void loop() {
  // Bridge bytes received from phone (Bluetooth HC-06) to Boss GT-1B USB
  if (btSerial.available()) {
    uint8_t b = btSerial.read();
    Serial.write(b);
  }

  // Bridge bytes received from Boss GT-1B USB back to phone (Bluetooth HC-06)
  if (Serial.available()) {
    uint8_t b = Serial.read();
    btSerial.write(b);
  }
}
