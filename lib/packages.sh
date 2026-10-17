#!/usr/bin/env bash

if [[ -n "${_PACKAGES_SH_LOADED:-}" ]]; then
    return 0
fi
_PACKAGES_SH_LOADED=1

select_user_packages() {
    log "Loading available packages from pacman..."

    # Sync package database first
    artix-chroot /mnt pacman -Sy --noconfirm 2>/dev/null || true

    # Get all available packages
    local all_pkgs
    all_pkgs=$(artix-chroot /mnt pacman -Ssq 2>/dev/null | sort)

    if [[ -z "$all_pkgs" ]]; then
        warn "Could not fetch package list. Skipping."
        return
    fi

    local total
    total=$(echo "$all_pkgs" | wc -l)
    log "Found $total packages"

    local search_term
    search_term=$(tui_inputbox "Search Packages" "Enter a search term to filter packages (e.g. 'firefox', 'vim'):")
    
    local filtered_pkgs
    if [[ -n "$search_term" ]]; then
        filtered_pkgs=$(echo "$all_pkgs" | grep -i "$search_term" | head -200)
    else
        filtered_pkgs=$(echo "$all_pkgs" | head -200)
    fi

    if [[ -z "$filtered_pkgs" ]]; then
        warn "No packages found matching '$search_term'."
        return
    fi

    local filtered_count
    filtered_count=$(echo "$filtered_pkgs" | wc -l)

    # Build menu items
    local items=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        items+=("$pkg" "")
    done <<< "$filtered_pkgs"

    local selected
    selected=$(tui_menu "Select Package to Add (showing $filtered_count of $total)" \
        "Select a package to add, or press Cancel to skip.\nSearch: ${search_term:-none}" \
        "${items[@]}")

    if [[ -z "$selected" ]]; then
        log "No additional packages selected."
        return
    fi

    log "Installing user-selected package: $selected"
    pkg_install_chroot "$selected"
    
    # Ask if user wants to add more
    while tui_yesno "Add More Packages" "Would you like to add another package?"; do
        search_term=$(tui_inputbox "Search Packages" "Enter a search term to filter packages:")
        
        if [[ -n "$search_term" ]]; then
            filtered_pkgs=$(echo "$all_pkgs" | grep -i "$search_term" | head -200)
        else
            filtered_pkgs=$(echo "$all_pkgs" | head -200)
        fi

        if [[ -z "$filtered_pkgs" ]]; then
            warn "No packages found matching '$search_term'."
            continue
        fi

        filtered_count=$(echo "$filtered_pkgs" | wc -l)
        items=()
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            items+=("$pkg" "")
        done <<< "$filtered_pkgs"

        selected=$(tui_menu "Select Package to Add (showing $filtered_count of $total)" \
            "Select a package to add, or press Cancel to skip.\nSearch: ${search_term:-none}" \
            "${items[@]}")

        [[ -z "$selected" ]] && break

        log "Installing user-selected package: $selected"
        pkg_install_chroot "$selected"
    done
}
