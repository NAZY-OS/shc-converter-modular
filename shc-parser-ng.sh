#!/bin/bash

# ==============================================================================
# Project:     shc-parser-ng.sh
# Author:      nazy-os
# Version:     3.1-rc1
# License:     MIT License
#
# Copyright (c) 2024 nazy-os
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# ==============================================================================

# --- Defaults ---
INPUT_FILE=""
OUTPUT_FILE="bundled_script.sh"

# --- Help Message ---
show_help() {
    echo "shc-parser-ng v3.1-rc1 | Author: nazy-os"
    echo "--------------------------------------------------"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --input FILE    Input shell script to parse"
    echo "  -o, --output FILE   Output bundled file (default: bundled_script.sh)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Description:"
    echo "  Bundles sourced files into one file and removes 'source'/'.' calls"
    echo "  to prepare the script for shc compilation."
    exit 0
}

# --- Dependency Check ---
check_dependencies() {
    # Check if shc is installed using command -v
    if ! command -v shc &> /dev/null; then
        echo "Error: 'shc' is not installed. Please install it to compile the output."
        echo "Example: sudo apt install shc"
        exit 1
    fi
}

# --- Recursive Source Resolver ---
resolve_sources() {
    local current_file="$1"
    
    # Find lines starting with 'source ' or '. '
    grep -E '^\s*(source\s+|\.\s+)' "$current_file" | while read -r line; do
        # Extract filename, remove quotes
        local sourced_file=$(echo "$line" | sed -E 's/^\s*(source|\.)\s+([^ ]+).*/\2/' | tr -d '"' | tr -d "'")

        if [ -f "$sourced_file" ]; then
            echo "[INFO] Bundling: $sourced_file"
            cat "$sourced_file" >> "$OUTPUT_FILE"
            # Recursive call for nested sources
            resolve_sources "$sourced_file"
        else
            echo "[WARN] Sourced file $sourced_file not found. Skipping."
        fi
    done
}

# --- Main Logic ---
main() {
    # 1. Parse Arguments
    PARSED_ARGS=$(getopt -o i:o:h --long input:,output:,help -n "$0" -- "$@")
    if [ $? -ne 0 ]; then show_help; fi
    eval set -- "$PARSED_ARGS"

    while true; do
        case "$1" in
            -i|--input)  INPUT_FILE="$2"; shift 2 ;;
            -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
            -h|--help)   show_help ;;
            --)          shift; break ;;
            *)           break ;;
        esac
    done

    # 2. Validation
    if [ -z "$INPUT_FILE" ]; then
        show_help
    fi

    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: Input file '$INPUT_FILE' not found."
        exit 1
    fi

    check_dependencies

    # 3. Processing
    echo "[INFO] Starting bundle process..."
    
    # Start with shebang of main file
    head -n 1 "$INPUT_FILE" > "$OUTPUT_FILE"

    # Append main file content without the source lines
    sed -E '/^\s*(source|\.)\s+/d' "$INPUT_FILE" >> "$OUTPUT_FILE"

    # Resolve and append all sourced files
    resolve_sources "$INPUT_FILE"
