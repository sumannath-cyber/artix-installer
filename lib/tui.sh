#!/usr/bin/env bash

if [[ -n "${_TUI_SH_LOADED:-}" ]]; then
    return 0
fi
_TUI_SH_LOADED=1

TUI_BACKTITLE="Artix Modular Installer"

tui_init() {
    export DIALOG_CANCEL=1
    export DIALOG_ESC=1
    if ! command -v dialog &>/dev/null; then
        warn "dialog not found, installing..."
        pacman -Sy --noconfirm dialog
    fi
}

tui_msg() {
    local title="$1" text="$2"
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --msgbox "$text" 0 0
}

tui_info() {
    local title="$1" text="$2"
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --infobox "$text" 0 0
}

tui_yesno() {
    local title="$1" text="$2"
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --yesno "$text" 0 0
}

tui_menu() {
    local title="$1" text="$2"
    shift 2
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --menu "$text" 0 0 0 "$@" 3>&1 1>&2 2>&3
}

tui_checklist() {
    local title="$1" text="$2"
    shift 2
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --checklist "$text" 0 0 0 "$@" 3>&1 1>&2 2>&3
}

tui_radiolist() {
    local title="$1" text="$2"
    shift 2
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --radiolist "$text" 0 0 0 "$@" 3>&1 1>&2 2>&3
}

tui_inputbox() {
    local title="$1" text="$2" init="${3:-}"
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --inputbox "$text" 0 0 "$init" 3>&1 1>&2 2>&3
}

tui_passwordbox() {
    local title="$1" text="$2"
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --passwordbox "$text" 0 0 3>&1 1>&2 2>&3
}

tui_gauge() {
    local title="$1" text="$2" percent="$3"
    echo "$percent" | dialog --backtitle "$TUI_BACKTITLE" --title "$title" --gauge "$text" 0 0 0
}

tui_textbox() {
    local title="$1" file="$2"
    dialog --backtitle "$TUI_BACKTITLE" --title "$title" --textbox "$file" 0 0
}

tui_mixedgauge() {
    local title="$1" text="$2" percent="$3"
    echo "$percent" | dialog --backtitle "$TUI_BACKTITLE" --title "$title" --mixedgauge "$text" 0 0 0
}

show_welcome() {
    tui_msg "Welcome" "Welcome to the Artix Modular Installer!\n\nThis installer supports:\n  - All Artix init systems (OpenRC, runit, dinit, s6, s6-rc)\n  - All major desktop environments\n  - Popular window managers with minimal dotfiles\n  - Modular package selection\n\nYour default terminal emulator (kitty) will NOT be changed.\n\nPress OK to begin."
}
