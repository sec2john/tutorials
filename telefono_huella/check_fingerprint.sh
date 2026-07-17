#!/usr/bin/env bash
# Colocar en /usr/local/bin/check_fingerprint.sh
# Configuración de Red
MOVIL_IP="192.168.1.129"
PUERTO_MOVIL=5002
PUERTO_ESCUCHA_PC=5001
TIMEOUT=15

# Rutas a tus certificados en el PC
CERT_PC="/home/sec2john/certs/pc.pem"
CA_MOVIL="/home/sec2john/certs/movil.crt"

echo -e "\e[1;33m[Biometría]\e[0m Se requiere huella en tu dispositivo móvil..."

# Creamos un archivo temporal en la memoria RAM para la comunicación entre procesos
TMP_FILE=$(mktemp -p /dev/shm fingerprint_XXXXXX)

# 1. ESCUCHAR PRIMERO (En segundo plano)
timeout $TIMEOUT socat - OPENSSL-LISTEN:$PUERTO_ESCUCHA_PC,reuseaddr,cert=$CERT_PC,cafile=$CA_MOVIL,verify=1,commonname="Mi-A2Lite-Mobil" 2>/dev/null > "$TMP_FILE" &
SOCAT_PID=$!

# Pausa para asegurar que el socket está listo
sleep 0.2

# 2. ENVIAR DESPUÉS
socat - OPENSSL:$MOVIL_IP:$PUERTO_MOVIL,cert=$CERT_PC,cafile=$CA_MOVIL,verify=1,commonname="Mi-A2Lite-Mobil" 2>/dev/null <<< "REQ"

if [ $? -ne 0 ]; then
    kill $SOCAT_PID 2>/dev/null
    rm -f "$TMP_FILE"
    exit 1
fi

# 3. ESPERAR a que interactúes con el móvil
wait $SOCAT_PID 2>/dev/null

# Leemos el resultado
respuesta=$(cat "$TMP_FILE")
rm -f "$TMP_FILE"

# 4. EVALUAR EL RESULTADO (Silencioso para PAM)
if [ "$respuesta" = "OK" ]; then
    exit 0  # PAM da paso libre
else
    exit 1  # PAM solicita la contraseña tradicional
fi
