# tone_gt_studio - Hardware Bridges (Puentes Inalámbricos)

Esta carpeta contiene el código de referencia para construir adaptadores inalámbricos de bajo costo para conectar la **Boss GT-1B** con la app móvil sin cables físicos al celular.

---

## Opción 1: Arduino Uno + USB Host Shield + HC-06
* **Microcontrolador:** Arduino Uno (ATmega328P).
* **Módulo Bluetooth:** HC-06 (Bluetooth 2.0 SPP Clásico).
* **Adaptador USB Host:** USB Host Shield basado en chip MAX3421E.
* **Diagrama de pines:**
  * Arduino Pin 2 (RX) $\leftarrow$ HC-06 Pin TXD.
  * Arduino Pin 3 (TX) $\rightarrow$ Divisor de voltaje (1kΩ / 2kΩ a GND) $\rightarrow$ HC-06 Pin RXD (3.3V).
  * VCC $\rightarrow$ 5V, GND $\rightarrow$ GND.
  * USB Host Shield acoplado sobre el Arduino Uno.
  * Cable USB A a B conectado a la GT-1B.

---

## Opción 2: ESP32-S3 (Recomendada)
* **Chip:** ESP32-S3 (soporte nativo de USB Host por hardware + Bluetooth BLE MIDI integrado).
* **Conexión:**
  * Pin GPIO 19 $\rightarrow$ USB D- de la GT-1B.
  * Pin GPIO 20 $\rightarrow$ USB D+ de la GT-1B.
  * Alimentación 5V y GND.
* **Ventajas:**
  * No requiere shields externos ni módulos Bluetooth adicionales.
  * Reconocido directamente como dispositivo MIDI BLE estándar por cualquier sistema operativo.
