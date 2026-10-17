#!/usr/bin/env bash

if [[ -n "${_COMMON_SH_LOADED:-}" ]]; then
    return 0
fi
_COMMON_SH_LOADED=1

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

require_root() {
    [[ $EUID -eq 0 ]] || die "This script must be run as root."
}

require_cmd() {
    command -v "$1" &>/dev/null || die "Required command not found: $1"
}

backup_file() {
    local f="$1"
    [[ -f "$f" ]] && cp -a "$f" "${f}.bak"
}

run_cmd() {
    log "Running: $*"
    "$@"
}

run_chroot() {
    log "chroot: $*"
    arch-chroot /mnt "$@"
}

detect_ucode() {
    local cpu
    cpu=$(grep -m1 'vendor_id' /proc/cpuinfo || true)
    if [[ "$cpu" == *"AuthenticAMD"* ]]; then
        echo "amd-ucode"
    elif [[ "$cpu" == *"GenuineIntel"* ]]; then
        echo "intel-ucode"
    else
        echo ""
    fi
}

detect_gpu() {
    local gpu
    gpu=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' || true)
    if [[ "$gpu" == *"NVIDIA"* ]]; then
        echo "nvidia"
    elif [[ "$gpu" == *"AMD"* || "$gpu" == *"ATI"* ]]; then
        echo "amd"
    elif [[ "$gpu" == *"Intel"* ]]; then
        echo "intel"
    else
        echo "generic"
    fi
}

list_init_systems() {
    local inits=()
    for d in "$DATA_DIR/init"/*/; do
        [[ -d "$d" ]] && inits+=("$(basename "$d")")
    done
    echo "${inits[@]}"
}

list_desktops() {
    local des=()
    for d in "$DE_DIR"/*/; do
        [[ -d "$d" ]] && des+=("$(basename "$d")")
    done
    for d in "$WM_DIR"/*/; do
        [[ -d "$d" ]] && des+=("$(basename "$d")")
    done
    echo "${des[@]}"
}

list_wms() {
    local wms=()
    for d in "$WM_DIR"/*/; do
        [[ -d "$d" ]] && wms+=("$(basename "$d")")
    done
    echo "${wms[@]}"
}

list_des() {
    local des=()
    for d in "$DE_DIR"/*/; do
        [[ -d "$d" ]] && des+=("$(basename "$d")")
    done
    echo "${des[@]}"
}

pkg_install() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0
    log "Installing packages: ${pkgs[*]}"
    pacstrap -K /mnt "${pkgs[@]}"
}

pkg_install_chroot() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0
    log "Installing packages in chroot: ${pkgs[*]}"
    arch-chroot /mnt pacman -S --noconfirm --needed "${pkgs[@]}"
}

wait_for_key() {
    echo
    read -r -p "Press Enter to continue..." _
}
