#!/usr/bin/env bash

if [[ -n "${_BOOT_SH_LOADED:-}" ]]; then
    return 0
fi
_BOOT_SH_LOADED=1

install_bootloader() {
    log "Installing bootloader"

    local bootloader
    bootloader=$(tui_menu "Bootloader" "Choose a bootloader:" \
        "grub" "GRUB (recommended)" \
        "refind" "rEFInd (UEFI only)" \
        "limine" "Limine" \
        "none" "No bootloader")

    [[ -z "$bootloader" ]] && { warn "No bootloader selected"; return; }

    case "$bootloader" in
        grub)
            install_grub
            ;;
        refind)
            install_refind
            ;;
        limine)
            install_limine
            ;;
        none)
            warn "No bootloader installed"
            ;;
    esac
}

install_grub() {
    log "Installing GRUB"
    artix-chroot /mnt pacman -S --noconfirm --needed grub efibootmgr os-prober

    if [[ "$PART_SCHEME" == "uefi" || -d /sys/firmware/efi ]]; then
        artix-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix
    else
        artix-chroot /mnt grub-install --target=i386-pc "$TARGET_DISK"
    fi

    # Enable os-prober for dual boot
    sed -i 's|^#GRUB_DISABLE_OS_PROBER=false|GRUB_DISABLE_OS_PROBER=false|' /mnt/etc/default/grub
    artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

install_refind() {
    log "Installing rEFInd"
    artix-chroot /mnt pacman -S --noconfirm --needed refind efibootmgr
    artix-chroot /mnt refind-install
}

install_limine() {
    log "Installing Limine"
    artix-chroot /mnt pacman -S --noconfirm --needed limine
    artix-chroot /mnt limine-bios-install "$TARGET_DISK" 2>/dev/null || true

    local root_uuid
    root_uuid=$(blkid -s UUID -o value "$ROOT_PART")

    cat > /mnt/boot/limine.conf <<EOF
timeout: 3

/Artix Linux
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    kernel_cmdline: root=UUID=$root_uuid rw
    module_path: boot():/initramfs-linux.img
EOF
}

finish() {
    log "Installation complete!"

    # Set timezone
    local tz
    tz=$(tui_inputbox "Timezone" "Enter your timezone (e.g. Asia/Kolkata or America/New_York):" "UTC")
    if [[ -n "$tz" && -f "/mnt/usr/share/zoneinfo/$tz" ]]; then
        artix-chroot /mnt ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime
        artix-chroot /mnt hwclock --systohc
    else
        log "Invalid timezone, defaulting to UTC"
        artix-chroot /mnt ln -sf /usr/share/zoneinfo/UTC /etc/localtime
        artix-chroot /mnt hwclock --systohc
    fi

    # Set locale
    sed -i 's|^#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /mnt/etc/locale.gen
    artix-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

    # Set hostname
    local hostname
    hostname=$(tui_inputbox "Hostname" "Enter hostname:" "artix")
    echo "$hostname" > /mnt/etc/hostname

    # Set keymap
    local keymap
    keymap=$(tui_inputbox "Keymap" "Enter keyboard layout:" "us")
    echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf

    # Final message
    tui_msg "Complete" "Artix Linux installation is complete!\n\nYou can now reboot into your new system.\n\nRemember:\n  - Your terminal emulator is kitty (unchanged)\n  - Init system: $SELECTED_INIT\n  - Desktop: $SELECTED_DESKTOP\n  - User: $USER_NAME\n\nEnjoy!"

    if tui_yesno "Reboot" "Would you like to reboot now?"; then
        umount -R /mnt
        reboot
    fi
}
