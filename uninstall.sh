#!/bin/bash
set -e

echo "=== dock_detect — Uninstall ==="

# Remove scripts
echo "[*] Removing scripts..."
sudo rm -f /usr/local/bin/is_home_desk.sh
sudo rm -f /usr/local/bin/home_dock_event.sh
sudo rm -f /usr/local/bin/lid_event.sh

# Remove udev rule
echo "[*] Removing udev rule..."
sudo rm -f /etc/udev/rules.d/99-home-dock.rules
sudo udevadm control --reload-rules

# Remove ACPI event
echo "[*] Removing ACPI event..."
sudo rm -f /etc/acpi/events/lid-home-dock
sudo systemctl restart acpid

echo ""
echo "=== Uninstall complete ==="
echo "Note: HandleLidSwitchDocked in /etc/systemd/logind.conf was NOT changed."
echo "Edit it manually if needed:"
echo "  sudo sed -i 's/HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=suspend/' /etc/systemd/logind.conf"
echo "  sudo systemctl restart systemd-logind"
