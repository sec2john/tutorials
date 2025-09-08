#!/usr/bin/env bash

# === Configuration ===
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.2"

# === Global vars ===

declare -r SEPARATOR="@#¬¬#@"
oriFolder=	#DIRECTORIO_ORIGINAL, pasado por parámetro y validado
destFolder=	#DIRECTORIO_DESTINO (opcional) pasado por parámetro y validado
auxFolder= #Variable auxiliar

FILES=  #Array de ficheros formato " mtime || PATH "

tmpFolder="/tmp/"


# === Utility functions ===

print_help() {
    cat << EOF
Uso: $SCRIPT_NAME [OPCIÓN] DIRECTORIO_ORIGEN [DIRECTORIO_DESTINO]

Utilidad que escanea un DIRECTORIO_ORIGEN buscando ficheros de determinadas extensiones.
Luego ofrece una estructura de subdirectorios nombrados por fecha de modificación.
Si el usuario lo permite, se crea esta estructura en un [DIRECTORIO_DESTINO] 
y bien se copian o se mueven (cortar-pegar) los archivos originales al mismo donde corresponden.
El principal objetivo es organizar fotografías y videos que se acumulan en un teléfono móvil,
pero los casos de uso pueden variar.


Options:
  -s, --scan		(Primer paso) Realiza un escaneo del directorio y ofrece resultados
  -m, --menu        Show interactive menu
  -v, --version     Show script version
  -f, --file <path> Specify a file (example parameter)		
  -h, --help        Muestra la ayuda
  

Examples:
  $SCRIPT_NAME --menu
  $SCRIPT_NAME -f input.txt
EOF
}

print_error() {
    echo "  ❌ Error: $1" >&2
}

ask_folder() {
    echo
    echo " >> Indica el nuevo $1:"
    read -rp " >> " auxFolder        
}

print_structure() {
    local tmpfile="${2:-/tmp/mediabacker_fullstruct.tmp}"  # archivo opcional como segundo parámetro
    
    # Crear/limpiar el fichero antes de empezar
    : > "$tmpfile"

    awk -F"$SEPARATOR" -v outfile="$tmpfile" '
        BEGIN {
            monthname["01"]="Enero"; monthname["02"]="Febrero"; monthname["03"]="Marzo";
            monthname["04"]="Abril"; monthname["05"]="Mayo"; monthname["06"]="Junio";
            monthname["07"]="Julio"; monthname["08"]="Agosto"; monthname["09"]="Septiembre";
            monthname["10"]="Octubre"; monthname["11"]="Noviembre"; monthname["12"]="Diciembre";
        }
        {
            split($1, a, " ")      # separar timestamp
            split(a[1], d, "-")    # YYYY-MM-DD
            year = d[1]
            month = d[2]

            # Generar líneas para pantalla y para fichero completo
            line_year = "    📁" year
            line_month = "        📁" monthname[month]
            n = split($2, parts, "/")
            line_file = "            📄" parts[n]

            # Guardar TODO en fichero completo
            if (year != last_year) {
                print line_year >> outfile
            }
            if (month != last_month) {
                print line_month >> outfile
            }
            print line_file >> outfile

            # Salida por pantalla con límites
            
				if (year != last_year) {
					if (totalcount <= 25) {
						print line_year
					}
					last_year = year
					last_month = ""  # reset mes al cambiar de año
				}

				if (month != last_month) {
					count = 0
					if (totalcount <= 25) {
						print line_month
					}
					last_month = month
				}
				
				count++
				totalcount++

				if (totalcount <= 25) {
					if (count <= 3) {
						print line_file
					} else if (count == 4) {
						print "            [...]"
					}   
				}         
			

            
        }' "$1"
}


# === Menu ===
show_menu() {
	echo 
	echo " >> Mostrando acciones disponibles"
	echo 
	echo 
    echo "=== $SCRIPT_NAME Menu ==="
    echo "                      "
    echo -n "    Directorio origen: " && [ -n "$oriFolder" ] && echo -n "$oriFolder" || echo -n "(Ninguno)"; echo
    echo -n "    Directorio destino: " && [ -n "$destFolder" ] && echo -n "$destFolder" || echo -n "(Ninguno)"; echo
	echo
	echo "=== $SCRIPT_NAME Menu ==="
    echo
    select option in "Volver a escanear '$oriFolder'" "Indicar un (nuevo) directorio origen (y reescanear)" "Indicar un (nuevo) directorio destino" "Mostrar toda la estructura (fichero /tmp/mediabacker_fullstruct.tmp)" "Crear nueva estructura en el directorio destino y COPIAR ficheros del directorio origen al directorio destino" "Crear nueva estructura en el directorio destino y MOVER ficheros del directorio origen al directorio destino" "Salir"; do
        case $REPLY in
            1) scan;show_menu;exit 0;;
            2)  ask_folder "directorio original";
				validate_folder "$auxFolder";
				if [[ $? == 0 ]]; 
					then 			
					    oriFolder="$auxFolder"
						scan
						show_menu
					else
						show_menu;
				fi;
				exit 0;;
            3) ask_folder "directorio destino";
				validate_folder "$auxFolder";
				if [[ $? == 0 ]]; 
					then 			
					    destFolder="$auxFolder"
						show_menu
					else
						show_menu;
				fi;
				exit 0;;
            4) /usr/bin/env less /tmp/mediabacker_fullstruct.tmp; show_menu; exit 0;;
            5) echo "5";;
            6) echo "6";;
            7) echo "Bye!"; exit 0;;
            *) print_error "Opción inválida";;
        esac
    done
}

# === Validation functions ===
validate_folder() {
    auxFolder="$1"
    if [[ -z "$auxFolder" ]]; then
        print_error "Especifica un directorio de origen por favor."
        return 1
    elif [[ ! -d "$auxFolder" ]] || [[ ! -r "$auxFolder" ]]; then
        print_error "El directorio '$auxFolder' no existe o no es legible."
        return 1
    fi    
    return 0    
}


# === Scanner ===
scan() {
	echo
	echo "░█▄█░█▀▀░█▀▄░▀█▀░█▀█░█▀▄░█▀█░█▀▀░█░█░█▀▀░█▀▄"
	echo "░█░█░█▀▀░█░█░░█░░█▀█░█▀▄░█▀█░█░░░█▀▄░█▀▀░█▀▄"
	echo "░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀░▀▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀"
	echo "                                 by Sec2John"
	echo 
	echo " >> Scaneando directorio $oriFolder ..."
	tmpFile=$(echo $tmpFolder"mediabacker.tmp")
	touch $tmpFile
		# ancho de terminal
		cols=$(tput cols 2>/dev/null || echo 120)

		# ocultar cursor y restaurarlo al salir
		tput civis 2>/dev/null
		trap 'printf "\r\033[2K"; tput cnorm 2>/dev/null; echo' EXIT

		count=0
		# spinner simple
		spinner='|/-\'
		spin_i=0
	
		stdbuf -oL find "$oriFolder" -type f \
			-exec stat -c "%y"$SEPARATOR"%n" {} \; \
			| tee $tmpFile \
			| while IFS= read -r line; 
				do
					count=$((count+1))
					# girar spinner
					spin_i=$(((spin_i+1)%4))
					char="${spinner:$spin_i:1}"
					# mensaje para mostrar
					msg="  [$char] Procesados: $count archivos"
					# imprimir truncando al ancho de terminal
					printf '\r\033[2K%.*s' "$((cols-1))" "$msg"
				done	
	#ordenamos el fichero		
	sort "$tmpFile" -o "$tmpFile"
	
	#readarray -t FILES < $tmpFile
	echo " >> "
	#echo " >> El directorio contiene un total de "${#FILES[@]}" ficheros."
	echo " >> El directorio contiene un total de "$count" ficheros."
	#declare -p FILES
	
	strFILES=$(printf "%s\n" "${FILES[@]}" | sort)	
	#echo "$strFILES"
	echo " >> La relación Nº de ficheros / extensión es (Por favor, espere)...:"
	echo
	#strRel=$(printf "%s\n" "${FILES[@]}" | awk -F"$SEPARATOR" '{print $2}' | xargs -n1 basename | sed -n 's/.*\.//p' | sort | uniq -c )
	strRel=$(awk -F"$SEPARATOR" '{print $2}' $tmpFile | xargs -n1 basename | sed -n 's/.*\.//p' | sort | uniq -c )
	echo "$strRel"
	echo
	echo " >> Las extensiones encontradas son: "
	strExt=$( echo "$strRel" | awk -F' ' '{print $2}' | xargs)
	echo
	echo "    $strExt"
	echo
	echo " >> Se crearía la siguiente estructura en un DIRECTORIO_DESTINO (si existe no sobreescribe, añade): "
	
	print_structure "$tmpFile"	

	echo
	echo "     [...] Esto es una muestra."
	echo "           REVISA el fichero /tmp/mediabacker_fullstruct.tmp y asegúrate de que lo que ves es correcto"
	echo
	echo " >> Fin del escáner."
	echo
}

# === Main ===
main() {
    # No arguments -> show help
    if [[ $# -eq 0 ]]; then
        print_help
        exit 0
    fi

	validate_folder "$1"; 
	if [[ $? == 0 ]]; then
		oriFolder="$1"
		scan
		show_menu
	else
		exit 1
	fi
    
 

    # Continue normal execution here...
    echo ""
}

# Run main with all args
main "$@"

