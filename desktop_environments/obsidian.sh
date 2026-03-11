#!/bin/zsh

# 1. Configuración de rutas y variables
REPO_PATH="$HOME/git/obsidian"
REMOTE_URL="https://sec2john:${GIT_TOKEN}@github.com/sec2john/obsidian.git"

cd "$REPO_PATH" || exit

# 2. Sincronización de entrada (Pre-apertura)
# Usamos git pull para traer cambios
git pull "$REMOTE_URL" > /dev/null 2>&1

# 3. Lanzar la aplicación (BLOQUEANTE)
# Al NO poner '&' aquí, el script se detiene en esta línea hasta que cierres Obsidian
flatpak run md.obsidian.Obsidian

# 4. Sincronización de salida (Post-cierre)
# Esta parte se ejecuta SOLO cuando Obsidian se cierra por completo
source ~/.zsh/gitup
gitup


