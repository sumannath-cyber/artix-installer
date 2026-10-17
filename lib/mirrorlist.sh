#!/usr/bin/env bash

if [[ -n "${_MIRRORLIST_SH_LOADED:-}" ]]; then
    return 0
fi
_MIRRORLIST_SH_LOADED=1

select_mirrorlist() {
    local init_choice
    init_choice=$(tui_menu "Select Init System" "Choose which Artix init variant you want to install. This determines the mirrorlist flavor:" \
        "openrc" "Artix OpenRC" \
        "runit" "Artix runit" \
        "dinit" "Artix dinit" \
        "s6" "Artix s6" \
        "s6-rc" "Artix s6-rc" \
        "nosystemd" "Artix nosystemd (no init)")

    [[ -z "$init_choice" ]] && die "No init system selected."

    local mirrorlist_content=""
    local flavor=""

    case "$init_choice" in
        openrc)
            flavor="openrc"
            mirrorlist_content=$(generate_mirrorlist "openrc")
            ;;
        runit)
            flavor="runit"
            mirrorlist_content=$(generate_mirrorlist "runit")
            ;;
        dinit)
            flavor="dinit"
            mirrorlist_content=$(generate_mirrorlist "dinit")
            ;;
        s6)
            flavor="s6"
            mirrorlist_content=$(generate_mirrorlist "s6")
            ;;
        s6-rc)
            flavor="s6-rc"
            mirrorlist_content=$(generate_mirrorlist "s6-rc")
            ;;
        nosystemd)
            flavor="nosystemd"
            mirrorlist_content=$(generate_mirrorlist "nosystemd")
            ;;
        *)
            die "Unknown init choice: $init_choice"
            ;;
    esac

    log "Configuring mirrorlist for $flavor (multilib enabled only)"

    # Pre-seed /mnt/etc so pacstrap picks it up
    mkdir -p /mnt/etc/pacman.d
    echo "$mirrorlist_content" > /etc/pacman.d/mirrorlist
    echo "$mirrorlist_content" > /mnt/etc/pacman.d/mirrorlist

    # Ensure multilib is in pacman.conf
    configure_pacman_conf

    # Rank mirrors for speed
    if tui_yesno "Rank Mirrors" "Would you like to rank mirrors by speed? (requires network)"; then
        log "Ranking mirrors..."
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
        rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist || true
        cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
    fi

    export ARTIX_FLAVOR="$flavor"
    log "Mirrorlist configured for Artix $flavor"
}

generate_mirrorlist() {
    local flavor="$1"
    cat <<EOF
## Artix Linux - $flavor mirrorlist (multilib only)

## Worldwide
Server = https://mirror.ghproxy.com/artixlinux/$flavor/\$arch/\$repo
Server = https://mirrors.tuna.tsinghua.edu.cn/artixlinux/$flavor/\$arch/\$repo
Server = https://mirrors.ustc.edu.cn/artixlinux/$flavor/\$arch/\$repo
Server = https://mirror.nju.edu.cn/artixlinux/$flavor/\$arch/\$repo
Server = https://mirrors.aliyun.com/artixlinux/$flavor/\$arch/\$repo
Server = https://mirrors.cloud.tencent.com/artixlinux/$flavor/\$arch/\$repo

## Europe
Server = https://artixlinux.mirror.uber.space/$flavor/\$arch/\$repo
Server = https://mirror.one.com/artixlinux/$flavor/\$arch/\$repo

## North America
Server = https://mirror.clarkson.edu/artixlinux/$flavor/\$arch/\$repo
Server = https://us.mirrors.cicku.me/artixlinux/$flavor/\$arch/\$repo
EOF
}

configure_pacman_conf() {
    local pacman_conf="/etc/pacman.conf"

    backup_file "$pacman_conf"

    # Uncomment multilib
    sed -i 's|^#\[multilib\]|[multilib]|' "$pacman_conf"
    sed -i '/^\[multilib\]/,/^$/{s|^#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|}' "$pacman_conf"

    # Ensure Color and ParallelDownloads
    sed -i 's|^#Color|Color|' "$pacman_conf"
    sed -i 's|^#ParallelDownloads|ParallelDownloads = 5|' "$pacman_conf"

    # Comment out testing repos
    sed -i 's^\[core-testing\]^[#core-testing\]^g' "$pacman_conf"
    sed -i 's^\[extra-testing\]^[#extra-testing\]^g' "$pacman_conf"
    sed -i 's^\[multilib-testing\]^[#multilib-testing\]^g' "$pacman_conf"

    cp "$pacman_conf" /mnt/etc/pacman.conf
}
