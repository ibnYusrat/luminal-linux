#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
SKEL_DIR="${PROJECT_ROOT}/airootfs/etc/skel"

echo "=================================================="
echo "🔄 Syncing Upstream Shell & Plugin Dependencies"
echo "=================================================="

# 1. Clean compiled zsh wordcode files and inner git repositories
find "${PROJECT_ROOT}/airootfs" -name "*.zwc" -delete 2>/dev/null || true
find "${PROJECT_ROOT}/airootfs" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

# 2. Sync Oh-My-Zsh
OMZ_DIR="${SKEL_DIR}/.oh-my-zsh"
if [ ! -d "${OMZ_DIR}" ] || [ ! -f "${OMZ_DIR}/oh-my-zsh.sh" ]; then
    echo "==> Fetching fresh Oh-My-Zsh from upstream..."
    rm -rf "${OMZ_DIR}"
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "${OMZ_DIR}"
    rm -rf "${OMZ_DIR}/.git"
fi

# 3. Sync Powerlevel10k Theme
P10K_DIR="${OMZ_DIR}/custom/themes/powerlevel10k"
if [ ! -d "${P10K_DIR}" ] || [ ! -f "${P10K_DIR}/powerlevel10k.zsh-theme" ]; then
    echo "==> Fetching fresh Powerlevel10k theme from upstream..."
    rm -rf "${P10K_DIR}"
    git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "${P10K_DIR}"
    rm -rf "${P10K_DIR}/.git"
fi

# 4. Sync z-lua
ZLUA_DIR="${SKEL_DIR}/.z-lua"
if [ ! -d "${ZLUA_DIR}" ] || [ ! -f "${ZLUA_DIR}/z.lua" ]; then
    echo "==> Fetching fresh z-lua from upstream..."
    rm -rf "${ZLUA_DIR}"
    git clone --depth 1 https://github.com/skywind3000/z.lua.git "${ZLUA_DIR}"
    rm -rf "${ZLUA_DIR}/.git"
fi

# 5. Clean compiled bytecode again before mirror
find "${PROJECT_ROOT}/airootfs" -name "*.zwc" -delete 2>/dev/null || true

# 6. Mirror skeleton into liveuser directory
LIVEUSER_DIR="${PROJECT_ROOT}/airootfs/home/liveuser"
rm -rf "${LIVEUSER_DIR}"
mkdir -p "${LIVEUSER_DIR}"
cp -a "${SKEL_DIR}/." "${LIVEUSER_DIR}/"

echo "✅ Upstream dependencies synced cleanly into airootfs."
