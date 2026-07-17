#!/usr/bin/env bash

PUERTO_ESCUCHA=5002
PC_IP="192.168.1.199"
PUERTO_PC=5001

CERT_MOVIL="/data/data/com.termux/files/home/certs/movil.pem"
CA_PC="/data/data/com.termux/files/home/certs/pc.crt"

echo "Servidor criptográfico activo en puerto $PUERTO_ESCUCHA..."

#Funcion para enviar resultados al PC usando TSL
function sendback() {
        echo "$1" | socat - OPENSSL:$PC_IP:$PUERTO_PC,cert=$CERT_MOVIL,cafile=$CA_PC,verify=1,commonname="PC-Linux-PAM" 2>/dev/null
}

while true; do
    # Escuchamos de forma segura mediante SSL/TLS.
    # Solo aceptamos conexiones si el PC presenta un certificado firmado/válido (verify=1)
    peticion=$(socat - OPENSSL-LISTEN:$PUERTO_ESCUCHA,cert=$CERT_MOVIL,cafile=$CA_PC,verify=1,commonname="PC-Linux-PAM" 2>/dev/null)

    if [ "$peticion" = "REQ" ]; then
        echo "Petición cifrada legítima recibida. Activando lector..."
# 1. Forzar a Termux a ponerse en primer plano (Foco absoluto de pantalla)
        # Levantamos la actividad principal de la consola
        am start --user 0 -n com.termux/.app.TermuxActivity >/dev/null 2>&1

# Pequeño margen para que Android renderice la ventana de Termux
        sleep 0.4

        # 2. Feedback físico (Vibración)
        termux-vibrate -d 300
        termux-notification --id 99 --title "Seguridad" --content "Pon tu huella para sudo" --priority high

        # 3. Lanzamos el lector de huellas (Ahora sí tiene el foco y saltará al 100%)
        resultado=$(termux-fingerprint)

        if echo "$resultado" | grep -q "AUTH_RESULT_SUCCESS"; then
            # Enviamos el "OK" de vuelta de forma cifrada al puerto seguro del PC
            sendback "OK"
            echo "Respuesta segura enviada."
        else
            echo "Autenticación fallida o cancelada."
            sendback "FAIL"
        fi
    else
            echo "Petición no soportada"
        fi
done
