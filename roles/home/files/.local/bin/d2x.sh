#!/bin/bash

PREFIX0="$HOME/.wine"
ARGS=()
UNKNOWN_ARGS=()

TEXT0="\e[0m"

function log() {
    echo -e "\n\t$TEXT$1$TEXT0${@:2}"
}

function err() {
    TEXT="\e[1;31m"
    log $@
    TEXT=""
    exit 1
}

# based on flags I recognized from https://diablo.fandom.com/wiki/Game_commands#Game_commands
while [ -n "$1" ]; do
    case $1 in
        -h|--help)
            SHOW_HELP=1
            ;;

        # set display resolution
        --res)
            XRANDR_RES=1280x720@60.000
            ;;

        --plugy|--PlugY)
            PLUGY=1
            ;;

        --skills)
            shift
            SKILLS_ON_LUP=$1
            PLUGY=1
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
    log "Proper usage:" "TODO"
    exit 0
fi

[ ! -e "$PREFIX0" ] && err "missing Diablo II" "\"$PREFIX0\" must exist, since it will be linked to different prefixes"

PREFIX="$PREFIX0${INSTANCE:+-$INSTANCE}"

PATH_GAME="drive_c/Program Files (x86)/Diablo II"
DIR_GAME="$PREFIX/$PATH_GAME"
DIR_GAME0="$PREFIX0/$PATH_GAME"

PATH_SAVES="drive_c/users/$USER/Saved Games/Diablo II"
DIR_SAVES="$PREFIX/$PATH_SAVES"
DIR_SAVES0="$PREFIX0/$PATH_SAVES"


[ "${#UNKNOWN_ARGS}" -gt 0 ] && err "Unknown argumets:" $(printf '\t\t%s\n' ${UNKNOWN_ARGS[*]})

if [ ! -e "$DIR_GAME" ]; then
    mkdir -p "${DIR_GAME%/*}"
    ln -s "$DIR_GAME0" "$DIR_GAME"
fi

if [ ! -e "$DIR_SAVES" ]; then
    mkdir -p "${DIR_SAVES%/*}"
    ln -s "$DIR_SAVES0" "$DIR_SAVES"
fi

if [ -v XRANDR_RES ]; then
    if [ -z "$(which gnome-randr)" ]; then
        echo "install gnome-randr"
    fi
    # TODO: get original res dynamically
    XRANDR_RES0=1920x1080@60.000
    gnome-randr modify HDMI-1 -m $XRANDR_RES
fi

cd "$DIR_GAME"

if [ -v PLUGY ]; then
    BIN="PlugY.exe"
    cd "Mod PlugY"
    if [ -v SKILLS_ON_LUP ]; then
        sed -i -E \
            's/^SkillPerLevelUp=[0-9]+/SkillPerLevelUp='$SKILLS_ON_LUP'/' \
            PlugY.ini
    fi
fi

WINEPREFIX="$PREFIX" wine "${BIN:-Diablo II.exe}" ${ARGS[*]}

if [ -v XRANDR_RES0 ]; then
    wineserver -w
    gnome-randr modify HDMI-1 -m $XRANDR_RES0
fi
