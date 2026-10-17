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
        "systemd-boot" "systemd-boot (UEFI only)" \
        "refind" "rEFInd (UEFI only)" \
        "limine" "Limine" \
        "none" "No bootloader")

    [[ -z "$bootloader" ]] && { warn "No bootloader selected"; return; }

    case "$bootloader" in
        grub)
            install_grub
            ;;
        systemd-boot)
            install_systemd_boot
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
    arch-chroot /mnt pacman -S --noconfirm --needed grub efibootmgr os-prober

    if [[ "$PART_SCHEME" == "uefi" ]]; then
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix
    else
        arch-chroot /mnt grub-install --target=i386-pc "$TARGET_DISK"
    fi

    # Enable os-prober for dual boot
    sed -i 's|^#GRUB_DISABLE_OS_PROBER=false|GRUB_DISABLE_OS_PROBER=false|' /mnt/etc/default/grub
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

install_systemd_boot() {
    log "Installing systemd-boot"
    arch-chroot /mnt bootctl install

    # Create loader.conf
    cat > /mnt/boot/loader/loader.conf <<EOF
default artix
timeout 3
console-mode max
EOF

    # Create entry
    local root_uuid
    root_uuid=$(blkid -s UUID -o value "$ROOT_PART")

    cat > "/mnt/boot/loader/entries/artix.conf" <<EOF
title   Artix Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
}

install_refind() {
    log "Installing rEFInd"
    arch-chroot /mnt pacman -S --noconfirm --needed refind
    arch-chroot /mnt refind-install
}

install_limine() {
    log "Installing Limine"
    arch-chroot /mnt pacman -S --noconfirm --needed limine
    arch-chroot /mnt limine-deploy "$TARGET_DISK"

    local root_uuid
    root_uuid=$(blkid -s UUID -o value "$ROOT_PART")

    cat > /mnt/boot/limine.conf <<EOF
timeout: 0

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
    tz=$(tui_inputbox "Timezone" "Enter your timezone (e.g. America/New_York):" "UTC")
    if [[ -n "$tz" && -f "/mnt/usr/share/zoneinfo/$tz" ]]; then
        arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime
        arch-chroot /mnt hwclock --systohc
    else
        log "Invalid timezone, defaulting to UTC"
        arch-chroot /mnt ln -sf /usr/share/zoneinfo/UTC /etc/localtime
        arch-chroot /mnt hwclock --systohc
    fi

    # Set locale
    sed -i 's|^#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
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
