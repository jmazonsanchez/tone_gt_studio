#!/usr/bin/env bash
# tone_gt_studio - Verificador de Hardware Boss GT-1B (v2.0)

echo "======================================================="
echo " 🎸 tone_gt_studio: Verificador de Hardware Boss GT-1B "
echo "======================================================="

# 1. Buscar dispositivo USB MIDI
PORT=$(amidi -l | grep -i "GT-1B" | awk '{print $2}' | head -n 1)

if [ -z "$PORT" ]; then
    echo "⚠️  No se detectó la Boss GT-1B conectada por USB."
    echo ""
    echo "Dispositivos MIDI actuales en el sistema:"
    amidi -l
    exit 1
fi

echo "✅ Boss GT-1B detectada en puerto: $PORT"

# Enviar Identity Request para verificar comunicación viva
echo -n "Probando enlace bidireccional con la pedalera... "
amidi -p "$PORT" -S "F0 7E 7F 06 01 F7" -t 1 > /tmp/gt1b_reply.hex 2>/dev/null
if [ -s /tmp/gt1b_reply.hex ]; then
    echo "¡CONEXIÓN CONFIRMADA! (Respondió: $(cat /tmp/gt1b_reply.hex))"
else
    echo "Enlace abierto."
fi

# Activar modo editor de comunicación Boss
amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 00 01 01 7F F7" 2>/dev/null

echo ""
echo "Elige una prueba:"
echo " 1) Activar AFINADOR (Mute ON - Device ID 00)"
echo " 2) Desactivar AFINADOR (Mute OFF)"
echo " 3) Cambiar a Patch U01 (Envía en todos los canales MIDI)"
echo " 4) Cambiar a Patch U02 (Envía en todos los canales MIDI)"
echo " 5) Cambiar a Patch U05 (Envía en todos los canales MIDI)"
echo " 6) Encender Overdrive (OD/DS ON)"
echo " 7) Apagar Overdrive (OD/DS OFF)"
echo " 8) Salir"
echo ""
read -p "Opción [1-8]: " OPCION

case "$OPCION" in
    1)
        echo "Enviando SysEx Tuner ON (Device ID 00 & 10)..."
        amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 00 01 01 7F F7"
        amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 05 00 01 7B F7"
        amidi -p "$PORT" -S "F0 41 10 00 00 00 3E 12 7F 00 05 00 01 7B F7"
        echo "Comando enviado. Revisa la pantalla de la GT-1B."
        ;;
    2)
        echo "Enviando SysEx Tuner OFF..."
        amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 05 00 00 7C F7"
        amidi -p "$PORT" -S "F0 41 10 00 00 00 3E 12 7F 00 05 00 00 7C F7"
        echo "Afinador desactivado."
        ;;
    3)
        echo "Cambiando a U01..."
        for ch in $(seq 0 15); do
            hex_ch=$(printf "%X" $((0xC0 + ch)))
            amidi -p "$PORT" -S "$hex_ch 00" 2>/dev/null
        done
        echo "Comando Program Change enviado a todos los canales MIDI."
        ;;
    4)
        echo "Cambiando a U02..."
        for ch in $(seq 0 15); do
            hex_ch=$(printf "%X" $((0xC0 + ch)))
            amidi -p "$PORT" -S "$hex_ch 01" 2>/dev/null
        done
        echo "Comando Program Change enviado a todos los canales MIDI."
        ;;
    5)
        echo "Cambiando a U05..."
        for ch in $(seq 0 15); do
            hex_ch=$(printf "%X" $((0xC0 + ch)))
            amidi -p "$PORT" -S "$hex_ch 04" 2>/dev/null
        done
        echo "Comando Program Change enviado a todos los canales MIDI."
        ;;
    6)
        echo "Enviando Overdrive ON..."
        amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 02 00 01 1D F7"
        echo "Overdrive activado."
        ;;
    7)
        echo "Enviando Overdrive OFF..."
        amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 02 00 00 1E F7"
        echo "Overdrive apagado."
        ;;
    *)
        echo "Saliendo."
        ;;
esac
