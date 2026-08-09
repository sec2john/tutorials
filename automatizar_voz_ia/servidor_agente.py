import socket
import subprocess
import os
import sys
from google import genai
from google.genai import types

# 1. Comprobar API Key. Debes obtener una API KEY de GEMINI y crear
# una variable de entorno que la contenga.
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    print("[X] ERROR: GEMINI_API_KEY no definida.")
    sys.exit(1)

client = genai.Client()

SYSTEM_INSTRUCTION = """
Eres un agente de automatización y control de GUI para Linux Mint XFCE.
El usuario te dará órdenes enviadas por voz desde un cliente remoto.

REGLAS DE EJECUCIÓN:
1. Traduce la INTENCIÓN del usuario en una secuencia BASH/XDOTOOL perfecta y robusta.
2. Si abres una app gráfica, usa '&' y un 'sleep 1.5' antes de interactuar con ella mediante 'xdotool' o 'pyautogui'.
3. Encadena los pasos con '&&' cuando dependan uno de otro.
4. Responde ÚNICAMENTE con la línea de comandos Bash final ejecutable.
5. NO uses formato Markdown (sin ```), comentarios ni explicaciones. Solo el comando plano.
"""

HOST = "0.0.0.0"  # Escucha en todas las interfaces de red
PORT = 5000 #Este puerto debe coincidir con el definido en cliente_voz.py

def procesar_orden(orden_usuario):
    prompt = f"Orden recibida por voz: {orden_usuario}"
    try:
        response = client.models.generate_content(
            model='models/gemini-3.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,
                temperature=0.2
            )
        )
        comando = response.text.strip()

        # Limpiar bloques Markdown sobrantes
        if comando.startswith("```"):
            lineas = comando.split("\n")
            comando = "\n".join([l for l in lineas if not l.startswith("```")]).strip()

        return comando
    except Exception as e:
        print(f" [✗] Error en la llamada a Gemini: {e}")
        return None

def iniciar_servidor():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(5)
    
    print("\n" + "="*60)
    print(f" 🚀 [SERVIDOR AGENTE EN ESCUCHA]")
    print(f" Puerto: {PORT}")
    print(f" Esperando órdenes enviadas desde la máquina anfitriona...")
    print("="*60 + "\n")
    
    while True:
        conn, addr = server.accept()
        data = conn.recv(2048)
        if data:
            orden = data.decode('utf-8').strip()
            print(f"\n[🎙️ ORDEN RECIBIDA de {addr[0]}]: \"{orden}\"")

            comando = procesar_orden(orden)
            if comando:
                print(f" [⚙️ Ejecutando Bash]: \033[1;33m{comando}\033[0m")
                subprocess.run(comando, shell=True)
            else:
                print(" [!] No se pudo interpretar la orden.")

        conn.close()

if __name__ == "__main__":
    iniciar_servidor()

