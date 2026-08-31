"""
Hardware detection for GPU, NVMe, WiFi, RAM, and Framework-specific components.
"""

import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from enum import Enum

from .utils import run_command, run_sudo_command


class CPUVendor(Enum):
    """CPU vendor types."""
    AMD = 'AMD'
    INTEL = 'Intel'
    UNKNOWN = 'Unknown'


class AMDGeneration(Enum):
    """AMD processor generation for thermal threshold calibration."""
    MODERN = 'modern'  # Ryzen 7000/AI 300 series - runs hot by design
    LEGACY = 'legacy'  # Older Ryzen - lower thermal limits


@dataclass
class GPUInfo:
    """GPU hardware information."""
    name: str
    pci_id: str
    vendor: str  # AMD, Intel, NVIDIA
    driver: str = ""
    is_discrete: bool = False


@dataclass
class NVMeInfo:
    """NVMe storage device information."""
    device: str  # e.g., /dev/nvme0n1
    model: str
    pci_id: str = ""
    firmware: str = ""


@dataclass
class DiskHealthInfo:
    """Disk health status from SMART data."""
    device: str  # e.g., /dev/nvme0n1 or /dev/sda
    model: str
    is_nvme: bool = True
    
    # Health status
    healthy: bool = True
    health_status: str = ""  # "PASSED", "FAILED", etc.
    
    # Key metrics (NVMe)
    percentage_used: Optional[int] = None  # 0-100%, 100% = end of life
    available_spare: Optional[int] = None  # Spare capacity %
    temperature: Optional[int] = None  # Celsius
    
    # Usage stats (NVMe) - the actually useful stuff
    data_written_tb: Optional[float] = None  # TB written
    power_on_hours: Optional[int] = None
    power_cycles: Optional[int] = None
    unsafe_shutdowns: Optional[int] = None
    media_errors: Optional[int] = None
    
    # Key metrics (SATA)
    reallocated_sectors: Optional[int] = None
    pending_sectors: Optional[int] = None
    
    # Warnings
    warnings: list[str] = field(default_factory=list)


@dataclass
class WiFiInfo:
    """WiFi adapter information."""
    name: str
    pci_id: str
    vendor: str  # Intel, MediaTek, etc.
    driver: str = ""


@dataclass
class RFKillDevice:
    """RF kill switch status for a wireless device."""
    index: int
    name: str  # e.g., "hci0", "phy0"
    device_type: str  # e.g., "Bluetooth", "Wireless LAN"
    soft_blocked: bool = False
    hard_blocked: bool = False


@dataclass
class WebcamInfo:
    """Webcam and microphone detection.
    
    Framework webcam modules have separate hardware privacy switches for
    camera and microphone:
    
    Gen 1 (OV2740/RTS5853):
      Camera switch OFF → USB device electrically disconnected, disappears from bus
      Mic switch OFF → microphones electrically disconnected
      
    Gen 2 (OV08X40/RTS5879):
      Camera switch OFF → sensor powered down, controller stays alive,
                          sends blank frames. USB device stays on bus.
      Mic switch OFF → microphones electrically disconnected
    
    Internal microphones route through mainboard audio codec (DMIC/HDA),
    NOT through USB webcam. When mic switch is off, ALSA capture device
    may still exist but records dead silence.
    
    We report what we can observe (device present/absent, capture devices)
    and leave interpretation to the support agent.
    """
    # Camera hardware
    detected: bool = False
    device_name: str = ""           # from V4L2 sysfs, e.g. "Integrated Camera"
    usb_id: str = ""                # e.g. "32ac:001c"
    usb_name: str = ""              # from lsusb, e.g. "Framework Laptop Webcam Module (2nd Gen)"
    v4l_devices: list[str] = field(default_factory=list)  # e.g. ["/dev/video0"]
    uvcvideo_loaded: bool = False
    
    # Microphone capture devices (from arecord -l)
    mic_capture_devices: list[str] = field(default_factory=list)


@dataclass
class DisplayInfo:
    """Connected display information."""
    connector: str  # e.g., "eDP-1", "DP-1", "HDMI-A-1"
    resolution: str = ""  # e.g., "2256x1504"
    refresh_rate: str = ""  # e.g., "60.00"
    is_internal: bool = False  # True for eDP (laptop internal panel)
    psr_status: str = ""  # e.g., "PSR1 enabled", "disabled", "" if N/A


@dataclass
class RAMInfo:
    """RAM information."""
    total_gb: int
    ram_type: str = ""  # DDR4, DDR5, etc.
    speed_mhz: int = 0


@dataclass
class FrameworkInfo:
    """Framework-specific device information."""
    is_framework: bool = False
    product_name: str = ""
    model_version: str = ""
    model_type: str = ""  # "Laptop 13", "Laptop 16", "Laptop 12", "Desktop"
    bios_version: str = ""
    
    # Power status
    ac_connected: bool = False
    battery_level: Optional[int] = None
    battery_status: str = ""
    battery_health_pct: Optional[float] = None  # Actual capacity vs design capacity
    
    # Battery detail (sysfs + upower)
    battery_cycle_count: Optional[int] = None
    battery_design_wh: Optional[float] = None  # Design capacity in Wh
    battery_full_wh: Optional[float] = None     # Current full charge capacity in Wh
    battery_charge_rate_w: Optional[float] = None  # Current charge/discharge rate in W
    battery_charge_limit_pct: Optional[int] = None  # Charge threshold if set (e.g., 80%)
    
    # Expansion cards
    expansion_cards: list[str] = field(default_factory=list)
    expansion_card_ports: list[tuple[str, str]] = field(default_factory=list)  # (card_name, usb_port_path)


@dataclass
class HardwareInfo:
    """Complete hardware information."""
    gpu: list[GPUInfo] = field(default_factory=list)
    nvme: list[NVMeInfo] = field(default_factory=list)
    disk_health: list[DiskHealthInfo] = field(default_factory=list)
    wifi: Optional[WiFiInfo] = None
    ram: Optional[RAMInfo] = None
    framework: FrameworkInfo = field(default_factory=FrameworkInfo)
    rfkill_devices: list[RFKillDevice] = field(default_factory=list)
    webcam: Optional[WebcamInfo] = None
    displays: list[DisplayInfo] = field(default_factory=list)
    
    cpu_vendor: CPUVendor = CPUVendor.UNKNOWN
    cpu_model: str = ""
    amd_generation: AMDGeneration = AMDGeneration.LEGACY


def _get_gpu_drivers_from_lshw() -> dict[str, str]:
    """Get GPU driver mapping from lshw -C display.
    
    Returns dict of pci_id -> driver_name, e.g. {'c1:00.0': 'amdgpu'}
    
    lshw output looks like:
      *-display
           bus info: pci@0000:c1:00.0
           configuration: driver=amdgpu latency=0
    """
    drivers = {}
    
    rc, stdout, _ = run_command(['lshw', '-C', 'display'])
    if rc != 0:
        return drivers
    
    current_pci = ''
    for line in stdout.split('\n'):
        stripped = line.strip()
        if stripped.startswith('bus info:') and 'pci@' in stripped:
            # "bus info: pci@0000:c1:00.0" -> "c1:00.0"
            pci_full = stripped.split('pci@')[-1].strip()
            # Strip domain prefix: "0000:c1:00.0" -> "c1:00.0"
            parts = pci_full.split(':')
            if len(parts) >= 3:
                current_pci = ':'.join(parts[1:])  # drop domain
            else:
                current_pci = pci_full
        elif stripped.startswith('configuration:') and current_pci:
            # "configuration: driver=amdgpu latency=0"
            for token in stripped.split():
                if token.startswith('driver='):
                    drivers[current_pci] = token.split('=', 1)[1]
                    break
            current_pci = ''
    
    return drivers


def detect_gpus() -> list[GPUInfo]:
    """Detect GPU hardware using lspci for device info, lshw for drivers.
    
    Classifies GPUs as integrated vs discrete using PCI device class:
    - "3D controller" (class 0302) → always discrete
    - "VGA compatible controller" (class 0300) → integrated if a 3D controller
      is also present, otherwise use vendor heuristics
    - NVIDIA → always discrete on Framework hardware
    
    Driver detection via lshw -C display (configuration: driver=X).
    """
    gpus = []
    
    rc, stdout, _ = run_command(['lspci'])
    if rc != 0:
        return gpus
    
    # Collect GPU entries from lspci
    entries = []
    for line in stdout.split('\n'):
        if any(x in line for x in ['VGA compatible controller',
                                     '3D controller',
                                     'Display controller']):
            parts = line.split(' ', 1)
            if len(parts) < 2:
                continue
            pci_id = parts[0]
            desc = parts[1]
            pci_class = desc.split(':')[0].strip() if ':' in desc else desc
            entries.append({'pci_id': pci_id, 'class': pci_class, 'desc': desc})
    
    # Get drivers from lshw
    lshw_drivers = _get_gpu_drivers_from_lshw()
    
    # Check if any entry is a "3D controller" — means system has iGPU + dGPU
    has_3d_controller = any('3D controller' in e['class'] for e in entries)
    
    for e in entries:
        desc = e['desc']
        vendor = 'Unknown'
        if 'AMD' in desc or 'ATI' in desc:
            vendor = 'AMD'
        elif 'Intel' in desc:
            vendor = 'Intel'
        elif 'NVIDIA' in desc:
            vendor = 'NVIDIA'
        
        if '3D controller' in e['class']:
            is_discrete = True
        elif vendor == 'NVIDIA':
            is_discrete = True
        elif has_3d_controller:
            is_discrete = False
        else:
            is_discrete = vendor not in ('Intel', 'AMD')
        
        driver = lshw_drivers.get(e['pci_id'], '')
        
        gpus.append(GPUInfo(
            name=desc,
            pci_id=e['pci_id'],
            vendor=vendor,
            driver=driver,
            is_discrete=is_discrete,
        ))
    
    return gpus


def detect_nvme_devices() -> list[NVMeInfo]:
    """
    Detect NVMe storage devices.
    
    BUG FIX: Improved model extraction using proper sed pattern
    """
    devices = []
    
    # First get PCI info
    rc, stdout, _ = run_command(['lspci'])
    if rc != 0:
        return devices
    
    pci_nvme = {}
    for line in stdout.split('\n'):
        if 'non-volatile' in line.lower() or 'nvme' in line.lower():
            parts = line.split(' ', 1)
            if len(parts) >= 2:
                pci_nvme[parts[0]] = parts[1]
    
    # Now get device details
    nvme_path = Path('/dev')
    for nvme in sorted(nvme_path.glob('nvme*n*')):
        # Skip partition devices (nvme0n1p1, etc.) and controller-only paths (nvme0)
        if not re.match(r'nvme\d+n\d+$', nvme.name):
            continue
        device_name = nvme.name
        model = ""
        firmware = ""
        
        # Get model using nvme id-ctrl
        # BUG FIX: Proper model extraction
        rc, stdout, _ = run_sudo_command(['nvme', 'id-ctrl', str(nvme)])
        if rc == 0:
            for line in stdout.split('\n'):
                # Match "mn      : Model Name Here"
                if line.startswith('mn'):
                    # Extract value after colon, strip whitespace
                    match = re.match(r'^mn\s*:\s*(.+)$', line)
                    if match:
                        model = match.group(1).strip()
                elif line.startswith('fr'):
                    match = re.match(r'^fr\s*:\s*(.+)$', line)
                    if match:
                        firmware = match.group(1).strip()
        
        devices.append(NVMeInfo(
            device=str(nvme),
            model=model or "(model not detected)",
            firmware=firmware
        ))
    
    return devices


def check_disk_health(known_nvme_models: Optional[dict[str, str]] = None) -> list[DiskHealthInfo]:
    """
    Check disk health using nvme-cli and smartctl.
    
    Args:
        known_nvme_models: Optional dict of device_path -> model_name from
                          detect_nvme_devices(), avoids duplicate sudo nvme id-ctrl calls.
    
    Returns health info for all detected drives.
    """
    if known_nvme_models is None:
        known_nvme_models = {}
    
    health_info = []
    
    # Check NVMe drives
    nvme_devices = list(Path('/dev').glob('nvme[0-9]*n[0-9]*'))
    # Filter out partition devices (nvme0n1p1, etc.)
    nvme_devices = [d for d in nvme_devices if re.match(r'nvme\d+n\d+$', d.name)]
    
    for nvme in nvme_devices:
        device = str(nvme)
        info = DiskHealthInfo(device=device, model="", is_nvme=True)
        
        # Reuse model from detect_nvme_devices() if available
        if device in known_nvme_models:
            info.model = known_nvme_models[device]
        else:
            # Get model name (only if not already detected)
            rc, stdout, _ = run_sudo_command(['nvme', 'id-ctrl', device])
            if rc == 0:
                for line in stdout.split('\n'):
                    if line.startswith('mn'):
                        match = re.match(r'^mn\s*:\s*(.+)$', line)
                        if match:
                            info.model = match.group(1).strip()
                            break
        
        # Get SMART health
        rc, stdout, _ = run_sudo_command(['nvme', 'smart-log', device])
        if rc == 0:
            for line in stdout.split('\n'):
                line = line.lower().strip()
                
                # Critical warning
                if 'critical_warning' in line or 'critical warning' in line:
                    match = re.search(r':\s*(\d+)', line)
                    if match and int(match.group(1)) != 0:
                        info.healthy = False
                        info.warnings.append(f"Critical warning flag: {match.group(1)}")
                
                # Percentage used (0-100%, higher = more worn)
                if info.percentage_used is None:
                    if 'percentage_used' in line or 'percentage used' in line:
                        match = re.search(r':\s*(\d+)', line)
                        if match:
                            info.percentage_used = int(match.group(1))
                            if info.percentage_used >= 90:
                                info.warnings.append(f"Drive is {info.percentage_used}% worn - replace soon")
                                info.healthy = False
                            elif info.percentage_used >= 80:
                                info.warnings.append(f"Drive is {info.percentage_used}% worn - monitor closely")
                
                # Available spare (NOT the threshold - that's a different field)
                # nvme smart-log shows: "available_spare : 100%" and "available_spare_threshold : 10%"
                # Only match lines starting with "available_spare" (not "available_spare_threshold")
                if info.available_spare is None:
                    spare_match = re.match(r'^available_spare\s*:\s*(\d+)', line)
                    if spare_match:
                        info.available_spare = int(spare_match.group(1))
                        if info.available_spare <= 10:
                            info.warnings.append(f"Low SSD spare blocks: {info.available_spare}% (drive wear-leveling reserve nearly exhausted)")
                            info.healthy = False
                
                # Temperature - be very specific to avoid matching thresholds or sensors
                # Formats seen:
                #   "temperature : 122 °F (323 K)"  - Fahrenheit with Kelvin
                #   "temperature : 308 K (35 Celsius)" - Kelvin with Celsius
                #   "temperature : 35" - Just a number (assume Celsius if <100, Kelvin if >200)
                # Avoid: "Temperature Sensor 1", "Warning Temperature Time", etc.
                if info.temperature is None:
                    # Match line that starts with just "temperature" followed by colon
                    temp_match = re.match(r'^temperature\s*:', line)
                    if temp_match:
                        # Try Celsius first (most reliable)
                        celsius_match = re.search(r'\((\d+)\s*[Cc]elsius\)', line)
                        if celsius_match:
                            info.temperature = int(celsius_match.group(1))
                        else:
                            # Try Fahrenheit: "122 °F" or "122°F"
                            fahrenheit_match = re.search(r':\s*(\d+)\s*°?[Ff]', line)
                            if fahrenheit_match:
                                temp_f = int(fahrenheit_match.group(1))
                                info.temperature = int((temp_f - 32) * 5 / 9)
                            else:
                                # Try Kelvin in parentheses: "(323 K)"
                                kelvin_match = re.search(r'\((\d+)\s*K\)', line)
                                if kelvin_match:
                                    temp_k = int(kelvin_match.group(1))
                                    info.temperature = temp_k - 273
                                else:
                                    # Fall back to raw number after colon
                                    num_match = re.search(r':\s*(\d+)', line)
                                    if num_match:
                                        temp = int(num_match.group(1))
                                        # Heuristic: >200 is Kelvin, <100 is Celsius
                                        if temp > 200:
                                            info.temperature = temp - 273
                                        elif temp < 100:
                                            info.temperature = temp
                
                # Data Units Written - "Data Units Written : 15310335 (7.84 TB)"
                if 'data units written' in line:
                    # Try to get TB value from parentheses
                    tb_match = re.search(r'\((\d+\.?\d*)\s*TB\)', line, re.IGNORECASE)
                    if tb_match:
                        info.data_written_tb = float(tb_match.group(1))
                    else:
                        # Fall back to calculating from units (1 unit = 512KB * 1000 = 512MB)
                        units_match = re.search(r':\s*(\d+)', line)
                        if units_match:
                            units = int(units_match.group(1))
                            info.data_written_tb = round(units * 512 * 1000 / (1024**4), 2)
                
                # Power on hours
                if 'power_on_hours' in line or 'power on hours' in line:
                    match = re.search(r':\s*(\d+)', line)
                    if match:
                        info.power_on_hours = int(match.group(1))
                
                # Power cycles
                if 'power_cycles' in line or 'power cycles' in line:
                    match = re.search(r':\s*(\d+)', line)
                    if match:
                        info.power_cycles = int(match.group(1))
                
                # Unsafe shutdowns (hard power-offs, not a big deal unless excessive)
                if 'unsafe_shutdowns' in line or 'unsafe shutdowns' in line:
                    match = re.search(r':\s*(\d+)', line)
                    if match:
                        info.unsafe_shutdowns = int(match.group(1))
                
                # Media errors
                if 'media_errors' in line or 'media errors' in line:
                    match = re.search(r':\s*(\d+)', line)
                    if match:
                        info.media_errors = int(match.group(1))
                        if info.media_errors > 0:
                            info.healthy = False
                            info.warnings.append(f"Media errors detected: {info.media_errors}")
        
        info.health_status = "PASSED" if info.healthy else "WARNING"
        health_info.append(info)
    
    # Check SATA drives with smartctl
    sata_devices = list(Path('/dev').glob('sd[a-z]'))
    for sata in sata_devices:
        device = str(sata)
        info = DiskHealthInfo(device=device, model="", is_nvme=False)
        
        # Get SMART health
        rc, stdout, _ = run_sudo_command(['smartctl', '-H', '-A', '-i', device])
        if rc == 0 or rc == 4:  # rc=4 means SMART threshold exceeded
            for line in stdout.split('\n'):
                # Model
                if 'Device Model' in line or 'Model Number' in line:
                    parts = line.split(':')
                    if len(parts) >= 2:
                        info.model = parts[1].strip()
                
                # Overall health
                if 'SMART overall-health' in line or 'SMART Health Status' in line:
                    info.health_status = "PASSED" if 'PASSED' in line or 'OK' in line else "FAILED"
                    if 'FAILED' in line:
                        info.healthy = False
                        info.warnings.append("SMART health check FAILED")
                
                # Reallocated sectors (ID 5)
                if 'Reallocated_Sector' in line:
                    match = re.search(r'(\d+)\s*$', line)
                    if match:
                        info.reallocated_sectors = int(match.group(1))
                        if info.reallocated_sectors > 0:
                            info.warnings.append(f"Reallocated sectors: {info.reallocated_sectors}")
                            if info.reallocated_sectors > 100:
                                info.healthy = False
                
                # Pending sectors (ID 197)
                if 'Current_Pending_Sector' in line:
                    match = re.search(r'(\d+)\s*$', line)
                    if match:
                        info.pending_sectors = int(match.group(1))
                        if info.pending_sectors > 0:
                            info.warnings.append(f"Pending sectors: {info.pending_sectors}")
                            info.healthy = False
                
                # Temperature
                if 'Temperature_Celsius' in line or 'Airflow_Temperature' in line:
                    match = re.search(r'(\d+)(?:\s+\(|\s*$)', line)
                    if match:
                        info.temperature = int(match.group(1))
        
        if not info.health_status:
            info.health_status = "UNKNOWN"
        
        if info.model:  # Only add if we got some info
            health_info.append(info)
    
    return health_info


def detect_wifi() -> Optional[WiFiInfo]:
    """Detect WiFi adapter."""
    rc, stdout, _ = run_command(['lspci'])
    if rc != 0:
        return None
    
    # WiFi detection patterns
    wifi_patterns = [
        r'wireless', r'wifi', r'802\.11',
        r'network controller.*wi-fi',
        r'network controller.*MT79',  # MediaTek
        r'network controller.*intel',
        r'network controller.*realtek',
        r'network controller.*broadcom',
        r'network controller.*mediatek',
    ]
    
    for line in stdout.split('\n'):
        line_lower = line.lower()
        for pattern in wifi_patterns:
            if re.search(pattern, line_lower):
                parts = line.split(' ', 1)
                if len(parts) >= 2:
                    pci_id = parts[0]
                    description = parts[1]
                    
                    vendor = 'Unknown'
                    if 'intel' in line_lower:
                        vendor = 'Intel'
                    elif 'mediatek' in line_lower or 'mt79' in line_lower:
                        vendor = 'MediaTek'
                    elif 'realtek' in line_lower:
                        vendor = 'Realtek'
                    elif 'broadcom' in line_lower:
                        vendor = 'Broadcom'
                    
                    return WiFiInfo(
                        name=description,
                        pci_id=pci_id,
                        vendor=vendor
                    )
    
    return None


def detect_ram() -> Optional[RAMInfo]:
    """Detect RAM information using dmidecode."""
    total_mb = 0
    ram_type = ""
    speed = 0
    
    # Try dmidecode first
    rc, stdout, _ = run_sudo_command(['dmidecode', '-t', 'memory'])
    if rc == 0:
        for line in stdout.split('\n'):
            line = line.strip()
            
            # Parse size lines
            if line.startswith('Size:') and 'No Module' not in line and 'Not Specified' not in line:
                match = re.search(r'(\d+)\s*(MB|GB)', line)
                if match:
                    size = int(match.group(1))
                    unit = match.group(2)
                    if unit == 'GB':
                        size *= 1024
                    total_mb += size
            
            # Parse type
            elif line.startswith('Type:') and 'Unknown' not in line and 'Error' not in line:
                ram_type = line.split(':')[1].strip()
            
            # Parse speed
            elif 'Configured Memory Speed:' in line:
                match = re.search(r'(\d+)', line)
                if match:
                    speed = int(match.group(1))
    
    # Fallback to /proc/meminfo
    if total_mb == 0:
        try:
            with open('/proc/meminfo') as f:
                for line in f:
                    if line.startswith('MemTotal:'):
                        match = re.search(r'(\d+)', line)
                        if match:
                            total_mb = int(match.group(1)) // 1024  # KB to MB
                        break
        except Exception:
            pass
    
    if total_mb > 0:
        return RAMInfo(
            total_gb=total_mb // 1024,
            ram_type=ram_type,
            speed_mhz=speed
        )
    
    return None


def detect_rfkill() -> list[RFKillDevice]:
    """
    Detect RF kill switch status for wireless devices.
    
    Parses output from 'rfkill list' command.
    """
    devices = []
    
    rc, stdout, _ = run_command(['rfkill', 'list'])
    if rc != 0:
        return devices
    
    current_device = None
    
    for line in stdout.split('\n'):
        # New device line: "0: hci0: Bluetooth"
        device_match = re.match(r'^(\d+):\s+(\S+):\s+(.+)$', line)
        if device_match:
            if current_device:
                devices.append(current_device)
            current_device = RFKillDevice(
                index=int(device_match.group(1)),
                name=device_match.group(2),
                device_type=device_match.group(3).strip()
            )
        elif current_device:
            # Soft blocked line
            if 'Soft blocked:' in line:
                current_device.soft_blocked = 'yes' in line.lower()
            # Hard blocked line
            elif 'Hard blocked:' in line:
                current_device.hard_blocked = 'yes' in line.lower()
    
    # Don't forget the last device
    if current_device:
        devices.append(current_device)
    
    return devices


# Known Framework webcam USB IDs (vendor:product)
_FRAMEWORK_WEBCAM_IDS = {
    '32ac:001c': ('Framework Laptop Webcam Module (2nd Gen)', 2),
    '04f2:b6d9': ('Chicony Integrated Camera', 1),        # FW13 1st gen
}

# Framework vendor ID for matching any future webcam modules
_FRAMEWORK_USB_VENDOR = '32ac'


def _detect_alsa_capture_devices() -> list[str]:
    """Detect ALSA capture devices via arecord -l.
    
    Returns list of capture device descriptions like:
        "card 0: PCH [HDA Intel PCH], device 0: ALC295 Analog [ALC295 Analog]"
    
    On Framework, internal mics route through mainboard audio codec (DMIC/HDA),
    not USB. When mic hardware switch is OFF, mics are electrically disconnected
    and may not appear as capture sources.
    """
    devices = []
    rc, stdout, _ = run_command(['arecord', '-l'])
    if rc != 0:
        return devices
    
    for line in stdout.split('\n'):
        if line.startswith('card '):
            devices.append(line.strip())
    
    return devices


def detect_webcam(is_framework: bool = False) -> WebcamInfo:
    """Detect webcam presence and mic capture devices.
    
    Detection approach:
    1. /sys/class/video4linux/ — V4L2 video devices present?
    2. Read device name from sysfs
    3. lsusb — known Framework webcam USB IDs
    4. uvcvideo module loaded?
    5. arecord -l — ALSA capture devices (mic hardware presence)
    
    Reports observable facts only. Does NOT attempt to determine
    privacy switch state — too many false positives without verified
    hardware behavior for gen 1 (USB removal vs module absent) and
    gen 2 (UVC privacy control semantics unverified).
    """
    info = WebcamInfo()
    
    # Check V4L2 devices via sysfs
    v4l_path = Path('/sys/class/video4linux')
    if v4l_path.exists():
        for dev in sorted(v4l_path.iterdir()):
            info.v4l_devices.append(f'/dev/{dev.name}')
            # Read device name
            name_file = dev / 'name'
            try:
                if name_file.exists():
                    name = name_file.read_text().strip()
                    if name and not info.device_name:
                        info.device_name = name
            except (OSError, PermissionError):
                pass
    
    # Check uvcvideo module
    rc, stdout, _ = run_command(['lsmod'])
    if rc == 0:
        for line in stdout.split('\n'):
            if line.startswith('uvcvideo '):
                info.uvcvideo_loaded = True
                break
    
    # Check lsusb for known webcam devices
    rc, stdout, _ = run_command(['lsusb'])
    if rc == 0:
        for line in stdout.split('\n'):
            # Check known Framework webcam IDs
            for usb_id, (name, _gen) in _FRAMEWORK_WEBCAM_IDS.items():
                if usb_id in line:
                    info.usb_id = usb_id
                    info.usb_name = name
                    break
            # Also check for any Framework vendor USB device with camera class
            if not info.usb_id and f'{_FRAMEWORK_USB_VENDOR}:' in line:
                if any(kw in line.lower() for kw in ['webcam', 'camera']):
                    parts = line.split('ID ')
                    if len(parts) > 1:
                        info.usb_id = parts[1].split()[0]
                        info.usb_name = parts[1].split(' ', 1)[1].strip() if ' ' in parts[1] else ''
    
    # Determine detection status
    info.detected = bool(info.v4l_devices) or bool(info.usb_id)
    
    # Mic capture device detection
    info.mic_capture_devices = _detect_alsa_capture_devices()
    
    return info


def detect_cpu_info() -> tuple[CPUVendor, str, AMDGeneration]:
    """Detect CPU vendor, model, and AMD generation."""
    vendor = CPUVendor.UNKNOWN
    model = ""
    amd_gen = AMDGeneration.LEGACY
    
    rc, stdout, _ = run_command(['lscpu'])
    if rc != 0:
        return vendor, model, amd_gen
    
    for line in stdout.split('\n'):
        if 'Vendor ID:' in line:
            if 'AMD' in line:
                vendor = CPUVendor.AMD
            elif 'Intel' in line:
                vendor = CPUVendor.INTEL
        elif 'Model name:' in line:
            model = line.split(':', 1)[1].strip()
    
    # Detect AMD generation for thermal thresholds
    if vendor == CPUVendor.AMD and model:
        # Modern AMD: Ryzen 7000/8000 series, AI 300 series
        if re.search(r'7[4-9]\d\d|8\d{3}|AI\s', model):
            amd_gen = AMDGeneration.MODERN
    
    return vendor, model, amd_gen


def detect_framework_info() -> FrameworkInfo:
    """Detect Framework-specific hardware information."""
    info = FrameworkInfo()
    
    # Get product name and version
    rc, stdout, _ = run_sudo_command(['dmidecode', '-s', 'system-product-name'])
    if rc == 0:
        info.product_name = stdout.strip()
    
    rc, stdout, _ = run_sudo_command(['dmidecode', '-s', 'system-version'])
    if rc == 0:
        info.model_version = stdout.strip()
    
    rc, stdout, _ = run_sudo_command(['dmidecode', '-s', 'bios-version'])
    if rc == 0:
        info.bios_version = stdout.strip()
    
    # Check if Framework device
    framework_indicators = ['Framework', 'Laptop Pro', 'Laptop 13', 'Laptop 16', 'Laptop 12', 'Desktop']
    if any(ind in info.product_name for ind in framework_indicators):
        info.is_framework = True
        
        # Determine model type
        if ('Laptop Pro' in info.product_name or 'Laptop 13 Pro' in info.product_name
                or 'Laptop Pro' in info.model_version or 'Laptop 13 Pro' in info.model_version):
            info.model_type = 'Laptop Pro'
        elif 'Laptop 13' in info.product_name or 'Laptop 13' in info.model_version:
            info.model_type = 'Laptop 13'
        elif 'Laptop 16' in info.product_name or 'Laptop 16' in info.model_version:
            info.model_type = 'Laptop 16'
        elif 'Laptop 12' in info.product_name or 'Laptop 12' in info.model_version:
            info.model_type = 'Laptop 12'
        elif 'Desktop' in info.product_name or 'Desktop' in info.model_version:
            info.model_type = 'Desktop'
    
    if info.is_framework:
        # Power status
        _detect_power_status(info)
        
        # Expansion cards
        _detect_expansion_cards(info)
    
    return info


def _detect_power_status(info: FrameworkInfo):
    """Detect power and battery status."""
    # Try multiple AC paths
    ac_paths = list(Path('/sys/class/power_supply').glob('ADP*/online')) + \
               list(Path('/sys/class/power_supply').glob('AC*/online'))
    
    for ac_path in ac_paths:
        try:
            status = ac_path.read_text().strip()
            info.ac_connected = (status == '1')
            break
        except Exception:
            pass
    
    # Battery
    bat_paths = list(Path('/sys/class/power_supply').glob('BAT*'))
    for bat_path in bat_paths:
        try:
            capacity_file = bat_path / 'capacity'
            status_file = bat_path / 'status'
            
            if capacity_file.exists():
                info.battery_level = int(capacity_file.read_text().strip())
            if status_file.exists():
                info.battery_status = status_file.read_text().strip()
            
            # Cycle count (direct sysfs read)
            cycle_file = bat_path / 'cycle_count'
            if cycle_file.exists():
                val = cycle_file.read_text().strip()
                if val.isdigit():
                    info.battery_cycle_count = int(val)
            
            # Charge rate in watts (power_now is in microwatts)
            power_file = bat_path / 'power_now'
            if power_file.exists():
                val = power_file.read_text().strip()
                if val.isdigit():
                    info.battery_charge_rate_w = round(int(val) / 1_000_000, 1)
            
            # Charge threshold (Framework EC exposes this)
            threshold_file = bat_path / 'charge_control_end_threshold'
            if threshold_file.exists():
                val = threshold_file.read_text().strip()
                if val.isdigit():
                    threshold = int(val)
                    # Only report if not default (100 = no limit set)
                    if threshold < 100:
                        info.battery_charge_limit_pct = threshold
            
            break
        except Exception:
            pass
    
    # Battery health + capacities using upower (more reliable than sysfs for Wh)
    rc, stdout, _ = run_command(['upower', '-e'])
    if rc == 0:
        for line in stdout.split('\n'):
            if 'battery' in line.lower():
                rc2, stdout2, _ = run_command(['upower', '-i', line.strip()])
                if rc2 == 0:
                    energy_full = None
                    energy_design = None
                    
                    for uline in stdout2.split('\n'):
                        if 'energy-full:' in uline and 'design' not in uline:
                            match = re.search(r'([\d.]+)', uline)
                            if match:
                                energy_full = float(match.group(1))
                        elif 'energy-full-design:' in uline:
                            match = re.search(r'([\d.]+)', uline)
                            if match:
                                energy_design = float(match.group(1))
                    
                    if energy_full:
                        info.battery_full_wh = round(energy_full, 1)
                    if energy_design:
                        info.battery_design_wh = round(energy_design, 1)
                    if energy_full and energy_design:
                        health = (energy_full / energy_design) * 100
                        info.battery_health_pct = round(health, 1)
                break


def _detect_expansion_cards(info: FrameworkInfo):
    """Detect Framework expansion cards and input modules using lsusb.
    
    Framework uses vendor ID 32ac for their branded hardware:
    
    Expansion Cards (FW13 + FW16):
    - 32ac:0002 - HDMI Expansion Card (Parade PS186 DP-to-HDMI converter)
    - 32ac:0003 - DisplayPort Expansion Card
    - 32ac:0010 - Audio Expansion Card (Conexant CX31993 DAC)
    
    Input Modules (FW16 only):
    - 32ac:0012 - Keyboard (ANSI)
    - 32ac:0013 - RGB Macropad
    - 32ac:0014 - Numpad
    - 32ac:0018 - Keyboard (ISO)
    - 32ac:0019 - Keyboard (JIS)
    - 32ac:0020 - LED Matrix
    
    Third-party chips in Framework expansion cards:
    - Ethernet: Realtek RTL8156 (0bda:8156) - 2.5Gbit
    
    Passive cards (no USB ID - won't appear in lsusb):
    - USB-A Expansion Card (passive, no chip)
    - USB-C Expansion Card (passive passthrough)
    
    Generic controllers (appear but not Framework-branded):
    - Storage Expansion Card (appears as generic USB storage)
    - MicroSD/SD Expansion Card (appears as generic card reader)
    """
    rc, stdout, _ = run_command(['lsusb'])
    if rc != 0:
        return
    
    # Framework-branded devices (vendor ID 32ac)
    FRAMEWORK_USB_IDS = {
        # Expansion Cards
        '32ac:0002': 'HDMI Expansion Card',
        '32ac:0003': 'DisplayPort Expansion Card',
        '32ac:0010': 'Audio Expansion Card',  # Conexant CX31993
        # Input Modules (FW16)
        '32ac:0012': 'Keyboard (ANSI)',
        '32ac:0013': 'RGB Macropad',
        '32ac:0014': 'Numpad',
        '32ac:0018': 'Keyboard (ISO)',
        '32ac:0019': 'Keyboard (JIS)',
        '32ac:0020': 'LED Matrix',
    }
    
    # Third-party chips used in Framework expansion cards
    # These appear with the chip vendor's ID, not Framework's
    EXPANSION_CARD_CHIPS = {
        '0bda:8156': 'Ethernet Expansion Card (2.5G)',  # Realtek RTL8156
    }
    
    # Build bus:device -> USB port path mapping from sysfs
    # sysfs encodes physical topology: e.g. "3-1.2" = bus 3, port 1, sub-port 2
    usb_port_map = _build_usb_port_map()
    
    for line in stdout.split('\n'):
        # lsusb format: "Bus 001 Device 002: ID 32ac:0002 Framework HDMI Expansion Card"
        match = re.search(r'Bus\s+(\d+)\s+Device\s+(\d+):\s+ID\s+([0-9a-f]{4}:[0-9a-f]{4})', line, re.IGNORECASE)
        if match:
            bus = match.group(1)
            device = match.group(2)
            usb_id = match.group(3).lower()
            
            card_name = FRAMEWORK_USB_IDS.get(usb_id) or EXPANSION_CARD_CHIPS.get(usb_id)
            if card_name:
                if card_name not in info.expansion_cards:
                    info.expansion_cards.append(card_name)
                
                # Look up USB port path for this device
                bus_dev_key = f"{int(bus)}:{int(device)}"
                port_path = usb_port_map.get(bus_dev_key, "")
                if port_path:
                    info.expansion_card_ports.append((card_name, port_path))


def _build_usb_port_map() -> dict[str, str]:
    """Build mapping of bus:device_num -> USB port path from sysfs.
    
    Reads /sys/bus/usb/devices/*/devnum and busnum to match lsusb output
    to sysfs device paths. The sysfs directory name encodes the physical
    USB port topology (e.g. '3-1.2' = bus 3, root port 1, hub port 2).
    
    Returns:
        Dict of 'bus:device' -> 'port_path' (e.g. '3:5' -> '3-1.2')
    """
    port_map = {}
    usb_devices = Path('/sys/bus/usb/devices')
    
    if not usb_devices.exists():
        return port_map
    
    for dev_dir in usb_devices.iterdir():
        try:
            busnum_file = dev_dir / 'busnum'
            devnum_file = dev_dir / 'devnum'
            
            if busnum_file.exists() and devnum_file.exists():
                busnum = busnum_file.read_text().strip()
                devnum = devnum_file.read_text().strip()
                key = f"{busnum}:{devnum}"
                # Use the sysfs directory name as the port path
                port_map[key] = dev_dir.name
        except Exception:
            pass
    
    return port_map


def _enrich_from_debugfs(displays: list[DisplayInfo], cpu_vendor: str = '') -> None:
    """Fill in PSR status and missing refresh rates from DRM debugfs.
    
    debugfs requires root (which we have — tool runs under sudo).
    
    Intel: /sys/kernel/debug/dri/*/i915_edp_psr_status
           /sys/kernel/debug/dri/*/i915_display_info
    AMD:   /sys/kernel/debug/dri/*/eDP-*/psr_state
           /sys/kernel/debug/dri/*/amdgpu_current_backlight_pwm (as probe)
    """
    debugfs = Path('/sys/kernel/debug/dri')
    if not debugfs.exists():
        return
    
    # --- PSR status (eDP only) ---
    edp_displays = [d for d in displays if d.is_internal]
    if edp_displays:
        _detect_psr_intel(debugfs, edp_displays)
        _detect_psr_amd(debugfs, edp_displays)
    
    # --- Refresh rate from debugfs when missing ---
    missing_refresh = [d for d in displays if not d.refresh_rate]
    if missing_refresh:
        _detect_refresh_from_debugfs(debugfs, missing_refresh)


def _detect_psr_intel(debugfs: Path, edp_displays: list[DisplayInfo]) -> None:
    """Detect Intel PSR status from i915 debugfs.
    
    File: /sys/kernel/debug/dri/*/i915_edp_psr_status
    
    Typical contents when enabled:
        Sink support: yes [0x01]
        PSR mode: PSR1 enabled
        Source PSR ctl: enabled [0x81f00e26]
    
    When disabled:
        Sink support: yes [0x01]
        PSR mode: disabled
        ...
    
    When not supported:
        Sink support: no
    """
    for card_dir in sorted(debugfs.iterdir()):
        psr_file = card_dir / 'i915_edp_psr_status'
        if not psr_file.exists():
            continue
        
        try:
            content = psr_file.read_text()
        except (OSError, PermissionError):
            # debugfs might need root even with sudo if securelevel is high
            rc, content, _ = run_sudo_command(['cat', str(psr_file)])
            if rc != 0:
                continue
        
        sink_support = False
        psr_mode = ""
        
        for line in content.split('\n'):
            line_lower = line.strip().lower()
            if 'sink support:' in line_lower:
                sink_support = 'yes' in line_lower
            if 'psr mode:' in line_lower:
                # "PSR mode: PSR1 enabled" or "PSR mode: disabled"
                psr_mode = line.split(':', 1)[1].strip()
        
        if not sink_support:
            status = "not supported (sink)"
        elif psr_mode:
            status = psr_mode
        else:
            status = "supported (state unknown)"
        
        for d in edp_displays:
            if not d.psr_status:  # Don't overwrite if already set
                d.psr_status = status
        
        break  # Only one i915 PSR status file per system


def _detect_psr_amd(debugfs: Path, edp_displays: list[DisplayInfo]) -> None:
    """Detect AMD PSR status from amdgpu debugfs.
    
    Newer kernels (6.x): /sys/kernel/debug/dri/*/eDP-1/psr_state
        Shows numeric state: 0=disabled, 1-5=various active states
    
    Also check: /sys/kernel/debug/dri/*/amdgpu_dm_psr_state (older path)
    """
    for card_dir in sorted(debugfs.iterdir()):
        # Method 1: Per-connector psr_state (newer kernels)
        for edp_dir in sorted(card_dir.glob('eDP-*')):
            psr_file = edp_dir / 'psr_state'
            if not psr_file.exists():
                continue
            
            try:
                content = psr_file.read_text().strip()
            except (OSError, PermissionError):
                rc, content, _ = run_sudo_command(['cat', str(psr_file)])
                if rc != 0:
                    continue
                content = content.strip()
            
            # Numeric state: 0 = disabled, 1+ = enabled in various states
            connector_name = edp_dir.name  # e.g., "eDP-1"
            try:
                state = int(content)
                status = "enabled" if state > 0 else "disabled"
            except ValueError:
                status = content  # Pass through whatever it says
            
            for d in edp_displays:
                if not d.psr_status and d.connector == connector_name:
                    d.psr_status = status
            return
        
        # Method 2: Global amdgpu_dm_psr_state (older kernels)
        global_psr = card_dir / 'amdgpu_dm_psr_state'
        if global_psr.exists():
            try:
                content = global_psr.read_text().strip()
            except (OSError, PermissionError):
                rc, content, _ = run_sudo_command(['cat', str(global_psr)])
                if rc != 0:
                    continue
                content = content.strip()
            
            try:
                state = int(content)
                status = "enabled" if state > 0 else "disabled"
            except ValueError:
                status = content
            
            for d in edp_displays:
                if not d.psr_status:
                    d.psr_status = status
            return


def _detect_refresh_from_debugfs(debugfs: Path, displays: list[DisplayInfo]) -> None:
    """Fill in missing refresh rates from DRM debugfs.
    
    Intel: /sys/kernel/debug/dri/*/i915_display_info
        Contains lines like:
            pipe A...mode="2256x1504": 60 ...
            
    AMD: /sys/kernel/debug/dri/*/state
        Contains lines like:
            mode=...2560x1600...vrefresh=165
    
    Falls back to modetest -c if debugfs doesn't work.
    """
    # Build lookup of connectors needing refresh
    need_refresh = {d.connector: d for d in displays}
    
    for card_dir in sorted(debugfs.iterdir()):
        if not card_dir.is_dir():
            continue
        
        # Intel: i915_display_info
        display_info = card_dir / 'i915_display_info'
        if display_info.exists():
            try:
                content = display_info.read_text()
            except (OSError, PermissionError):
                rc, content, _ = run_sudo_command(['cat', str(display_info)])
                if rc != 0:
                    content = ""
            
            if content:
                _parse_intel_display_info(content, need_refresh)
                if not need_refresh:
                    return
        
        # AMD: per-connector state files or global state
        state_file = card_dir / 'state'
        if state_file.exists():
            try:
                content = state_file.read_text()
            except (OSError, PermissionError):
                # This file can be huge, skip if can't read
                content = ""
            
            if content:
                _parse_amd_state(content, need_refresh)
                if not need_refresh:
                    return
    
    # Last resort: modetest -c (from libdrm)
    if need_refresh:
        _try_modetest(need_refresh)


def _parse_intel_display_info(content: str, need_refresh: dict[str, DisplayInfo]) -> None:
    """Parse i915_display_info for active mode refresh rates.
    
    Look for patterns like:
        [CONNECTOR:236:eDP-1]: ...
        ...
        crtc = (C1) ... "2256x1504": 60 267956 2256 2264 2296 2368 1504 ...
    
    Or in newer kernels:
        [CRTC:51:pipe A]:
        ...
        active=yes, mode="2256x1504": 60 ...
    """
    current_connector = None
    
    for line in content.split('\n'):
        # Track current connector
        conn_match = re.search(r'\[CONNECTOR:\d+:(\S+)\]', line)
        if conn_match:
            name = conn_match.group(1)
            current_connector = name if name in need_refresh else None
            continue
        
        # Look for mode with refresh rate near a connector or pipe section
        # Pattern: "2256x1504": 60  or mode="2256x1504": 60
        if current_connector:
            mode_match = re.search(r'"(\d+x\d+)":\s+(\d+)', line)
            if mode_match:
                resolution = mode_match.group(1)
                refresh = mode_match.group(2)
                disp = need_refresh[current_connector]
                if disp.resolution == resolution or not disp.resolution:
                    disp.refresh_rate = refresh
                    del need_refresh[current_connector]
                    current_connector = None
                    if not need_refresh:
                        return


def _parse_amd_state(content: str, need_refresh: dict[str, DisplayInfo]) -> None:
    """Parse amdgpu state file for vrefresh.
    
    Look for patterns like:
        connector[67]: ... name=eDP-1 ...
        ...
        vrefresh=165
    """
    current_connector = None
    
    for line in content.split('\n'):
        # Connector line
        conn_match = re.search(r'name=(eDP-\d+|DP-\d+|HDMI-A-\d+)', line)
        if conn_match:
            name = conn_match.group(1)
            current_connector = name if name in need_refresh else None
            continue
        
        if current_connector:
            # vrefresh in mode line
            vr_match = re.search(r'vrefresh=(\d+)', line)
            if vr_match:
                need_refresh[current_connector].refresh_rate = vr_match.group(1)
                del need_refresh[current_connector]
                current_connector = None
                if not need_refresh:
                    return


def _try_modetest(need_refresh: dict[str, DisplayInfo]) -> None:
    """Last-resort: use modetest -c from libdrm for refresh rates.
    
    Output format:
        Connectors:
        id  encoder status      name        size (mm)   modes   encoders
        236 235     connected   eDP-1       285x190     3       235
          modes:
            index name          refresh (Hz) ...
            #0 2256x1504 59.99 ...
    """
    rc, stdout, _ = run_command(['modetest', '-c'], timeout=5)
    if rc != 0:
        return
    
    current_connector = None
    in_modes = False
    
    for line in stdout.split('\n'):
        # Connector header line: "236 235 connected eDP-1 ..."
        conn_match = re.match(r'^\d+\s+\d+\s+connected\s+(\S+)', line)
        if conn_match:
            name = conn_match.group(1)
            current_connector = name if name in need_refresh else None
            in_modes = False
            continue
        
        if current_connector and 'modes:' in line:
            in_modes = True
            continue
        
        # First mode line after "modes:": "#0 2256x1504 59.99 ..."
        if current_connector and in_modes:
            mode_match = re.match(r'\s+#0\s+(\S+)\s+([\d.]+)', line)
            if mode_match:
                refresh = mode_match.group(2)
                need_refresh[current_connector].refresh_rate = refresh
                del need_refresh[current_connector]
                current_connector = None
                in_modes = False
                if not need_refresh:
                    return


def detect_displays() -> list[DisplayInfo]:
    """Detect connected displays with resolution and refresh rate.
    
    Three-layer approach:
    1. Try xrandr --current (works on X11 and Wayland with XWayland, which
       is the default on GNOME, KDE, etc.)
    2. Fall back to sysfs /sys/class/drm/ for connected outputs and preferred
       modes (works everywhere but only shows preferred mode, not necessarily
       the active one)
    3. Enrich from DRM debugfs: fill in missing refresh rates + PSR status
    
    For Framework laptops:
    - eDP = internal panel (Laptop 13: 2256x1504@60, Laptop 16: 2560x1600@165,
      Laptop 12: 2880x1920@120)
    - DP-* = DisplayPort expansion card or USB-C dock
    - HDMI-* = HDMI expansion card
    """
    displays = []
    
    # Method 1: xrandr --current
    # Need to find the right DISPLAY/XAUTHORITY for sudo context
    display_env = {}
    sudo_user = os.environ.get('SUDO_USER', '')
    
    if sudo_user:
        # Running as sudo — need to pass through display environment
        # Try common DISPLAY values
        for display_var in [os.environ.get('DISPLAY', ''), ':0', ':1']:
            if display_var:
                display_env['DISPLAY'] = display_var
                break
        
        # XAUTHORITY for X11
        xauth = os.environ.get('XAUTHORITY', '')
        if not xauth and sudo_user:
            # Common locations
            for candidate in [
                f'/home/{sudo_user}/.Xauthority',
                f'/run/user/{os.environ.get("SUDO_UID", "1000")}/.Xauthority',
            ]:
                if Path(candidate).exists():
                    xauth = candidate
                    break
        if xauth:
            display_env['XAUTHORITY'] = xauth
        
        # WAYLAND_DISPLAY for XWayland
        wayland = os.environ.get('WAYLAND_DISPLAY', '')
        if wayland:
            display_env['WAYLAND_DISPLAY'] = wayland
        
        xdg_runtime = os.environ.get('XDG_RUNTIME_DIR', '')
        if not xdg_runtime:
            xdg_runtime = f'/run/user/{os.environ.get("SUDO_UID", "1000")}'
        display_env['XDG_RUNTIME_DIR'] = xdg_runtime
    
    # Try xrandr with display env
    env = {**os.environ, **display_env} if display_env else None
    rc, stdout, _ = run_command(['xrandr', '--current'], env=env)
    
    if rc == 0 and stdout.strip():
        displays = _parse_xrandr(stdout)
    
    # Method 2: sysfs fallback if xrandr failed or returned nothing
    if not displays:
        displays = _parse_drm_sysfs()
    
    # Method 3: Enrich from debugfs — fill missing refresh rates + PSR status
    if displays:
        _enrich_from_debugfs(displays)
    
    return displays


def _parse_xrandr(output: str) -> list[DisplayInfo]:
    """Parse xrandr --current output for connected displays.
    
    Example output:
        eDP-1 connected primary 2256x1504+0+0 (...) 285mm x 190mm
           2256x1504     59.99*+
           1920x1280     59.99  
        DP-1 connected 3840x2160+2256+0 (...) 600mm x 340mm
           3840x2160     60.00*+  30.00
           1920x1080     60.00    30.00
        HDMI-A-1 connected (normal ...) 
           3840x2160     60.00 +  30.00
    
    The '*' marks the current active mode.
    The '+' marks the preferred mode (fallback if no active mode).
    """
    displays = []
    current_display = None
    found_active = False  # Whether we found a '*' mode for current display
    preferred_res = ""    # First '+' mode as fallback
    preferred_rate = ""
    
    for line in output.split('\n'):
        # Connector line: "eDP-1 connected primary 2256x1504+0+0 ..."
        conn_match = re.match(
            r'^(\S+)\s+connected\s+(?:primary\s+)?(?:(\d+x\d+)\+\d+\+\d+)?',
            line
        )
        if conn_match:
            # Save previous display
            if current_display:
                if not found_active and preferred_res:
                    # No active mode found — use preferred
                    current_display.resolution = preferred_res
                    current_display.refresh_rate = preferred_rate
                if current_display.resolution:
                    displays.append(current_display)
            
            connector = conn_match.group(1)
            current_display = DisplayInfo(
                connector=connector,
                is_internal=connector.lower().startswith('edp'),
            )
            # Resolution from the connector line geometry (active output)
            if conn_match.group(2):
                current_display.resolution = conn_match.group(2)
            found_active = False
            preferred_res = ""
            preferred_rate = ""
            continue
        
        # Skip disconnected connectors
        if re.match(r'^(\S+)\s+disconnected', line):
            # Save previous display before moving on
            if current_display:
                if not found_active and preferred_res:
                    current_display.resolution = preferred_res
                    current_display.refresh_rate = preferred_rate
                if current_display.resolution:
                    displays.append(current_display)
            current_display = None
            found_active = False
            continue
        
        if not current_display:
            continue
        
        # Mode line: "   2256x1504     59.99*+   48.00"
        # Active mode (has '*')
        if '*' in line and not found_active:
            mode_match = re.match(r'^\s+(\d+x\d+)\s+([\d.]+)\*', line)
            if mode_match:
                current_display.resolution = mode_match.group(1)
                current_display.refresh_rate = mode_match.group(2)
                found_active = True
        
        # Preferred mode (has '+') — capture as fallback
        if '+' in line and not preferred_res:
            pref_match = re.match(r'^\s+(\d+x\d+)\s+([\d.]+)', line)
            if pref_match:
                preferred_res = pref_match.group(1)
                preferred_rate = pref_match.group(2)
    
    # Don't forget the last one
    if current_display:
        if not found_active and preferred_res:
            current_display.resolution = preferred_res
            current_display.refresh_rate = preferred_rate
        if current_display.resolution:
            displays.append(current_display)
    
    return displays


def _parse_drm_sysfs() -> list[DisplayInfo]:
    """Fall back to sysfs DRM connector info.
    
    Reads /sys/class/drm/card*-*/ directories for:
    - status: "connected" or "disconnected"
    - modes: list of supported modes (first = preferred)
    
    This gives preferred mode, not necessarily the active mode,
    but it's the best we can do without a display server connection.
    """
    displays = []
    drm_path = Path('/sys/class/drm')
    
    if not drm_path.exists():
        return displays
    
    for connector_dir in sorted(drm_path.iterdir()):
        # Match card*-ConnectorName-N (e.g., card1-eDP-1, card1-DP-1)
        dir_match = re.match(r'^card\d+-(.+)$', connector_dir.name)
        if not dir_match:
            continue
        
        connector_name = dir_match.group(1)
        
        # Check if connected
        status_file = connector_dir / 'status'
        try:
            if not status_file.exists():
                continue
            status = status_file.read_text().strip()
            if status != 'connected':
                continue
        except (OSError, PermissionError):
            continue
        
        display = DisplayInfo(
            connector=connector_name,
            is_internal=connector_name.lower().startswith('edp'),
        )
        
        # Read preferred mode from modes file (first line)
        modes_file = connector_dir / 'modes'
        try:
            if modes_file.exists():
                modes = modes_file.read_text().strip().split('\n')
                if modes and modes[0]:
                    # Format: "2256x1504" or "2560x1600" (no refresh in sysfs modes)
                    display.resolution = modes[0].strip()
        except (OSError, PermissionError):
            pass
        
        if display.resolution:
            displays.append(display)
    
    return displays


def detect_all_hardware() -> HardwareInfo:
    """Detect all hardware information."""
    hw = HardwareInfo()
    
    hw.gpu = detect_gpus()
    hw.nvme = detect_nvme_devices()
    
    # Pass already-detected NVMe models to avoid duplicate sudo nvme id-ctrl calls
    nvme_models = {nvme.device: nvme.model for nvme in hw.nvme if nvme.model}
    hw.disk_health = check_disk_health(known_nvme_models=nvme_models)
    hw.wifi = detect_wifi()
    hw.ram = detect_ram()
    hw.rfkill_devices = detect_rfkill()
    hw.framework = detect_framework_info()
    hw.webcam = detect_webcam(is_framework=hw.framework.is_framework)
    hw.displays = detect_displays()
    hw.cpu_vendor, hw.cpu_model, hw.amd_generation = detect_cpu_info()
    
    return hw


def format_hardware_report(hw: HardwareInfo) -> list[str]:
    """Format hardware info for the diagnostic report."""
    lines = []
    
    lines.append("Hardware Context:")
    
    # GPU
    for gpu in hw.gpu:
        gpu_type = "dGPU" if gpu.is_discrete else "iGPU"
        driver_str = f" [{gpu.driver}]" if gpu.driver else " [no driver loaded]"
        lines.append(f"  GPU ({gpu_type}): {gpu.name}{driver_str}")
    
    # Storage
    if hw.nvme:
        lines.append("  Storage:")
        for nvme in hw.nvme:
            lines.append(f"    {Path(nvme.device).name}: {nvme.model}")
    
    # WiFi
    if hw.wifi:
        lines.append(f"  WiFi: {hw.wifi.name}")
    
    # RAM
    if hw.ram:
        ram_str = f"  RAM: {hw.ram.total_gb} GB"
        if hw.ram.ram_type:
            ram_str += f" {hw.ram.ram_type}"
        if hw.ram.speed_mhz:
            ram_str += f" @ {hw.ram.speed_mhz} MHz"
        lines.append(ram_str)
    
    # RF Kill Status (wireless device blocking)
    if hw.rfkill_devices:
        blocked_devices = [d for d in hw.rfkill_devices if d.soft_blocked or d.hard_blocked]
        if blocked_devices:
            lines.append("  RF Kill:")
            for dev in blocked_devices:
                status_parts = []
                if dev.hard_blocked:
                    status_parts.append("❌ hardware blocked")
                if dev.soft_blocked:
                    status_parts.append("⚠️ software blocked")
                lines.append(f"    {dev.device_type} ({dev.name}): {', '.join(status_parts)}")
    
    # Webcam & Mic
    if hw.webcam:
        cam = hw.webcam
        if cam.detected:
            name = cam.usb_name or cam.device_name or 'Detected'
            id_str = f" ({cam.usb_id})" if cam.usb_id else ""
            dev_str = f", {cam.v4l_devices[0]}" if cam.v4l_devices else ""
            lines.append(f"  Webcam: {name}{id_str}{dev_str}")
        else:
            lines.append("  Webcam: ❌ Not detected")
        
        if not cam.mic_capture_devices:
            lines.append("  Mic: ⚠️  No ALSA capture devices found")
    
    # Displays
    if hw.displays:
        for disp in hw.displays:
            label = "Internal" if disp.is_internal else "External"
            res_str = disp.resolution or "unknown"
            if disp.refresh_rate:
                res_str += f" @ {disp.refresh_rate} Hz"
            if disp.psr_status:
                res_str += f" [PSR: {disp.psr_status}]"
            lines.append(f"  Display ({label}): {disp.connector} — {res_str}")
    else:
        lines.append("  Display: (no connected displays detected)")
    
    return lines


def format_disk_health_report(hw: HardwareInfo) -> list[str]:
    """Format disk health info for the diagnostic report."""
    lines = []
    
    if not hw.disk_health:
        return lines
    
    lines.append("Disk Health:")
    
    for disk in hw.disk_health:
        device_name = Path(disk.device).name
        status_icon = "✅" if disk.healthy else "⚠️"
        
        lines.append(f"  {device_name}: {disk.model}")
        lines.append(f"    Status: {status_icon} {disk.health_status}")
        
        # NVMe specific - show actual useful stats
        if disk.is_nvme:
            # Usage stats
            usage_parts = []
            if disk.data_written_tb is not None:
                usage_parts.append(f"{disk.data_written_tb} TB written")
            if disk.power_on_hours is not None:
                days = disk.power_on_hours // 24
                usage_parts.append(f"{disk.power_on_hours:,} hours ({days} days)")
            if disk.power_cycles is not None:
                usage_parts.append(f"{disk.power_cycles:,} power cycles")
            if usage_parts:
                lines.append(f"    Usage: {', '.join(usage_parts)}")
            
            # Health indicators
            health_parts = []
            if disk.media_errors is not None:
                if disk.media_errors == 0:
                    health_parts.append("✅ No media errors")
                else:
                    health_parts.append(f"❌ {disk.media_errors} media errors")
            if disk.unsafe_shutdowns is not None and disk.unsafe_shutdowns > 0:
                # Only show if notably high relative to power cycles
                if disk.power_cycles and disk.unsafe_shutdowns > disk.power_cycles * 0.5:
                    health_parts.append(f"⚠️ {disk.unsafe_shutdowns} unexpected power-offs")
                # Otherwise just informational, no warning icon
            if health_parts:
                lines.append(f"    Health: {', '.join(health_parts)}")
            
            # Endurance (only show if getting worn)
            if disk.percentage_used is not None and disk.percentage_used > 0:
                wear_icon = "✅" if disk.percentage_used < 80 else "⚠️" if disk.percentage_used < 90 else "❌"
                lines.append(f"    Endurance: {wear_icon} {disk.percentage_used}% of rated lifespan used")
        
        # SATA specific
        else:
            if disk.reallocated_sectors is not None and disk.reallocated_sectors > 0:
                lines.append(f"    ⚠️ Reallocated sectors: {disk.reallocated_sectors}")
            if disk.pending_sectors is not None and disk.pending_sectors > 0:
                lines.append(f"    ⚠️ Pending sectors: {disk.pending_sectors}")
        
        # Temperature
        if disk.temperature is not None:
            # NVMe drives run warm - typically fine up to 70°C
            temp_icon = "✅" if disk.temperature < 55 else "⚠️" if disk.temperature < 70 else "❌"
            lines.append(f"    Temp: {temp_icon} {disk.temperature}°C")
        
        # Additional warnings
        for warning in disk.warnings:
            if warning not in str(lines):  # Avoid duplicates
                lines.append(f"    ⚠️ {warning}")
    
    return lines
