#!/usr/bin/env bash

if [[ -n "${_DESKTOP_SH_LOADED:-}" ]]; then
    return 0
fi
_DESKTOP_SH_LOADED=1

declare -g SELECTED_DESKTOP=""

select_desktop() {
    local des=($(list_des))
    local items=()

    for d in "${des[@]}"; do
        local desc=""
        if [[ -d "$DE_DIR/$d" ]]; then
            desc="Desktop Environment"
        elif [[ -d "$WM_DIR/$d" ]]; then
            desc="Window Manager (includes dotfiles)"
        fi
        items+=("$d" "$desc")
    done

    SELECTED_DESKTOP=$(tui_menu "Select Desktop / Window Manager" "Choose your desktop environment or window manager:" "${items[@]}")
    [[ -z "$SELECTED_DESKTOP" ]] && die "No desktop selected."

    log "Selected: $SELECTED_DESKTOP"
}

install_desktop() {
    log "Installing desktop: $SELECTED_DESKTOP"

    local de_dir="$DE_DIR/$SELECTED_DESKTOP"
    local wm_dir="$WM_DIR/$SELECTED_DESKTOP"

    if [[ -d "$de_dir" ]]; then
        install_de "$SELECTED_DESKTOP" "$de_dir"
    elif [[ -d "$wm_dir" ]]; then
        install_wm "$SELECTED_DESKTOP" "$wm_dir"
    else
        die "Desktop config not found: $SELECTED_DESKTOP"
    fi
}

install_de() {
    local name="$1" dir="$2"
    log "Installing DE: $name"

    local pkgs=()
    if [[ -f "$dir/packages.txt" ]]; then
        mapfile -t pkgs < <(grep -v '^#' "$dir/packages.txt" | grep -v '^$')
    fi

    # Common X11/Wayland base
    local common=(
        "xorg-server" "xorg-xinit" "xorg-xrandr" "xorg-xsetroot"
        "mesa" "lib32-mesa" "xf86-video-vesa" "xf86-video-fbdev"
        "ttf-dejavu" "ttf-liberation" "noto-fonts"
        "kitty" "dunst" "rofi" "polybar" "picom"
        "thunar" "thunar-archive-plugin" "gvfs" "tumbler"
        "feh" "nitrogen" "lxappearance" "qt5ct" "kvantum"
        "papirus-icon-theme" "arc-gtk-theme"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
        "networkmanager" "network-manager-applet"
        "bluez" "bluez-utils" "blueman"
        "xdg-user-dirs" "xdg-utils"
        "polkit" "polkit-gnome"
        "gnome-keyring" "seahorse"
        "gvfs-mtp" "gvfs-gphoto2"
        "udisks2" "udiskie"
        "ntfs-3g" "exfat-utils" "dosfstools"
        "bash-completion" "zsh" "zsh-completions"
        "git" "wget" "curl" "unzip" "p7zip"
        "htop" "btop" "neofetch"
        "firefox" "vim" "nano"
    )

    pkg_install_chroot "${common[@]}"
    pkg_install_chroot "${pkgs[@]}"

    # Enable display manager
    local dm=""
    case "$name" in
        kde) dm="sddm" ;;
        gnome) dm="gdm" ;;
        xfce) dm="lightdm" ;;
        cinnamon) dm="lightdm" ;;
        mate) dm="lightdm" ;;
        lxqt) dm="sddm" ;;
        budgie) dm="lightdm" ;;
    esac

    if [[ -n "$dm" ]]; then
        arch-chroot /mnt pacman -S --noconfirm --needed "$dm"
        case "$SELECTED_INIT" in
            openrc) arch-chroot /mnt rc-update add "$dm" default ;;
            runit) arch-chroot /mnt ln -sf "/etc/runit/sv/$dm" "/etc/runit/runsvdir/default/$dm" 2>/dev/null || true ;;
            dinit) arch-chroot /mnt dinitctl enable "$dm" 2>/dev/null || true ;;
            s6|s6-rc) arch-chroot /mnt s6-rc-bundle-update add "$dm" 2>/dev/null || true ;;
        esac
    fi
}

install_wm() {
    local name="$1" dir="$2"
    log "Installing WM: $name"

    local pkgs=()
    if [[ -f "$dir/packages.txt" ]]; then
        mapfile -t pkgs < <(grep -v '^#' "$dir/packages.txt" | grep -v '^$')
    fi

    local common=(
        "xorg-server" "xorg-xinit" "xorg-xrandr" "xorg-xsetroot"
        "mesa" "lib32-mesa"
        "ttf-dejavu" "ttf-liberation" "noto-fonts"
        "kitty" "dunst" "rofi" "picom"
        "thunar" "gvfs" "tumbler"
        "feh" "lxappearance" "qt5ct" "kvantum"
        "papirus-icon-theme" "arc-gtk-theme"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
        "networkmanager" "network-manager-applet"
        "bluez" "bluez-utils" "blueman"
        "xdg-user-dirs" "xdg-utils"
        "polkit" "polkit-gnome"
        "udisks2" "udiskie"
        "ntfs-3g" "exfat-utils" "dosfstools"
        "bash-completion" "zsh" "zsh-completions"
        "git" "wget" "curl" "unzip" "p7zip"
        "htop" "btop" "neofetch"
        "firefox" "vim" "nano"
    )

    pkg_install_chroot "${common[@]}"
    pkg_install_chroot "${pkgs[@]}"
}

configure_desktop() {
    log "Configuring desktop: $SELECTED_DESKTOP"

    local de_dir="$DE_DIR/$SELECTED_DESKTOP"
    local wm_dir="$WM_DIR/$SELECTED_DESKTOP"

    if [[ -d "$de_dir" ]]; then
        configure_de "$SELECTED_DESKTOP" "$de_dir"
    elif [[ -d "$wm_dir" ]]; then
        configure_wm "$SELECTED_DESKTOP" "$wm_dir"
    fi
}

configure_de() {
    local name="$1" dir="$2"
    log "Configuring DE: $name"

    if [[ -d "$dir/etc" ]]; then
        cp -r "$dir/etc/"* /mnt/etc/ 2>/dev/null || true
    fi

    if [[ -d "$dir/skel" ]]; then
        cp -r "$dir/skel/"* /mnt/etc/skel/ 2>/dev/null || true
    fi
}

configure_wm() {
    local name="$1" dir="$2"
    log "Configuring WM: $name"

    if [[ -d "$dir/etc" ]]; then
        cp -r "$dir/etc/"* /mnt/etc/ 2>/dev/null || true
    fi

    if [[ -d "$dir/skel" ]]; then
        cp -r "$dir/skel/"* /mnt/etc/skel/ 2>/dev/null || true
    fi

    # Copy WM-specific dotfiles to skel
    if [[ -d "$dir/skel/.config" ]]; then
        cp -r "$dir/skel/.config/"* /mnt/etc/skel/.config/ 2>/dev/null || true
    fi
}
