#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AIROOTFS="${PROJECT_ROOT}/airootfs"

echo "=================================================="
echo "🧪 Running Distro Configuration Test Suite"
echo "=================================================="

ERRORS=0

log_pass() {
    echo "  [PASS] $1"
}

log_fail() {
    echo "  [FAIL] $1: $2"
    ERRORS=$((ERRORS + 1))
}

# 1. Test Custom Shell Scripts Syntax (bash -n and zsh -n)
echo "--> 1. Verifying Shell Scripts Syntax..."
while IFS= read -r -d '' script; do
    if bash -n "$script" 2>&1; then
        log_pass "$(realpath --relative-to="${PROJECT_ROOT}" "$script")"
    else
        log_fail "$script" "Bash syntax error"
    fi
done < <(find "${AIROOTFS}/usr/local/bin" "${AIROOTFS}/etc/skel/.config/hypr" "${PROJECT_ROOT}/scripts" -name "*.sh" -print0 2>/dev/null || true)

# 2. Test JSON Configs (jq .)
echo "--> 2. Verifying JSON Configuration Files..."
while IFS= read -r -d '' json; do
    if jq . "$json" > /dev/null 2>&1; then
        log_pass "$(realpath --relative-to="${PROJECT_ROOT}" "$json")"
    else
        log_fail "$json" "Invalid JSON format"
    fi
done < <(find "${AIROOTFS}/etc/skel/.config" -name "*.json" -print0 2>/dev/null || true)

# 3. Test XML Configs (Python xml.etree check)
echo "--> 3. Verifying XML Configuration Files..."
while IFS= read -r -d '' xml; do
    if python3 -c "import xml.etree.ElementTree as ET; ET.parse('$xml')" > /dev/null 2>&1; then
        log_pass "$(realpath --relative-to="${PROJECT_ROOT}" "$xml")"
    else
        log_fail "$xml" "Invalid XML structure"
    fi
done < <(find "${AIROOTFS}/etc/skel/.config" -name "*.xml" -print0 2>/dev/null || true)

# 4. Test Lua Configs (luac -p)
echo "--> 4. Verifying Lua Configurations..."
if command -v luac > /dev/null 2>&1; then
    while IFS= read -r -d '' lua; do
        if luac -p "$lua" > /dev/null 2>&1; then
            log_pass "$(realpath --relative-to="${PROJECT_ROOT}" "$lua")"
        else
            log_fail "$lua" "Lua syntax error"
        fi
    done < <(find "${AIROOTFS}/etc/skel/.config/hypr" "${AIROOTFS}/etc/skel/.config/caelestia" -name "*.lua" -print0 2>/dev/null || true)
fi

# 5. Test Critical System Files Existence
echo "--> 5. Checking Critical Distro Artifacts..."
CRITICAL_FILES=(
    "${PROJECT_ROOT}/profiledef.sh"
    "${PROJECT_ROOT}/packages.x86_64"
    "${PROJECT_ROOT}/pacman.conf"
    "${AIROOTFS}/etc/systemd/system-preset/90-distro.preset"
    "${AIROOTFS}/etc/systemd/user-preset/90-distro-user.preset"
    "${AIROOTFS}/etc/plymouth/plymouthd.conf"
    "${AIROOTFS}/usr/share/custom-distro/kernel-presets/linux.preset"
    "${AIROOTFS}/etc/default/useradd"
    "${AIROOTFS}/etc/skel/.config/hypr"
    "${AIROOTFS}/etc/skel/.config/kitty/kitty.conf"
    "${AIROOTFS}/etc/skel/.config/Thunar/uca.xml"
    "${AIROOTFS}/etc/skel/.zshrc"
    "${AIROOTFS}/etc/skel/.p10k.zsh"
    "${PROJECT_ROOT}/repo/custom-distro-repo.db.tar.gz"
    "${PROJECT_ROOT}/README.md"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -e "$file" ]; then
        log_pass "$(realpath --relative-to="${PROJECT_ROOT}" "$file")"
    else
        log_fail "$file" "Missing required file"
    fi
done

# 6. Test File Permissions for System Executables
echo "--> 6. Checking Script Permissions..."
while IFS= read -r -d '' bin; do
    if [ -x "$bin" ]; then
        log_pass "$(realpath --relative-to="${PROJECT_ROOT}" "$bin") (Executable)"
    else
        log_fail "$bin" "Script is missing executable bit (chmod +x needed)"
    fi
done < <(find "${AIROOTFS}/usr/local/bin" -type f -print0 2>/dev/null || true)

echo "=================================================="
if [ $ERRORS -eq 0 ]; then
    echo "🎉 ALL DISTRO PRE-FLIGHT TESTS PASSED!"
    exit 0
else
    echo "❌ $ERRORS TEST(S) FAILED. Please review the errors above."
    exit 1
fi
