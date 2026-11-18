#!/usr/bin/env bash
# tone_gt_studio - Herramienta de prueba de hardware directo para Boss GT-1B

echo "======================================================="
echo " 🎸 tone_gt_studio: Verificador de Hardware Boss GT-1B "
echo "======================================================="

# 1. Buscar dispositivo USB MIDI
PORT=$(amidi -l | grep -i "GT-1B" | awk '{print $2}' | head -n 1)

if [ -z "$PORT" ]; then
    echo "⚠️  No se detectó la Boss GT-1B conectada por USB."
    echo ""
    echo "Pasos para conectar:"
    echo " 1. Enciende tu pedalera Boss GT-1B."
    echo " 2. Conéctala a un puerto USB de esta computadora con su cable."
    echo " 3. Vuelve a ejecutar este script: bash tools/test_gt1b_hardware.sh"
    echo ""
    echo "Dispositivos MIDI actuales en el sistema:"
    amidi -l
    exit 1
fi

echo "✅ Boss GT-1B detectada en puerto: $PORT"
echo ""
echo "Elige una prueba:"
echo " 1) Activar AFINADOR (Mute ON en la pedalera)"
echo " 2) Desactivar AFINADOR (Mute OFF)"
echo " 3) Cambiar a Patch U01"
echo " 4) Cambiar a Patch U02"
echo " 5) Cambiar a Patch U05"
echo " 6) Encender Overdrive (OD/DS ON)"
echo " 7) Apagar Overdrive (OD/DS OFF)"
echo " 8) Salir"
echo ""
read -p "Opción [1-8]: " OPCION

case "$OPCION" in
    1)
        echo "Enviando SysEx Tuner ON..."
        amidi -p "$PORT" -S "F0 41 10 00 00 00 3E 12 7F 00 05 00 01 7B F7"
        echo "¡Revisa la pantalla de tu GT-1B! Debería estar en modo afinador."
        ;;
    2)
        echo "Enviando SysEx Tuner OFF..."
        amidi -p "$PORT" -S "F0 41 10 00 00 00 3E 12 7F 00 05 00 00 7C F7"
        echo "¡Afinador desactivado!"
        ;;
    3)
        echo "Enviando Program Change U01..."
        amidi -p "$PORT" -S "C0 00"
        echo "Pedalera cambiada a U01."
        ;;
    4)
        echo "Enviando Program Change U02..."
        amidi -p "$PORT" -S "C0 01"
        echo "Pedalera cambiada a U02."
        ;;
    5)
        echo "Enviando Program Change U05..."
        amidi -p "$PORT" -S "C0 04"
        echo "Pedalera cambiada a U05."
        ;;
    6)
        echo "Enviando SysEx OD/DS ON..."
        amidi -p "$PORT" -S "F0 41 10 00 00 00 3E 12 60 00 02 00 01 1D F7"
        echo "Overdrive activado en la GT-1B."
        ;;
    7)
        echo "Enviando SysEx OD/DS OFF..."
        amidi -p "$PORT" -S "F0 41 10 00 00 00 3E 12 60 00 02 00 00 1E F7"
        echo "Overdrive apagado en la GT-1B."
        ;;
    *)
        echo "Saliendo."
        ;;
esac
