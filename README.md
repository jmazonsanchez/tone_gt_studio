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

## 📁 Estructura del proyecto

```text
tone_gt_studio/
├── app/                  # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── models/       # Modelos de datos (Patch, EffectBlock, Parameter)
│   │   ├── protocol/     # Motor SysEx de Roland y tablas de direcciones
│   │   ├── services/     # Controladores de conexión USB-MIDI y Bluetooth
│   │   ├── ui/           # Pantallas, controles táctiles y afinador
│   │   └── main.dart
│   └── pubspec.yaml
├── firmware/             # Código para puentes inalámbricos (ESP32 / Arduino)
└── docs/                 # Documentación técnica y mapa de memoria SysEx
```

---

## 📄 Licencia
Este proyecto es de código abierto bajo la licencia MIT.

*Aviso legal: Boss y Roland son marcas registradas de Roland Corporation. Este proyecto es una iniciativa comunitaria independiente sin afiliación oficial con Roland Corporation.*
