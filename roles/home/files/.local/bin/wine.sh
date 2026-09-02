#!/bin/sh

set -Eeux

declare -A games=(
    [avp2ph]="$HOME/.wine-avp2/drive_c/Program Files (x86)/Aliens versus Predator 2 - Primal Hunt/PrimalHunt!.exe"
    
    [xiii]="$HOME/.wine-xiii/drive_c/GOG Games/XIII/system/XIII.exe"

    [avp2010]="$HOME/.wine-avp2010/drive_c/Program Files (x86)/DODI-Repacks/Aliens vs Predator/AvP_Launcher.exe"

    [LTspice]="$HOME/.wine-LTspice/drive_c/Program Files/ADI/LTspice/LTspice.exe"

    [TINA-TI]="$HOME/.wine-TINA-TI/drive_c/Program Files (x86)/DesignSoft/Tina 9 - TI/TINA.EXE"
)

case "$1" in 
    install) WINEPREFIX=~/.wine-$2 wine "$3"; exit 0;;

    *)
        path="${games[$1]}"
        export WINEPREFIX="${path%/drive_c/*}"
        cd "${path%/*}"
        wine "${path##*/}"
        ;;
esac

