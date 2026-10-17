#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
DATA_DIR="$SCRIPT_DIR/Data"
DE_DIR="$SCRIPT_DIR/De"
WM_DIR="$SCRIPT_DIR/Wm"
DOTFILES_DIR="$SCRIPT_DIR/Dotfiles"

source "$LIB_DIR/common.sh"
source "$LIB_DIR/tui.sh"
source "$LIB_DIR/mirrorlist.sh"
source "$LIB_DIR/disk.sh"
source "$LIB_DIR/base.sh"
source "$LIB_DIR/init.sh"
source "$LIB_DIR/desktop.sh"
source "$LIB_DIR/packages.sh"
source "$LIB_DIR/user.sh"
source "$LIB_DIR/boot.sh"

main() {
    tui_init
    show_welcome
    select_mirrorlist
    select_disk
    partition_disk
    format_disk
    mount_disk
    install_base
    select_init
    configure_init
    select_desktop
    install_desktop
    configure_desktop
    select_user_packages
    create_user
    install_bootloader
    copy_dotfiles
    finish
}

main "$@"
