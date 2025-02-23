#!/usr/bin/env bash
# Script que realiza una subida automática a un repositorio git: APTO para backup en git
# Ejecutar en el directorio del repositorio de git así:
        # gitup "MESSAGE to the commit (use double quotes)"
# Importante: Este comando no maneja todas las posibles casuísticas relacioandas con el estado de un repositorio (branches, numero de commits por delante, etc)
# Antes de ejecutarlo asegurarse de que el repositorio se encuentra en un estado adecuado antes de un git add, commit y push.
#
# Condiciones del repo:
# - previamente clonado (clone) y en funcionamiento (init)
#
# Pasos para la configuración:
# - Configurar la url del repositorio en la variable 'url' definida más abajo
# - Si se desea se puede incluir el token clásico de git en una variable de entorno llamada GIT_TOKEN. Este token se obtiene online de tu repositorio de git.
#	- En .bashr o equivalente incluir -> export GIT_TOKEN=<git_token....>, seguidamente -> source .bashrc
# - Si no, se solicitarán credenciales del push por consola.

# set -e: En caso de algun comando con error, para y sale inmediatamente.
set -e
cmtmssge=$(! [ -z $1 ] && echo "$1" || echo "$(date) - No message.") 

echo
echo ">> git status..."
echo
git status -s

# Git pull first to get changes of the repository
#If env var with the token is present, pull automatically
#else... will ask for credentials
if ! [[ -z $GIT_TOKEN ]]
then       
	url="https://myusername:"$GIT_TOKEN"@github.com/myusername/myrepo.git"
	echo ">> git token found in env var."
        echo ">> pulling from url "${url/\:*\@/:<TOKEN_FILTERED>@}        
        echo 
	git pull "$url"
	echo 
else       
	echo ">> git token NOT found in env var."        
	echo ">> pulling from repo using user/pass credentials"
	git pull
	echo
fi 

echo
echo ">> git add... "
echo
git add .

echo
echo ">> git commit with message: \"$cmtmssge\""
echo
git commit -m "$cmtmssge"
echo

#If env var with the token is present, update automatically
#else... will ask for credentials
if ! [[  -z $GIT_TOKEN ]]
then
	# place your repo url here
	url="https://myusername:"$GIT_TOKEN"@github.com/myusername/myrepo.git"
	echo ">> git token found in env var."
	echo ">> pushing to url "${url/\:*\@/:<TOKEN_FILTERED>@}
	echo 
	git push "$url"
	echo
else
    	echo ">> git token NOT found in env var."
    	echo ">> pushing to repo using user/pass credentials"
	git push
	echo
fi
