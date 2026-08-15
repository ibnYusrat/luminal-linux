#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="/tmp/archiso-work"
OUT_DIR="${SCRIPT_DIR}/out"

echo "=================================================="
echo "🚀 Building Custom Arch Linux ISO"
echo "=================================================="

# 1. Run Pre-flight Tests
"${SCRIPT_DIR}/scripts/test-distro-configs.sh"

# 2. Sync Upstream Dependencies
"${SCRIPT_DIR}/scripts/sync-upstream.sh"

# 3. Check if local AUR repo exists
if [ ! -f "${SCRIPT_DIR}/repo/custom-distro-repo.db.tar.gz" ]; then
    echo "==> Local AUR repository not found. Running build-aur-repo.sh..."
    "${SCRIPT_DIR}/scripts/build-aur-repo.sh"
fi

# 3. Clean previous workspace & prepare output
mkdir -p "${OUT_DIR}"
echo "==> Cleaning previous temporary build cache in ${WORK_DIR}..."
if [ -d "${WORK_DIR}" ]; then
    sudo umount -l -R "${WORK_DIR}" 2>/dev/null || true
    sudo rm -rf "${WORK_DIR}" 2>/dev/null || true
fi
mkdir -p "${WORK_DIR}"

# 4. Dynamically configure local repository path in pacman.conf
sed -i "s|Server = file://.*repo|Server = file://${SCRIPT_DIR}/repo|g" "${SCRIPT_DIR}/pacman.conf"

# 5. Run mkarchiso
echo "==> Starting mkarchiso build..."
sudo mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${SCRIPT_DIR}"

echo "=================================================="
echo "🎉 Build Complete!"
echo "Your ISO is available at:"
ls -lh "${OUT_DIR}"/*.iso
echo "=================================================="
