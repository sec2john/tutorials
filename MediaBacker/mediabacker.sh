#!/usr/bin/env bash

# === Configuration ===
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.4"

# === Global vars ===

declare -r SEPARATOR="@#¬¬#@"
oriFolder=	#DIRECTORIO_ORIGINAL, pasado por parámetro y validado
destFolder=	#DIRECTORIO_DESTINO (opcional) pasado por parámetro y validado
auxFolder= #Variable auxiliar

FILES=  #Array de ficheros formato " mtime || PATH "

tmpFolder="/tmp"
declare -r fullStructFile="$tmpFolder/mediabacker_fullstruct.tmp"

# ancho de terminal
cols=$(tput cols 2>/dev/null || echo 120)
# spinner simple
spinner='|/-\'
spin_i=0

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

Examples:
  $SCRIPT_NAME path/to/original_folder 
  $SCRIPT_NAME path/to/original_folder path/to/destiny_folder 
EOF
}

print_error() {
    echo "  X Error: $1" >&2
}

print_banner() {
	echo
	echo "  ░█▄█░█▀▀░█▀▄░▀█▀░█▀█░█▀▄░█▀█░█▀▀░█░█░█▀▀░█▀▄"
	echo "  ░█░█░█▀▀░█░█░░█░░█▀█░█▀▄░█▀█░█░░░█▀▄░█▀▀░█▀▄"
	echo "  ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀░▀▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀"
	echo "                                   by Sec2John"
}

ask_folder() {
    echo
    echo " >> Indica el nuevo $1:"
    read -rp " >> " auxFolder        
}

print_structure() {
    local tmpfile="${2:-$fullStructFile}"  # archivo opcional como segundo parámetro
    
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
            line_year = "    " year
            line_month = "        " monthname[month]
            n = split($2, parts, "/")
            line_file = "            " parts[n]

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


copy_files() {
	awk -F"$SEPARATOR" -v DEST="$2" '
        BEGIN {
			srand()             # inicializa semilla
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
            n = split($2, parts, "/")
            line_file = parts[n]
            
            # Renombramos caracteres especiales por un numero en DESTINO
			N = 1000
			r = int(rand() * N)
            gsub(/[:*?"<>|\\\/]/, r, line_file)

            # Generar líneas para pantalla y para fichero completo
            line_year = year
            line_month = monthname[month]
            
            # crear directorios (mkdir -p)
			# cmd = "mkdir -p \"" DEST "/" line_year "/" line_month "\""
			# system(cmd)
			#folder=DEST "/" line_year "/" line_month 
			#print folder
            
            cmd = "cp \"" $2 "\" \"" DEST "/" line_year "/" line_month "/" line_file "\""
            # print cmd
            endpath=$2 " " DEST "/" line_year "/" line_month "/" line_file
            
            print $2 "\x1f" DEST "/" line_year "/" line_month "/" line_file
            
        }' "$1"| while IFS=$'\x1f' read -r src dst; do
        echo
        #echo "in whilE " "$src $dst"
        #echo "mkdir folder: $(dirname "$dst")"
        safe_dir=$(printf "%q" "$dst")
		mkdir -p "$(dirname "$safe_dir")"
			#echo "DEST: "$(dirname "$dst")
		safe_src=$(printf "%q" "$src")
		safe_dst=$(printf "%q" "$dst")
		#echo "copy cmd: cp $safe_src $safe_dst"
			#echo "SRC DEST" "$src" "$dst"
		#echo " cp command: cp $safe_src $safe_dst "
		eval cp $safe_src $safe_dst
			if [ $? != 0 ] 
			then
				print_error "No se pudo copiar $src" 
			fi
					count=$((count+1))
					# girar spinner
					spin_i=$(((spin_i+1)%4))
					char="${spinner:$spin_i:1}"
					# mensaje para mostrar
					msg="  [$char] Copiando: "$((count+1))" archivos."
					# imprimir truncando al ancho de terminal
					printf '\r\033[2K%.*s' "$((cols-1))" "$msg"
		done
		echo
}

# === Menu ===
show_menu() {
	
	print_banner;
	
    echo "==========================================================="
    echo -n "      Directorio origen: " && [ -n "$oriFolder" ] && echo -n "$oriFolder" || echo -n "(Ninguno)"; echo
    echo -n "      Directorio destino: " && [ -n "$destFolder" ] && echo -n "$destFolder" || echo -n "(Ninguno)"; echo
    echo "==========================================================="
    echo
    select option in "Volver a escanear '$oriFolder'" "Indicar un (nuevo) directorio origen (y reescanear)" "Indicar un (nuevo) directorio destino" "Mostrar toda la estructura (fichero $fullStructFile) Pulsa 'q' para salir." "Crear nueva estructura en el directorio destino y COPIAR ficheros del directorio origen al directorio destino" "Crear nueva estructura en el directorio destino y MOVER ficheros del directorio origen al directorio destino" "Salir"; do
        case $REPLY in
            1) 	scan;
				show_menu;
				exit 0;;
            2)  ask_folder "directorio original";
				validate_folder "$auxFolder";
				if [[ $? == 0 ]]; 
					then 			
					    oriFolder="$auxFolder"
						scan
						show_menu
					else
						print_error "Directorio no válido.";
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
					    print_error "Directorio no válido.";
						show_menu;
				fi;
				exit 0;;
            4) 
				/usr/bin/env less "$fullStructFile"; 
				show_menu; 
				exit 0;;
            5) if [[ -z "$destFolder" ]]; then
					print_error "Especifica un directorio destino primero.";
				else
					copy_files "$tmpFile" "$destFolder";
				fi
				show_menu; 
				exit 0;;
            6) echo "6";;
            7) echo "Hasta la vista!"; exit 0;;
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
	echo " >> Scaneando directorio $oriFolder ..."
	tmpFile=$(echo $tmpFolder"/mediabacker.tmp")
	touch $tmpFile		

		# ocultar cursor y restaurarlo al salir
		tput civis 2>/dev/null
		trap 'printf "\r\033[2K"; tput cnorm 2>/dev/null; echo' EXIT
	
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
					msg="  [$char] Encontrados: $count archivos"
					# imprimir truncando al ancho de terminal
					printf '\r\033[2K%.*s' "$((cols-1))" "$msg"
				done	
	#ordenamos el fichero		
	sort "$tmpFile" -o "$tmpFile"
	
	#readarray -t FILES < $tmpFile
	echo " >> "
	#echo " >> El directorio contiene un total de "${#FILES[@]}" ficheros."
	#echo " >> El directorio contiene un total de "$count" ficheros."
	#declare -p FILES
	
	strFILES=$(printf "%s\n" "${FILES[@]}" | sort)	
	#echo "$strFILES"
	echo " >> La relación Nº de ficheros / extensión es (Por favor, espere)...:"
	echo
	#strRel=$(printf "%s\n" "${FILES[@]}" | awk -F"$SEPARATOR" '{print $2}' | xargs -n1 basename | sed -n 's/.*\.//p' | sort | uniq -c )
	strRel=$(awk -F"$SEPARATOR" '{print $2}' $tmpFile | xargs -n1 basename | sed -n 's/.*\.//p' | sort | uniq -c )
	echo "$strRel"
	
	echo
	echo " Pulsa Enter para continuar..."
	 read
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
	echo "     REVISA el fichero $fullStructFile (o utiliza la opcíon del menú a continuación)"
	echo "     y asegúrate de que lo que ves es correcto"
	echo " >> Fin del escáner."
	
	#destFolder="/tmp/dest"
}

# === Main ===
main() {
	
    # No arguments -> show help
    if [[ $# -eq 0 ]]; then
        print_help
        exit 0
    fi
    
    validate_folder "$2"; 
	if [[ $? == 0 ]]; then
		destFolder="$2"	
	fi

	validate_folder "$1"; 
	if [[ $? == 0 ]]; then
		oriFolder="$1"	
			
		print_banner;
		echo
		echo " Listo para escanear el directorio orígen '$oriFolder' "
		echo " No se realizará modificación de ningún tipo."
		echo " Tras el escáner se ofrecerá un menú de opciones."
		echo
		echo " Pulsa Enter para continuar..."
		read
		
		scan
		show_menu
	else
		exit 1
	fi
    
}

# Run main with all args
main "$@"

