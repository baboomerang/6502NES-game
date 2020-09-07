#!/bin/bash

usage() { echo "Usage: ${0} <file.asm>"; exit 1; }

if [ -z "${1}" ]; then
    usage
else
    filename=$(basename ${1} ".asm")    #strip extension
    filepath=$(dirname ${1})

    cd ${filepath}

    #if  nesasm "${filename}" | grep 'error'; then
    #    echo "Errors occurred check below"
    #    nesasm "${filename}"
    #    exit 1
    #fi
    #dumb solution but nesasm always returns 0 even if it errors

    asm6f -c "${filename}.asm"
    
    if [ $? -ne 0 ]; then
        echo "check errors"
    fi

    mv "${filename}.bin" "${filename}.nes"
    mesen "${filename}.nes"
fi
