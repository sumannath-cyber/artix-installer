#!/usr/bin/env bash

if [[ -n "${_DISK_SH_LOADED:-}" ]]; then
    return 0
fi
_DISK_SH_LOADED=1

declare -g TARGET_DISK=""
declare -g PART_SCHEME=""
declare -g EFI_PART=""
declare -g ROOT_PART=""
declare -g SWAP_SIZE=""

select_disk() {
    local disks=()
    local items=()

    while IFS= read -r line; do
        disks+=("$line")
    done < <(lsblk -d -o NAME,SIZE,MODEL -n -p | grep -v 'loop\|sr0')

    if [[ ${#disks[@]} -eq 0 ]]; then
        die "No disks found!"
    fi

    for d in "${disks[@]}"; do
        local name size model
        name=$(echo "$d" | awk '{print $1}')
        size=$(echo "$d" | awk '{print $2}')
        model=$(echo "$d" | awk '{$1="";$2="";print}')
        items+=("$name" "$size $model")
    done

    TARGET_DISK=$(tui_menu "Select Disk" "Choose the disk to install Artix on:" "${items[@]}")
    [[ -z "$TARGET_DISK" ]] && die "No disk selected."

    log "Selected disk: $TARGET_DISK"

    # Ask for partitioning scheme
    local scheme
    scheme=$(tui_menu "Partition Scheme" "Choose a partitioning scheme for $TARGET_DISK:" \
        "uefi" "UEFI (GPT with EFI system partition)" \
        "bios" "Legacy BIOS (GPT with BIOS boot partition)" \
        "dualboot" "Dual boot (use free space)")

    [[ -z "$scheme" ]] && die "No partition scheme selected."
    PART_SCHEME="$scheme"

    # Swap size
    SWAP_SIZE=$(tui_menu "Swap Size" "Choose swap partition size:" \
        "2G" "2 GB" \
        "4G" "4 GB" \
        "8G" "8 GB" \
        "16G" "16 GB" \
        "none" "No swap")
}

partition_disk() {
    if ! tui_yesno "WARNING" "This will DESTROY all data on $TARGET_DISK. Are you sure?"; then
        die "Aborted by user."
    fi

    log "Partitioning $TARGET_DISK with scheme: $PART_SCHEME"

    wipefs -af "$TARGET_DISK" 2>/dev/null || true

    local root_size=""
    if [[ "$SWAP_SIZE" != "none" && -n "$SWAP_SIZE" ]]; then
        root_size="size=-${SWAP_SIZE},"
    fi

    case "$PART_SCHEME" in
        uefi)
            sfdisk --wipe always "$TARGET_DISK" <<EOF
label: gpt
size=550M, type=U, name="EFI System"
${root_size} type=L, name="Linux Root"
EOF
            EFI_PART="${TARGET_DISK}1"
            ROOT_PART="${TARGET_DISK}2"
            ;;
        bios)
            sfdisk --wipe always "$TARGET_DISK" <<EOF
label: gpt
size=1M, type=21686148-6449-6E6F-744E-656564454649, name="BIOS Boot"
size=550M, type=L, name="EFI System"
${root_size} type=L, name="Linux Root"
EOF
            EFI_PART="${TARGET_DISK}2"
            ROOT_PART="${TARGET_DISK}3"
            ;;
        dualboot)
            warn "Dual boot: using cfdisk for manual partitioning"
            cfdisk "$TARGET_DISK"
            EFI_PART=$(tui_inputbox "EFI Partition" "Enter the EFI partition device (e.g. /dev/sda1):")
            ROOT_PART=$(tui_inputbox "Root Partition" "Enter the root partition device (e.g. /dev/sda3):")
            ;;
    esac

    if [[ "$SWAP_SIZE" != "none" && -n "$SWAP_SIZE" ]]; then
        log "Adding swap partition ($SWAP_SIZE)"
        echo 'type=S, name="Linux Swap"' | sfdisk --append "$TARGET_DISK"
        SWAP_PART=$(lsblk -lnpo NAME "$TARGET_DISK" | tail -1)
        mkswap "$SWAP_PART"
        swapon "$SWAP_PART"
    fi
}

format_disk() {
    log "Formatting partitions"

    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 -F "$ROOT_PART"
}

mount_disk() {
    log "Mounting partitions"

    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
}
