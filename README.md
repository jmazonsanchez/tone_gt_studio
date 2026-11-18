# tone_gt_studio 🎸🎛️

Open-source patch editor, librarian, and controller for **Boss GT-1B** (Bass) and **Boss GT-1** (Guitar) multi-effects processors, built with **Flutter**.

---

## 🎯 Objetivo

**tone_gt_studio** permite a los músicos controlar y editar su pedalera directamente desde un dispositivo móvil (Android / iOS). Diseñado tanto para la configuración detallada de sonido en casa como para el cambio rápido de patches y efectos en vivo.

### Características clave:
- 📱 **Interfaz táctil móvil:** Conmutadores virtuales para cada pedal de la cadena, perillas de parámetros y afinador en pantalla.
- 🔄 **Motor SysEx Roland/Boss:** Comunicación nativa mediante tramas System Exclusive (DT1 / RQ1) con cálculo automático de Checksum.
- ⚡ **Conectividad dual:**
  - **USB OTG:** Conexión directa por cable USB-MIDI sin hardware adicional ($0 costo).
  - **Puente inalámbrico:** Soporte para módulos Bluetooth BLE / SPP (ESP32 / Arduino).
- 💾 **Librería de patches:** Gestión y cambio rápido de patches de usuario (U01 a U99).
- 🎸 **Arquitectura escalable:** Optimizado para bajo (GT-1B) y ampliable a guitarra (GT-1).

---

## 📊 Matriz de Estado del Proyecto (Progreso y Pendientes)

La siguiente tabla detalla el estado actual de cada componente del sistema:

| Módulo | Característica | Estado | Detalle técnico |
| :--- | :--- | :---: | :--- |
| **Protocolo SysEx** | Cálculo de Checksum Roland (7-bit) | ✅ Completado | Algoritmo `(128 - (sum % 128)) & 0x7F` implementado y testeado. |
| **Protocolo SysEx** | Tramas DT1 (Data Set) y RQ1 (Data Request) | ✅ Completado | Constructores de tramas con cabecera `F0 41 10 00 00 00 3E ... F7`. |
| **Protocolo SysEx** | Cambio de Presets (Program Change) | ✅ Completado | Mensajes MIDI `0xC0 [0..98]` para patches U01 a U99. |
| **Protocolo SysEx** | Control de Afinador (Tuner / Mute) | ✅ Completado | Dirección `0x7F 0x00 0x05 0x00` con checksum verificado. |
| **Protocolo SysEx** | Mapeo de memoria oficial GT-1B | ✅ Completado | Extraído en `docs/gt1b_addressmap.json`. |
| **Interfaz Móvil (UI)** | Tablero de cadena de pedales (Stompboxes) | ✅ Completado | Vista de tarjetas con switches e indicadores LED de estado. |
| **Interfaz Móvil (UI)** | Potenciómetros rotativos interactivos (Knobs) | ✅ Completado | Widget `ParameterKnob` con física de arrastre táctil y display digital. |
| **Interfaz Móvil (UI)** | Editor modal de parámetros de cada efecto | ✅ Completado | Edición en vivo de Gain, Bass, Level, Time, Feedback, etc. vía SysEx. |
| **Interfaz Móvil (UI)** | Modal de Afinador cromático en vivo | ✅ Completado | Pantalla de afinación cromática con aguja de tono y mute. |
| **Interfaz Móvil (UI)** | Selector y buscador de 99 patches de usuario | ✅ Completado | Modal `PatchListModal` con barra de búsqueda instantánea. |
| **Interfaz Móvil (UI)** | Reordenamiento de la cadena de efectos | ⏳ Pendiente | Arrastrar y soltar para mover pedales antes/después del preamp. |
| **Interfaz Móvil (UI)** | Editor de asignaciones (EXP Pedal / CTL1) | ⏳ Pendiente | Configuración de pedales de expresión externos y funciones de switch. |
| **Conectividad** | Script de prueba de hardware directo para PC | ✅ Completado | `tools/test_gt1b_hardware.sh` interactivo mediante ALSA MIDI en Linux. |
| **Conectividad** | Conexión directa por cable USB OTG (Móvil) | 🔄 En progreso | Integración con `flutter_midi_command` para Android. |
| **Conectividad** | Firmware para puente ESP32-S3 (BLE MIDI) | ✅ Código base | Firmware inicial en `firmware/esp32_ble_midi_bridge/`. |
| **Conectividad** | Firmware para Arduino Uno + USB Host + HC-06 | ✅ Código base | Firmware inicial en `firmware/arduino_usb_host_bridge/`. |
| **Conectividad** | Pruebas físicas de enlace con pedalera real | 🔄 En progreso | Verificación pendiente con GT-1B física conectada. |
| **Librería & Datos** | Respaldo y exportación de patches (.tsl / JSON) | ⏳ Pendiente | Guardar y cargar bancos de sonido completos en la memoria del teléfono. |
| **Librería & Datos** | Importador de patches de Boss Tone Central | ⏳ Pendiente | Parser de archivos `.tsl` de Roland para importar sonidos comunitarios. |
| **Multi-dispositivo** | Soporte y selector para Boss GT-1 (Guitarra) | ⏳ Pendiente | Conmutador de Model ID (`0x3B`) y diccionario de amplificadores de guitarra. |

**Leyenda:**  
* ✅ **Completado:** Implementado, verificado y versionado en el repositorio.  
* 🔄 **En progreso:** Código estructurado, pendiente de pruebas con hardware físico o integración final.  
* ⏳ **Pendiente:** Planificado en la hoja de ruta para próximas versiones.

---

## 📁 Estructura del proyecto

```text
tone_gt_studio/
├── app/                  # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── models/       # Modelos de datos (Patch, EffectBlock, EffectParameter)
│   │   ├── protocol/     # Motor SysEx de Roland y tablas de direcciones
│   │   ├── services/     # Controladores de conexión USB-MIDI y estado reactivo
│   │   ├── ui/           # Pantallas, controles táctiles, perillas y afinador
│   │   └── main.dart
│   ├── test/             # Tests unitarios del protocolo SysEx
│   └── pubspec.yaml
├── firmware/             # Código para puentes inalámbricos (ESP32 / Arduino)
├── tools/                # Scripts de prueba y depuración MIDI por hardware
└── docs/                 # Documentación técnica y mapa de memoria SysEx oficial
```

---

## 📄 Licencia
Este proyecto es de código abierto bajo la licencia MIT.

*Aviso legal: Boss y Roland son marcas registradas de Roland Corporation. Este proyecto es una iniciativa comunitaria independiente sin afiliación oficial con Roland Corporation.*
