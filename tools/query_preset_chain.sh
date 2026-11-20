#!/usr/bin/env bash
# ==============================================================================
# query_preset_chain.sh
# Herramienta para consultar directamente a la pedalera física Boss GT-1B
# la cadena y orden de conexión de efectos de cualquier preset (ej. U02).
# ==============================================================================

set -e

PRESET="${1:-U02}"

python3 - <<EOF
import ctypes
import time
import sys
import re
import subprocess

preset_str = "$PRESET".strip().upper()
# Parse preset index (0..98 for U01..U99)
match = re.search(r'(\d+)', preset_str)
if match:
    preset_num = int(match.group(1))
    patch_idx = (preset_num - 1) if preset_num >= 1 else 0
else:
    preset_num = 2
    patch_idx = 1

# Detect ALSA Sequencer Client
dest_client = 20
dest_port = 0
try:
    aconnect_out = subprocess.check_output(['aconnect', '-l'], text=True)
    for line in aconnect_out.splitlines():
        if 'client' in line and 'GT-1B' in line:
            m = re.search(r'client\s+(\d+):', line)
            if m:
                dest_client = int(m.group(1))
except Exception:
    pass

asound = ctypes.CDLL('/usr/lib/x86_64-linux-gnu/libasound.so.2')

class SndSeqAddr(ctypes.Structure):
    _fields_ = [('client', ctypes.c_uint8), ('port', ctypes.c_uint8)]

class SndSeqEvExt(ctypes.Structure):
    _fields_ = [('len', ctypes.c_uint32), ('ptr', ctypes.c_void_p)]

class SndSeqEventData(ctypes.Union):
    _fields_ = [('ext', SndSeqEvExt), ('raw', ctypes.c_uint8 * 32)]

class SndSeqEvent(ctypes.Structure):
    _fields_ = [
        ('type', ctypes.c_uint8),
        ('flags', ctypes.c_uint8),
        ('tag', ctypes.c_int8),
        ('queue', ctypes.c_uint8),
        ('time_tick', ctypes.c_uint32),
        ('time_sec', ctypes.c_uint32),
        ('source', SndSeqAddr),
        ('dest', SndSeqAddr),
        ('data', SndSeqEventData),
    ]

seq_p = ctypes.c_void_p()
if asound.snd_seq_open(ctypes.byref(seq_p), b'default', 3, 0) < 0:
    print('❌ Error: No se pudo abrir ALSA Sequencer.')
    sys.exit(1)

my_client = asound.snd_seq_client_id(seq_p)
my_port = asound.snd_seq_create_simple_port(
    seq_p, b'gt1b_query',
    1 | 2 | 32 | 64,
    (1 << 20) | (1 << 1)
)
asound.snd_seq_connect_to(seq_p, my_port, dest_client, dest_port)
asound.snd_seq_connect_from(seq_p, my_port, dest_client, dest_port)

coder = ctypes.c_void_p()
asound.snd_midi_event_new(2048, ctypes.byref(coder))

def roland_cs(data):
    return (128 - (sum(data) % 128)) & 0x7F

def send_syx(syx):
    buf = (ctypes.c_ubyte * len(syx))(*syx)
    ev = SndSeqEvent()
    asound.snd_midi_event_encode(coder, buf, len(syx), ctypes.byref(ev))
    ev.source.client = my_client
    ev.source.port = my_port
    ev.dest.client = dest_client
    ev.dest.port = dest_port
    ev.queue = 253
    asound.snd_seq_event_output_direct(seq_p, ctypes.byref(ev))

# 1. Editor mode ON: F0 41 00 00 00 00 3E 12 7F 00 00 01 01 7F F7
send_syx(bytes([0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x12, 0x7F, 0x00, 0x00, 0x01, 0x01, 0x7F, 0xF7]))
time.sleep(0.04)

# 2. RQ1 Patch Name (10 [patch_idx] 00 00, len 16)
cs_name = roland_cs([0x10, patch_idx, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10])
send_syx(bytes([0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x11, 0x10, patch_idx, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, cs_name, 0xF7]))
time.sleep(0.04)

# 3. RQ1 FX Chain (10 [patch_idx] 07 20, len 20 = 0x14)
cs_chain = roland_cs([0x10, patch_idx, 0x07, 0x20, 0x00, 0x00, 0x00, 0x14])
send_syx(bytes([0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x11, 0x10, patch_idx, 0x07, 0x20, 0x00, 0x00, 0x00, 0x14, cs_chain, 0xF7]))

time.sleep(0.4)
asound.snd_seq_nonblock(seq_p, 1)
ev_in_p = ctypes.POINTER(SndSeqEvent)()
rx = (ctypes.c_ubyte * 1024)()

patch_name = None
fx_chain_slots = None

while asound.snd_seq_event_input(seq_p, ctypes.byref(ev_in_p)) >= 0:
    e = ev_in_p.contents
    if e.type == 130: # SNDRV_SEQ_EVENT_SYSEX
        l = asound.snd_midi_event_decode(coder, rx, len(rx), ev_in_p)
        msg = bytes(rx[:l])
        if len(msg) > 13 and msg[0] == 0xF0 and msg[1] == 0x41 and msg[7] == 0x12:
            addr = msg[8:12]
            payload = msg[12:-2]
            if addr == bytes([0x10, patch_idx, 0x00, 0x00]):
                patch_name = ''.join(chr(b) if 32 <= b <= 126 else ' ' for b in payload).strip()
            elif addr == bytes([0x10, patch_idx, 0x07, 0x20]):
                fx_chain_slots = list(payload)

asound.snd_seq_close(seq_p)

# ID to Effect Name mapping for Boss GT-1B
FX_NAMES = {
    1: ('FV', 'Foot Volume (Fijo/Ruteo)'),
    2: ('OD/DS', 'Overdrive / Distortion'),
    5: ('PDL', 'Pedal FX (Wah / Pitch Bend)'),
    6: ('DELAY', 'Delay'),
    7: ('FX2', 'FX2 Effects (Mod/Octaver)'),
    9: ('REVERB', 'Reverb'),
    11: ('FV', 'Foot Volume (Móvil)'),
    12: ('NS', 'Noise Suppressor'),
    13: ('PREAMP', 'PreAmp / Bass Amp (Canal A)'),
    15: ('FX1', 'FX1 Effects (Sub Wah / Mod)'),
    0: ('INPUT', 'Input Buffer'),
    4: ('SEND', 'Internal Send / Route A'),
    8: ('RETURN', 'Internal Return / Route B'),
    10: ('EQ_FIX', 'Fixed Pre-EQ / Filter'),
    14: ('MIX_A', 'Internal Mixer A'),
    17: ('MIX_B', 'Internal Mixer B'),
    18: ('MASTER', 'Master Level / EQ'),
    3: ('D_OUT', 'Direct USB Out L/R'),
    19: ('MAIN_OUT', 'Main Output L/Mono'),
    16: ('SUB_OUT', 'Sub Output R / Phones'),
}

print(f'======================================================================')
print(f' 🎸 CONSULTA DE CADENA DE EFECTOS EN HARDWARE BOSS GT-1B')
print(f'======================================================================')
print(f'Dispositivo ALSA:      Cliente {dest_client}:{dest_port} (Roland GT-1B MIDI 1)')
print(f'Preset Consultado:     U{preset_num:02d} (Índice de memoria: {patch_idx})')
print(f'Nombre en la Pedalera: "{patch_name if patch_name else "(Sin respuesta)"}"')
print(f'Dirección SysEx:       10 {patch_idx:02X} 07 20 (Longitud: 20 bytes)')
print(f'----------------------------------------------------------------------')

if not fx_chain_slots:
    print('❌ Error: No se recibió respuesta de cadena de efectos del pedal.')
    sys.exit(1)

print(f'Buffer crudo de 20 slots (Dirección 0x20 a 0x33):')
print(f'{fx_chain_slots}')
print(f'')
print(f'📌 DESGLOSE DETALLADO SEGÚN ARQUITECTURA OFICIAL BOSS GT-1B:')
print(f'----------------------------------------------------------------------')
print(f'1. Ruteo Fijo de Entrada (Slots 1..7 / Índices 0..6):')
for i in range(7):
    id_val = fx_chain_slots[i]
    tag, desc = FX_NAMES.get(id_val, (f'ID_{id_val}', 'Ruteo Fijo'))
    print(f'   - Posición {i+1:2d} (Byte 0x{0x20+i:02X}): ID {id_val:2d} [{tag}] -> {desc}')

print(f'')
print(f'2. 🎛️ CADENA MÓVIL DE 9 EFECTOS (Slots 8..16 / Índices 7..15) [DE IZQUIERDA A DERECHA]:')
movable = fx_chain_slots[7:16]
for idx, id_val in enumerate(movable, start=1):
    pos_num = 7 + idx
    byte_addr = 0x20 + 7 + idx - 1
    tag, desc = FX_NAMES.get(id_val, (f'ID_{id_val}', 'Efecto'))
    print(f'   {idx}️⃣  Posición {pos_num:2d} (Byte 0x{byte_addr:02X}): ID {id_val:2d} -> [{tag:7s}] : {desc}')

print(f'')
print(f'3. Ruteo Fijo de Salida / Master (Slots 17..20 / Índices 16..19):')
for i in range(16, 20):
    id_val = fx_chain_slots[i]
    tag, desc = FX_NAMES.get(id_val, (f'ID_{id_val}', 'Ruteo Salida'))
    print(f'   - Posición {i+1:2d} (Byte 0x{0x20+i:02X}): ID {id_val:2d} [{tag}] -> {desc}')

print(f'======================================================================')
print(f'RESUMEN VISUAL EN LA PEDALERA PARA PRESET U{preset_num:02d} (IZQUIERDA A DERECHA):')
summary_names = [FX_NAMES.get(x, (f'{x}', ''))[0] for x in movable]
print(f'  --> [ {" ] -> [ ".join(summary_names)} ] <--')
print(f'======================================================================')
EOF
