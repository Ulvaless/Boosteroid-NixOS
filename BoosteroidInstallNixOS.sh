#!/usr/bin/env bash
set -e

echo "========================================"
echo "        Boosteroid NixOS Installer"
echo "========================================"
echo

PACKAGES=(
    wget
    gnutar
    steam-run
    libvdpau
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
)

TOTAL=${#PACKAGES[@]}
INSTALLED=0

echo "==> Checking dependencies..."
echo

for package in "${PACKAGES[@]}"; do
    if nix-store -q --roots "$(nix-instantiate --eval '<nixpkgs>' -A "$package" 2>/dev/null | tr -d '"')" >/dev/null 2>&1; then
        echo "[Already Installed] $package"
    else
        echo "[Installing] $package"
    fi
done

echo
echo "==> Preparing Boosteroid environment..."
echo

nix-shell -p \
    "${PACKAGES[@]}" \
    --run '
        echo "==> All dependencies are ready."
        echo

        cd "$HOME/Downloads"

        if [ -d "BoosteroidGamesS.R.L." ] && [ -f "BoosteroidGamesS.R.L./Boosteroid" ]; then
            echo "[Already Installed] Boosteroid"
        else
            echo "==> Downloading Boosteroid..."

            wget --show-progress \
                -O boosteroid_portable.tar \
                "https://boosteroid.com/linux/installer/boosteroid_portable.tar"

            echo
            echo "==> Extracting Boosteroid..."

            mkdir -p BoosteroidGamesS.R.L.
            tar xf boosteroid_portable.tar -C BoosteroidGamesS.R.L.
            rm boosteroid_portable.tar

            echo "[Installed] Boosteroid"
        fi

        cd "$HOME/Downloads/BoosteroidGamesS.R.L."

        echo
        echo "==> Finding required libraries..."

        LIBS=""

        for lib in \
            "libvdpau.so.1" \
            "libxcb-icccm.so.4" \
            "libxcb-image.so.0" \
            "libxcb-keysyms.so.1" \
            "libxcb-render-util.so.0"
        do
            path=$(find /nix/store -name "$lib" 2>/dev/null | head -1)

            if [ -z "$path" ]; then
                echo "[ERROR] $lib not found"
                exit 1
            fi

            dir=$(dirname "$path")
            LIBS="${LIBS:+$LIBS:}$dir"

            echo "[OK] $lib"
        done

        echo
        echo "========================================"
        echo "       Starting Boosteroid..."
        echo "========================================"
        echo

        LD_LIBRARY_PATH="$LIBS" steam-run ./Boosteroid
    '
