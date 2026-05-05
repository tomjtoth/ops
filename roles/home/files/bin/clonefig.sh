#!/bin/bash


SUDO_CONF=/etc/sudoers.d/99_wheel


TEXT_YELLOW='\033[93m'
TEXT_RESET='\033[0m'
TEXT_BOLD='\033[1m'
TEXT_WHITE='\033[0;37m'
TEXT_BLACK='\033[90m'
TEXT_RED='\033[0;31m'
TEXT_GREEN='\033[0;32m'


function log() {
    local args="$*"
    [ -z "$args" ] && args="${FUNCNAME[1]//_/ }"
    printf "${TEXT_BOLD}==> ${TEXT_YELLOW}%s${TEXT_RESET}\n" "$args"
}


function skip() {
    local args="$*"
    [ -z "$args" ] && args="${FUNCNAME[1]//_/ }"
    printf "${TEXT_WHITE}==> ${TEXT_BLACK}%s${TEXT_RESET}\n" "skipped $args"
}


function err() {
    printf "\n\t${TEXT_RED}FAILED ${FUNCNAME[1]//_/ }${TEXT_RESET}: ${TEXT_BOLD}%s${TEXT_RESET}\n\n" "$*"
}


function raw_err() {
    printf "\n\t${TEXT_RED}ERROR${TEXT_RESET}: ${TEXT_BOLD}%s${TEXT_RESET}\n\n" "$*"
}


function success() {
    printf "\n\t${TEXT_GREEN}DONE${TEXT_RESET}\n\n"
}


function run_as_1000() {
    sed -i 's/ALL$/NOPASSWD: ALL/m' $SUDO_CONF
    sudo -u \#1000 "$@"
    sed -i 's/NOPASSWD: ALL$/ALL/m' $SUDO_CONF
}


function join_by_char() {
    local IFS="$1"
    shift
    echo "$*"
}


if [ -z "$BASH_VERSION" ]; then
    raw_err "This script must be run with BASH"
    exit 1
fi


# shellcheck disable=SC2046
if [ $(id -u) -ne 0 ]; then
	err "This script must be run as root"
	exit 1
fi

if [ -z "$1" ]; then
    err "Pass primary username as \$1"
    exit 1
fi

# what host is this?
[ -f /bin/pacman ] && ARCH=1
[ -f /sbin/apk ] && ALPINE=1

user=$1

function limiting_systemd_journal_size() {
    local conf=/etc/systemd/journald.conf.d/00-journal-size.conf

    if [ -v ARCH ] && [ ! -f $conf ]; then
        log

        mkdir ${conf%/*} 2>/dev/null

        printf '%s\n' \
            [Journal] \
            SystemMaxUse=50M \
            > $conf

        success
    else
        skip
    fi
}


function enabling_sudo_for_group_wheel() {
    if [ ! -f $SUDO_CONF ]; then
        log

        local line="%wheel ALL=(ALL:ALL) ALL"

        # NOPASSWD on Alpine VMs
        [ -v ALPINE ] && line='%wheel ALL=(ALL) NOPASSWD: ALL'

        printf '%s\n' \
            "# users in group wheel" \
            "$line\n" \
            > $SUDO_CONF

        chmod 0440 $SUDO_CONF

        success
    else
        skip
    fi
}


function adding_primary_user() {
    if ! grep -q :1000: /etc/passwd; then
        log

        if [ -v ARCH ]; then
            useradd -m -G wheel,docker,boinc $user
            passwd $user
        elif [ -v ALPINE ]; then
            adduser $user
            adduser $user wheel
            # set login shell to BASH
            sed -i -r 's/^('$user':.+:\/bin)\/sh/\1\/bash/' /etc/passwd
         fi

        success
    else
        skip
    fi
}


function configuring_pacman() {
    local conf=/etc/pacman.conf

    if [ -v ARCH ] && grep -q '^#Color' $conf; then
        log

        sed -i \
            -re 's/^#(Color)$/\1/m' \
            -re 's/^(NoProgressBar)$/#\1/m' \
            -re 's/^#(CheckSpace)$/\1/m' \
            -re 's/^(ParallelDownloads) *= *[0-9]+$/\1 = 20/m' \
            $conf

        success
    else
        skip
    fi
}


function installing_missing_packages() {
    [ -v ALPINE ] && skip && return 0
    
    local missing_pkgs pkgs=(

        # cli utils
        nano mc htop ncdu networkmanager ntp pacman-contrib bluez-utils man-db ntfs-3g os-prober ansible-core

        # Desktop Environment
        gdm gnome-shell gnome-keyring eog nautilus file-roller
        gnome-terminal
        gnome-control-center
        gnome-shell-extension-appindicator
        gnome-shell-extension-caffeine
        xdg-desktop-portal-gnome
        gnome-browser-connector
        gnome-calculator gnome-tweaks
        ttf-dejavu

        # gui utils
        evince vlc geany geany-plugins keepassxc

        # video editing
        obs-studio avidemux-qt

        # Web
        firefox chromium qbittorrent

        # coding
        docker docker-buildx docker-compose

        # openCL
        intel-compute-runtime clinfo clpeak
    )

    mapfile -t missing_pkgs < <(diff -B --changed-group-format='%<'\
        --unchanged-group-format='' \
        <(printf "%s\n" "${pkgs[@]}" | sort) \
        <(printf "%s\n" "$(pacman -Qenq)" | sort)
    )

    if [ ${#missing_pkgs[@]} -ne 0 ]; then
        log

        pacman -Syyu "${missing_pkgs[@]}" || return

        success
    else
        skip
    fi
}


function configuring_makepkg() {
    local conf=/etc/makepkg.conf

    if [ -v ARCH ] && grep -q '^#MAKEFLAGS=' $conf; then
        sed -i \
            's/^#MAKEFLAGS="-j2"$/MAKEFLAGS="-j'"$(nproc)"'"/m' \
            $conf

        success
    else
        skip
    fi
}


function installing_paru() {
    if [ -v ARCH ] && [ ! -f /usr/bin/paru ]; then
        log

        mkdir /tmp/clonefig
        cd /tmp/clonefig
        curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/paru.tar.gz
        tar -xvzf paru.tar.gz
        chown -R 1000 .
        cd paru
        run_as_1000 makepkg -si --noconfirm
        cd ..
        rm -rf paru{,.tar.gz}

        success
    else
        skip
    fi
}


function configuring_ssh() {
    local conf=/etc/ssh/sshd_config.d/01_wheel.conf

    if [ ! -f $conf ]; then
        log

        local opts=(
            Port            55522
            AllowGroups     wheel
            PermitRootLogin no
        )

        [ -v ALPINE ] && opts+=(
            PubkeyAuthentication    yes
            PasswordAuthentication  no
        )

        printf '%-25s %s\n' \
            ${opts[@]} \
            > $conf

        success
    else
        skip
    fi
}


function enabling_autologin_in_GDM() {
    if [ -v ARCH ] && ! grep -q '^AutomaticLoginEnable=True$' /etc/gdm/custom.conf; then
        log

        sed -i '/^\[daemon\]$/aAutomaticLogin='"$user"'\nAutomaticLoginEnable=True' \
            /etc/gdm/custom.conf

        success
    else
        skip
    fi
}


function relocating_docker(){
    if [ -v ARCH ] && [ ! -d /home/docker ]; then
        log

        mkdir /home/docker
        ln -s /home/docker /var/lib/docker

        success
    else
        skip
    fi
}


function enabling_systemd_services() {
    if [ -v ARCH ] && [ "$(systemctl is-enabled gdm)" != "enabled" ]; then
        log

        for svc in docker gdm ntpd bluetooth NetworkManager; do
            systemctl enable $svc && log $svc ✓
        done
    else
        skip
    fi
}


function enabling_discards_in_LVM() {
    local conf=/etc/lvm/lvm.conf

    if [ -v ARCH ] && ! grep -qP '^\s+issue_discards\s*=\s*1' $conf; then
        log

        sed -i -E "s/^(\s*)#(\s*issue_discards)\s*=\s*0$/\1 \2 = 1/" $conf

        success
    else
        skip
    fi
}


function adding_discard_options_in_fstab() {
    [ -v ALPINE ] && skip && return 0

    local conf=/etc/fstab \
        uuids=($(lsblk -o uuid --filter 'ROTA != 1'))
    uuids=$(join_by_char "|" ${uuids[@]:1})

    if ! grep -qP '^UUID=('"$uuids"').+discard\s+\d+\s+\d+\s*$' $conf; then
        log

        sed -i -E "s/^(UUID=($uuids)\s+.+)(\s+[0-9]+\s+[0-9]+\s*)$/\1,discard \3/mg" $conf

        success
    else
        skip
    fi
}


function adding_menu_entries_to_GRUB() {
    local conf=/etc/grub.d/40_custom

    if [ -v ARCH ] && ! grep -qP 'Shutdown|Restart' $conf; then
        log

        printf '%s\n' \
            'menuentry "Restart" { reboot }' \
            'menuentry "Shutdown" { halt }' \
            >> $conf
        grub-mkconfig -o /boot/grub/grub.cfg

        success
    else
        skip
    fi
}


# calling each func in order
limiting_systemd_journal_size
enabling_sudo_for_group_wheel
adding_primary_user
configuring_pacman
installing_missing_packages
configuring_makepkg
installing_paru
configuring_ssh
enabling_autologin_in_GDM
relocating_docker
enabling_systemd_services
enabling_discards_in_LVM
adding_discard_options_in_fstab
adding_menu_entries_to_GRUB
