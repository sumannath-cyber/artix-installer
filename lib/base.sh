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

    local flavor=""
    case "${ARTIX_FLAVOR:-openrc}" in
        openrc)     flavor="artix-base-openrc" ;;
        runit)      flavor="artix-base-runit" ;;
        dinit)      flavor="artix-base-dinit" ;;
        s6)         flavor="artix-base-s6" ;;
        s6-rc)      flavor="artix-base-s6-rc" ;;
        nosystemd)  flavor="artix-base-nosystemd" ;;
    esac

    base_pkgs+=("$flavor")

    # Essential networking
    base_pkgs+=("networkmanager" "dhcpcd" "iwd")

    # Microcode already added via ucode

    basestrap /mnt "${base_pkgs[@]}"

    log "Base system installed"

    # Generate fstab
    fstabgen -U /mnt >> /mnt/etc/fstab
}
