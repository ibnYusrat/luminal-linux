#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="${PROJECT_ROOT}/repo"
BUILD_DIR="/tmp/aur-build-temp"

AUR_PACKAGES=(
    "yay-bin"
    "libcava"
    "caelestia-cli"
    "quickshell-git"
    "caelestia-shell"
    "python-materialyoucolor"
    "qtengine"
    "papirus-folders"
    "ttf-rubik-vf"
    "ttf-material-symbols-variable"
    "mpvpaper"
)

export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
export CARGO_NET_GIT_FETCH_WITH_CLI=true

echo "=================================================="
echo "📦 Staging AUR Packages for Custom Distro"
echo "=================================================="

mkdir -p "${REPO_DIR}"
mkdir -p "${BUILD_DIR}"

# Step 1: Ensure yay is installed for automated AUR dependency resolution
if ! command -v yay &>/dev/null; then
    echo "==> yay not found. Building and bootstrapping yay-bin..."
    cd "${BUILD_DIR}"
    rm -rf yay-bin
    if git clone --depth 1 "https://aur.archlinux.org/yay-bin.git"; then
        cd yay-bin
        if makepkg -sc --noconfirm --needed; then
            cp -v ./*.pkg.tar.zst "${REPO_DIR}/" 2>/dev/null || true
            sudo pacman -U --noconfirm ./*.pkg.tar.zst 2>/dev/null || true
            echo "  [SUCCESS] yay bootstrapped."
        fi
    fi
fi

# Step 2: Build any missing target AUR packages using yay
echo "==> 2. Checking and building any missing AUR packages..."
for pkg in "${AUR_PACKAGES[@]}"; do
    echo "----------------------------------------"
    echo "--> Checking AUR package: ${pkg}"
    
    # Check if package already exists in repo
    pkg_base="${pkg%-bin}"
    pkg_base="${pkg_base%-git}"
    if compgen -G "${REPO_DIR}/${pkg}-*.pkg.tar.zst" > /dev/null || compgen -G "${REPO_DIR}/${pkg_base}-*.pkg.tar.zst" > /dev/null || compgen -G "${REPO_DIR}/${pkg_base}*-git-*.pkg.tar.zst" > /dev/null; then
        echo "  [EXISTS] Package ${pkg} found in repository."
        continue
    fi

    echo "  [BUILD] Building ${pkg} via yay..."
    if command -v yay &>/dev/null; then
        yay -S --builddir "${BUILD_DIR}" --noconfirm --mflags "--nocheck" "${pkg}" 2>/dev/null || true
    else
        cd "${BUILD_DIR}"
        rm -rf "${pkg}"
        if git clone --depth 1 "https://aur.archlinux.org/${pkg}.git"; then
            cd "${pkg}"
            makepkg -sc --noconfirm --needed --nocheck 2>/dev/null || true
        fi
    fi
done

# Step 3: Harvest all generated packages from yay cache and build directory
echo "==> 3. Harvesting built packages into repository..."
find "${BUILD_DIR}" "$HOME/.cache/yay" -type f -name "*.pkg.tar.zst" ! -name "*-debug-*.pkg.tar.zst" 2>/dev/null | while read -r pkg_file; do
    pkg_basename="$(basename "${pkg_file}")"
    if [ ! -f "${REPO_DIR}/${pkg_basename}" ]; then
        cp -v "${pkg_file}" "${REPO_DIR}/" 2>/dev/null || true
    fi
done

# Remove any debug packages
rm -f "${REPO_DIR}"/*-debug-*.pkg.tar.zst 2>/dev/null || true

# Step 4: Index the repository with repo-add
echo "=================================================="
echo "==> 4. Updating repository database..."
cd "${REPO_DIR}"

if compgen -G "*.pkg.tar.zst" > /dev/null; then
    rm -f custom-distro-repo.db* custom-distro-repo.files*
    repo-add custom-distro-repo.db.tar.gz ./*.pkg.tar.zst
    echo "=================================================="
    echo "🎉 Local repository database is ready!"
    echo "Total packages staged: $(ls -1 ./*.pkg.tar.zst | wc -l)"
    echo "=================================================="
else
    echo "⚠️ No packages found in ${REPO_DIR}."
fi
