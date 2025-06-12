#!/usr/bin/env python3
"""
WiFi Mesh Power Detective
Detect WiFi power management issues causing false disconnects
Save this file as: mesh_power_detective.py
Put it in the same folder as your main analyzer script
"""

import subprocess
import time
import os
import re
import glob
from datetime import datetime
from pathlib import Path

class MeshPowerDetective:
    """Detect WiFi power management issues causing false disconnects"""
    
    def __init__(self, interface):
        self.interface = interface
        self.issues_found = []
        self.power_events = []
        self.alert_thresholds = {
            'signal_drop': 15,  # dBm
            'latency_spike': 100,  # ms
            'packet_loss': 5  # percent
        }
        
    def check_all_power_issues(self):
        """Run comprehensive power management detection"""
        print("🔋 WiFi Power Management Detective")
        print("=" * 60)
        print("Scanning for power-related WiFi issues...")
        
        issues = {
            'wifi_power_save': self.check_wifi_power_save(),
            'usb_autosuspend': self.check_usb_autosuspend(),
            'pcie_aspm': self.check_pcie_aspm(),
            'network_manager': self.check_network_manager_power(),
            'tlp_settings': self.check_tlp_settings(),
            'laptop_mode': self.check_laptop_mode_tools(),
            'systemd_sleep': self.check_systemd_sleep_settings(),
            'driver_params': self.check_driver_power_params()
        }
        
        self._generate_report(issues)
        return issues
    
    def check_wifi_power_save(self):
        """Check if WiFi power saving is causing drops"""
        issues = []
        
        # Check current power save status
        try:
            result = subprocess.run(f"iw dev {self.interface} get power_save", 
                                  shell=True, capture_output=True, text=True, timeout=5)
            if "on" in result.stdout.lower():
                issues.append({
                    'severity': 'high',
                    'issue': 'WiFi power saving is ON',
                    'impact': 'Can cause periodic disconnects and latency spikes',
                    'fix': f'sudo iw dev {self.interface} set power_save off'
                })
        except:
            pass
        
        # Check iwconfig power management
        try:
            result = subprocess.run(f"iwconfig {self.interface}", 
                                  shell=True, capture_output=True, text=True, timeout=5)
            if "Power Management:on" in result.stdout:
                issues.append({
                    'severity': 'high',
                    'issue': 'iwconfig shows Power Management ON',
                    'impact': 'Causes disconnects every 1-5 minutes',
                    'fix': f'sudo iwconfig {self.interface} power off'
                })
        except:
            pass
        
        return issues
    
    def check_usb_autosuspend(self):
        """Check if USB autosuspend is affecting USB WiFi adapters"""
        issues = []
        
        # Check if WiFi is USB
        try:
            # Find device path
            device_path = f"/sys/class/net/{self.interface}/device"
            if os.path.exists(device_path):
                real_path = os.path.realpath(device_path)
                
                if "usb" in real_path:
                    # It's a USB WiFi adapter
                    issues.append({
                        'severity': 'info',
                        'issue': 'USB WiFi adapter detected',
                        'impact': 'USB autosuspend can cause disconnects'
                    })
                    
                    # Check USB autosuspend setting
                    autosuspend_path = "/sys/module/usbcore/parameters/autosuspend"
                    if os.path.exists(autosuspend_path):
                        with open(autosuspend_path, 'r') as f:
                            value = f.read().strip()
                            if value != "-1":
                                issues.append({
                                    'severity': 'high',
                                    'issue': f'USB autosuspend is enabled ({value}s)',
                                    'impact': 'WiFi adapter suspends after inactivity',
                                    'fix': 'echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend'
                                })
                    
                    # Check specific device power/control
                    usb_power_path = None
                    for parent in Path(real_path).parents:
                        control_path = parent / "power/control"
                        if control_path.exists():
                            usb_power_path = control_path
                            break
                    
                    if usb_power_path and usb_power_path.exists():
                        with open(usb_power_path, 'r') as f:
                            if f.read().strip() == "auto":
                                issues.append({
                                    'severity': 'high',
                                    'issue': 'USB device power control set to auto',
                                    'impact': 'Device can sleep during use',
                                    'fix': f'echo on | sudo tee {usb_power_path}'
                                })
        except Exception as e:
            # Debug info for troubleshooting
            pass
            
        return issues
    
    def check_pcie_aspm(self):
        """Check PCIe Active State Power Management"""
        issues = []
        
        # Check if WiFi is PCIe
        try:
            result = subprocess.run(f"lspci -k | grep -A 3 -i network", 
                                  shell=True, capture_output=True, text=True, timeout=5)
            if result.stdout:
                # Check ASPM policy
                aspm_path = "/sys/module/pcie_aspm/parameters/policy"
                if os.path.exists(aspm_path):  # FIXED: was "asmp_path"
                    with open(aspm_path, 'r') as f:  # FIXED: was "asmp_path"
                        policy = f.read().strip()
                        if "powersave" in policy or "powersupersave" in policy:
                            issues.append({
                                'severity': 'medium',
                                'issue': f'PCIe ASPM set to: {policy}',
                                'impact': 'Can cause latency and brief disconnects',
                                'fix': 'Add pcie_aspm=off to kernel boot parameters'
                            })
        except:
            pass
            
        return issues
    
    def check_network_manager_power(self):
        """Check NetworkManager power saving settings"""
        issues = []
        
        try:
            # Check if NetworkManager is managing power
            nm_conf_paths = [
                "/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf",
                "/etc/NetworkManager/conf.d/wifi-powersave.conf"
            ]
            
            for conf_path in nm_conf_paths:
                if os.path.exists(conf_path):
                    with open(conf_path, 'r') as f:
                        content = f.read()
                        if "wifi.powersave = 3" in content or "wifi.powersave = 2" in content:
                            issues.append({
                                'severity': 'high',
                                'issue': 'NetworkManager WiFi power saving enabled',
                                'impact': 'Periodic disconnects and poor roaming',
                                'fix': 'Set wifi.powersave = 2 (disable) in ' + conf_path
                            })
        except:
            pass
            
        return issues
    
    def check_tlp_settings(self):
        """Check TLP (laptop power management) settings"""
        issues = []
        
        if os.path.exists("/etc/tlp.conf"):
            try:
                with open("/etc/tlp.conf", 'r') as f:
                    content = f.read()
                    
                    # Check WiFi power saving
                    if re.search(r'WIFI_PWR_ON_AC\s*=\s*on', content):
                        issues.append({
                            'severity': 'medium',
                            'issue': 'TLP WiFi power saving on AC',
                            'impact': 'Power saving even when plugged in',
                            'fix': 'Set WIFI_PWR_ON_AC=off in /etc/tlp.conf'
                        })
                    
                    # Check USB autosuspend
                    if re.search(r'USB_AUTOSUSPEND\s*=\s*1', content):
                        issues.append({
                            'severity': 'high',
                            'issue': 'TLP USB autosuspend enabled',
                            'impact': 'USB WiFi adapters will suspend',
                            'fix': 'Set USB_AUTOSUSPEND=0 in /etc/tlp.conf'
                        })
            except:
                pass
                
        return issues
    
    def check_laptop_mode_tools(self):
        """Check laptop-mode-tools settings"""
        issues = []
        
        lmt_conf = "/etc/laptop-mode/conf.d/wireless-power.conf"
        if os.path.exists(lmt_conf):
            try:
                with open(lmt_conf, 'r') as f:
                    content = f.read()
                    if 'WIRELESS_AC_POWER_SAVING=1' in content:
                        issues.append({
                            'severity': 'medium',
                            'issue': 'Laptop-mode-tools WiFi power saving on AC',
                            'impact': 'Unnecessary power saving when plugged in',
                            'fix': 'Set WIRELESS_AC_POWER_SAVING=0 in ' + lmt_conf
                        })
            except:
                pass
                
        return issues
    
    def check_systemd_sleep_settings(self):
        """Check systemd sleep/suspend settings affecting WiFi"""
        issues = []
        
        try:
            # Check if system is suspending network
            result = subprocess.run("systemctl status systemd-networkd", 
                                  shell=True, capture_output=True, text=True, timeout=5)
            
            # Check sleep.conf
            if os.path.exists("/etc/systemd/sleep.conf"):
                with open("/etc/systemd/sleep.conf", 'r') as f:
                    content = f.read()
                    if "HibernateDelaySec=2" in content:
                        issues.append({
                            'severity': 'low',
                            'issue': 'Quick hibernate delay detected',
                            'impact': 'System may hibernate network too quickly',
                            'fix': 'Increase HibernateDelaySec in /etc/systemd/sleep.conf'
                        })
        except:
            pass
            
        return issues
    
    def check_driver_power_params(self):
        """Check WiFi driver-specific power parameters"""
        issues = []
        
        try:
            # Get driver name
            driver_path = f"/sys/class/net/{self.interface}/device/driver"
            if os.path.exists(driver_path):
                driver = os.path.basename(os.readlink(driver_path))
                
                # Intel WiFi (iwlwifi)
                if driver == "iwlwifi":
                    issues.extend(self._check_intel_power(driver))
                
                # Realtek (rtw88, rtw89)
                elif "rtw" in driver or "r8" in driver:
                    issues.extend(self._check_realtek_power(driver))
                
                # Atheros/Qualcomm (ath9k, ath10k, ath11k)
                elif "ath" in driver:
                    issues.extend(self._check_atheros_power(driver))
                
                # MediaTek (mt76, mt7921, mt7922, etc)
                elif "mt7" in driver or "mt76" in driver:
                    issues.extend(self._check_mediatek_power(driver))
                
                # Qualcomm mobile (qca_cld3_wlan)
                elif "qca" in driver:
                    issues.extend(self._check_qualcomm_power(driver))
                
                # Marvell (mwifiex, mwl8k)
                elif "mwifiex" in driver or "mwl" in driver:
                    issues.extend(self._check_marvell_power(driver))
                
                # Generic power management check for any driver
                issues.extend(self._check_generic_power_management())
                
        except Exception as e:
            pass
            
        return issues
    
    def _check_intel_power(self, driver):
        """Check Intel WiFi power settings"""
        issues = []
        
        # Check module parameters
        if os.path.exists("/sys/module/iwlwifi/parameters/power_save"):
            with open("/sys/module/iwlwifi/parameters/power_save", 'r') as f:
                if f.read().strip() == "Y":
                    issues.append({
                        'severity': 'high',
                        'issue': 'Intel WiFi power_save enabled',
                        'impact': 'Causes disconnects and poor performance',
                        'fix': 'Add iwlwifi.power_save=0 to kernel parameters'
                    })
        
        if os.path.exists("/sys/module/iwlwifi/parameters/power_level"):
            with open("/sys/module/iwlwifi/parameters/power_level", 'r') as f:
                level = f.read().strip()
                if level != "0":
                    issues.append({
                        'severity': 'medium',
                        'issue': f'Intel WiFi power_level={level}',
                        'impact': 'Reduced performance for power saving',
                        'fix': 'Add iwlwifi.power_level=0 to kernel parameters'
                    })
        
        return issues
    
    def _check_realtek_power(self, driver):
        """Check Realtek WiFi power settings"""
        issues = []
        
        if os.path.exists(f"/sys/module/{driver}/parameters/disable_lps"):
            with open(f"/sys/module/{driver}/parameters/disable_lps", 'r') as f:
                if f.read().strip() == "N":
                    issues.append({
                        'severity': 'high',
                        'issue': 'Realtek WiFi LPS (power save) enabled',
                        'impact': 'Known to cause frequent disconnects',
                        'fix': f'Add {driver}.disable_lps=1 to kernel parameters'
                    })
        
        return issues
    
    def _check_atheros_power(self, driver):
        """Check Atheros WiFi power settings"""
        issues = []
        
        if os.path.exists(f"/sys/module/{driver}/parameters/ps_enable"):
            with open(f"/sys/module/{driver}/parameters/ps_enable", 'r') as f:
                if f.read().strip() == "1":
                    issues.append({
                        'severity': 'medium',
                        'issue': 'Atheros WiFi power save enabled',
                        'impact': 'May cause latency and disconnects',
                        'fix': f'Add {driver}.ps_enable=0 to kernel parameters'
                    })
        
        return issues
    
    def _check_mediatek_power(self, driver):
        """Check MediaTek WiFi power settings"""
        issues = []
        
        # MT7921/MT7922 (common in newer laptops)
        if driver in ["mt7921e", "mt7921u", "mt7922"]:
            # Check runtime PM
            runtime_pm_path = f"/sys/class/net/{self.interface}/device/power/runtime_status"
            if os.path.exists(runtime_pm_path):
                with open(runtime_pm_path, 'r') as f:
                    status = f.read().strip()
                    if status == "suspended":
                        issues.append({
                            'severity': 'high',
                            'issue': 'MediaTek WiFi runtime suspended',
                            'impact': 'Device is currently suspended - will cause drops',
                            'fix': f'echo on > /sys/class/net/{self.interface}/device/power/control'
                        })
            
            # Check deep sleep mode
            if os.path.exists(f"/sys/module/{driver}/parameters/disable_deep_sleep"):
                with open(f"/sys/module/{driver}/parameters/disable_deep_sleep", 'r') as f:
                    if f.read().strip() == "N":
                        issues.append({
                            'severity': 'high',
                            'issue': 'MediaTek deep sleep enabled',
                            'impact': 'Causes 1-3 second reconnection delays',
                            'fix': f'echo Y > /sys/module/{driver}/parameters/disable_deep_sleep'
                        })
        
        # MT76 series power management
        if "mt76" in driver:
            # Check power save mode via debugfs
            ps_path = f"/sys/kernel/debug/ieee80211/phy*/netdev:{self.interface}/mt76/runtime-pm"
            for path in glob.glob(ps_path):
                if os.path.exists(path):
                    with open(path, 'r') as f:
                        if "enable" in f.read():
                            issues.append({
                                'severity': 'medium',
                                'issue': 'MT76 runtime PM enabled',
                                'impact': 'May cause latency spikes',
                                'fix': 'Disable via debugfs or module parameter'
                            })
        
        return issues
    
    def _check_qualcomm_power(self, driver):
        """Check Qualcomm/QCA WiFi power settings"""
        issues = []
        
        # QCA6174/QCA9377 (common in laptops)
        if driver in ["ath10k_pci", "ath11k_pci"]:
            # Check WoWLAN (Wake on WLAN)
            wowlan_path = f"/sys/class/net/{self.interface}/phy80211/wowlan"
            if os.path.exists(wowlan_path):
                with open(wowlan_path, 'r') as f:
                    if "enabled" in f.read():
                        issues.append({
                            'severity': 'medium',
                            'issue': 'QCA WoWLAN enabled',
                            'impact': 'Can cause false wakeups and power issues',
                            'fix': f'iw phy phy0 wowlan disable'
                        })
            
            # Check firmware power save
            if os.path.exists(f"/sys/module/{driver}/parameters/fw_powersave"):
                with open(f"/sys/module/{driver}/parameters/fw_powersave", 'r') as f:
                    if f.read().strip() == "1":
                        issues.append({
                            'severity': 'high',
                            'issue': 'QCA firmware power save enabled',
                            'impact': 'Known to cause disconnects on QCA chips',
                            'fix': f'echo 0 > /sys/module/{driver}/parameters/fw_powersave'
                        })
        
        # Mobile Qualcomm chips
        elif driver == "qca_cld3_wlan":
            # Check IPA (power aggregator)
            if os.path.exists("/sys/module/wlan/parameters/enable_ipa"):
                with open("/sys/module/wlan/parameters/enable_ipa", 'r') as f:
                    if f.read().strip() == "1":
                        issues.append({
                            'severity': 'low',
                            'issue': 'QCA IPA power aggregation enabled',
                            'impact': 'May affect throughput for power saving',
                            'fix': 'Add wlan.enable_ipa=0 to kernel parameters'
                        })
        
        return issues
    
    def _check_marvell_power(self, driver):
        """Check Marvell WiFi power settings"""
        issues = []
        
        if driver == "mwifiex":
            # Check PS mode
            ps_mode_path = f"/sys/kernel/debug/mwifiex/{self.interface}/ps_mode"
            if os.path.exists(ps_mode_path):
                with open(ps_mode_path, 'r') as f:
                    mode = f.read().strip()
                    if mode != "0":
                        issues.append({
                            'severity': 'high',
                            'issue': f'Marvell PS mode {mode} active',
                            'impact': 'Aggressive power saving causes drops',
                            'fix': f'echo 0 > {ps_mode_path}'
                        })
            
            # Check sleep parameters
            if os.path.exists(f"/sys/module/{driver}/parameters/auto_ds"):
                with open(f"/sys/module/{driver}/parameters/auto_ds", 'r') as f:
                    if f.read().strip() == "Y":
                        issues.append({
                            'severity': 'medium',
                            'issue': 'Marvell auto deep sleep enabled',
                            'impact': 'Wake-up delays after idle',
                            'fix': f'Add {driver}.auto_ds=N to kernel parameters'
                        })
        
        return issues
    
    def _check_generic_power_management(self):
        """Generic power checks that apply to any WiFi driver"""
        issues = []
        
        # Check runtime PM for ANY WiFi device
        runtime_pm = f"/sys/class/net/{self.interface}/device/power/control"
        if os.path.exists(runtime_pm):
            with open(runtime_pm, 'r') as f:
                if f.read().strip() == "auto":
                    issues.append({
                        'severity': 'medium',
                        'issue': 'Generic runtime PM set to auto',
                        'impact': 'Device may suspend unexpectedly',
                        'fix': f'echo on > {runtime_pm}'
                    })
        
        # Check for aggressive kernel power settings
        if os.path.exists("/proc/sys/kernel/nmi_watchdog"):
            with open("/proc/sys/kernel/nmi_watchdog", 'r') as f:
                if f.read().strip() == "0":
                    issues.append({
                        'severity': 'info',
                        'issue': 'NMI watchdog disabled (laptop power saving)',
                        'impact': 'System may be in aggressive power save mode',
                        'fix': 'Consider if other subsystems are also affected'
                    })
        
        return issues
    
    def monitor_power_events(self, duration=60):
        """Monitor for power-related WiFi events"""
        print(f"\n🔍 Monitoring for power-related issues for {duration} seconds...")
        print("Watch for correlation between power events and disconnects")
        
        start_time = time.time()
        last_state = "unknown"
        
        while time.time() - start_time < duration:
            # Check power save state
            try:
                result = subprocess.run(f"iw dev {self.interface} get power_save", 
                                      shell=True, capture_output=True, text=True, timeout=2)
                current_state = "on" if "on" in result.stdout.lower() else "off"
                
                if current_state != last_state and last_state != "unknown":
                    self.power_events.append({
                        'time': datetime.now(),
                        'event': f'Power save changed: {last_state} -> {current_state}'
                    })
                    print(f"⚡ Power save state changed to: {current_state}")
                
                last_state = current_state
                
                # Check connection state
                link_result = subprocess.run(f"iw dev {self.interface} link", 
                                           shell=True, capture_output=True, text=True, timeout=2)
                if "Not connected" in link_result.stdout:
                    self.power_events.append({
                        'time': datetime.now(),
                        'event': 'Connection lost (check if power-related)'
                    })
                    
            except:
                pass
                
            time.sleep(0.5)
        
        if self.power_events:
            print(f"\n📊 Detected {len(self.power_events)} power-related events")
        else:
            print("\n✅ No power-related events detected")
    
    def _generate_report(self, issues):
        """Generate comprehensive report"""
        total_issues = sum(len(v) for v in issues.values())
        critical_issues = sum(1 for v in issues.values() for i in v if i.get('severity') == 'high')
        
        print(f"\n📋 POWER MANAGEMENT REPORT")
        print("=" * 60)
        print(f"Total issues found: {total_issues}")
        print(f"Critical issues: {critical_issues}")
        
        if total_issues == 0:
            print("\n✅ No power management issues detected!")
            print("Your WiFi should not be affected by power saving.")
        else:
            print("\n🚨 Issues Found:\n")
            
            for category, category_issues in issues.items():
                if category_issues:
                    print(f"{category.replace('_', ' ').title()}:")
                    for issue in category_issues:
                        severity_icon = {
                            'high': '🔴',
                            'medium': '🟡',
                            'low': '🟠',
                            'info': 'ℹ️'
                        }.get(issue.get('severity', 'info'))
                        
                        print(f"\n  {severity_icon} {issue['issue']}")
                        print(f"     Impact: {issue['impact']}")
                        if 'fix' in issue:
                            print(f"     Fix: {issue['fix']}")
        
        # Generate fix script
        self._generate_fix_script(issues)
    
    def _generate_fix_script(self, issues):
        """Generate a script to fix all issues"""
        fixes = []
        
        for category_issues in issues.values():
            for issue in category_issues:
                if 'fix' in issue and issue.get('severity') in ['high', 'medium']:
                    fixes.append(issue['fix'])
        
        if fixes:
            print("\n📝 Generated fix script: /tmp/fix_wifi_power.sh")
            with open("/tmp/fix_wifi_power.sh", "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# WiFi Power Management Fixes\n")
                f.write("# Generated by mesh_power_detective.py\n\n")
                
                f.write("echo 'Applying WiFi power management fixes...'\n\n")
                
                for fix in fixes:
                    f.write(f"echo 'Running: {fix}'\n")
                    f.write(f"{fix}\n\n")
                
                f.write("echo 'Fixes applied! Restart WiFi or reboot to ensure all changes take effect.'\n")
            
            os.chmod("/tmp/fix_wifi_power.sh", 0o755)
            print("Run with: sudo /tmp/fix_wifi_power.sh")


# Usage example and testing
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: mesh_power_detective.py <interface> [options]")
        print("\nOptions:")
        print("  --monitor    Monitor power events for 60 seconds")
        print("  --fix        Generate fix script automatically")
        print("\nExamples:")
        print("  sudo python3 mesh_power_detective.py wlan0")
        print("  sudo python3 mesh_power_detective.py wlan0 --monitor")
        print("  sudo python3 mesh_power_detective.py wlan0 --fix")
        sys.exit(1)
    
    interface = sys.argv[1]
    
    # Check if interface exists
    if not os.path.exists(f"/sys/class/net/{interface}"):
        print(f"❌ Network interface '{interface}' not found")
        print("💡 Try: ip link show")
        sys.exit(1)
    
    detective = MeshPowerDetective(interface)
    
    print(f"🔋 WiFi Power Management Detective")
    print(f"📡 Interface: {interface}")
    print("=" * 50)
    
    try:
        # Run all checks
        detective.check_all_power_issues()
        
        # Optional monitoring
        if "--monitor" in sys.argv:
            detective.monitor_power_events(duration=60)
        
        if "--fix" in sys.argv:
            print("\n💡 Fix script has been generated if issues were found")
            
    except KeyboardInterrupt:
        print("\n👋 Analysis interrupted by user")
    except Exception as e:
        print(f"❌ Error: {e}")
        print("💡 Make sure you're running with sudo privileges")
