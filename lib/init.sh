#!/usr/bin/env bash

if [[ -n "${_INIT_SH_LOADED:-}" ]]; then
    return 0
fi
_INIT_SH_LOADED=1

declare -g SELECTED_INIT=""

select_init() {
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
        "elogind" "polkit" "dbus" "libelogind"
        "openssh" "cronie" "cronie-openrc" "haveged" "haveged-openrc"
        "alsa-utils" "alsa-utils-openrc" "pipewire" "pipewire-pulse"
        "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    # Enable services
    arch-chroot /mnt rc-update add elogind default
    arch-chroot /mnt rc-update add dbus default
    arch-chroot /mnt rc-update add cronie default
    arch-chroot /mnt rc-update add haveged default
    arch-chroot /mnt rc-update add sshd default
    arch-chroot /mnt rc-update add alsa default
    arch-chroot /mnt rc-update add NetworkManager default

    # Copy init configs
    if [[ -d "$DATA_DIR/init/openrc/etc" ]]; then
        cp -r "$DATA_DIR/init/openrc/etc/"* /mnt/etc/ 2>/dev/null || true
    fi
}

configure_runit() {
    log "Configuring runit"
    local pkgs=(
        "runit" "elogind" "polkit" "dbus"
        "openssh" "cronie" "cronie-runit" "haveged" "haveged-runit"
        "alsa-utils" "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    # Set up runit services
    for svc in elogind dbus cronie haveged sshd; do
        arch-chroot /mnt ln -sf "/etc/runit/sv/$svc" "/etc/runit/runsvdir/default/$svc" 2>/dev/null || true
    done

    # Ensure pipewire starts per-user via xinitrc/profile later
    if [[ -d "$DATA_DIR/init/runit/etc" ]]; then
        cp -r "$DATA_DIR/init/runit/etc/"* /mnt/etc/ 2>/dev/null || true
    fi
}

configure_dinit() {
    log "Configuring dinit"
    local pkgs=(
        "dinit" "elogind" "polkit" "dbus"
        "openssh" "cronie" "cronie-dinit" "haveged" "haveged-dinit"
        "alsa-utils" "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    # Enable dinit services
    for svc in elogind dbus cronie haveged sshd; do
        arch-chroot /mnt dinitctl enable "$svc" 2>/dev/null || true
    done

    if [[ -d "$DATA_DIR/init/dinit/etc" ]]; then
        cp -r "$DATA_DIR/init/dinit/etc/"* /mnt/etc/ 2>/dev/null || true
    fi
}

configure_s6() {
    log "Configuring s6"
    local pkgs=(
        "s6" "s6-linux-init" "s6-rc" "elogind" "polkit" "dbus"
        "openssh" "cronie" "cronie-s6" "haveged" "haveged-s6"
        "alsa-utils" "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    # Create s6-rc bundle
    arch-chroot /mnt s6-rc-compile /etc/s6-rc/compiled /etc/s6-rc/source 2>/dev/null || true
    arch-chroot /mnt s6-rc-init /run/s6 2>/dev/null || true

    if [[ -d "$DATA_DIR/init/s6/etc" ]]; then
        cp -r "$DATA_DIR/init/s6/etc/"* /mnt/etc/ 2>/dev/null || true
    fi
}

configure_s6rc() {
    log "Configuring s6-rc"
    local pkgs=(
        "s6-rc" "s6-linux-init" "elogind" "polkit" "dbus"
        "openssh" "cronie" "cronie-s6" "haveged" "haveged-s6"
        "alsa-utils" "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    )
    pkg_install_chroot "${pkgs[@]}"

    arch-chroot /mnt s6-rc-compile /etc/s6-rc/compiled /etc/s6-rc/source 2>/dev/null || true
    arch-chroot /mnt s6-rc-init /run/s6 2>/dev/null || true

    if [[ -d "$DATA_DIR/init/s6-rc/etc" ]]; then
        cp -r "$DATA_DIR/init/s6-rc/etc/"* /mnt/etc/ 2>/dev/null || true
    fi
}

configure_nosystemd() {
    warn "No init system selected - minimal setup only"
    local pkgs=("elogind" "polkit" "dbus")
    pkg_install_chroot "${pkgs[@]}"
}
