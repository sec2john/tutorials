#!/usr/bin/env python
import feedparser
import requests
import json
import re

# --- CONFIGURACIÓN ---
NTFY_URL = "https://ntfy.sh/noticias8764_SJ"
OLLAMA_URL = "http://localhost:11434/api/chat"

FEEDS_LINUX = [
    "https://www.muylinux.com/feed/",
    "https://www.phoronix.com/phoronix-rss.php",
    "https://ubunlog.com/feed/",
    "https://unaaldia.hispasec.com/feed",
    "https://feeds.feedburner.com/TheHackerNews",
    "https://archlinux.org/feeds/news/",
    "https://www.cyberciti.biz/feed/"
]

def limpiar_html(texto_html):
    if not texto_html:
        return ""
    texto_limpio = re.sub(r'<[^>]+>', '', texto_html)
    texto_limpio = re.sub(r'http\s+', '', texto_limpio)
    return " ".join(texto_limpio.split())

def consultar_ia_tags(titulo_noticia, cuerpo_noticia):
    print(f"    [*] Extrayendo tags técnicos para: {titulo_noticia[:30]}...")

    prompt_sistema = (
        "Eres un extractor de metadatos técnicos especializado en informática, Linux y ciberseguridad. "
        "Tu única tarea es leer el texto proporcionado, identificar las palabras técnicas clave "
        "y devolverlas en una única línea separadas por comas. "
        "No inventes palabras, no escribas introducciones y no uses listas. "
        "Devuelve un MÁXIMO de 10 tags en texto plano."
    )
    # Recortamos el contexto a los primeros 1000 caracteres como segundo muro de defensa
    # para que las noticias masivas de Arch no saturen la RAM del Xiaomi
    texto_contexto = f"TÍTULO: {titulo_noticia}\nCONTENIDO: {cuerpo_noticia[:1000]}"

    payload = {
        "model": "qwen2.5:0.5b",
        "messages": [
            {"role": "system", "content": prompt_sistema},
            {"role": "user", "content": texto_contexto}
        ],
        "stream": False
    }

    try:
        # Ponemos el timeout a 150 segundos (2-3 minutos)
        response = requests.post(OLLAMA_URL, json=payload, timeout=150)
        resultado = response.json()['message']['content'].strip()
        return resultado.replace("#", "").replace("\n", " ")

    except requests.exceptions.Timeout:
        print("    [!] ¡TIMEOUT! La IA ha tardado demasiado con esta noticia. Saltando...")
        return "TIMEOUT_EXCEEDED"  # Devolvemos un flag para saber qué pasó
    except Exception as e:
        return f"Error en extracción de tags: {e}"

def enviar_ntfy(titulo_feed, bloque_noticias):
    print(f"[*] Enviando boletín de {titulo_feed} a ntfy...")
    headers = {
        #"Title": "{titulo_feed}",
        "Priority": "default",
        "Tags": "penguin,bulb", # Icono de bombilla para las ideas de contenido
        "X-Markdown": "yes"
    }
    try:
        requests.post(NTFY_URL, data=bloque_noticias.encode('utf-8'), headers=headers, timeout=30)
        print(f"[+] ¡Boletín de {titulo_feed} enviado!")
    except Exception as e:
        print(f"[-] Error al notificar ntfy: {e}")

if __name__ == "__main__":
    print("[+] Iniciando el Agente de Contenido Linuxero Local...")

    for url in FEEDS_LINUX:
        try:
            feed = feedparser.parse(url)
            nombre_feed = feed.feed.title if 'title' in feed.feed else url
            print(f"\n[*] Procesando Feed: {nombre_feed}")

            reporte_feed = ""
            for i, entry in enumerate(feed.entries[:1]):
                #print(f"  -> Noticia {i+1}/4")

                cuerpo_sucio = ""
                if 'content' in entry:
                    cuerpo_sucio = entry.content[0].value
                elif 'summary' in entry:
                    cuerpo_sucio = entry.summary

