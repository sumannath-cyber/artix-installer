#!/usr/bin/env bash

if [[ -n "${_USER_SH_LOADED:-}" ]]; then
    return 0
fi
_USER_SH_LOADED=1

declare -g USER_NAME=""
declare -g USER_PASSWORD=""

create_user() {
    log "Creating user"

    USER_NAME=$(tui_inputbox "Username" "Enter username for the new user:")
    [[ -z "$USER_NAME" ]] && die "No username entered."

    while true; do
        USER_PASSWORD=$(tui_passwordbox "Password" "Enter password for $USER_NAME:")
        [[ -z "$USER_PASSWORD" ]] && { warn "Password cannot be empty"; continue; }

        local confirm
        confirm=$(tui_passwordbox "Confirm Password" "Re-enter password:")
        if [[ "$USER_PASSWORD" == "$confirm" ]]; then
            break
        fi
        tui_msg "Error" "Passwords do not match. Try again."
    done

    log "Creating user: $USER_NAME"
    artix-chroot /mnt useradd -m -G wheel,audio,video,storage,optical,power,input -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$USER_PASSWORD" | artix-chroot /mnt chpasswd

    # Enable sudo
    sed -i 's|^# %wheel ALL=(ALL:ALL) ALL|%wheel ALL=(ALL:ALL) ALL|' /mnt/etc/sudoers

    # Copy skel first
    if [[ -d /mnt/etc/skel ]]; then
        cp -r /mnt/etc/skel/. "/mnt/home/$USER_NAME/" 2>/dev/null || true
    fi

    # Copy dotfiles to user home properly
    if [[ -d "$DOTFILES_DIR" ]]; then
        for d in "$DOTFILES_DIR"/*/; do
            [[ -d "$d" ]] || continue
            local name
            name=$(basename "$d")
            log "Copying dotfiles: $name"
            if [[ "$name" == "bash" || "$name" == "zsh" ]]; then
                cp -r "$d." "/mnt/home/$USER_NAME/" 2>/dev/null || true
            else
                mkdir -p "/mnt/home/$USER_NAME/.config/$name"
                cp -r "$d." "/mnt/home/$USER_NAME/.config/$name/" 2>/dev/null || true
            fi
        done
    fi

    # If Wayland WM (hyprland/sway), update .bash_profile to launch it instead of startx
    if [[ "$SELECTED_DESKTOP" == "hyprland" ]]; then
        sed -i 's|exec startx|exec Hyprland|' "/mnt/home/$USER_NAME/.bash_profile" 2>/dev/null || true
    elif [[ "$SELECTED_DESKTOP" == "sway" ]]; then
        sed -i 's|exec startx|exec sway|' "/mnt/home/$USER_NAME/.bash_profile" 2>/dev/null || true
    elif [[ -d "$DE_DIR/$SELECTED_DESKTOP" ]]; then
        # Desktop Environments use a Display Manager (SDDM/LightDM/GDM), remove auto-startx
        sed -i '/exec startx/d' "/mnt/home/$USER_NAME/.bash_profile" 2>/dev/null || true
    fi

    artix-chroot /mnt chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME" 2>/dev/null || true

    log "User $USER_NAME created"
}

copy_dotfiles() {
    log "Copying dotfiles"

    # Ensure kitty config is preserved (never overwrite)
    if [[ -d "$DOTFILES_DIR/kitty" ]]; then
        mkdir -p "/mnt/home/$USER_NAME/.config/kitty"
        cp -r "$DOTFILES_DIR/kitty/." "/mnt/home/$USER_NAME/.config/kitty/" 2>/dev/null || true
        artix-chroot /mnt chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.config/kitty" 2>/dev/null || true
        log "Kitty config preserved"
    fi
}
