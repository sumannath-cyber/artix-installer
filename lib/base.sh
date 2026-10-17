#!/usr/bin/env bash

if [[ -n "${_BASE_SH_LOADED:-}" ]]; then
    return 0
fi
_BASE_SH_LOADED=1

install_base() {
    log "Installing base system"

    local base_pkgs=(base base-devel linux linux-firmware linux-headers vim nano wget curl git pacman-contrib)

    local ucode
    ucode=$(detect_ucode)
    [[ -n "$ucode" ]] && base_pkgs+=("$ucode")

    local init_sys="${ARTIX_FLAVOR:-openrc}"
    case "$init_sys" in
        openrc|nosystemd)
            base_pkgs+=(openrc elogind-openrc networkmanager-openrc dhcpcd-openrc)
            ;;
        runit)
            base_pkgs+=(runit elogind-runit networkmanager-runit dhcpcd-runit)
            ;;
        dinit)
            base_pkgs+=(dinit elogind-dinit networkmanager-dinit dhcpcd-dinit)
            ;;
        s6|s6-rc)
            base_pkgs+=(s6-base elogind-s6 networkmanager-s6 dhcpcd-s6)
            ;;
    esac

    # Essential networking
    base_pkgs+=("networkmanager" "dhcpcd" "iwd")

    basestrap /mnt "${base_pkgs[@]}"

    # Copy configured pacman.conf and mirrorlist into target system
    cp /etc/pacman.conf /mnt/etc/pacman.conf
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    log "Base system installed"

    # Generate fstab
    fstabgen -U /mnt > /mnt/etc/fstab
}
