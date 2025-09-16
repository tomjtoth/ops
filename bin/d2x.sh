#!/bin/bash

PREFIX0="$HOME/.wine"
ARGS=()
UNKNOWN_ARGS=()

# based on flags I recognized from https://diablo.fandom.com/wiki/Game_commands#Game_commands
while [ -n "$1" ]; do
    case $1 in
        -h|--help)
            SHOW_HELP=1
            ;;

        # single flags
        -act1|-act2|-act3|-act4|-act5|\
        -ama|-asn|-bar|-dru|-nec|-pal|-sor|\
        -exp|-expansion|-nm|-nomonster|-multiclient|\
        -d3d|-glide|-lq|-lowquality|-nofixaspect|-opengl|-per|-perspective|-rave|\
        -vsync|-w|-window|-ns|-nosound)
            ARGS+=($1)
            ;;

        # flags with values
        -fr|-framerate|-gamma|\
        -title)
            ARGS+=($1 $2)
            shift
            ;;

        # anything else
        *)
            if [[ "$1" =~ [0-9]+ ]] && [ -z "$INSTANCE" ]; then
                INSTANCE=$1
            else
                UNKNOWN_ARGS+=($1)
            fi
            ;;
    esac
    shift
done

if [ -v SHOW_HELP ]; then
    printf "\"$PREFIX0\" must exist, it will be linked to different prefixes"
    exit 0
fi

PREFIX="$PREFIX0${INSTANCE:+-$INSTANCE}"

PATH_GAME="drive_c/Program Files (x86)/Diablo II"
DIR_GAME="$PREFIX/$PATH_GAME"
DIR_GAME0="$PREFIX0/$PATH_GAME"

PATH_SAVES="drive_c/users/$USER/Saved Games/Diablo II"
DIR_SAVES="$PREFIX/$PATH_SAVES"
DIR_SAVES0="$PREFIX0/$PATH_SAVES"


if [ "${#UNKNOWN_ARGS}" -gt 0 ]; then
    printf '\n\tUnknown argumets:\n'
    printf '\t\t%s\n' ${UNKNOWN_ARGS[*]}
    exit 1
fi

if [ ! -e "$DIR_GAME" ]; then
    mkdir -p "${DIR_GAME%/*}"
    ln -s "$DIR_GAME0" "$DIR_GAME"
fi

if [ ! -e "$DIR_SAVES" ]; then
    mkdir -p "${DIR_SAVES%/*}"
    ln -s "$DIR_SAVES0" "$DIR_SAVES"
fi

WINEPREFIX="$PREFIX" wine "$DIR_GAME/Diablo II.exe" ${ARGS[*]}
