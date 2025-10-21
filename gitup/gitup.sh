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
# - Configurar el nombre de usuario de git que hará la subida en la variable "myusername" más abajo
# - La url de git se crea en base a este esquema: https://myusername:"$GIT_TOKEN"@github.com/myusername/myrepo.git
#	- myusername: Nombre de usuario que actúa sobre el repo (configurado en la variable myusername)
#	- GIT_TOKEN: Env var externa con el token de git.
#	- @github... el resto de la url se extrae de .git/config de forma automatica.
# - Si se desea se puede incluir el token clásico de git en una variable de entorno llamada GIT_TOKEN. Este token se obtiene online de tu repositorio de git.
#	- En .bashr o equivalente incluir -> export GIT_TOKEN=<git_token....>, seguidamente -> source .bashrc
# - Si no, se solicitarán credenciales del push por consola.
#
# Nota: Crear una funcion en .bashrc llamada "gitup" tal que así:
# gitup () 
# { 
#    bash ~/scripts/gitup.sh "$@"
# }
# Donde la ruta lleva hasta este script con permisos de ejecución. 
# De esta forma se puede ejecutar "gitup 'message...'" en cualqueir directorio git.

# set -e: En caso de algun comando con error, para y sale inmediatamente.
set -e
cmtmssge=$(! [ -z $1 ] && echo "$1" || echo "$(date) - No message.") 

# CONFIG ################
myusername=""
if [ -z $myusername ]; then echo "username cannot be null. exiting..."; exit 2; fi
echo ">> username: $myusername"

#try to get url from .git/config
#        url = https://github.com/.....
configUrl=$(echo $(grep "url" .git/config | cut -d"=" -f2 ))
if [ -z $configUrl ]; then echo "Cannot find .git/config url. Execute the script in an initiated git folder repo. Exiting..."; exit 2; fi
echo ">> url found in .git/config: "
echo ">> $configUrl"
url=${configUrl/\:\/\//\:\/\/${myusername}:$GIT_TOKEN@}
echo ">> final url (GIT_TOKEN filtered): "
echo ">> ${url/\:*\@/:<TOKEN_FILTERED>@}"

read -p "Press Enter to continue or type 'exit' to quit: " userInput
if [ "$userInput" = "exit" ]; then
    echo "Exiting the script..."
    exit 0
fi   

#########################

echo
echo ">> git status..."
echo
git status -s

# Git pull first to get changes of the repository
#If env var with the token is present, pull automatically
#else... will ask for credentials
if ! [[ -z $GIT_TOKEN ]]
then       
	#url="https://myusername:"$GIT_TOKEN"@github.com/myusername/myrepo.git"
	url=${configUrl/\:\/\//\:\/\/${myusername}:$GIT_TOKEN@}
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
	#url="https://myusername:"$GIT_TOKEN"@github.com/myusername/myrepo.git"
	url=${configUrl/\:\/\//\:\/\/${myusername}:$GIT_TOKEN@}
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
