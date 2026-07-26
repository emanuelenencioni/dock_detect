# dock_detect

Automatically manage your ThinkPad T14 Gen 2 display when docking at your home desk.

## What it does

- **Hub plugged in at home** → disables internal display, enables external monitor
- **Lid closed at home** → prevents suspend, keeps external monitor on
- **Hub unplugged** → re-enables internal display
- **At office** → does nothing (different monitors, different EDID)

## Requirements

- Arch Linux
- Hyprland
- `hyprctl` available
- `pacman` for installing acpid

## Detection method

Uses **EDID hashing** of your specific home monitor on DP-3 (via USB-C hub).

You'll need to find your own monitor's EDID (see below).

If you ever change monitors, re-run the EDID scan:

```bash
for mon in /sys/class/drm/*/edid; do
  [ -f "$mon" ] && echo "$(basename $(dirname $mon)): $(md5sum $mon | cut -d' ' -f1)"
done
```

Then update `HOME_SERIAL` in `scripts/is_home_desk.sh`.

## Configuration

Before running setup, edit these placeholders in the scripts:

| File | Value to set |
|------|-------------|
| `scripts/is_home_desk.sh` | `USER` → your Linux username, `HOME_SERIAL` → your monitor's serial |
| `scripts/home_dock_event.sh` | `USER` → your Linux username |
| `scripts/lid_event.sh` | `USER` → your Linux username |

To find your monitor serial:
```bash
hyprctl monitors all -j | grep serial
```

## Quick start

```bash
git clone <your-repo-url> dock_detect
cd dock_detect
./setup.sh
```

## Directory structure

```
dock_detect/
├── setup.sh                # Install everything
├── uninstall.sh            # Remove everything
├── README.md
├── scripts/
│   ├── is_home_desk.sh     # Returns 0 if home monitor is detected
│   ├── home_dock_event.sh  # Triggered by udev on hub plug/unplug
│   └── lid_event.sh        # Triggered by acpid on lid close/open
├── udev/
│   └── 99-home-dock.rules  # udev rule matching your Terminus hub
```

## What setup.sh does

1. Copies scripts to `/usr/local/bin/` and sets executable permissions
2. Installs the udev rule and reloads it
3. Installs `acpid` (if not already installed)
4. Sets up the ACPI lid event handler
5. Optionally configures `HandleLidSwitchDocked=ignore` in `logind.conf`

## Testing

### Check if home desk monitor is detected:

```bash
/usr/local/bin/is_home_desk.sh && echo "Home" || echo "Not home"
```

### Trigger the dock event manually:

```bash
# Simulate plugging the hub
sudo /usr/local/bin/home_dock_event.sh add

# Simulate unplugging the hub
sudo /usr/local/bin/home_dock_event.sh remove
```

### Trigger the lid event manually:

```bash
# Simulate lid closed
sudo /usr/local/bin/lid_event.sh

# Check the lid state
cat /proc/acpi/button/lid/*/state
```

## Troubleshooting

### The internal display doesn't disable when I plug the hub

1. Check if the udev rule is loaded:
   ```bash
   udevadm info -a -n /dev/bus/usb/003/006 | grep -i "idVendor\|idProduct"
   ```
   Make sure it matches `1a40` and `0101`. If the device path changed, update the udev file.

2. Check if home desk detection works:
   ```bash
   /usr/local/bin/is_home_desk.sh && echo "Home" || echo "Not home"
   ```
   If it says "Not home", your monitor EDID might have changed (e.g., after a monitor firmware update). Re-run the EDID scan and update the script.

3. Run the event handler manually to see errors:
   ```bash
   sudo /usr/local/bin/home_dock_event.sh add
   ```

### The laptop still suspends when I close the lid while docked

Make sure you have `HandleLidSwitchDocked=ignore` set in `/etc/systemd/logind.conf`:

```bash
grep HandleLidSwitchDocked /etc/systemd/logind.conf
```

If missing, add it and restart:
```bash
echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo systemctl restart systemd-logind
```

### acpid isn't running

```bash
sudo systemctl status acpid
sudo systemctl enable --now acpid
```

## Uninstall

```bash
cd dock_detect
./uninstall.sh
```

This removes:
- `/usr/local/bin/is_home_desk.sh`
- `/usr/local/bin/home_dock_event.sh`
- `/usr/local/bin/lid_event.sh`
- `/etc/udev/rules.d/99-home-dock.rules`
- `/etc/acpi/events/lid-home-dock`

It does **not** revert `HandleLidSwitchDocked` — do that manually if needed:

```bash
sudo sed -i 's/HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=suspend/' /etc/systemd/logind.conf
sudo systemctl restart systemd-logind
```

## Unifying Receiver wake

If you want to wake the laptop from standby using the Logitech mouse when docked:

1. Make sure the Logitech Unifying Receiver is plugged into the USB switch (or directly into the hub)
2. The receiver is already wake-enabled (`3-7` has `power/wakeup = enabled`)

If you need to enable wake on another USB device:

```bash
# Find the device
lsusb -t

# Enable wake
echo enabled | sudo tee /sys/bus/usb/devices/3-6.X/power/wakeup
```

## How it works (summary)

1. **udev** detects the Terminus Technology hub (`1a40:0101`) being plugged/unplugged
2. **home_dock_event.sh** runs and calls **is_home_desk.sh** to verify the monitor EDID matches your home monitor
3. If it's a match → disables internal display (`eDP-1`), enables external (`DP-3`)
4. If HDMI is also connected → enables that too
5. When unplugged → re-enables internal display
6. **acpid** catches lid close → checks if at home → if yes, inhibits suspend and disables internal display
7. When lid opens → re-enables internal display

At the office, the EDID check fails → nothing happens. Normal behavior is preserved.
