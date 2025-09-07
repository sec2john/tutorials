#!/usr/bin/env bash

# === Configuration ===
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

# === Utility functions ===

print_help() {
    cat << EOF
Uso: $SCRIPT_NAME [options] [arguments]

Options:
  -h, --help        Show this help message
  -m, --menu        Show interactive menu
  -v, --version     Show script version
  -f, --file <path> Specify a file (example parameter)

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
    select option in "Option 1" "Option 2" "Quit"; do
        case $REPLY in
            1) echo "You chose Option 1";;
            2) echo "You chose Option 2";;
            3) echo "Bye!"; exit 0;;
            *) print_error "Invalid choice";;
        esac
    done
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

