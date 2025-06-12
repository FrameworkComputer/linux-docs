#!/usr/bin/env python3
"""
WiFi Mesh Roaming Detector
Detect and measure actual drops, reconnects, and roaming events
Save this file as: mesh_roaming_detector.py
Put it in the same folder as your main analyzer script
"""

import subprocess
import time
import threading
from collections import deque
from datetime import datetime
import os

class MeshRoamingDetector:
    """Detect and measure actual drops, reconnects, and roaming events"""
    
    def __init__(self, interface):
        self.interface = interface
        self.events = deque(maxlen=1000)
        self.current_bssid = None
        self.monitoring = False
        
    def monitor_connection_state(self, interval=0.1):
        """High-frequency monitoring to catch brief drops"""
        self.monitoring = True
        last_state = None
        last_bssid = None
        disconnect_start = None
        
        while self.monitoring:
            # Get current connection state FAST
            state = self._get_connection_state_fast()
            
            # Extract status and info from state
            current_status = state.get('status', 'unknown') if isinstance(state, dict) else state
            current_bssid = state.get('bssid') if isinstance(state, dict) else None
            current_signal = state.get('signal', -100) if isinstance(state, dict) else -100
            
            # Detect disconnection
            if (isinstance(last_state, dict) and last_state.get('status') == "connected" and 
                current_status == "disconnected"):
                disconnect_start = time.time()
                self.events.append({
                    'type': 'disconnect',
                    'timestamp': disconnect_start,
                    'last_bssid': last_bssid,
                    'last_signal': last_state.get('signal', -100) if isinstance(last_state, dict) else -100
                })
            
            # Detect reconnection
            elif (last_state == "disconnected" or 
                  (isinstance(last_state, dict) and last_state.get('status') == "disconnected")) and current_status == "connected":
                reconnect_time = time.time()
                downtime = reconnect_time - disconnect_start if disconnect_start else 0
                
                self.events.append({
                    'type': 'reconnect',
                    'timestamp': reconnect_time,
                    'downtime_seconds': downtime,
                    'new_bssid': current_bssid,
                    'new_signal': current_signal
                })
                disconnect_start = None  # Reset disconnect timer
            
            # Detect roaming (BSSID change without disconnect)
            elif (current_status == "connected" and 
                  (isinstance(last_state, dict) and last_state.get('status') == "connected") and 
                  last_bssid and current_bssid and last_bssid != current_bssid):
                
                self.events.append({
                    'type': 'roam',
                    'timestamp': time.time(),
                    'from_bssid': last_bssid,
                    'to_bssid': current_bssid,
                    'from_signal': last_state.get('signal', -100) if isinstance(last_state, dict) else -100,
                    'to_signal': current_signal,
                    'seamless': True  # No disconnect detected
                })
            
            # Update tracking variables
            last_state = state
            last_bssid = current_bssid
            time.sleep(interval)
    
    def _get_connection_state_fast(self):
        """Fastest possible connection state check with robust error handling"""
        try:
            # Use /proc/net/wireless for fastest reads
            with open('/proc/net/wireless', 'r') as f:
                lines = f.readlines()
                for line in lines:
                    if self.interface in line:
                        # Parse signal level with error handling
                        parts = line.split()
                        if len(parts) >= 4:
                            try:
                                # Handle different possible formats
                                signal_str = parts[3].rstrip('.')
                                signal = int(float(signal_str))
                            except (ValueError, IndexError):
                                signal = -100
                            
                            # Get BSSID from iw (cached)
                            try:
                                cmd = f"iw dev {self.interface} link | grep 'Connected to'"
                                result = subprocess.run(cmd, shell=True, capture_output=True, 
                                                      text=True, timeout=1)
                                
                                if "Connected to" in result.stdout:
                                    bssid_part = result.stdout.split("Connected to ")[1].split()[0]
                                    # Clean BSSID
                                    bssid = bssid_part.split('(')[0].strip().upper()
                                    
                                    # Validate BSSID format
                                    if len(bssid) == 17 and bssid.count(':') == 5:
                                        return {'status': 'connected', 'signal': signal, 'bssid': bssid}
                                    else:
                                        return {'status': 'disconnected'}
                                else:
                                    return {'status': 'disconnected'}
                            except (subprocess.TimeoutExpired, subprocess.SubprocessError):
                                return {'status': 'unknown'}
            
            return {'status': 'disconnected'}
            
        except (FileNotFoundError, PermissionError, OSError):
            # Fallback method
            try:
                cmd = f"iw dev {self.interface} link"
                result = subprocess.run(cmd, shell=True, capture_output=True, 
                                      text=True, timeout=2)
                
                if "Not connected" in result.stdout:
                    return {'status': 'disconnected'}
                elif "Connected to" in result.stdout:
                    # Parse signal and BSSID with error handling
                    lines = result.stdout.split('\n')
                    bssid = None
                    signal = -100
                    
                    for line in lines:
                        try:
                            if "Connected to" in line:
                                bssid_part = line.split("Connected to ")[1].split()[0]
                                bssid = bssid_part.split('(')[0].strip().upper()
                                # Validate BSSID format
                                if len(bssid) != 17 or bssid.count(':') != 5:
                                    bssid = None
                            elif "signal:" in line:
                                signal_part = line.split("signal: ")[1].split()[0]
                                signal = int(float(signal_part))
                        except (IndexError, ValueError):
                            continue
                    
                    if bssid:
                        return {'status': 'connected', 'signal': signal, 'bssid': bssid}
                    else:
                        return {'status': 'connected', 'signal': signal, 'bssid': 'unknown'}
                else:
                    return {'status': 'unknown'}
                    
            except (subprocess.TimeoutExpired, subprocess.SubprocessError, OSError):
                return {'status': 'unknown'}
    
    def detect_microdropouts(self, duration=60):
        """Detect drops shorter than 1 second"""
        print(f"🔍 Monitoring for micro-dropouts for {duration} seconds...")
        print("These are drops your system might not normally notice")
        print("💡 Keep using your WiFi normally - browse, stream, etc.")
        
        # Clear previous events
        self.events.clear()
        
        # Use rapid polling
        monitor_thread = threading.Thread(
            target=self.monitor_connection_state, 
            args=(0.05,)  # 50ms polling
        )
        monitor_thread.start()
        
        time.sleep(duration)
        self.monitoring = False
        monitor_thread.join()
        
        # Analyze micro-dropouts
        dropouts = [e for e in self.events if e['type'] == 'reconnect' and e.get('downtime_seconds', 0) < 1.0]
        
        if dropouts:
            print(f"\n🔴 Found {len(dropouts)} micro-dropouts:")
            for d in dropouts:
                print(f"   • {d['downtime_seconds']:.3f}s dropout at {datetime.fromtimestamp(d['timestamp']).strftime('%H:%M:%S')}")
                if d.get('new_bssid'):
                    print(f"     Reconnected to: {d['new_bssid']} ({d.get('new_signal', 'unknown')}dBm)")
        else:
            print(f"\n✅ No micro-dropouts detected in {duration} seconds")
            print("Your mesh is handling connections smoothly!")
        
        # Show any roaming events
        roams = [e for e in self.events if e['type'] == 'roam']
        if roams:
            print(f"\n🔄 Detected {len(roams)} seamless roaming events:")
            for r in roams:
                print(f"   • {datetime.fromtimestamp(r['timestamp']).strftime('%H:%M:%S')}: {r['from_bssid']} → {r['to_bssid']}")
                print(f"     Signal: {r['from_signal']}dBm → {r['to_signal']}dBm")
    
    def measure_roaming_performance(self, walk_test=False):
        """Measure actual roaming performance"""
        print("📊 Measuring roaming performance...")
        if walk_test:
            print("🚶 Walk around your space now. Press Ctrl+C when done.")
            print("💡 Try to move between different rooms/areas")
        else:
            print("🏠 Monitoring roaming events for 2 minutes...")
        
        # Clear previous events
        self.events.clear()
        
        # Start monitoring
        monitor_thread = threading.Thread(
            target=self.monitor_connection_state, 
            args=(0.1,)  # 100ms polling
        )
        monitor_thread.start()
        
        try:
            if walk_test:
                # Let user control duration
                input("Press Enter when you're done walking around...")
            else:
                time.sleep(120)  # 2 minutes
        except KeyboardInterrupt:
            pass
        
        self.monitoring = False
        monitor_thread.join()
        
        # Analyze roaming events
        roams = [e for e in self.events if e['type'] == 'roam']
        disconnects = [e for e in self.events if e['type'] == 'disconnect']
        reconnects = [e for e in self.events if e['type'] == 'reconnect']
        
        print(f"\n📊 Roaming Analysis:")
        print(f"   • Seamless roams: {len(roams)}")
        print(f"   • Disconnection events: {len(disconnects)}")
        
        if reconnects:
            downtimes = [e['downtime_seconds'] for e in reconnects if e.get('downtime_seconds') is not None]
            if downtimes:
                print(f"   • Average downtime: {sum(downtimes)/len(downtimes):.3f}s")
                print(f"   • Longest downtime: {max(downtimes):.3f}s")
                print(f"   • Shortest downtime: {min(downtimes):.3f}s")
        
        # Show roaming details
        if roams:
            print(f"\n🔄 Roaming Events:")
            for r in roams:
                time_str = datetime.fromtimestamp(r['timestamp']).strftime('%H:%M:%S')
                signal_change = r['to_signal'] - r['from_signal']
                print(f"   • {time_str}: {r['from_bssid'][:17]} → {r['to_bssid'][:17]}")
                print(f"     Signal change: {signal_change:+d}dBm ({r['from_signal']} → {r['to_signal']})")
        
        return {
            'seamless_roams': len(roams),
            'dropped_roams': len(disconnects),
            'avg_downtime': sum(e.get('downtime_seconds', 0) for e in reconnects) / len(reconnects) if reconnects else 0,
            'micro_dropouts': len([e for e in reconnects if e.get('downtime_seconds', 0) < 1.0])
        }
    
    def track_problem_transitions(self):
        """Identify problematic BSSID transitions"""
        transition_stats = {}
        
        # Analyze roaming events
        for event in self.events:
            if event['type'] == 'roam':
                key = f"{event['from_bssid']} → {event['to_bssid']}"
                if key not in transition_stats:
                    transition_stats[key] = {'count': 0, 'seamless': 0, 'avg_signal_change': []}
                
                transition_stats[key]['count'] += 1
                if event.get('seamless'):
                    transition_stats[key]['seamless'] += 1
                
                signal_change = event['to_signal'] - event['from_signal']
                transition_stats[key]['avg_signal_change'].append(signal_change)
        
        if not transition_stats:
            print("\n🔄 No roaming transitions detected")
            print("💡 Try walking around or wait longer for roaming events")
            return
        
        print("\n🔄 Transition Analysis:")
        for transition, stats in transition_stats.items():
            success_rate = (stats['seamless'] / stats['count']) * 100
            avg_signal_change = sum(stats['avg_signal_change']) / len(stats['avg_signal_change'])
            
            status_emoji = "✅" if success_rate == 100 else "⚠️" if success_rate > 80 else "🔴"
            print(f"   {status_emoji} {transition}")
            print(f"     Success: {success_rate:.1f}% ({stats['seamless']}/{stats['count']} seamless)")
            print(f"     Avg signal change: {avg_signal_change:+.1f}dBm")
    
    def continuous_quality_monitor(self):
        """Monitor connection quality during normal use"""
        print("📊 Starting continuous connection quality monitor...")
        print("This will track all drops and roaming events in the background")
        print("💡 Use Ctrl+C to stop monitoring")
        
        # Create log file with proper error handling
        try:
            log_file = "/tmp/mesh_roaming_log.txt"
            
            with open(log_file, "a") as log:
                log.write(f"\n--- Roaming Monitor Session Started {datetime.now()} ---\n")
                log.flush()
                
                print(f"📝 Logging to: {log_file}")
                print("🏃 Monitor running... use your WiFi normally")
                
                # Clear previous events
                self.events.clear()
                
                # Start monitoring thread
                monitor_thread = threading.Thread(
                    target=self.monitor_connection_state,
                    args=(0.1,)  # 100ms polling
                )
                monitor_thread.start()
                
                # Log events as they happen
                last_event_count = 0
                while True:
                    time.sleep(1)  # Check for new events every second
                    
                    if len(self.events) > last_event_count:
                        # New events to log
                        for event in list(self.events)[last_event_count:]:
                            timestamp = datetime.fromtimestamp(event['timestamp']).strftime('%H:%M:%S')
                            
                            if event['type'] == 'disconnect':
                                msg = f"{timestamp}: 🔴 CONNECTION LOST from {event.get('last_bssid', 'unknown')}"
                                log.write(msg + "\n")
                                print(msg)
                                
                            elif event['type'] == 'reconnect':
                                downtime = event.get('downtime_seconds', 0)
                                msg = f"{timestamp}: 🟢 RECONNECTED to {event.get('new_bssid', 'unknown')} (down {downtime:.3f}s)"
                                log.write(msg + "\n")
                                print(msg)
                                
                            elif event['type'] == 'roam':
                                signal_change = event['to_signal'] - event['from_signal']
                                msg = f"{timestamp}: 🔄 ROAMED {event['from_bssid']} → {event['to_bssid']} ({signal_change:+d}dBm)"
                                log.write(msg + "\n")
                                print(msg)
                            
                            log.flush()
                        
                        last_event_count = len(self.events)
                
        except KeyboardInterrupt:
            self.monitoring = False
            monitor_thread.join()
            print(f"\n👋 Monitoring stopped")
            print(f"📊 Total events logged: {len(self.events)}")
            print(f"📝 Log saved to: {log_file}")
            
            # Quick summary
            roams = len([e for e in self.events if e['type'] == 'roam'])
            drops = len([e for e in self.events if e['type'] == 'disconnect'])
            if roams or drops:
                print(f"📈 Summary: {roams} roams, {drops} drops")
            else:
                print("📈 Summary: Stable connection - no events detected")
        
        except (PermissionError, OSError) as e:
            print(f"❌ Error accessing log file: {e}")
            print("💡 Try running with sudo or check /tmp permissions")


# Usage example and testing
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: mesh_roaming_detector.py <interface> [test_type]")
        print("\nAvailable tests:")
        print("  microdropouts  - Detect brief connection drops (30 seconds)")
        print("  roaming        - Measure roaming performance (walk test)")
        print("  transitions    - Analyze problematic transitions")
        print("  monitor        - Continuous background monitoring")
        print("\nExamples:")
        print("  sudo python3 mesh_roaming_detector.py wlan0 microdropouts")
        print("  sudo python3 mesh_roaming_detector.py wlan0 roaming")
        print("  sudo python3 mesh_roaming_detector.py wlan0 monitor")
        sys.exit(1)
    
    interface = sys.argv[1]
    test_type = sys.argv[2] if len(sys.argv) > 2 else "microdropouts"
    
    # Check if interface exists
    if not os.path.exists(f"/sys/class/net/{interface}"):
        print(f"❌ Network interface '{interface}' not found")
        print("💡 Try: ip link show")
        sys.exit(1)
    
    detector = MeshRoamingDetector(interface)
    
    print(f"🔍 WiFi Mesh Roaming Detector")
    print(f"📡 Interface: {interface}")
    print(f"🧪 Test: {test_type}")
    print("=" * 50)
    
    try:
        if test_type == "microdropouts":
            detector.detect_microdropouts(duration=30)
        elif test_type == "roaming":
            detector.measure_roaming_performance(walk_test=True)
        elif test_type == "transitions":
            # Run brief monitoring first to collect data
            print("Collecting roaming data for 60 seconds...")
            detector.measure_roaming_performance(walk_test=False)
            detector.track_problem_transitions()
        elif test_type == "monitor":
            detector.continuous_quality_monitor()
        else:
            print(f"❌ Unknown test type: {test_type}")
            print("Available: microdropouts, roaming, transitions, monitor")
    
    except KeyboardInterrupt:
        print("\n👋 Test interrupted by user")
    except Exception as e:
        print(f"❌ Error: {e}")
        print("💡 Make sure you're running with sudo privileges")
