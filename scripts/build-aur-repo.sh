#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="${PROJECT_ROOT}/repo"
BUILD_DIR="/tmp/aur-build-temp"

AUR_PACKAGES=(
    "yay-bin"
    "caelestia-cli"
    "caelestia-shell"
    "quickshell-git"
    "python-materialyoucolor"
    "darkly-bin"
    "qtengine"
    "papirus-folders"
    "ttf-rubik-vf"
    "ttf-material-symbols-variable"
    "mpvpaper"
    "espanso-bin"
    "oh-my-zsh-git"
    "caelestia-sddm-git"
)

export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
export CARGO_NET_GIT_FETCH_WITH_CLI=true

echo "=================================================="
echo "📦 Staging AUR Packages for Custom Distro"
echo "=================================================="

mkdir -p "${REPO_DIR}"
mkdir -p "${BUILD_DIR}"

# Step 1: Harvest pre-built packages from yay cache
echo "==> 1. Harvesting pre-built packages from ~/.cache/yay..."
if [ -d "$HOME/.cache/yay" ]; then
    find "$HOME/.cache/yay" -type f -name "*.pkg.tar.zst" ! -name "*-debug-*.pkg.tar.zst" 2>/dev/null | while read -r pkg_file; do
        pkg_basename="$(basename "${pkg_file}")"
        if [ ! -f "${REPO_DIR}/${pkg_basename}" ]; then
            cp -v "${pkg_file}" "${REPO_DIR}/"
        fi
    done
fi

# Step 2: Build any missing target AUR packages
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

    # Build using makepkg
    echo "  [BUILD] Cloning and building ${pkg} from AUR..."
    cd "${BUILD_DIR}"
    rm -rf "${pkg}"
    if git clone --depth 1 "https://aur.archlinux.org/${pkg}.git"; then
        cd "${pkg}"
        if makepkg -sc --noconfirm --needed; then
            cp -v ./*.pkg.tar.zst "${REPO_DIR}/"
            echo "  [SUCCESS] Built ${pkg}."
        else
            echo "  [WARNING] Failed building ${pkg}."
        fi
    else
        echo "  [WARNING] Failed to clone ${pkg} from AUR."
    fi
done

# Step 3: Remove any debug packages
rm -f "${REPO_DIR}"/*-debug-*.pkg.tar.zst 2>/dev/null || true

# Step 4: Index the repository with repo-add
echo "=================================================="
echo "==> 3. Updating repository database..."
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
