#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="luminal-linux"
iso_label="LUMINAL_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Luminal Linux <https://github.com/ibnyusrat/luminal-linux>"
iso_application="Luminal Linux Live/Rescue/Install System"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xdict-size' '1M' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/10-wheel"]="0:0:440"
  ["/etc/sudoers.d/liveuser"]="0:0:440"
  ["/root"]="0:0:750"
  ["/home/liveuser"]="1000:1000:750"
  ["/usr/local/bin/screen-off"]="0:0:755"
  ["/usr/local/bin/toggle-launcher"]="0:0:755"
  ["/usr/local/bin/select-timezone"]="0:0:755"
  ["/usr/local/bin/installer"]="0:0:755"
  ["/usr/local/bin/welcome-app"]="0:0:755"
  ["/usr/local/bin/mount-shared"]="0:0:755"
  ["/usr/local/bin/offline-install"]="0:0:755"
  ["/usr/local/bin/luminal-nvidia"]="0:0:755"
)
