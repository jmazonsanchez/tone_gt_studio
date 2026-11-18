# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/lang/es/).

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
