#!/bin/bash

usage() { echo "Usage: ${0} <file.asm>"; exit 1; }

main() {
#    if [ -z "$1" ]; then
#        usage
#    fi
#
#    filename=$(basename "$1" ".asm")
#    filepath=$(dirname "$1")
#
    cd "src" || exit

    asm6f -cm "main.asm" "game.nes"

    if [ $? -ne 0 ]; then
        echo "build failed"
        exit 1
    fi

    fceux "game.nes" &
}

main "$@"
