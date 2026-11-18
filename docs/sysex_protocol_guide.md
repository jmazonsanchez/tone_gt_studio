# Guía del Protocolo Roland/Boss SysEx (Boss GT-1B)

Esta guía documenta la estructura de tramas MIDI System Exclusive (SysEx) utilizadas para la comunicación bidireccional entre **tone_gt_studio** y la pedalera **Boss GT-1B**.

---

## 1. Identificadores de Hardware (Header)

Toda trama SysEx dirigida a la Boss GT-1B sigue el formato estándar de Roland Corporation:

| Byte | Valor Hex | Descripción |
| :--- | :--- | :--- |
| **0** | `0xF0` | Inicio de trama SysEx (SOX - Start of Exclusive) |
| **1** | `0x41` | ID de fabricante (Roland Corporation) |
| **2** | `0x10` | Device ID por defecto (o canal de dispositivo) |
| **3..6** | `0x00, 0x00, 0x00, 0x3E` | Model ID de la **Boss GT-1B** (en GT-1 guitarra es `0x3B`) |
| **7** | `0x11` o `0x12` | Comando (`0x11` = RQ1 / Lectura, `0x12` = DT1 / Escritura) |
| **8..11**| `aa bb cc dd` | Dirección de memoria (4 bytes) |
| **12..N**| `data...` | Datos a escribir (en DT1) o longitud solicitada (en RQ1) |
| **N+1**| `chk` | Checksum de comprobación Roland (7 bits) |
| **N+2**| `0xF7` | Fin de trama SysEx (EOX - End of Exclusive) |

---

## 2. Cálculo del Checksum Roland

El checksum asegura que la dirección y los datos no se hayan corrompido durante la transmisión. Se calcula únicamente sobre los bytes de **dirección** y **datos** (los encabezados `F0 41 10 ...` no se incluyen en la suma):

$$\text{Suma} = \sum (\text{bytes de dirección} + \text{bytes de datos})$$
$$\text{Resto} = \text{Suma} \pmod{128}$$
$$\text{Checksum} = (128 - \text{Resto}) \pmod{128}$$

*Si el resultado es 128, el checksum es 0.*

---

## 3. Ejemplos Prácticos de Tramas

### A. Activar Afinador (Tuner)
* **Dirección:** `0x7F, 0x00, 0x05, 0x00`
* **Dato ON:** `0x01`
* **Cálculo:**
  * Suma: $127 + 0 + 5 + 0 + 1 = 133$
  * Resto: $133 \pmod{128} = 5$
  * Checksum: $128 - 5 = 123$ (`0x7B`)
* **Trama completa:**
  ```text
  F0 41 10 00 00 00 3E 12 7F 00 05 00 01 7B F7
  ```

### B. Desactivar Afinador (Mute Off)
* **Dato OFF:** `0x00`
* **Checksum:** `0x7C`
* **Trama completa:**
  ```text
  F0 41 10 00 00 00 3E 12 7F 00 05 00 00 7C F7
  ```

### C. Cambio de Patch (Preset)
Para cambiar de preset de usuario (U01 a U99), no es necesario SysEx completo; se envía un mensaje estándar **MIDI Program Change (PC)**:
* Canal 1: `0xC0 [Patch_Index]` (donde `0x00` = U01, `0x01` = U02 ... `0x62` = U99).
