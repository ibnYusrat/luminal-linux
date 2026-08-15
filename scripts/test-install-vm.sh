#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_PATH=$(ls -t "${PROJECT_ROOT}/out/"*.iso 2>/dev/null | head -n 1)

if [ -z "${ISO_PATH}" ] || [ ! -f "${ISO_PATH}" ]; then
    echo "❌ No ISO found in out/. Please run ./build-iso.sh first."
    exit 1
fi

DISK_PATH="/dev/shm/luminal-test-disk.qcow2"
SHARED_DIR="${PROJECT_ROOT}/out/shared"

mkdir -p "${SHARED_DIR}"

echo "==> Initializing fresh virtual hard drive in RAM (/dev/shm)..."
rm -f "${DISK_PATH}"
qemu-img create -f qcow2 -o cluster_size=2M "${DISK_PATH}" 25G

echo "=================================================="
echo "🚀 Launching Live ISO with Virtual Target Disk & Shared Folder"
echo "=================================================="
echo "• ISO:           ${ISO_PATH}"
echo "• Target Disk:   ${DISK_PATH} (Shows up as /dev/vda in installer)"
echo "• Shared Folder: ${SHARED_DIR} <---> /mnt/shared inside VM"
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
    -drive file="${DISK_PATH}",if=virtio,format=qcow2 \
    -drive file="${ISO_PATH}",if=none,id=cd0,media=cdrom,readonly=on \
    -device virtio-scsi-pci,id=scsi0 \
    -device scsi-cd,drive=cd0,bootindex=0 \
    -virtfs local,path="${SHARED_DIR}",mount_tag=hostshare,security_model=none,id=hostshare \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0,romfile=""
