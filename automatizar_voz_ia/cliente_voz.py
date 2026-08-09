import socket
import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav
import tempfile
import os
import whisper

# CONFIGURACIÓN DE RED DE LA VM
VM_IP = "192.168.1.XXX"  # <--- CAMBIA ESTO por la IP real de tu máquina virtual
VM_PORT = 5000 # <--- CAMBIA EL PUERTO POR EL QUE PREFIERAS

# CONFIGURACIÓN DE AUDIO
SAMPLE_RATE = 16000

print("[*] Cargando modelo Whisper en el anfitrión...")
# 'tiny' o 'base' para máxima velocidad de respuesta en vivo
model = whisper.load_model("base") 

def enviar_socket(texto_orden):
    try:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.settimeout(5)
        client.connect((VM_IP, VM_PORT))
        client.sendall(texto_orden.encode('utf-8'))
        client.close()
        print(f"[📡 ENVIADO A VM]: \"{texto_orden}\"")
    except Exception as e:
        print(f"[❌ ERROR AL CONECTAR CON VM ({VM_IP}:{VM_PORT})]: {e}")

def grabar_hasta_enter():
    print("\n[🎙️ GRABANDO... Habla todo el tiempo que necesites. Presiona ENTER para finalizar]")
    
    frames = []
    
    def callback(indata, frame_count, time_info, status):
        if status:
            print(f"[!] Error de audio: {status}", file=sys.stderr)
        frames.append(indata.copy())

    # Iniciar flujo de grabación en segundo plano
    stream = sd.InputStream(samplerate=SAMPLE_RATE, channels=1, dtype='float32', callback=callback)
    with stream:
        input() # Mantiene la grabación activa hasta que el usuario pulsa ENTER de nuevo

    print("[⌛ Deteniendo grabación y procesando con Whisper...]")
    
    if not frames:
        return ""

    # Concatenar todos los bloques de audio grabados
    audio = np.concatenate(frames, axis=0)
    audio_int16 = (audio * 32767).astype(np.int16)

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as fp:
        wav.write(fp.name, SAMPLE_RATE, audio_int16)
        temp_filename = fp.name

    # Transcripción limpia desactivando fp16 para evitar NaN en CUDA
    result = model.transcribe(temp_filename, language="es", fp16=False)
    texto = result["text"].strip()
    
    if os.path.exists(temp_filename):
        os.remove(temp_filename)
        
    return texto

if __name__ == "__main__":
    print("\n" + "="*60)
    print(" 🎙️ CLIENTE DE VOZ DINÁMICO (Anfitrión -> VM Linux Mint)")
    print(" Presiona ENTER para EMPEZAR a hablar y ENTER para TERMINAR.")
    print(" Escribe 'q' y Enter para salir.")
    print("="*60 + "\n")
    
    while True:
        opcion = input("\n[Presiona ENTER para iniciar grabación / 'q' para salir]: ")
        if opcion.lower() == 'q':
            break
            
        orden_texto = grabar_hasta_enter()
        
        if orden_texto:
            print(f"[📝 Transcripción Whisper]: \"{orden_texto}\"")
            enviar_socket(orden_texto)
        else:
            print("[!] No se detectó ninguna palabra.")
