#!/bin/bash
set -e

echo "=== dock_detect — Home Desk Dock Setup ==="

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy scripts
echo "[*] Installing scripts to /usr/local/bin/..."
sudo cp "$REPO_DIR/scripts/is_home_desk.sh" /usr/local/bin/
sudo cp "$REPO_DIR/scripts/home_dock_event.sh" /usr/local/bin/
sudo chmod +x /usr/local/bin/is_home_desk.sh
sudo chmod +x /usr/local/bin/home_dock_event.sh

# Copy udev rule
echo "[*] Installing udev rule..."
sudo cp "$REPO_DIR/udev/99-home-dock.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Install acpid (for lid event)
echo "[*] Installing acpid..."
sudo pacman -S --needed --noconfirm acpid

# Copy ACPI event handler
echo "[*] Installing ACPI lid event handler..."
sudo cp "$REPO_DIR/scripts/lid_event.sh" /usr/local/bin/
sudo chmod +x /usr/local/bin/lid_event.sh

# Install ACPI event rule
sudo tee /etc/acpi/events/lid-home-dock << 'EOF'
event=button/lid.*
action=/usr/local/bin/lid_event.sh
EOF

sudo systemctl enable --now acpid

# HandleLidSwitchDocked check
echo ""
echo "[!] Important: Make sure /etc/systemd/logind.conf has:"
echo "    HandleLidSwitchDocked=ignore"
echo ""
echo "    Currently: $(grep -E '^HandleLidSwitchDocked' /etc/systemd/logind.conf 2>/dev/null || echo 'not set (default)')"
echo ""
read -p "Do you want to set it now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo sed -i 's/^#\?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
    if ! grep -q 'HandleLidSwitchDocked=ignore' /etc/systemd/logind.conf; then
        echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf
    fi
    sudo systemctl restart systemd-logind
    echo "[✓] Done"
fi

echo ""
echo "=== Setup complete! ==="
echo "Next steps:"
echo "  1. Plug your home dock — the internal display should disable automatically"
echo "  2. Close the lid — it should stay on (no suspend)"
echo "  3. Open the lid or unplug — internal display comes back"
echo ""
echo "To test the EDID detection manually:"
echo "  /usr/local/bin/is_home_desk.sh && echo 'At home desk!' || echo 'Not at home'"
