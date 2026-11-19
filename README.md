# tone_gt_studio 🎸🎛️

Open-source patch editor, librarian, and controller for **Boss GT-1B** (Bass) and **Boss GT-1** (Guitar) multi-effects processors, built with **Flutter**.

---

## 🎯 Objetivo

**tone_gt_studio** permite a los músicos controlar y editar su pedalera directamente desde un dispositivo móvil (Android / iOS) o PC. Diseñado tanto para la configuración detallada de sonido en casa como para el cambio instantáneo de patches y efectos en vivo.

### Características clave:
- 📱 **Interfaz táctil móvil:** Conmutadores virtuales para cada pedal de la cadena, perillas de parámetros y afinador en pantalla.
- 🔄 **Motor SysEx Roland/Boss:** Comunicación nativa mediante tramas System Exclusive (DT1 / RQ1) con cálculo automático de Checksum 7-bit.
- ⚡ **Conectividad dual:**
  - **USB OTG:** Conexión directa por cable USB-MIDI sin hardware adicional ($0 costo).
  - **Puente inalámbrico:** Soporte para módulos Bluetooth BLE / SPP (ESP32 / Arduino).
- 💾 **Librería de patches:** Gestión y cambio rápido de patches de usuario (U01 a U99).
- 🎸 **Arquitectura escalable:** Optimizado para bajo (GT-1B) y ampliable a guitarra (GT-1).

---

## 📊 Matriz de Estado del Proyecto (Progreso y Pendientes)

| Módulo | Característica | Estado | Detalle técnico |
| :--- | :--- | :---: | :--- |
| **Protocolo SysEx** | Cálculo de Checksum Roland (7-bit) | ✅ Completado | Algoritmo `(128 - (sum % 128)) & 0x7F` implementado y testeado con tests unitarios. |
| **Protocolo SysEx** | Tramas DT1 (Data Set) y RQ1 (Data Request) | ✅ Completado | Tramas con Device ID `0x00`, Model ID `00 00 00 3E` verificadas en hardware real. |
| **Protocolo SysEx** | Cambio de Presets (Patch Change) | ✅ Completado | SysEx DT1 a `00 01 00 00` con 2 bytes de índice (`00 00` = U01, `00 01` = U02, etc.). Probado con éxito en GT-1B. |
| **Protocolo SysEx** | Control de Afinador (Tuner / Mute) | ✅ Completado | Dirección `7F 00 00 02` (`01` = Tuner, `00` = Play). La pedalera responde transmitiendo pitch en tiempo real. |
| **Protocolo SysEx** | Lectura de Presets y Parámetros en vivo (RQ1) | ✅ Completado | Peticiones RQ1 a `10 [patch] 00 00` para leer los 99 nombres reales y `60 00 00 00` para estados de efectos en vivo. |
| **Protocolo SysEx** | Conmutación de efectos (Stompbox ON/OFF) | ✅ Completado | Verificado en hardware real: OD/DS (`60 00 00 30`), COMP (`60 00 00 20`), DELAY (`60 00 05 60`), etc. |
| **Protocolo SysEx** | Mapeo de memoria oficial GT-1B | ✅ Completado | Extraído en `docs/gt1b_addressmap.json` desde el instalador oficial de Boss Tone Studio. |
| **Interfaz Móvil (UI)** | Botones frontales negros GT-1B (Retroiluminados) | ✅ Completado | Fila física de botones táctiles negros con ranuras LED rojas (`COMP`, `OD/DS`, `PREAMP`, `FX1`, `FX2`, `DELAY`, `REV`, `WAH`). |
| **Interfaz Móvil (UI)** | Pedal de Expresión y Footswitch WAH | ✅ Completado | Widget `WahExpressionCard` con pisador de punta (Toe Switch), LED de estado y deslizador de barrido en tiempo real (`60 00 06 20` / `27`). |
| **Interfaz Móvil (UI)** | Mini-Pedales Boutique interactivos (Stompboxes) | ✅ Completado | Widget `MiniPedalCard` con chasis esmaltado, Jewel LED 3D, mini-knobs rotativos y footswitch metálico cromado. |
| **Interfaz Móvil (UI)** | Potenciómetros rotativos interactivos (Knobs) | ✅ Completado | Widget `ParameterKnob` con física de arrastre táctil vertical y lectura numérica. |
| **Interfaz Móvil (UI)** | Editor modal de parámetros de cada efecto | ✅ Completado | Edición en vivo de Gain, Bass, Level, Time, Feedback, etc. vía SysEx. |
| **Interfaz Móvil (UI)** | Modal de Afinador cromático en vivo | ✅ Completado | Pantalla con aguja gráfica de afinación, nota detectada y botón Mute. |
| **Interfaz Móvil (UI)** | Sincronización y lector de 99 patches de usuario | ✅ Completado | Botón de sincronización con barra de progreso interactiva y lectura directa de la memoria de la GT-1B. |
| **Interfaz Móvil (UI)** | Reordenamiento de cadena (MEMORY EDIT) | ✅ Completado | Widget `MemoryEditChainBar` con línea de conexión serie ([IN] ➔ [FX] ➔ [OUT]), conmutación táctil y cambio de posición dinámica. |
| **Interfaz Móvil (UI)** | Editor de asignaciones (EXP Pedal / CTL1 / Assigns 1-8) | ✅ Completado | `AssignEditorModal` con configuración de CTL1, EXP, Toe Switch y las 8 matrices Assign. |
| **Conectividad** | Script de verificación interactiva de hardware (PC) | ✅ Completado | `tools/test_gt1b_hardware.sh` con detección de bloqueo de puertos y prueba en vivo de parches, afinador y efectos. |
| **Conectividad** | Pruebas físicas con pedalera real | ✅ Completado | Boss GT-1B probada exitosamente por USB: responde a identidad, conmuta efectos y cambia presets. |
| **Conectividad** | Conexión directa USB OTG y Web MIDI API | ✅ Completado | Conexión directa Plug & Play con reconexión automática periódica y recuperación de fallos. |
| **Conectividad** | Firmware para puente ESP32-S3 (BLE MIDI) | ✅ Código base | Código fuente funcional en `firmware/esp32_ble_midi_bridge/`. |
| **Conectividad** | Firmware para Arduino Uno + USB Host + HC-06 | ✅ Código base | Código de referencia en `firmware/arduino_usb_host_bridge/`. |
| **Librería & Datos** | Respaldo y exportación de patches (.tsl / JSON) | ✅ Completado | `TslSerializer` con exportación de LiveSets Boss Tone Studio (.tsl) y respaldo portable JSON. |
| **Librería & Datos** | Importador de archivos Boss Tone Studio (.tsl) | ✅ Completado | Parser y restaurador compatible al 100% con presets oficiales Boss Tone Studio. |
| **Librería & Datos** | Guardado en memoria física (Write a hardware) | ✅ Completado | Escritura directa `7F 00 01 04` en slots U01..U99 con protección de solo-lectura para P01..P99. |
| **Sistema & Utilidades** | Afinador en vivo, Global EQ, Metrónomo, USB | ✅ Completado | `SystemSettingsModal` y afinador cromático de alta precisión con aguja de centésimas en tiempo real. |
| **Multi-dispositivo** | Soporte para Smartphones y Tablets (Android/iOS) | ✅ Completado | Diseño responsivo adaptativo (2 columnas en móviles, 3-4 en tablets/iPad) con soporte vertical y apaisado. |
| **Multi-dispositivo** | Detección automática USB OTG (Plug & Play) | ✅ Completado | Filtro `device_filter.xml` con Vendor ID Boss `1410` (0x0582) y Product ID GT-1B `500` (0x01F3). |
| **Multi-dispositivo** | Compilación automática de APK (GitHub Actions) | ✅ Completado | Workflow CI/CD que compila el APK de release y corre los tests en cada push. |
| **Multi-dispositivo** | Soporte y selector para Boss GT-1 (Guitarra) | ⏳ Siguiente | Arquitectura modular desacoplada lista para cargar Model ID (`0x3B`). |

**Leyenda:**  
* ✅ **Completado:** Implementado, verificado en tests y probado con hardware real.  
* 🔄 **En progreso:** Código estructurado, en proceso de integración móvil/driver.  
* ⏳ **Pendiente:** Planificado en el roadmap para versiones posteriores.

---

## 📱 Soporte para Móviles y Tablets

La aplicación ha sido diseñada desde cero para pantallas táctiles de cualquier tamaño:

- **Smartphones (Android / iOS):**
  - Cuadrícula de 2 columnas de mini-pedales boutique optimizada para el pulgar.
  - Indicador de patch gigante de alto contraste visible en escenario (`U01`).
  - Barra de conmutación rápida de botones de goma iluminados (`COMP`, `OD/DS`, `PREAMP`, `FX1`, `FX2`, `DELAY`, `REV`, `WAH`).
  - Tarjeta de pedal de expresión dedicada para activar WAH de punta (*toe switch*) o modular el barrido con el dedo.

- **Tablets y iPads (Android / iPadOS):**
  - Cuadrícula adaptativa de 3 a 4 columnas de pedales con proporciones boutique reales.
  - Soporte completo para orientación vertical (*Portrait*) y apaisada (*Landscape*).
  - Mayor área táctil para ajuste preciso de perillas y perfiles de ecualización.

### 🔌 Conexión Directa USB OTG (Móvil / Tablet a GT-1B)
1. Conecta un cable **USB OTG** (USB-C a USB-B o Micro-USB según tu dispositivo) entre tu teléfono/tablet y el puerto USB de la Boss GT-1B.
2. Al conectar el cable, Android reconocerá automáticamente el dispositivo (Vendor ID `0x0582`, Product ID `0x01F3`) gracias a `device_filter.xml` y solicitará abrir **tone_gt_studio**.
3. La app iniciará la sincronización en vivo del preset activo y descargará automáticamente los 99 nombres de tus patches en segundo plano.

---

## 🚀 Cómo Levantar y Ejecutar la Aplicación

### 📋 Requisitos Previos
- **Flutter SDK:** versión >= 3.3.0 (`flutter --version`)
- **Navegador Web:** Google Chrome o Edge (para soporte de Web MIDI API con SysEx)
- **O Dispositivo Móvil:** Teléfono o Tablet con Android 8.0+ y cable adaptador **USB OTG** (USB-C / Micro-USB a USB-B de impresora)
- **Hardware:** Pedalera Boss GT-1B conectada por USB

---

### Opción 1: Ejecución Rápida en el Navegador (Web MIDI - PC / Laptop)
Esta es la forma más rápida de usar y depurar la app con la pedalera conectada al PC por USB:

1. Entra al directorio de la aplicación:
   ```bash
   cd tone_gt_studio/app
   ```
2. Instala las dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecuta la aplicación en Chrome:
   ```bash
   flutter run -d chrome
   ```
4. Al abrirse Chrome, conecta tu Boss GT-1B por USB. Cuando el navegador solicite permisos de dispositivos MIDI / SysEx, haz clic en **Permitir**.

> [!TIP]
> También puedes servir directamente la versión compilada de producción web:
> ```bash
> cd tone_gt_studio/app/build/web
> python3 -m http.server 8080
> ```
> Y abrir en Chrome: `http://localhost:8080`.

---

### Opción 2: Ejecución en Dispositivo Móvil o Tablet (Android)

1. Conecta tu teléfono o tablet a la computadora por cable USB con la **Depuración por USB activada** en Opciones de Desarrollador.
2. Verifica que Flutter reconozca tu dispositivo:
   ```bash
   flutter devices
   ```
3. Ejecuta la aplicación directamente en tu dispositivo:
   ```bash
   cd tone_gt_studio/app
   flutter run -d <id_de_tu_dispositivo>
   ```
4. Una vez instalada, desconecta el teléfono de la PC y conéctalo directamente a la Boss GT-1B usando un **cable USB OTG**.

---

### Opción 3: Compilar el APK de Producción para Android

Para generar el archivo instalador `.apk` listo para instalar en cualquier móvil o tablet:
```bash
cd tone_gt_studio/app
flutter build apk --release
```
El archivo generado se ubicará en:
`tone_gt_studio/app/build/app/outputs/flutter-apk/app-release.apk`

---

## 📜 Historial de Cambios y Despliegues

Para consultar el seguimiento detallado de todas las versiones, características añadidas y correcciones técnicas, consulta el archivo [CHANGELOG.md](file:///home/jmazons/Repositorios/BossGT1B/tone_gt_studio/CHANGELOG.md).

Para revisar el mapa exhaustivo de direcciones de memoria SysEx de todos los bloques y parámetros del hardware, consulta [docs/gt1b_full_parameter_map.md](file:///home/jmazons/Repositorios/BossGT1B/tone_gt_studio/docs/gt1b_full_parameter_map.md).

---

## 🛠️ Cómo Probar la Conexión con tu Boss GT-1B

1. Conecta la Boss GT-1B mediante cable USB a la computadora.
2. **IMPORTANTE:** Cierra cualquier otro programa que use el pedal (por ejemplo, *GT-1BFxFloorBoard* o DAWs como Ardour), ya que toman el puerto MIDI en modo exclusivo.
3. Ejecuta el verificador interactivo en una terminal:
   ```bash
   ./tools/test_gt1b_hardware.sh
   ```
4. Verás el menú interactivo para encender/apagar Overdrive, el afinador, o cambiar presets directamente en tu pedalera física.

---

## 📁 Estructura del repositorio

```text
tone_gt_studio/
├── app/                  # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── models/       # Modelos de datos (Patch, EffectBlock, EffectParameter)
│   │   ├── protocol/     # Motor SysEx de Roland y direcciones verificadas
│   │   ├── services/     # Controladores MIDI y gestión de estado
│   │   ├── ui/           # Interfaz de usuario, Stompbox cards, Knobs y Afinador
│   │   └── main.dart     # Entrada de la app
│   ├── test/             # Tests unitarios del protocolo SysEx
│   └── pubspec.yaml
├── firmware/             # Códigos puente inalámbricos (ESP32 / Arduino)
├── tools/                # Scripts de prueba y análisis de tráfico MIDI
└── docs/                 # Documentación técnica y mapa de memoria oficial
```

---

## 📄 Licencia
Este proyecto es de código abierto bajo la licencia MIT.

*Aviso legal: Boss y Roland son marcas registradas de Roland Corporation. Este proyecto es una iniciativa comunitaria independiente sin afiliación oficial con Roland Corporation.*
