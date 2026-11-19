# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [1.0.0] - 2026-11-19

### 🚀 Publicación Final y Cierre de Fases (Fases 5, 6, 7 y 8)

#### 🎛️ Fase 5: Control, EXP y Matrices Assign (CTL1 / EXP / Toe Switch & Assigns 1-8)
- Modelado completo e inmutable de asignaciones (`AssignSetting`, `CtlExpSetting`) en `app/lib/models/assign_model.dart`.
- Catálogo oficial Roland de funciones asignables, fuentes físicas y targets de modulación en `gt1b_assigns.dart`.
- Modal `AssignEditorModal` con dos pestañas de escenario:
  - `AssignCtlTab`: Configuración rápida de CTL1 (Función y Modo Latch/Momentary), EXP Pedal (Función, Min, Max) y Toe Switch (EXP SW).
  - `AssignMatrixTab`: Editor matricial de las 8 matrices Assign con switch ON/OFF, selección de target, rango calibrado (min/max), fuente física y modo.
- Ruteo SysEx DT1 bidireccional hacia las direcciones del buffer `60 00 07 50` y `60 00 08 10`.
- Rediseño del panel izquierdo (`StageLeftPanel`) como configurador puro de Master: Patch Level, Master BPM, Master Key y Master EQ de 4 bandas.

#### 🎚️ Fase 6: Sistema y Utilidades GT-1B
- Modelo integral `SystemSettings` en `app/lib/models/system_settings.dart`.
- Afinador cromático de alta precisión (`TunerModal`) con nota musical gigante en display neón, aguja reactiva de centésimas (-50..+50) procesando en tiempo real el flujo continuo DT1 `7F 00 05 00`, calibración de tono base (435..445 Hz) y selector de salida (Mute / Bypass).
- Modal `SystemSettingsModal` con 3 pestañas:
  - `SystemGlobalTab`: Selección de tipo de salida (Output Select para ampli o PA), nivel de entrada general, Global 4-Band Parametric EQ y Total Reverb.
  - `SystemMetronomeTab`: Metrónomo interno con tempo BPM (20..250), compás (1/4..7/8) y volumen.
  - `SystemUsbTab`: Ruteo USB Audio (Primary/Secondary, Direct Monitor) y configuración de apagado automático (Auto Off).
- Sincronización y lectura completa del bloque de sistema (`00 00 00 00`).

#### 💾 Fase 7: Librería y Persistencia
- Protocolo de escritura en memoria de hardware GT-1B (`buildPatchWrite`) con direccionamiento `7F 00 01 04`.
- Protección estricta de presets de fábrica: escritura bloqueada para índices ≥ 99 (`P01..P99`), garantizando la integridad de la ROM de la pedalera.
- Modal de guardado `PatchWriteModal` con selector de slot de usuario destino (`U01..U99`) y campo de renombrado con padding exacto de 16 caracteres ASCII.
- Copia directa de presets (`copyPatch`, `7F 00 01 00`) desde cualquier origen (incluso de fábrica) hacia un slot de usuario.
- Serializador bidireccional `TslSerializer`:
  - Exportación e importación de LiveSets oficiales compatibles con Boss Tone Studio (`.tsl`).
  - Respaldo portable individual en formato JSON.
- Modal de biblioteca `PatchListModal` reestructurado en tres pestañas: `USER (U01-U99)`, `FÁBRICA (P01-P99)` y `BACKUP & TSL`.

#### 🛡️ Fase 8: Robustez, Auto-Reconexión y Publicación
- Manejo resiliente de desconexiones imprevistas con transición automática a `MidiConnectionState.reconnecting`.
- Bucle periódico de reconexión sin bloqueo de interfaz y re-activación automática del Modo Editor Roland (`GtSysEx.buildEditorMode(enable: true)`).
- Barra visual interactiva de estado de reconexión en `StagePedalboardScreen` y badge en `StageHeaderBar`.
- Pacing seguro de peticiones masivas en el bus USB-MIDI (40 msg/s con timeout adaptativo) y soporte de cancelación instantánea (`cancelSync()`).
- Modularización de widgets de hardware en `pedal_hardware_widgets.dart`, asegurando que el 100% de los archivos de UI midan ≤ 300 líneas.
- 80/80 tests unitarios y de widgets superados con 100% de éxito.
- Compilación web para producción verificada (`flutter build web --release`).
- 10/10 reglas de arquitectura `codegraph` superadas (0 violaciones, 0 advertencias, 0 ciclos).

---

## [0.8.0] - 2026-11-18

### 🚀 Añadido (Fase 4: Algoritmos Dinámicos FX1 / FX2, Sincronización Completa y Cadena Drag & Drop)
- **Corrección Crítica de Sincronización de Efectos Activos (Solución al fallo de presets como U01):**
  - **Causa identificada:** Anteriormente, `selectPatch` y `_autoSyncFromHardware` solo consultaban el Bloque 0 (`60 00 00 00`), que únicamente contiene COMP, OD/DS y PREAMP. Efectos activos en la pedalera como FX1 (`60 00 01 00`), FX2 (`60 00 03 4C`), DELAY (`60 00 05 60`), CHORUS/REVERB (`60 00 06 00`) nunca eran solicitados al cambiar de preset, mostrando solo 2 efectos en pantalla cuando el pedal tenía 4 o más encendidos.
  - **Solución implementada:** Nuevo método unificado `syncFullActivePatch()` que interroga y procesa en secuencia todos los bloques del buffer temporal de la GT-1B: Bloque 0 (Preamp, OD, Comp), Bloque 1 (EQ, FX1), Bloque 3 (FX2), Bloque 5 (Delay), Bloque 6 (Chorus, Reverb, Wah, Foot Vol, NS) y Bloque 7 (Orden de cadena FX).
  - Al seleccionar cualquier preset (`U01..U99`, `P01..P99`) o recibir un cambio de programa de hardware, todos los efectos activos físicos se reflejan fielmente al 100%.
- **Línea de Conexión y Memory Edit Interactiva con Arrastre (`MemoryEditChainBar` & `ChainBlockChip`):**
  - Corrección de la posición del jack `[OUTPUT]`: ahora está limpiamente anclado a la derecha de la ruta de señal (`AMP / PA`), mientras que `[INPUT]` (`BASS IN`) está fijado a la izquierda.
  - Soporte de reordenamiento drag-and-drop horizontal mediante `ReorderableListView` con `ReorderableDelayedDragStartListener` y manejador visual táctil (`Icons.drag_indicator`).
  - Arrastrar cualquier cajita de efecto reordena la cadena en pantalla y transmite automáticamente la nueva configuración física a la pedalera mediante SysEx DT1 (`60 00 07 20`).
  - Modularización limpia: extracción de `ChainBlockChip` (120 líneas) y optimización de `MemoryEditChainBar` (278 líneas), cumpliendo la regla ≤ 300 líneas.
- **Catálogo y Motor de Algoritmos Dinámicos FX1 y FX2 (`Gt1bFxAlgorithms`):**
  - Modelado completo de los 36 algoritmos oficiales de la Boss GT-1B con prioridad en bajo eléctrico: `SUB OD/DS`, `T.WAH`, `AUTO WAH`, `SUB WAH`, `COMPRESSOR`, `LIMITER`, `GRAPHIC EQ`, `PARAMETRIC EQ`, `TONE MODIFY`, `BASS SIM`, `SLOW GEAR`, `DEFRETTER`, `BASS SYNTH`, `SITAR SIM`, `OCTAVE`, `PITCH SHIFTER`, `HARMONIST`, `SOUND HOLD`, `AC.PROCESSOR`, `PHASER`, `FLANGER`, `TREMOLO`, `ROTARY`, `UNI-V`, `PAN`, `SLICER`, `VIBRATO`, `RING MOD`, `HUMANIZER`, `2x2 CHORUS`, `SUB DELAY`, `AC.GUITAR SIM`, `ROTARY 2`, `OVERTONE`, `FEEDBACKER`, `CHORUS`.
  - Direccionamiento SysEx DT1 exacto para cada parámetro según el bloque (`01/02` para FX1 y `03/04/05/10` para FX2).
  - Reactividad bidireccional en el panel de edición: al cambiar el algoritmo en el dropdown (o en la pedalera vía `60 00 01 41` o `60 00 03 4D`), las perillas y controles se adaptan inmediatamente a los parámetros del nuevo efecto (ej. Octave muestra Oct Level y Direct Mix; Defretter muestra Attack, Reso, Depth, Sens, Tone).
- **Calidad y Verificación:**
  - 46/46 pruebas unitarias y de widgets pasando al 100% (`fx_algorithms_test.dart`, `stage_pedalboard_screen_test.dart`, etc.).
  - 0 advertencias o errores en `flutter analyze`.
  - 10/10 reglas de arquitectura `codegraph` superadas (0 violaciones, 0 ciclos, archivos ≤ 300 líneas).

---

## [0.7.0] - 2026-11-18

### 🚀 Añadido (Fase 3: Edición Profunda de Parámetros)
- **Catálogo Oficial Roland / Boss GT-1B Completo (`Gt1bCatalog`):**
  - Extracción y modelado de todas las opciones oficiales de la pedalera: 8 tipos de Compresor, 24 tipos de Overdrive/Distorsión, 13 tipos de Preamp de bajo, 12 tipos de caja/altavoz, 5 tipos de micrófonos, 7 tipos de Delay, 3 modos de Chorus, 7 tipos de Reverb, 7 tipos de Wah, 3 curvas de Foot Volume y 3 fuentes de detección para Noise Suppressor.
  - Parámetros extendidos en `EffectParameter` con offsets de visualización (`displayOffset`), unidades (`ms`, `dB`, `%`), selectores enum e interruptores toggle.
- **Panel Genérico de Edición de Parámetros (`EffectEditorPanel` y `param_controls.dart`):**
  - Panel modal de escenario horizontal optimizado para pantallas táctiles y escritorio sin scroll vertical.
  - Selector prominente de algoritmos y tipos de amplificador/efecto con nombres de modelos reales (`Concert 810`, `Bass OD`, `Plate`, `Tape Echo`, etc.).
  - Controles modulares: `ParameterKnob` con dial knurled giratorio, arco de valor iluminado y display de valores ajustados; `ToggleParamCard` para switches booleanos (`Bright`, `Solo Switch`); `EnumParamDropdown` para selectores secundarios (`Speaker Sim`, `Mic Type`, `Detect`).
- **Sincronización Bidireccional de Perillas Físicas en Tiempo Real:**
  - El giro físico de las perillas en la GT-1B actualiza inmediatamente los diales en pantalla mediante la captura y ruteo de paquetes SysEx DT1.
  - La manipulación táctil o con ratón de los diales en la app escribe hacia la pedalera a través de la cola con throttling y supresión de eco.
- **Calidad y Cobertura:**
  - 37 pruebas unitarias y de widgets pasando al 100% (`effect_editor_test.dart`).
  - 0 advertencias o errores en `flutter analyze`.
  - 10/10 reglas de arquitectura `codegraph` superadas (0 violaciones, 0 ciclos, archivos ≤ 300 líneas).

---

## [0.6.0] - 2026-11-18

### 🚀 Añadido (Fase 2: Escenario Horizontal y Espejo en Vivo)
- **Orientación Horizontal Bloqueada (`main.dart`):**
  - Configuración nativa de orientación forzada a horizontal (`DeviceOrientation.landscapeLeft` y `DeviceOrientation.landscapeRight`) para uso ergonómico en vivo sobre el escenario con móvil, tablet y web.
- **Arquitectura de Escenario en Tres Zonas sin Scroll Vertical (`LandscapeScaffold`):**
  - `app/lib/ui/layout/landscape_scaffold.dart` y `responsive_breakpoints.dart` con soporte adaptativo para resoluciones Wide (≥1150px), Medium (750-1149px) y Compact (<750px móvil horizontal).
- **Zona 1 (Izquierda): Panel de Botones Frontales de Silicona (`StageLeftPanel`):**
  - Réplica física de los 12 botones frontales de la GT-1B (`COMP`, `OD/DS`, `PREAMP`, `EQ`, `FX1`, `FX2`, `DELAY`, `REVERB`, `PEDAL FX`, `FOOT VOL`, `NS`, `MASTER`) con retroiluminación LED roja activa y respuesta instantánea al hardware en vivo.
- **Zona 2 (Centro): Línea de Señal y Pedalera Boutique (`StageCenterPanel`):**
  - Ruteo dinámico de cadena de audio (`MemoryEditChainBar`) con reflejo inmediato de cambios de slot (`60 00 07 20+n`).
  - Estante horizontal de mini-pedales boutique (`MiniPedalCard`) con chasis esmaltado, 3D Jewel LEDs con halo óptico y footswitch metálico animado con `FittedBox` anti-desbordamiento.
- **Zona 3 (Derecha): Expresión, WAH y Medidor Foot Volume (`StageRightPanel`):**
  - Treadle de pedal de expresión con pisador de punta (*toe switch*) y LED ámbar de activación WAH.
  - Medidor vertical de escalera LED continua (10 segmentos: verde, ámbar, rojo) para Foot Volume en vivo (`0..100%`, H10, D6).
- **Barra Superior de Escenario (`StageHeaderBar`):**
  - Indicador de estado de conexión con barra de progreso de sincronización real (0..100%).
  - Selector de parches con indicación de banco e índice (`U01..U99` y `P01..P99`), badge `[FABRICA]` para presets de solo lectura, botones de navegación ◀ ▶ con teclas dedicadas y acceso directo a afinador cromático.
- **Modularización y Calidad Estructural:**
  - Separación de `GatewayScreen` y reducción de `home_pedalboard_screen.dart` de 718 a 85 líneas (cumplimiento estricto del límite ≤ 300 líneas en todos los módulos).
  - 31 pruebas unitarias y de widgets pasando al 100%.
  - 10/10 reglas de arquitectura `codegraph` superadas (0 violaciones, 0 ciclos).

---

## [0.5.0] - 2026-11-18

### 🚀 Añadido (Fase 1: Refactor de Arquitectura y Verificación de Hardware)
- **Capa de Transporte Desacoplada (`MidiTransport` & `FakeTransport`):**
  - Interfaz abstracta `MidiTransport` en `app/lib/core/transport/midi_transport.dart`.
  - Simulador de hardware en memoria `FakeTransport` para ejecutar tests automatizados de sincronización completa sin necesidad de pedalera física conectada.
- **Motor SysEx Roland Puro (`RolandSysEx`):**
  - Motor de bajo nivel en `app/lib/protocol/roland_sysex.dart` con resolución estricta del defecto D1: emparejamiento de paquetes RQ1/DT1 por dirección completa de 4 bytes (`addressMatches`).
- **Soporte Completo de 198 Presets (Bancos U01..U99 y P01..P99):**
  - Integración de los dos bancos confirmados por hardware (H9): `U01..U99` (User, lectura y escritura, direcciones `10 nn 00 00`) y `P01..P99` (Factory Presets, solo lectura, direcciones `20 nn 00 00`).
  - Modelo `PatchRef` inmutable con indicador `isReadOnly` y visualización adecuada de badges `[FABRICA]` / `[SOLO LECTURA]`.
- **Cola de Escritura Throttled con Supresión de Eco (`WriteQueue`):**
  - Control de flujo a ~30 msg/s con deduplicación por dirección y supresión de eco DT1 emitido por la GT-1B tras escritura (H3).
- **Enrutador de Eventos Físicos (`EventRouter`):**
  - Enrutamiento reactivo en tiempo real de conmutadores de pedal (H10), reordenamiento de cadena por slot individual en Memory Edit (`60 00 07 20+n`, H8, D5), nivel continuo de Foot Volume 0..100 (H10, D6), y activación de modo Afinador.
- **Motor de Sincronización Escalonado (`SyncEngine`):**
  - Lectura en tramos ≤128 bytes para evitar fragmentación de paquetes en la GT-1B (H4).
  - Recarga e invalidación del patch temporal tras cambio de preset físico (H7, D7).
- **Controladores de Estado Especializados:**
  - `ConnectionController` como único dueño de la conexión y handshake de Modo Editor (D2).
  - `PatchController` y `LibraryController` para el manejo reactivo del patch activo y la biblioteca de 198 parches.
- **Generadores y Pruebas Unitarias:**
  - Catálogo auto-generado con `tools/gen_catalog.py` (`gt1b_map.dart` y `gt1b_catalog.dart`).
  - Cobertura completa de tests (25/25 pasando) en `sync_engine_test.dart`, `event_router_test.dart`, `roland_sysex_test.dart` y `gt_sysex_test.dart`.

---

## [0.4.0] - 2026-11-18

### 🚀 Añadido
- **Sincronización Bidireccional en Vivo (Hardware ➔ App):**
  - Implementación de activación automática del **Modo Editor Roland** (`7F 00 00 01 = 01`) al conectar con la GT-1B.
  - Escucha continua de eventos SysEx DT1 y Program Change (PC `0xC0`):
    - Al pulsar cualquier botón físico en la pedalera (`COMP`, `OD/DS`, `PREAMP`, `FX1`, `FX2`, `DELAY`), el Jewel LED y el botón en la app se encienden/apagan instantáneamente.
    - Al pulsar los footswitches de banco o preset en la pedalera, la app salta automáticamente al nuevo preset y consulta sus efectos.
    - Al activar el afinador en la pedalera (footswitches 1+2), la app abre o refleja el afinador cromático.
    - Al mover el pedal de expresión (barrido o conmutador de punta WAH), la app actualiza el estado en vivo.
    - Al girar las perillas físicas 1, 2 o 3, los parámetros en pantalla se actualizan en tiempo real.
- **Nuevos Bloques de Efectos Integrados:**
  - **Noise Suppressor (NS / N.SUPR):** Conmutación `60 00 06 63`, control de Threshold (`60 00 06 64`) y Release (`60 00 06 65`).
  - **Foot Volume (FV):** Nivel en vivo `60 00 06 33`, volumen mínimo/máximo y curva de respuesta.
  - **Ecualizador (EQ):** Switch `60 00 01 30` integrado en la barra física y en la cadena.
- **Puerta de Entrada Obligatoria (Paso 1: Conectar a la Pedalera):**
  - Pantalla inicial *Gateway* de alto contraste que exige conectar el cable USB OTG antes de mostrar las opciones.
  - Opción de "Modo Demo Offline" para pruebas de interfaz sin hardware conectado.
- **Documentación de Arquitectura de Memoria:**
  - Archivo `docs/gt1b_full_parameter_map.md` con las direcciones completas de los 12 bloques y su flujo de interacción.

---

## [0.3.0] - 2026-11-18

### 🚀 Añadido
- **Línea de Conexión y Ruteo Dinámico (MEMORY EDIT):**
  - Petición RQ1 a la dirección `60 00 07 20` (20 bytes) para leer el orden exacto configurado en la memoria de la GT-1B.
  - Widget interactivo `MemoryEditChainBar` mostrando la ruta de audio `[INPUT] ➔ [COMP] ➔ [OD] ➔ ... ➔ [OUTPUT]` con controles táctiles de reordenamiento.
- **Lectura Real de los 99 Presets Físicos:**
  - Consulta secuencial no bloqueante RQ1 a las direcciones `10 [patch] 00 00` para leer los nombres exactos creados por el usuario en su pedalera.
- **Auditoría Estructural Codegraph MCP:**
  - Indexación AST completa y verificación de 0 ciclos en el grafo de dependencias.
  - Refactorización de complejidad ciclomática en el puente Web MIDI (`app/web/midi_bridge.js`).

---

## [0.2.0] - 2026-11-18

### 🚀 Añadido
- **Interfaz Móvil Boutique:**
  - Reemplazo del diseño genérico por mini-pedales stompbox boutique (`MiniPedalCard`) con chasis esmaltado, Jewel LED 3D y switch metálico cromado.
  - Fila física de botones frontales negros GT-1B con retroiluminación LED roja.
  - Tarjeta de Pedal de Expresión y Footswitch WAH con pisador de punta (*toe switch*).
  - Indicador de preset gigante de escenario con navegación rápida táctil.
  - Afinador cromático y silenciador (Mute) en barra inferior fija.
  - Soporte responsivo para Smartphones (2 columnas) y Tablets (3 a 4 columnas).

---

## [0.1.0] - 2026-11-18

### 🚀 Añadido
- **Motor SysEx Roland / Boss:**
  - Cálculo de Checksum Roland de 7 bits (`(128 - (sum % 128)) & 0x7F`).
  - Generación de tramas DT1 (Data Set) y RQ1 (Data Request) para Model ID `00 00 00 3E`.
  - Conexión probada y verificada exitosamente en hardware físico Boss GT-1B mediante cable USB.
  - Script interactivo de diagnóstico en terminal: `tools/test_gt1b_hardware.sh`.
