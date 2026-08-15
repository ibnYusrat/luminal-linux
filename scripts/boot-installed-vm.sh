#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK_PATH="/dev/shm/luminal-test-disk.qcow2"
SHARED_DIR="${PROJECT_ROOT}/out/shared"

mkdir -p "${SHARED_DIR}"

if [ ! -f "${DISK_PATH}" ]; then
    echo "❌ No virtual hard drive found in RAM at ${DISK_PATH}."
    echo "Please install to the disk first by running: ./scripts/test-install-vm.sh"
    exit 1
fi

echo "=================================================="
echo "🚀 Booting Installed Custom Arch Linux (From Virtual Disk)"
echo "=================================================="
echo "• Virtual Disk:  ${DISK_PATH}"
echo "• Shared Folder: ${SHARED_DIR} <---> /mnt/shared"
echo "• Memory:        4GB, Cores: 4"
echo "• Release Mouse: Press Ctrl+Alt+G"
echo "=================================================="

qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -smp 4 \
    -cpu host \
    -vga virtio \
    -display default,show-cursor=on \
    -bios /usr/share/edk2/x64/OVMF.4m.fd \
    -drive file="${DISK_PATH}",if=none,id=hd0,format=qcow2 \
    -device virtio-blk-pci,drive=hd0,bootindex=0 \
    -virtfs local,path="${SHARED_DIR}",mount_tag=hostshare,security_model=none,id=hostshare \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0,romfile=""
