# 🔊 Linux Audio Diagnostic Script

A comprehensive, read-only diagnostic tool for troubleshooting Linux audio issues across PipeWire, PulseAudio, and ALSA configurations.

- [Fedora Audio Guide](https://knowledgebase.frame.work/en_us/fedora-audio-troubleshooting-guide-BJAe1Kr0o)
- [Ubuntu Audio Guide](https://knowledgebase.frame.work/en_us/ubuntu-audio-issues-Bkw2Wlf2o)

## ✨ Features

- **Universal compatibility**: Works with PipeWire (WirePlumber/Media Session), PulseAudio, and ALSA
- **Distro-agnostic**: Supports Ubuntu, Fedora, Debian, Arch, and other major distributions
- **Non-invasive**: Read-only operations, makes no system changes
- **Comprehensive checks**: Services, devices, routing, profiles, and recent logs
- **Smart detection**: Identifies common issues like dummy outputs, suspended nodes, and disabled profiles
- **Test capability**: Optional audio playback test to verify output
+ **Technical detail reporting**: Shows Bluetooth codecs, sample rates, latency, and battery levels
+ **Enhanced Bluetooth support**: Real-time battery monitoring via bluetoothctl

## 📋 Requirements

### Core Requirements
- Linux system with systemd
- One of: PipeWire, PulseAudio, or ALSA

#### Ubuntu users:
  
```sudo apt update && sudo apt install curl -y```

### Optional Tools (auto-detected)
- `wpctl` - PipeWire control (for PipeWire systems)
- `pactl` - PulseAudio control
- `aplay` - ALSA utilities
- `journalctl` - System log access
+ `bluetoothctl` - Bluetooth battery monitoring
+ `bc` - Volume percentage calculations

## 🚀 Quick Start

### One-line Install & Run

```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/misc/audio-diagnostic/audio-diagnostic.sh -o audio-diagnostic.sh && chmod +x audio-diagnostic.sh && bash audio-diagnostic.sh
```

### Step-by-Step

```bash
# Download the script
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/misc/audio-diagnostic/audio-diagnostic.sh -o audio-diagnostic.sh

# Make it executable
chmod +x audio-diagnostic.sh

# Run basic diagnostic
./audio-diagnostic.sh

# Run with audio test
./audio-diagnostic.sh -t

# Check recent issues (last 2 hours)
./audio-diagnostic.sh --since "2 hours ago"
```

## 📖 Usage

```bash
./audio-diagnostic.sh [OPTIONS]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `-t`, `--test` | Play a test sound after diagnostics | `./audio-diagnostic.sh -t` |
| `--since <time>` | Set journal time window (default: 45 minutes ago) | `./audio-diagnostic.sh --since "2 hours ago"` |
| `-v`, `--verbose` | Show detailed log entries | `./audio-diagnostic.sh -v` |
| `-h`, `--help` | Display help message | `./audio-diagnostic.sh -h` |

### Time Window Examples

```bash
# Check logs from last 10 minutes
./audio-diagnostic.sh --since "10 minutes ago"

# Check all of today's logs
./audio-diagnostic.sh --since "today"

# Check since specific time
./audio-diagnostic.sh --since "2024-01-15 14:00:00"

# Use environment variable
SINCE="1 hour ago" ./audio-diagnostic.sh
```

## 📊 What It Checks

### 1. Core Audio Services
- PipeWire/WirePlumber status
- PulseAudio daemon status
- Service health and activity

### 2. Default Devices & Routing
- Current default output (sink)
- Current default input (source)
- Device routing (HDMI, Bluetooth, USB, built-in)
- Dummy device detection
+ Bluetooth codec quality (SBC, AAC, aptX, LDAC)
+ Sample rates and formats (48kHz/s16le)
+ Channel configurations (stereo, 5.1, 7.1)
+ Latency monitoring
+ Battery levels for wireless devices
+ DSP effects (echo cancellation, noise suppression)

### 3. Available Audio Devices
- All audio sinks (outputs)
- All audio sources (inputs)
- Sound card profiles
- Device states and volumes

### 4. System-Specific Checks
- Suspended audio nodes (PipeWire)
- User audio group membership (Ubuntu/Debian)
- ALSA card detection
- TiMidity interference (Ubuntu)

### 5. Recent System Logs
- Service lifecycle events (starts/stops/restarts)
- Error messages and warnings
- Bluetooth audio issues
- Dummy output fallbacks

### 6. Optional Audio Test
- Plays system sound through default output
- Verifies audio pipeline functionality

## 🔍 Understanding the Output

### Status Indicators

- ✅ **Green checkmarks**: Everything working correctly
- ⚠️ **Yellow warnings**: Potential issues that may need attention
- ❌ **Red X marks**: Critical problems requiring fixes
- ℹ️ **Info icons**: Important routing information
- 🔊 **Dim text**: Additional details and suggestions

+ ### Technical Details Shown
+ 
+ | Detail | What It Means | Good Values |
+ |--------|---------------|-------------|
+ | **Codec** | Bluetooth audio compression | AAC, aptX, LDAC (avoid SBC) |
+ | **Sample Rate** | Audio quality/resolution | 44.1kHz or 48kHz standard |
+ | **Latency** | Audio delay in samples | <1000 samples |
+ | **Battery** | Wireless device charge | >20% |
+ | **Channels** | Audio channel config | Stereo for most uses |

## 💡 Example Outputs

### Healthy System
```
✅ PipeWire core: active (systemd)
✅ WirePlumber session: active (systemd)
✅ Default Output: alsa_output.pci-0000_00_1f.3.analog-stereo (ID: 47)
+

Output Device Technical Details:
ℹ️  • Connection: Bluetooth
✅ • Codec: AAC (Good quality - balanced efficiency)
✅ • Battery: 85%
✅ • Sample Rate: 48000Hz/s16le (Standard quality)
✅ • Channels: Stereo
ℹ️  • Latency: 512 samples
ℹ️  • Volume: 76%
✅ No service events or errors in recent logs
✅ No critical issues detected - audio system appears healthy
```

### Problem System
```
❌ WirePlumber session: inactive
❌ Default output is dummy device. Expect silence.
⚠️  One or more audio devices have profile OFF
❌ Found 12 concerning entries in wireplumber logs
```

## 🛠️ Troubleshooting

### No Audio Output?

1. Run the diagnostic:
   ```bash
   ./audio-diagnostic.sh
   ```

2. Follow the suggested fixes in the "Conclusions" section

3. Test audio after fixes:
   ```bash
   ./audio-diagnostic.sh -t
   ```

### Script Not Working?

Check dependencies:
```bash
# For PipeWire systems
which wpctl pw-cli

# For PulseAudio systems  
which pactl

# For ALSA
which aplay
```

### Need More Detail?

Run in verbose mode:
```bash
./audio-diagnostic.sh -v --since "1 hour ago"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Testing on Different Systems

Before submitting changes, please test on:
- [ ] Ubuntu/Debian with PulseAudio
- [ ] Fedora with PipeWire
- [ ] Arch with PipeWire
- [ ] System with Bluetooth audio
- [ ] System with USB audio
- [ ] System with HDMI audio

## 📜 License

GPL-3.0-1 License - [See LICENSE file for details](https://github.com/FrameworkComputer/linux-docs/tree/main?tab=GPL-3.0-1-ov-file#readme)

## 🐛 Known Issues

- Journal time window may include system-wide logs when user logs are empty
- Some device names may be truncated in PipeWire listings
- Bluetooth device detection relies on device naming patterns
+ Bluetooth battery levels require bluetoothctl and may not work with all devices
+ Some PipeWire versions may not expose all technical properties


## ❓ FAQ

**Q: Is it safe to run this script?**  
A: Yes, the script is completely read-only and makes no system modifications.

**Q: Why do I see "dummy output"?**  
A: This means your audio system couldn't find real hardware. Usually fixed by restarting the audio service or installing missing drivers.

**Q: Can I run this via SSH?**  
A: Yes, but the audio test (-t) won't produce sound remotely. Diagnostics will still work.

**Q: How often should I run this?**  
A: Only when experiencing audio issues. It's a diagnostic tool, not a monitoring service.

**Q: Does this work with Bluetooth headphones?**  
A: Yes, it detects and reports Bluetooth audio devices and related issues.

+ **Q: Why don't I see battery levels for my Bluetooth device?**
+ A: Battery reporting requires bluetoothctl and device support. Not all Bluetooth devices report battery status.

---

*For issues or questions, please open a GitHub issue.*
