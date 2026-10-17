#!/usr/bin/env bash

if [[ -n "${_MIRRORLIST_SH_LOADED:-}" ]]; then
    return 0
fi
_MIRRORLIST_SH_LOADED=1

select_mirrorlist() {
    local init_choice
    init_choice=$(tui_menu "Select Init System" "Choose which Artix init variant you want to install:" \
        "openrc" "Artix OpenRC" \
        "runit" "Artix runit" \
        "dinit" "Artix dinit" \
        "s6" "Artix s6" \
        "s6-rc" "Artix s6-rc" \
        "nosystemd" "Artix nosystemd (no init)")

    [[ -z "$init_choice" ]] && die "No init system selected."

    local mirrorlist_content
    mirrorlist_content=$(generate_mirrorlist)

    log "Configuring Artix mirrorlist..."
    echo "$mirrorlist_content" > /etc/pacman.d/mirrorlist

    # Ensure lib32 / multilib is enabled in pacman.conf
    configure_pacman_conf

    # Rank mirrors for speed if rankmirrors is available
    if command -v rankmirrors &>/dev/null && tui_yesno "Rank Mirrors" "Would you like to rank mirrors by speed? (requires network)"; then
        log "Ranking mirrors..."
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
        rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist || cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
    fi

    export ARTIX_FLAVOR="$init_choice"
    export SELECTED_INIT="$init_choice"
    log "Mirrorlist configured for Artix ($init_choice)"
}

generate_mirrorlist() {
    cat <<'EOF'
## Artix Linux mirrorlist

## Worldwide / GeoIP
Server = https://mirrors.dotsrc.org/artix-linux/repos/$repo/os/$arch
Server = https://mirror.clarkson.edu/artix-linux/repos/$repo/os/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/artixlinux/$repo/os/$arch
Server = https://mirrors.ustc.edu.cn/artixlinux/$repo/os/$arch
Server = https://mirrors.aliyun.com/artixlinux/$repo/os/$arch
Server = https://artix.wheaton.edu/repos/$repo/os/$arch
Server = https://ftp.ntua.gr/pub/linux/artix-linux/repos/$repo/os/$arch
EOF
}

configure_pacman_conf() {
    local pacman_conf="/etc/pacman.conf"

    backup_file "$pacman_conf"

    # Uncomment Artix [lib32] (and [multilib] if present)
    sed -i 's|^#\[lib32\]|[lib32]|' "$pacman_conf"
    sed -i '/^\[lib32\]/,/^$/{s|^#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|}' "$pacman_conf"
    sed -i 's|^#\[multilib\]|[multilib]|' "$pacman_conf"
    sed -i '/^\[multilib\]/,/^$/{s|^#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|}' "$pacman_conf"

    # Ensure Color and ParallelDownloads
    sed -i 's|^#Color|Color|' "$pacman_conf"
    sed -i 's|^#ParallelDownloads.*|ParallelDownloads = 5|' "$pacman_conf"
}
