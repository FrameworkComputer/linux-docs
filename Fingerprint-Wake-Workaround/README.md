# Framework 13 Ryzen AI 300 series Fingerprint Wake Workaround

Automatic workaround for Framework 13 AMD fingerprint reader not working after suspend/resume.

## Problem

On Framework 13 AMD laptops, the Goodix fingerprint reader sometimes fails to reconnect after waking from suspend. This requires a manual reboot to restore functionality.

**Tracking Issue**: https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/102

## Solution

This script automatically detects your fingerprint reader hardware and creates a systemd service that:
- Monitors for the fingerprint reader after each wake
- Automatically resets the USB controller if the reader is missing
- Restarts the fprintd service to restore functionality
- Logs all actions for debugging

**No hardcoded values** - works across different Framework 13 AMD configurations and fingerprint reader variants (Goodix, Synaptics, ELAN).

## Supported Hardware

- **Laptop**: Framework 13 AMD (Ryzen AI 300 series)
- **Fingerprint Reader**: Goodix Fingerprint Reader
- **Distributions**: Any systemd-based Linux distribution

## Installation

One-line install:

    curl -sSL https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Fingerprint-Wake-Workaround/install-fingerprint-wake.sh | bash

The installer will auto-detect your hardware and show you exactly what was found.

## Testing

After installation, test the workaround:

    journalctl -t fp-rebind -f

Then suspend your system and resume. Check if fingerprint reader works and view the logs.

## Uninstallation

One-line uninstall:

    curl -sSL https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Fingerprint-Wake-Workaround/uninstall-fingerprint-wake.sh | bash

## How It Works

1. **Detection Phase**: Scans USB devices to find your fingerprint reader
2. **Path Resolution**: Follows sysfs symlinks to find the PCI controller
3. **Driver Detection**: Identifies which driver (xhci_hcd/xhci-pci) is in use
4. **Service Creation**: Generates a systemd service with detected values
5. **Wake Monitoring**: After each suspend/resume, checks if reader is present
6. **Automatic Recovery**: If missing, unbinds and rebinds the USB controller

## Files Created

- `/etc/local/bin/run-after-wake-for-fprint.sh` - Wake monitoring script
- `/etc/systemd/system/run-after-wake-for-fprint.service` - Systemd service unit

## Troubleshooting

View service logs:

    journalctl -t fp-rebind --since "24 hours ago"

Check service status:

    systemctl status run-after-wake-for-fprint.service

Test the script manually:

    sudo systemctl start run-after-wake-for-fprint.service

## Contributing

Issues and pull requests welcome! Please test on your Framework 13 AMD before submitting.

## License

MIT License - feel free to use and modify.

## Credits

Inspired by kariudo's original implementation: https://github.com/kariudo/framework-13-fingerprint-fix

This version improves upon the original by:
- Auto-detecting all hardware values instead of hardcoding
- Supporting multiple fingerprint reader variants
- Working across different PCI configurations
- Providing detailed diagnostic output during installation
