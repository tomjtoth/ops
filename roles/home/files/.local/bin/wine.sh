#!/bin/sh

set -Eeux

declare -A games=(
    [avp2ph]="$HOME/.wine-avp2/drive_c/Program Files (x86)/Aliens versus Predator 2 - Primal Hunt/PrimalHunt!.exe"
    
    [xiii]="$HOME/.wine-xiii/drive_c/GOG Games/XIII/system/XIII.exe"

    [avp2010]="$HOME/.wine-avp2010/drive_c/Program Files (x86)/DODI-Repacks/Aliens vs Predator/AvP_Launcher.exe"

    [d2x]="$HOME/.wine-d2x/drive_c/Program Files (x86)/Diablo II/Mod PlugY/PlugY.exe"
)

case "$1" in 
    install) WINEPREFIX=~/.wine-$2 wine "$3";;

    d2x)
        # https://diablo.fandom.com/wiki/Game_commands#Game_commands
        
        gsettings set org.gnome.desktop.a11y.magnifier mouse-tracking 'none'
        gsettings set org.gnome.desktop.a11y.magnifier mag-factor 1.75
        gsettings set org.gnome.desktop.a11y.applications screen-magnifier-enabled true
        ;;&


    *)
        path="${games[$1]}"
        shift
        export WINEPREFIX="${path%/drive_c/*}"
        cd "${path%/*}"
        wine "${path##*/}" "$@"
        ;;&

    d2x)
        wineserver -w

        gsettings set org.gnome.desktop.a11y.applications screen-magnifier-enabled false
        gsettings set org.gnome.desktop.a11y.magnifier mouse-tracking 'proportional'
        ;;
esac

