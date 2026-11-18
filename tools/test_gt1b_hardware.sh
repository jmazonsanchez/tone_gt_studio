#!/usr/bin/env bash
# tone_gt_studio - Verificador Interactivo de Hardware Boss GT-1B (v3.0)
set -e

echo "======================================================="
echo " 🎸 tone_gt_studio: Verificador de Hardware Boss GT-1B "
echo "======================================================="

# 1. Verificar si hay procesos bloqueando el puerto MIDI
LOCKED_PIDS=$(pgrep -f "GT-1BFxFloorBoard" || true)
if [ -n "$LOCKED_PIDS" ]; then
    echo "⚠️  Detectado proceso 'GT-1BFxFloorBoard' (PID: $LOCKED_PIDS) bloqueando el puerto MIDI."
    read -p "¿Deseas cerrarlo para liberar el pedal? [s/N]: " RESP
    if [[ "$RESP" =~ ^[sSyY]$ ]]; then
        kill -9 $LOCKED_PIDS 2>/dev/null || true
        sleep 1
        echo "✅ Puerto liberado."
    else
        echo "❌ No se puede continuar mientras el puerto esté bloqueado por otra aplicación."
        exit 1
    fi
fi

# 2. Buscar dispositivo USB MIDI
PORT=$(amidi -l | grep -i "GT-1B" | awk '{print $2}' | head -n 1)

if [ -z "$PORT" ]; then
    echo "⚠️  No se detectó la Boss GT-1B conectada por USB."
    echo ""
    echo "Dispositivos MIDI actuales en el sistema:"
    amidi -l
    exit 1
fi

echo "✅ Boss GT-1B detectada en puerto ALSA: $PORT"

# 3. Enviar Universal Identity Request
echo -n "Probando enlace bidireccional con la pedalera... "
REPLY=$(amidi -p "$PORT" -S "F0 7E 7F 06 01 F7" -t 1 -d 2>/dev/null | tr -d '\n' | head -c 50 || true)
if [ -n "$REPLY" ]; then
    echo "¡CONEXIÓN CONFIRMADA!"
    echo "   Respuesta del pedal: $REPLY"
else
    echo "Enlace abierto (sin respuesta inmediata)."
fi

# Inicializar modo editor SysEx
amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 00 01 01 7F F7" 2>/dev/null || true

while true; do
    echo ""
    echo "======================================================="
    echo " Elige una acción para probar en tu pedal físico:     "
    echo "======================================================="
    echo " 1) Cambiar a Patch U01 (SysEx DT1 00 01 00 00 00 00)"
    echo " 2) Cambiar a Patch U02 (SysEx DT1 00 01 00 00 00 01)"
    echo " 3) Cambiar a Patch U05 (SysEx DT1 00 01 00 00 00 04)"
    echo " 4) Activar AFINADOR (Tuner Mode ON: 7F 00 00 02 01)"
    echo " 5) Desactivar AFINADOR (Play Mode: 7F 00 00 02 00)"
    echo " 6) Encender OVERDRIVE (OD/DS ON: 60 00 00 30 01)"
    echo " 7) Apagar OVERDRIVE (OD/DS OFF: 60 00 00 30 00)"
    echo " 8) Encender COMPRESSOR (COMP ON: 60 00 00 20 01)"
    echo " 9) Apagar COMPRESSOR (COMP OFF: 60 00 00 20 00)"
    echo " 10) Encender DELAY (DELAY ON: 60 00 05 60 01)"
    echo " 11) Apagar DELAY (DELAY OFF: 60 00 05 60 00)"
    echo " 12) Monitor en tiempo real (mueve botones en el pedal)"
    echo " 13) Salir"
    echo "======================================================="
    read -p "Opción [1-13]: " OPCION

    case "$OPCION" in
        1)
            echo "Enviando Patch U01..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 00 01 00 00 00 00 7F F7"
            echo "✅ Patch U01 enviado. ¡Mira la pantalla del Boss GT-1B!"
            ;;
        2)
            echo "Enviando Patch U02..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 00 01 00 00 00 01 7E F7"
            echo "✅ Patch U02 enviado. ¡Mira la pantalla del Boss GT-1B!"
            ;;
        3)
            echo "Enviando Patch U05..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 00 01 00 00 00 04 7B F7"
            echo "✅ Patch U05 enviado. ¡Mira la pantalla del Boss GT-1B!"
            ;;
        4)
            echo "Activando Afinador..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 00 02 01 7E F7"
            echo "✅ Afinador activado en la pedalera."
            ;;
        5)
            echo "Desactivando Afinador..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 7F 00 00 02 00 7F F7"
            echo "✅ Afinador desactivado (Modo Play)."
            ;;
        6)
            echo "Encendiendo Overdrive..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 00 30 01 6F F7"
            echo "✅ OD/DS encendido (LED encendido)."
            ;;
        7)
            echo "Apagando Overdrive..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 00 30 00 70 F7"
            echo "✅ OD/DS apagado."
            ;;
        8)
            echo "Encendiendo Compressor..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 00 20 01 7F F7"
            echo "✅ COMP encendido."
            ;;
        9)
            echo "Apagando Compressor..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 00 20 00 00 F7"
            echo "✅ COMP apagado."
            ;;
        10)
            echo "Encendiendo Delay..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 05 60 01 3A F7"
            echo "✅ DELAY encendido."
            ;;
        11)
            echo "Apagando Delay..."
            amidi -p "$PORT" -S "F0 41 00 00 00 00 3E 12 60 00 05 60 00 3B F7"
            echo "✅ DELAY apagado."
            ;;
        12)
            echo "📡 Escuchando eventos SysEx del Boss GT-1B en tiempo real..."
            echo "   (Mueve potenciómetros, footswitches o botones en la pedalera)."
            echo "   (Presiona Ctrl+C para regresar al menú)"
            trap 'echo -e "\nMonitor finalizado."' INT
            amidi -p "$PORT" -d || true
            trap - INT
            ;;
        13)
            echo "¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
done
