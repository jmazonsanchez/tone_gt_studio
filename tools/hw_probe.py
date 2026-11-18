#!/usr/bin/env python3
"""Verificacion de hardware Boss GT-1B (sin dependencias, usa `amidi` de ALSA).

Uso:
  tools/hw_probe.py auto               # pruebas automaticas (lectura + eco de escritura)
  tools/hw_probe.py listen [segundos] [--editor]   # escucha pasiva; pulsa botones en la pedalera

Todos los hallazgos se imprimen y se guardan en docs/hardware_findings_raw.log
"""
import subprocess, sys, time, datetime, os

PORT = os.environ.get("GT_PORT", "hw:1,0,0")
HDR = [0xF0, 0x41, 0x00, 0x00, 0x00, 0x00, 0x3E]
LOG = os.path.join(os.path.dirname(__file__), "..", "docs", "hardware_findings_raw.log")


def checksum(body):
    return (128 - (sum(body) % 128)) & 0x7F


def dt1(addr, data):
    body = list(addr) + list(data)
    return HDR + [0x12] + body + [checksum(body), 0xF7]


def rq1(addr, size):
    sz = [(size >> 21) & 0x7F, (size >> 14) & 0x7F, (size >> 7) & 0x7F, size & 0x7F]
    body = list(addr) + sz
    return HDR + [0x11] + body + [checksum(body), 0xF7]


def hexs(b):
    return " ".join(f"{x:02X}" for x in b)


def log(line):
    print(line)
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    with open(LOG, "a") as f:
        f.write(f"{datetime.datetime.now().isoformat(timespec='milliseconds')} {line}\n")


def xfer(send, secs):
    """Envia (opcional) y captura durante `secs`. Devuelve lista de mensajes (bytes)."""
    cmd = ["amidi", "-p", PORT]
    if send:
        cmd += ["-S", hexs(send)]
    cmd += ["-d", "-t", str(max(1, int(round(secs))))]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    toks = [int(t, 16) for t in out.split() if len(t) == 2]
    msgs, cur = [], []
    for t in toks:
        if t == 0xF0:
            cur = [t]
        elif cur:
            cur.append(t)
            if t == 0xF7:
                msgs.append(bytes(cur)); cur = []
        else:
            msgs.append(bytes([t]))  # bytes sueltos (PC, CC...) - se agrupan abajo
    return msgs


def regroup(msgs):
    """Agrupa bytes sueltos en mensajes MIDI cortos (C0 xx / B0 xx yy)."""
    res, buf = [], []
    for m in msgs:
        if len(m) > 1 or m[0] == 0xF0:
            if buf: res.append(bytes(buf)); buf = []
            res.append(m)
        else:
            b = m[0]
            if b & 0x80 and buf:
                res.append(bytes(buf)); buf = []
            buf.append(b)
    if buf: res.append(bytes(buf))
    return res


def describe(m):
    if m[0] == 0xF0 and len(m) > 12 and m[7] == 0x12:
        a = m[8:12]; d = m[12:-2]
        return f"DT1 addr={hexs(a)} data={hexs(d[:16])}{'...' if len(d)>16 else ''} (len={len(d)})"
    return hexs(m)


def editor(on):
    return dt1([0x7F, 0x00, 0x00, 0x01], [1 if on else 0])


def cmd_auto():
    log("=== AUTO PROBE ===")
    r = regroup(xfer([0xF0, 0x7E, 0x7F, 0x06, 0x01, 0xF7], 2))
    log(f"[1] Identity reply: {[describe(x) for x in r]}")

    r = regroup(xfer(rq1([0x60, 0x00, 0x00, 0x00], 0x80), 2))
    log(f"[2] RQ1 60 00 00 00 (sin modo editor): {len(r)} msgs -> {[describe(x) for x in r]}")
    base = next((x for x in r if len(x) > 12 and x[7] == 0x12), None)

    r = regroup(xfer(editor(True), 2))
    log(f"[3] Editor ON -> respuesta inmediata: {[describe(x) for x in r]}")

    r = regroup(xfer(None, 4))
    log(f"[4] Escucha pasiva 4s tras editor ON (sin tocar nada): {[describe(x) for x in r]}")

    # Eco de escritura: leer OD/DS, invertir, observar respuesta, restaurar
    rr = regroup(xfer(rq1([0x60, 0x00, 0x00, 0x30], 1), 2))
    cur = next((x for x in rr if len(x) > 12 and x[7] == 0x12), None)
    if cur:
        orig = cur[12]
        new = 0 if orig else 1
        r = regroup(xfer(dt1([0x60, 0x00, 0x00, 0x30], [new]), 2))
        log(f"[5] Escritura OD/DS {orig}->{new}; respuesta/eco del equipo: {[describe(x) for x in r]}")
        chk = regroup(xfer(rq1([0x60, 0x00, 0x00, 0x30], 1), 2))
        log(f"[6] Relectura OD/DS: {[describe(x) for x in chk]}")
        xfer(dt1([0x60, 0x00, 0x00, 0x30], [orig]), 1)
        log(f"[7] OD/DS restaurado a {orig}")
    else:
        log("[5] No se pudo leer OD/DS")

    # Tamanos de lectura soportados
    for size in (0x10, 0x40, 0x80, 0x100):
        r = regroup(xfer(rq1([0x60, 0x00, 0x00, 0x00], size), 2))
        sizes = [len(x) - 14 for x in r if len(x) > 14 and x[7] == 0x12]
        log(f"[8] RQ1 60 00 00 00 size={size:#x}: paquetes DT1 con datos {sizes}")

    xfer(editor(False), 1)
    log("[9] Editor OFF enviado")


def cmd_listen(secs, with_editor):
    log(f"=== LISTEN {secs}s editor={with_editor} ===")
    if with_editor:
        xfer(editor(True), 1)
        log("Editor ON enviado")
    log(">>> PULSA AHORA botones / mueve el pedal / cambia de preset <<<")
    # Una sola captura continua (evita perder eventos entre aperturas del puerto)
    r = regroup(xfer(None, secs))
    if not r:
        log("SIN EVENTOS durante la captura")
    for m in r:
        log(f"EVENTO {describe(m)}")
    if with_editor:
        xfer(editor(False), 1)
        log("Editor OFF enviado")


if __name__ == "__main__":
    a = sys.argv[1:] or ["auto"]
    if a[0] == "auto":
        cmd_auto()
    elif a[0] == "listen":
        s = int(a[1]) if len(a) > 1 and a[1].isdigit() else 30
        cmd_listen(s, "--editor" in a)
