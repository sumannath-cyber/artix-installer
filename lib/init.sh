#!/usr/bin/env bash

if [[ -n "${_INIT_SH_LOADED:-}" ]]; then
    return 0
fi
_INIT_SH_LOADED=1

declare -g SELECTED_INIT=""

select_init() {
    if [[ -n "${ARTIX_FLAVOR:-}" ]]; then
        SELECTED_INIT="$ARTIX_FLAVOR"
        log "Using selected init system: $SELECTED_INIT"
        return 0
    fi

    local inits=($(list_init_systems))
    local items=()

    for init in "${inits[@]}"; do
        local desc="Artix $init"
        case "$init" in
            openrc) desc="OpenRC - Gentoo-style init" ;;
            runit) desc="runit - UNIX init scheme" ;;
            dinit) desc="dinit - fast init system" ;;
            s6) desc="s6 - process supervision" ;;
            s6-rc) desc="s6-rc - s6 service manager" ;;
            nosystemd) desc="No init system" ;;
        esac
        items+=("$init" "$desc")
    done

    SELECTED_INIT=$(tui_menu "Select Init System" "Choose your init system:" "${items[@]}")
    [[ -z "$SELECTED_INIT" ]] && die "No init selected."

    log "Selected init: $SELECTED_INIT"
}

configure_init() {
    log "Configuring init system: $SELECTED_INIT"

    local init_dir="$DATA_DIR/init/$SELECTED_INIT"
    [[ -d "$init_dir" ]] || die "Init config directory not found: $init_dir"

    case "$SELECTED_INIT" in
        openrc) configure_openrc ;;
        runit) configure_runit ;;
        dinit) configure_dinit ;;
        s6) configure_s6 ;;
        s6-rc) configure_s6rc ;;
        nosystemd) configure_nosystemd ;;
    esac
}

configure_openrc() {
    log "Configuring OpenRC"
    local pkgs=(
        "elogind" "elogind-openrc" "polkit" "dbus" "dbus-openrc"
        "openssh" "openssh-openrc" "cronie" "cronie-openrc" "haveged" "haveged-openrc"
        "alsa-utils" "alsa-utils-openrc" "networkmanager-openrc"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    # Enable services
    for svc in elogind dbus cronie haveged sshd alsa NetworkManager; do
        artix-chroot /mnt rc-update add "$svc" default 2>/dev/null || true
    done

    # Copy init configs
    if [[ -d "$DATA_DIR/init/openrc/etc" ]]; then
        cp -r "$DATA_DIR/init/openrc/etc/"* /mnt/etc/ 2>/dev/null || true
    fi
}

configure_runit() {
    log "Configuring runit"
    local pkgs=(
        "runit" "elogind" "elogind-runit" "polkit" "dbus" "dbus-runit"
        "openssh" "openssh-runit" "cronie" "cronie-runit" "haveged" "haveged-runit"
        "alsa-utils" "alsa-utils-runit" "networkmanager-runit"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    if [[ -d "$DATA_DIR/init/runit/etc" ]]; then
        cp -r "$DATA_DIR/init/runit/etc/"* /mnt/etc/ 2>/dev/null || true
        chmod +x /mnt/etc/runit/sv/*/run 2>/dev/null || true
    fi

    # Set up runit services
    mkdir -p /mnt/etc/runit/runsvdir/default
    for svc in elogind dbus cronie haveged sshd NetworkManager; do
        artix-chroot /mnt ln -sf "/etc/runit/sv/$svc" "/etc/runit/runsvdir/default/$svc" 2>/dev/null || true
    done
}

configure_dinit() {
    log "Configuring dinit"
    local pkgs=(
        "dinit" "elogind" "elogind-dinit" "polkit" "dbus" "dbus-dinit"
        "openssh" "openssh-dinit" "cronie" "cronie-dinit" "haveged" "haveged-dinit"
        "alsa-utils" "alsa-utils-dinit" "networkmanager-dinit"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    if [[ -d "$DATA_DIR/init/dinit/etc" ]]; then
        cp -r "$DATA_DIR/init/dinit/etc/"* /mnt/etc/ 2>/dev/null || true
    fi

    # Enable dinit services
    mkdir -p /mnt/etc/dinit.d/boot.d
    for svc in elogind dbus cronie haveged sshd NetworkManager; do
        artix-chroot /mnt ln -sf "/etc/dinit.d/$svc" "/etc/dinit.d/boot.d/$svc" 2>/dev/null || true
    done
}

configure_s6() {
    log "Configuring s6"
    local pkgs=(
        "s6-base" "elogind" "elogind-s6" "polkit" "dbus" "dbus-s6"
        "openssh" "openssh-s6" "cronie" "cronie-s6" "haveged" "haveged-s6"
        "alsa-utils" "alsa-utils-s6" "networkmanager-s6"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    if [[ -d "$DATA_DIR/init/s6/etc" ]]; then
        cp -r "$DATA_DIR/init/s6/etc/"* /mnt/etc/ 2>/dev/null || true
    fi

    for svc in elogind dbus cronie haveged sshd NetworkManager; do
        artix-chroot /mnt s6-rc-bundle-update -c /etc/s6/rc/compiled add default "$svc" 2>/dev/null || true
    done
}

configure_s6rc() {
    configure_s6
}

configure_nosystemd() {
    warn "No init system selected - minimal setup only"
    local pkgs=("elogind" "polkit" "dbus")
    pkg_install_chroot "${pkgs[@]}"
}
