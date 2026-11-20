#!/bin/bash
# Script de apagado automático seguro para tone_gt_studio
# Diseñado para superar bloqueos de sesión GNOME e inhibidores de systemd sin requerir contraseña de root.

export XDG_RUNTIME_DIR="/run/user/1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
export DISPLAY=":0"
LOG_FILE="/tmp/auto_shutdown_gt1b.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === INICIANDO SECUENCIA DE APAGADO PC ===" > "$LOG_FILE"

# 1. Sincronizar buffers de disco
sync

# 2. Paso 1: Notificar a GNOME Session Manager de forma no bloqueante
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Paso 1] Notificando cierre a GNOME SessionManager..." >> "$LOG_FILE"
busctl --user call org.gnome.SessionManager /org/gnome/SessionManager org.gnome.SessionManager Shutdown >> "$LOG_FILE" 2>&1 &
gnome-session-quit --power-off --no-prompt >> "$LOG_FILE" 2>&1 &

sleep 3

# 3. Paso 2: Invocar systemctl poweroff ignorando inhibidores
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Paso 2] Ejecutando systemctl poweroff -i (ignorar inhibidores)..." >> "$LOG_FILE"
systemctl poweroff -i --no-ask-password >> "$LOG_FILE" 2>&1

sleep 4

# 4. Verificar si el sistema ya está en proceso de detención
STATE=$(systemctl is-system-running 2>/dev/null)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Estado actual de systemd: $STATE" >> "$LOG_FILE"

if [ "$STATE" = "stopping" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Sistema entrando en apagado (stopping). Proceso confirmado." >> "$LOG_FILE"
    exit 0
fi

# 5. Paso 3: Si un inhibidor de sesión persiste, detener la sesión gráfica para liberar el descriptor
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Paso 3] Liberando inhibidores de sesión gráfica..." >> "$LOG_FILE"
systemctl --user stop graphical-session.target >> "$LOG_FILE" 2>&1
systemctl --user stop gnome-session.target >> "$LOG_FILE" 2>&1
pkill -f gnome-session-service >> "$LOG_FILE" 2>&1
pkill -f gnome-session-binary >> "$LOG_FILE" 2>&1

sleep 2

# 6. Paso 4: Con inhibidores liberados, ejecutar poweroff estándar
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Paso 4] Ejecutando poweroff estándar con sesión liberada..." >> "$LOG_FILE"
systemctl poweroff --no-ask-password >> "$LOG_FILE" 2>&1

# 7. Bucle de sondeo y reintento continuo
ATTEMPT=1
while true; do
    sleep 6
    STATE=$(systemctl is-system-running 2>/dev/null)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Sondeo $ATTEMPT] Estado del sistema: $STATE" >> "$LOG_FILE"
    if [ "$STATE" = "stopping" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Sistema apagándose." >> "$LOG_FILE"
        exit 0
    fi
    systemctl poweroff -i --no-ask-password >> "$LOG_FILE" 2>&1
    systemctl poweroff --no-ask-password >> "$LOG_FILE" 2>&1
    busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager PowerOff b true >> "$LOG_FILE" 2>&1
    ATTEMPT=$((ATTEMPT + 1))
done
