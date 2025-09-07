#!/usr/bin/env bash

# === Configuration ===
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

# === Global vars ===

declare -r SEPARATOR="@#¬¬#@"
oriFolder=	#DIRECTORIO_ORIGINAL, pasado por parámetro y validado
destFolder=	#DIRECTORIO_DESTINO (opcional) pasado por parámetro y validado

FILES=  #Array de ficheros formato " mtime || PATH "


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
    echo "❌ Error: $1" >&2
}

# === Menu ===
show_menu() {
    echo "=== $SCRIPT_NAME Menu ==="
    select option in "Indicar un directorio destino" "Volver a escanear '$oriFolder'" "Copiar archivos del origen al destino" "Cortar y pegar archivos del origen al destino (peligro)" "Salir"; do
        case $REPLY in
            1) echo "You chose Option 1";;
            2) scan;show_menu;exit 0;;
            3) echo "You chose Option 3";;
            4) echo "You chose Option 3";;
            5) echo "Bye!"; exit 0;;
            *) print_error "Opción inválida";;
        esac
    done
}

# === Validation functions ===
validate_folder() {
    oriFolder="$1"
    if [[ -z "$oriFolder" ]]; then
        print_error "Especifica un directorio de origen por favor."
        exit 1
    elif [[ ! -d "$oriFolder" ]] || [[ ! -r "$oriFolder" ]]; then
        print_error "El directorio '$oriFolder' no existe o no es legible."
        exit 1
    fi
    
}



# === Scanner ===
scan() {
	echo 
	echo 
	echo " >> Scaneando directorio $oriFolder ..."
	readarray -t FILES < <(find "$oriFolder" -type f  -exec stat -c "%y"$SEPARATOR"%n" {} \;)
	echo " >> "
	echo " >> El directorio contiene un total de "$((${#FILES[@]}-1))" ficheros."
	#declare -p FILES
	
	strFILES=$(printf "%s\n" "${FILES[@]}" | sort)	
	#echo "$strFILES"
	echo " >> La relación Nº de ficheros / extensión es :"
	echo
	strRel=$(printf "%s\n" "${FILES[@]}" | awk -F"$SEPARATOR" '{print $2}' | xargs -n1 basename | sed -n 's/.*\.//p' | sort | uniq -c )
	echo "$strRel"
	echo
	echo " >> Las extensiones encontradas son: "
	strExt=$( echo "$strRel" | awk -F' ' '{print $2}' | xargs)
	echo
	echo "    $strExt"
	echo
	echo " >> Se crearía la siguiente estructura en un DIRECTORIO_DESTINO: "
	#echo "$strFILES"
	#echo "$strFILES" | awk -F"$SEPARATOR" '
	#	{
	#		split($1, a, " ")      # split the timestamp by space
	#		date = a[1]             # take the date part (YYYY-MM-DD)
	#
	#		if (date != last_date) {
	#			print "     "date          # print new date when it changes
	#			last_date = date
	#		}			
	#		
	#		n = split($2, parts, "/")   # split path by /
	#		print "         "parts[n]              # last element is the file name
	#		
	#	}'
	
	echo "$strFILES" | awk -F"$SEPARATOR" '
			{
			split($1, a, " ")      # split timestamp by space
			date = a[1]             # extract YYYY-MM-DD

			if (date != last_date) {
				count = 0           # reset counter for new date
				print "     " date
				last_date = date
			}

			count++
			totalcount++
			if (count <= 3) {
				n = split($2, parts, "/")   # split path by /
				print "         " parts[n]  # last element is filename
			} else if (count == 4) {
				print "         [...]"      # print once when exceeding 4
			}
			
			if (totalcount == 25) exit #Así no llenamos la pantalla con mucha información
		}'
	echo
	echo "     [...] Salida posiblemente incompleta por ser una muestra. "
	echo "           REVISA el fichero FICHERO y asegúrate de que lo que ves es correcto"
	echo
}

# === Main ===
main() {
    # No arguments -> show help
    if [[ $# -eq 0 ]]; then
        print_help
        exit 0
    fi

    # Parse args
    while [[ $# -gt 0 ]]; do
        case $1 in
			-s|--scan)    validate_folder "$2"; 
						  scan;
						  show_menu; 
						  exit 0;;
            -h|--help)    print_help; exit 0;;
            -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0;;
            -m|--menu)    show_menu; exit 0;;
            -f|--file)    validate_file "$2"; shift;;
            *) print_error "Unknown option: $1"; print_help; exit 1;;
        esac
        shift
    done

    # Continue normal execution here...
    echo "✅ Script executed successfully!"
}

# Run main with all args
main "$@"

