#!/usr/bin/env python3
"""
WiFi Mesh Network Analyzer - Analysis and Recommendations
- Comprehensive radio environment analysis
- Historical performance tracking
- Mesh topology intelligence with Venn overlap analysis
- Problem detection and recommendations
- HTML report generation
- Focus on accurate analysis without configuration complexity
"""

import subprocess
import re
import time
import pickle
import os
import json
import zipfile
from datetime import datetime
from collections import defaultdict, deque
from dataclasses import dataclass, asdict
from typing import Dict, List, Set, Optional
import threading
from pathlib import Path
import logging

# Import the new Venn calculator
try:
    from mesh_venn_calculator import MeshVennCalculator
except ImportError:
    # Fallback if file not found
    class MeshVennCalculator:
        def generate_venn_data(self, nodes_data):
            return {'nodes': nodes_data, 'overlaps': [], 'total_coverage': 0}
        def get_overlap_quality_assessment(self, venn_data):
            return {'quality': 'unknown', 'score': 0, 'description': 'Venn calculator not available'}

# Import the updated HTML reporter with roaming and power support
try:
    from mesh_html_reporter import MeshHTMLReporter
    UPDATED_HTML_REPORTER_AVAILABLE = True
except ImportError:
    UPDATED_HTML_REPORTER_AVAILABLE = False
    print("⚠️ Warning: mesh_html_reporter.py not found - using built-in reporter")

# Import the roaming detector - Matt is testing some new functionality - adding two new modules for import. 
try:
    from mesh_roaming_detector import MeshRoamingDetector
    ROAMING_DETECTOR_AVAILABLE = True
except ImportError:
    ROAMING_DETECTOR_AVAILABLE = False
    MeshRoamingDetector = None

# Import the power detective
try:
    from mesh_power_detective import MeshPowerDetective
    POWER_DETECTIVE_AVAILABLE = True
except ImportError:
    POWER_DETECTIVE_AVAILABLE = False
    MeshPowerDetective = None

@dataclass
class APScan:
    ssid: str
    bssid: str
    freq: int
    signal: int
    capabilities: Set[str]
    last_seen: float
    
    def to_dict(self):
        """Convert to JSON-serializable dict"""
        return {
            'ssid': self.ssid,
            'bssid': self.bssid,
            'freq': self.freq,
            'signal': self.signal,
            'capabilities': list(self.capabilities),  # Convert set to list
            'last_seen': self.last_seen
        }

@dataclass
class ConnectionEvent:
    timestamp: float
    bssid: str
    event_type: str  # 'connect', 'disconnect', 'auth_timeout'
    signal: int
    duration: Optional[float] = None
    reason: Optional[str] = None

@dataclass
class BSSIDHistory:
    bssid: str
    total_connections: int = 0
    successful_connections: int = 0
    total_duration: float = 0.0
    avg_signal: float = 0.0
    signal_samples: List[tuple] = None
    auth_failures: int = 0
    disconnects: int = 0
    last_seen: float = 0.0
    stability_score: float = 0.0
    
    def __post_init__(self):
        if self.signal_samples is None:
            self.signal_samples = []

def make_json_serializable(obj):
    """Convert object to JSON-serializable format"""
    if isinstance(obj, set):
        return list(obj)
    elif isinstance(obj, dict):
        return {k: make_json_serializable(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [make_json_serializable(item) for item in obj]
    elif hasattr(obj, 'to_dict'):
        return obj.to_dict()
    elif hasattr(obj, '__dict__'):
        return make_json_serializable(obj.__dict__)
    else:
        return obj

class LogManager:
    """Comprehensive logging system with automatic compression"""
    
    def __init__(self, data_dir: Path):
        self.data_dir = data_dir
        self.logs_dir = data_dir / "logs"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        
        # Create timestamp for this session
        self.session_timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        self.session_date = datetime.now().strftime("%Y-%m-%d")
        
        # Initialize log files
        self.analysis_log = self.logs_dir / f"analysis_{self.session_timestamp}.log"
        self.connections_log = self.logs_dir / f"connections_{self.session_date}.log"
        self.performance_log = self.logs_dir / f"performance_{self.session_date}.log"
        self.debug_log = self.logs_dir / f"debug_{self.session_date}.log"
        
        # Setup loggers
        self.setup_loggers()
        
        print(f"📝 Logging enabled: {self.logs_dir}")
    
    def setup_loggers(self):
        """Setup structured loggers for different log types"""
        
        # Analysis logger (detailed scan results)
        self.analysis_logger = logging.getLogger('analysis')
        self.analysis_logger.setLevel(logging.INFO)
        analysis_handler = logging.FileHandler(self.analysis_log)
        analysis_handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(levelname)s | %(message)s'
        ))
        self.analysis_logger.addHandler(analysis_handler)
        
        # Connection logger (WiFi events)
        self.connection_logger = logging.getLogger('connections')
        self.connection_logger.setLevel(logging.INFO)
        connection_handler = logging.FileHandler(self.connections_log)
        connection_handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(message)s'
        ))
        self.connection_logger.addHandler(connection_handler)
        
        # Performance logger (metrics over time)
        self.performance_logger = logging.getLogger('performance')
        self.performance_logger.setLevel(logging.INFO)
        performance_handler = logging.FileHandler(self.performance_log)
        performance_handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(message)s'
        ))
        self.performance_logger.addHandler(performance_handler)
        
        # Debug logger (technical details)
        self.debug_logger = logging.getLogger('debug')
        self.debug_logger.setLevel(logging.DEBUG)
        debug_handler = logging.FileHandler(self.debug_log)
        debug_handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(levelname)s | %(funcName)s:%(lineno)d | %(message)s'
        ))
        self.debug_logger.addHandler(debug_handler)
    
    def log_analysis_start(self, interface: str):
        """Log the start of a new analysis session"""
        self.analysis_logger.info("="*80)
        self.analysis_logger.info(f"WiFi Mesh Network Analysis Session Started")
        self.analysis_logger.info(f"Interface: {interface}")
        self.analysis_logger.info(f"Session ID: {self.session_timestamp}")
        self.analysis_logger.info("="*80)
        self.debug_logger.info(f"Analysis session started on interface {interface}")
    
    def log_network_scan(self, aps_found: int, scan_duration: float):
        """Log network scan results"""
        self.analysis_logger.info(f"Network Scan Complete: {aps_found} APs found in {scan_duration:.2f}s")
        self.debug_logger.info(f"Scan duration: {scan_duration:.3f}s, APs discovered: {aps_found}")
    
    def log_mesh_analysis(self, mesh_data: Dict):
        """Log detailed mesh analysis results"""
        self.analysis_logger.info("MESH TOPOLOGY ANALYSIS:")
        self.analysis_logger.info(f"  Brand: {mesh_data.get('brand', 'Unknown')}")
        self.analysis_logger.info(f"  Type: {mesh_data.get('mesh_type', 'Unknown')}")
        self.analysis_logger.info(f"  Nodes: {mesh_data.get('total_nodes', 0)}")
        self.analysis_logger.info(f"  Radios: {mesh_data.get('total_radios', 0)}")
        self.analysis_logger.info(f"  Bands: {', '.join(mesh_data.get('bands', []))}")
        self.analysis_logger.info(f"  Topology Health: {mesh_data.get('topology_health', 'Unknown')}")
        self.analysis_logger.info(f"  Signal Range: {mesh_data.get('signal_range', 0)}dB")
        
        # Log detailed node information
        mesh_nodes = mesh_data.get('mesh_nodes', {})
        for node_id, node_info in mesh_nodes.items():
            self.analysis_logger.info(f"  Node {node_id}: {node_info['strongest_signal']}dBm, {len(node_info['radios'])} radios")
            for radio in node_info['radios']:
                self.analysis_logger.info(f"    Radio {radio['bssid']}: {radio['signal']}dBm ({radio['band']})")
        
        # Store as JSON for structured analysis with proper serialization
        try:
            serializable_data = make_json_serializable(mesh_data)
            self.debug_logger.info(f"Mesh topology data: {json.dumps(serializable_data, indent=2)}")
        except Exception as e:
            self.debug_logger.warning(f"Could not serialize mesh data for JSON logging: {e}")
            self.debug_logger.info(f"Mesh topology data (raw): {mesh_data}")
    
    def log_connection_event(self, event):
        """Log WiFi connection events"""
        event_msg = f"EVENT: {event.event_type.upper()} | BSSID: {event.bssid} | Signal: {event.signal}dBm"
        if event.duration:
            event_msg += f" | Duration: {event.duration:.1f}s"
        if event.reason:
            event_msg += f" | Reason: {event.reason}"
        
        self.connection_logger.info(event_msg)
        self.debug_logger.debug(f"Connection event: {event}")
    
    def log_performance_metrics(self, current_conn: Dict, alternatives: List[Dict]):
        """Log performance metrics and recommendations"""
        if current_conn:
            self.performance_logger.info(f"CURRENT CONNECTION:")
            self.performance_logger.info(f"  BSSID: {current_conn['bssid']}")
            self.performance_logger.info(f"  Signal: {current_conn['signal']}dBm")
            self.performance_logger.info(f"  Frequency: {current_conn['freq']}MHz")
            self.performance_logger.info(f"  Band: {self._get_band_from_freq(current_conn['freq'])}")
        
        if alternatives:
            self.performance_logger.info(f"ALTERNATIVES FOUND: {len(alternatives)}")
            for i, alt in enumerate(alternatives[:3], 1):
                band = self._get_band_from_freq(alt['freq'])
                self.performance_logger.info(
                    f"  Option {i}: {alt['bssid']} | {alt['signal']}dBm ({band}) | "
                    f"Score: {alt['score']:.1f} | Diff: {alt['signal_diff']:+d}dB"
                )
    
    def log_recommendations(self, recommendations: Dict):
        """Log analysis recommendations"""
        self.analysis_logger.info("RECOMMENDATIONS:")
        if recommendations.get('action_recommended'):
            self.analysis_logger.info(f"  Action: {recommendations['action']}")
            self.analysis_logger.info(f"  Target: {recommendations.get('target_bssid', 'Unknown')}")
            self.analysis_logger.info(f"  Expected Improvement: {recommendations.get('signal_improvement', 0)}dB")
            self.analysis_logger.info(f"  Priority: {recommendations.get('priority', 'Unknown')}")
            self.analysis_logger.info(f"  Method: {recommendations.get('method', 'Unknown')}")
        else:
            self.analysis_logger.info("  No action recommended - current connection optimal")
        
        # Store detailed recommendations as JSON with proper serialization
        try:
            serializable_recommendations = make_json_serializable(recommendations)
            self.debug_logger.info(f"Recommendations data: {json.dumps(serializable_recommendations, indent=2)}")
        except Exception as e:
            self.debug_logger.warning(f"Could not serialize recommendations for JSON logging: {e}")
            self.debug_logger.info(f"Recommendations data (raw): {recommendations}")
    
    def log_problems_detected(self, patterns: Dict):
        """Log detected problems and patterns"""
        total_issues = sum(len(v) if isinstance(v, list) else len(v) if isinstance(v, dict) else 0 
                          for v in patterns.values())
        
        self.analysis_logger.info(f"PROBLEM DETECTION: {total_issues} issues found")
        
        if patterns.get('roaming_loops'):
            self.analysis_logger.info(f"  Roaming Loops: {len(patterns['roaming_loops'])}")
        if patterns.get('auth_failure_clusters'):
            self.analysis_logger.info(f"  Auth Failures: {len(patterns['auth_failure_clusters'])}")
        if patterns.get('rapid_disconnects'):
            self.analysis_logger.info(f"  Rapid Disconnects: {len(patterns['rapid_disconnects'])}")
        
        if total_issues > 0:
            try:
                serializable_patterns = make_json_serializable(patterns)
                self.debug_logger.warning(f"Problems detected: {json.dumps(serializable_patterns, indent=2)}")
            except Exception as e:
                self.debug_logger.warning(f"Could not serialize patterns for JSON logging: {e}")
                self.debug_logger.warning(f"Problems detected (raw): {patterns}")
    
    def log_command_execution(self, command: str, output: str, duration: float):
        """Log system command execution for debugging"""
        self.debug_logger.debug(f"Command: {command}")
        self.debug_logger.debug(f"Duration: {duration:.3f}s")
        if len(output) > 1000:
            self.debug_logger.debug(f"Output: {output[:500]}...[truncated]...{output[-500:]}")
        else:
            self.debug_logger.debug(f"Output: {output}")
    
    def log_error(self, error: Exception, context: str = ""):
        """Log errors with context"""
        error_msg = f"ERROR in {context}: {type(error).__name__}: {str(error)}"
        self.analysis_logger.error(error_msg)
        self.debug_logger.exception(f"Exception in {context}")
    
    def _get_band_from_freq(self, freq: int) -> str:
        """Helper to get band name from frequency"""
        if 2400 <= freq <= 2500:
            return '2.4GHz'
        elif 5000 <= freq <= 5999:
            return '5GHz'
        elif 6000 <= freq <= 7125:
            return '6GHz'
        else:
            return f'{freq}MHz'
    
    def create_analysis_archive(self) -> str:
        """Create compressed archive of all logs and data"""
        try:
            # Create archive filename
            archive_name = f"mesh_analysis_{self.session_timestamp}.zip"
            archive_path = self.data_dir / archive_name
            
            with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                # Add all log files from today
                for log_file in self.logs_dir.glob("*.log"):
                    if self.session_date in log_file.name or self.session_timestamp in log_file.name:
                        zipf.write(log_file, f"logs/{log_file.name}")
                
                # Add data files
                data_files = [
                    self.data_dir / "bssid_history.pkl",
                    self.data_dir / "connection_events.pkl"
                ]
                
                for data_file in data_files:
                    if data_file.exists():
                        zipf.write(data_file, f"data/{data_file.name}")
                
                # Create summary file
                summary_content = self._create_session_summary()
                zipf.writestr("session_summary.txt", summary_content)
                
                # Create README
                readme_content = self._create_readme()
                zipf.writestr("README.txt", readme_content)
            
            self.analysis_logger.info(f"Analysis archive created: {archive_path}")
            return str(archive_path)
            
        except Exception as e:
            self.log_error(e, "create_analysis_archive")
            return ""
    
    def _create_session_summary(self) -> str:
        """Create a summary of the analysis session"""
        summary = []
        summary.append("WiFi Mesh Network Analysis Session Summary")
        summary.append("=" * 50)
        summary.append(f"Session ID: {self.session_timestamp}")
        summary.append(f"Date: {self.session_date}")
        summary.append(f"Logs Directory: {self.logs_dir}")
        summary.append("")
        summary.append("Files Included:")
        summary.append("- logs/analysis_*.log - Detailed analysis results")
        summary.append("- logs/connections_*.log - WiFi connection events")
        summary.append("- logs/performance_*.log - Performance metrics")
        summary.append("- logs/debug_*.log - Technical debugging info")
        summary.append("- data/bssid_history.pkl - Historical BSSID performance data")
        summary.append("- data/connection_events.pkl - Connection event history")
        summary.append("")
        summary.append("Analysis Tools:")
        summary.append("- Mesh topology detection and health assessment")
        summary.append("- Signal strength analysis and optimization")
        summary.append("- Historical performance tracking")
        summary.append("- Problem pattern detection")
        summary.append("- Actionable recommendations with step-by-step guidance")
        
        return "\n".join(summary)
    
    def _create_readme(self) -> str:
        """Create README for the archive"""
        readme = []
        readme.append("WiFi Mesh Network Analyzer - Log Archive")
        readme.append("=" * 45)
        readme.append("")
        readme.append("This archive contains comprehensive logs from a WiFi mesh network analysis session.")
        readme.append("")
        readme.append("LOG FILES:")
        readme.append("")
        readme.append("analysis_*.log")
        readme.append("  - Complete analysis results including mesh topology, recommendations,")
        readme.append("    and problem detection. Human-readable format.")
        readme.append("")
        readme.append("connections_*.log")
        readme.append("  - Real-time WiFi connection events including roaming, disconnects,")
        readme.append("    and authentication events. Useful for troubleshooting connectivity issues.")
        readme.append("")
        readme.append("performance_*.log") 
        readme.append("  - Performance metrics over time including signal strength variations,")
        readme.append("    alternative options, and optimization opportunities.")
        readme.append("")
        readme.append("debug_*.log")
        readme.append("  - Technical debugging information including command outputs,")
        readme.append("    timing data, and detailed system interactions.")
        readme.append("")
        readme.append("DATA FILES:")
        readme.append("")
        readme.append("data/bssid_history.pkl")
        readme.append("  - Binary file containing historical performance data for each BSSID")
        readme.append("  - Includes stability scores, connection success rates, signal tracking")
        readme.append("")
        readme.append("data/connection_events.pkl")
        readme.append("  - Binary file containing detailed connection event history")
        readme.append("  - Used for pattern analysis and problem detection")
        readme.append("")
        readme.append("USAGE:")
        readme.append("These logs can be used for:")
        readme.append("- Network troubleshooting and optimization")
        readme.append("- Performance trend analysis")
        readme.append("- Mesh system health monitoring")
        readme.append("- Problem pattern identification")
        readme.append("- Technical support and debugging")
        
        return "\n".join(readme)

class HistoryTracker:
    """Tracks WiFi connection history and performance per BSSID"""
    
    def __init__(self, data_dir: str = None, log_manager = None):
        if data_dir is None:
            # Use consistent location regardless of sudo
            if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
                sudo_user = os.environ['SUDO_USER']
                import pwd
                real_user_home = pwd.getpwnam(sudo_user).pw_dir
                data_dir = os.path.join(real_user_home, ".mesh_analyzer")
            else:
                home = os.path.expanduser("~")
                data_dir = os.path.join(home, ".mesh_analyzer")
        
        self.data_dir = Path(data_dir)
        self.log_manager = log_manager
        
        # Create directory with proper permissions
        try:
            self.data_dir.mkdir(parents=True, exist_ok=True)
            
            # If created as root but should belong to user, fix permissions
            if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
                sudo_user = os.environ['SUDO_USER']
                import pwd
                user_info = pwd.getpwnam(sudo_user)
                os.chown(self.data_dir, user_info.pw_uid, user_info.pw_gid)
                
        except Exception as e:
            print(f"⚠️ Warning: Could not create/fix permissions for {data_dir}: {e}")
            if self.log_manager:
                self.log_manager.log_error(e, "HistoryTracker.__init__")
        
        self.history_file = self.data_dir / "bssid_history.pkl"
        self.events_file = self.data_dir / "connection_events.pkl"
        
        self.bssid_history: Dict[str, BSSIDHistory] = {}
        self.connection_events: List[ConnectionEvent] = []
        
        self._load_history()
        print(f"📁 History storage: {self.data_dir}")
    
    def _load_history(self):
        """Load historical data from disk"""
        try:
            if self.history_file.exists():
                with open(self.history_file, 'rb') as f:
                    self.bssid_history = pickle.load(f)
                print(f"📊 Loaded history for {len(self.bssid_history)} BSSIDs")
                if self.log_manager:
                    self.log_manager.debug_logger.info(f"Loaded BSSID history: {len(self.bssid_history)} entries")
            
            if self.events_file.exists():
                with open(self.events_file, 'rb') as f:
                    self.connection_events = pickle.load(f)
                    # Keep only last 30 days of events
                    cutoff = time.time() - (30 * 24 * 3600)
                    original_count = len(self.connection_events)
                    self.connection_events = [e for e in self.connection_events if e.timestamp > cutoff]
                    cleaned_count = original_count - len(self.connection_events)
                    if cleaned_count > 0:
                        print(f"🧹 Cleaned {cleaned_count} old events (keeping last 30 days)")
                        if self.log_manager:
                            self.log_manager.debug_logger.info(f"Cleaned {cleaned_count} old events, keeping {len(self.connection_events)}")
                    print(f"📈 Loaded {len(self.connection_events)} recent connection events")
        except (pickle.UnpicklingError, EOFError, pickle.PickleError) as e:
            print(f"⚠️ Could not load history (corrupted pickle files): {e}")
            print("🔧 Attempting to recover by backing up and resetting history...")
            if self.log_manager:
                self.log_manager.log_error(e, "load_history")
            self._backup_and_reset_corrupted_files()
            self.bssid_history = {}
            self.connection_events = []
            print("🆕 Starting with fresh history tracking")
        except Exception as e:
            print(f"⚠️ Could not load history: {e}")
            print("🆕 Starting with fresh history tracking")
            if self.log_manager:
                self.log_manager.log_error(e, "load_history")
            self.bssid_history = {}
            self.connection_events = []
    
    def _backup_and_reset_corrupted_files(self):
        """Backup corrupted files and reset for fresh start"""
        try:
            import shutil
            timestamp = int(time.time())
            
            if self.history_file.exists():
                backup_history = self.data_dir / f"bssid_history_corrupted_{timestamp}.pkl"
                shutil.move(str(self.history_file), str(backup_history))
                print(f"📦 Backed up corrupted history to: {backup_history.name}")
            
            if self.events_file.exists():
                backup_events = self.data_dir / f"connection_events_corrupted_{timestamp}.pkl"
                shutil.move(str(self.events_file), str(backup_events))
                print(f"📦 Backed up corrupted events to: {backup_events.name}")
                
        except Exception as e:
            print(f"⚠️ Could not backup corrupted files: {e}")
    
    def _save_history(self):
        """Save historical data to disk"""
        try:
            self.data_dir.mkdir(exist_ok=True)
            
            with open(self.history_file, 'wb') as f:
                pickle.dump(self.bssid_history, f)
            
            with open(self.events_file, 'wb') as f:
                pickle.dump(self.connection_events, f)
                
            # Fix file permissions if running as sudo
            if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
                sudo_user = os.environ['SUDO_USER']
                import pwd
                user_info = pwd.getpwnam(sudo_user)
                os.chown(self.history_file, user_info.pw_uid, user_info.pw_gid)
                os.chown(self.events_file, user_info.pw_uid, user_info.pw_gid)
                
        except Exception as e:
            print(f"⚠️ Warning: Could not save history: {e}")

    def record_event(self, event: ConnectionEvent):
        """Record a connection event"""
        self.connection_events.append(event)
        
        # Log the event
        if self.log_manager:
            self.log_manager.log_connection_event(event)
        
        # Update BSSID history
        if event.bssid not in self.bssid_history:
            self.bssid_history[event.bssid] = BSSIDHistory(bssid=event.bssid)
        
        history = self.bssid_history[event.bssid]
        history.last_seen = event.timestamp
        
        if event.event_type == 'connect':
            history.total_connections += 1
            history.successful_connections += 1
        elif event.event_type == 'auth_timeout':
            history.auth_failures += 1
        elif event.event_type == 'disconnect':
            history.disconnects += 1
            if event.duration:
                history.total_duration += event.duration
        
        # Update signal tracking
        if event.signal != -100:
            history.signal_samples.append((event.timestamp, event.signal))
            history.signal_samples = history.signal_samples[-100:]  # Keep last 100
            
            if history.signal_samples:
                history.avg_signal = sum(s[1] for s in history.signal_samples) / len(history.signal_samples)
        
        # Calculate stability score
        self._calculate_stability_score(history)
        self._save_history()
    
    def _calculate_stability_score(self, history: BSSIDHistory):
        """Calculate stability score (0-100) based on historical performance"""
        score = 100.0
        
        # Penalize auth failures (50 point penalty max)
        if history.total_connections > 0:
            failure_rate = history.auth_failures / (history.total_connections + history.auth_failures)
            score -= failure_rate * 50
        
        # Penalize frequent disconnects (30 point penalty max)
        if history.successful_connections > 0:
            disconnect_rate = history.disconnects / history.successful_connections
            score -= min(disconnect_rate * 30, 30)
        
        # Reward consistent signal (10 point bonus for consistency)
        if len(history.signal_samples) > 5:
            signals = [s[1] for s in history.signal_samples[-10:]]
            signal_variance = max(signals) - min(signals)
            if signal_variance < 10:
                score += 10
            elif signal_variance > 30:
                score -= 20
        
        # Reward longer connection durations
        if history.successful_connections > 0 and history.total_duration > 0:
            avg_duration = history.total_duration / history.successful_connections
            if avg_duration > 3600:  # > 1 hour
                score += 15
            elif avg_duration < 300:  # < 5 minutes
                score -= 15
        
        history.stability_score = max(0, min(100, score))
    
    def get_bssid_performance(self, bssid: str) -> Optional[BSSIDHistory]:
        """Get historical performance for a specific BSSID"""
        return self.bssid_history.get(bssid)
    
    def get_recent_events(self, hours: int = 24) -> List[ConnectionEvent]:
        """Get connection events from the last N hours"""
        cutoff = time.time() - (hours * 3600)
        return [e for e in self.connection_events if e.timestamp > cutoff]

class MeshIntelligence:
    """Mesh network topology analysis with built-in OUI database"""
    
    def __init__(self):
        # Updated mesh brand OUI database (May 2025)
        self.oui_database = {
    # eero (Amazon) - Mesh WiFi Systems
    'eero': [
        'A0:21:B7', '68:1D:A0', 'B0:8E:86', 'F8:BB:BF', 'D8:8E:D4', 'E8:D3:EB',  # Original entries
        '00:AB:48', '80:DA:13', '74:B6:B6', '6C:AE:F6', '68:4A:76', '60:5F:8D',  # Additional eero prefixes
        '50:F5:DA', 'C4:93:D9', '58:D9:D5', '50:1A:C5', '04:D3:B0', '24:F5:AA',
        '9C:30:5B', 'A8:81:95', '74:75:48', '60:32:B1', '84:D8:1B', '00:90:4C',
        '70:56:81', 'C8:69:CD', '40:B4:CD', 'BC:E6:43', '8C:85:90', 'DC:A6:32',
        '88:E9:FE', '28:6C:07', '3C:22:FB', '90:72:40', 'D0:04:01', 'AC:BC:32',
        '34:D2:70', 'B0:BE:76', '58:8B:F3', 'EC:01:EE', 'A4:11:6B', '70:4D:7B',
        '98:F1:70', 'CC:32:E5', '40:A3:CC', '1C:69:7A', 'B8:C7:5D', '2C:1F:23',
        '44:CE:7D', 'D4:61:9D', '78:4F:43', '0C:47:C9', 'B4:A9:FC', '88:1F:A1',
        'FC:EC:DA', '30:23:03', '24:A0:74', '6C:72:20', 'E0:55:3D', '48:43:7C'
    ],

    # Netgear Orbi - Mesh WiFi Systems  
    'orbi_netgear': [
        '98:97:9A', '44:B1:3B', '9C:28:EF', 'A0:04:60', '04:A1:51',  # Original entries
        '10:0D:7F', '28:C6:8E', 'B0:7F:B9', '4C:60:DE', '9C:3D:CF',  # Additional Netgear prefixes
        'A0:40:A0', '20:E5:2A', 'C4:04:15', '84:1B:5E', '40:16:7E',
        '2C:30:33', 'E0:46:9A', '6C:19:8F', 'C0:3F:0E', '08:BD:43',
        '74:44:01', 'B0:39:56', '30:46:9A', 'A0:63:91', '44:94:FC',
        '3C:37:86', 'R0:48:7A', '1C:C1:DE', '78:D2:94', 'DC:EF:09',
        '08:02:8E', '74:98:0B', 'A4:2B:B0', '50:C7:BF', '6C:B0:CE',
        '84:A4:23', 'E0:91:F5', 'CC:40:D0', '9C:5C:8E', '28:56:5A',
        '70:4F:57', 'FC:94:E3', '1C:BD:B9', 'B4:75:0E', '34:98:B5',
        '40:0D:10', '6C:CD:D6', 'A0:21:B7', '30:87:30', '50:6A:03'
    ],

    # Google Nest WiFi & Google WiFi
    'google_nest': [
        'A4:50:46', '64:FF:89', 'CC:52:AF', '6C:71:0D',  # Original entries
        'F4:F5:D8', '4C:49:E3', '78:E1:03', '18:B4:30',  # Additional Google prefixes
        '30:FD:38', 'A4:DA:32', '90:72:40', 'F8:8F:CA',
        '6C:AD:F8', 'F0:EF:86', '40:4E:36', 'E8:40:F2',
        'B4:CE:F6', '84:F3:EB', '3C:36:3D', '00:1A:11',
        'D8:50:E6', 'B0:79:94', 'C8:14:79', '54:60:09',
        '68:C6:3A', 'DC:3A:5E', '48:57:02', '7C:2E:BD',
        '98:DE:D0', '14:2D:27', 'B8:AD:28', 'E0:CB:4E',
        '20:DF:B9', 'A0:C5:89', '74:E5:43', '58:CB:52',
        '88:3F:D3', 'C4:B3:01', '60:F1:89', '9C:B6:D0'
    ],

    # ASUS - WiFi Routers and Mesh Systems
    'asus': [
        '40:ED:00', '88:1F:A1', 'AC:9E:17', '2C:56:DC', '04:D4:C4',  # Original entries
        '70:4D:7B', 'B8:EE:65', '1C:87:2C', '50:46:5D', 'D8:50:E6',  # Additional ASUS prefixes
        '38:D5:47', 'F0:2F:74', '30:5A:3A', '04:92:26', '00:E0:4C',
        '00:08:A1', '00:0E:A6', '00:11:D8', '00:13:D4', '00:15:F2',
        '00:17:31', '00:19:DB', '00:1B:FC', '00:1E:8C', '00:22:15',
        '00:23:54', '00:24:8C', '00:26:18', '08:60:6E', '10:7B:44',
        '14:DD:A9', '20:CF:30', '24:4B:FE', '28:10:7B', '30:85:A9',
        '34:97:F6', '38:2C:4A', '3C:7C:3F', '40:16:7E', '48:EE:0C',
        '4C:ED:FB', '50:3E:AA', '54:04:A6', '5C:AC:4C', '60:45:CB',
        '64:66:B3', '6C:F0:49', '70:8B:CD', '74:D0:2B', '78:24:AF',
        '7C:10:C9', '80:1F:02', '84:A4:23', '88:D7:F6', '8C:10:D4',
        '90:F6:52', '94:FB:A7', '98:5A:EB', '9C:5C:8E', 'A0:F3:C1',
        'AC:22:0B', 'B0:6E:BF', 'B4:2E:99', 'B8:AE:6E', 'BC:EE:7B',
        'C8:60:00', 'CC:2D:E0', 'D0:17:C2', 'D4:5D:64', 'D8:47:32',
        'DC:FB:02', 'E0:3F:49', 'E4:70:B8', 'E8:CC:18', 'EC:F4:BB',
        'F0:79:59', 'F4:6D:04', 'F8:32:E4', 'FC:34:97'
    ],

    # TP-Link Deco Mesh Systems
    'tp_link_deco': [
        '98:25:4A', '44:94:FC', 'B0:48:7A', '50:C7:BF', 'A4:2B:B0',  # Original entries
        '14:CC:20', '1C:61:B4', '98:48:27', 'A4:2B:B0', '18:A6:F7',  # Additional TP-Link prefixes
        '00:23:CD', '00:27:19', '04:8D:38', '08:55:31', '0C:80:63',
        '10:27:F5', '14:E6:E4', '18:D6:C7', '1C:FA:68', '20:F4:78',
        '24:05:0F', '28:2C:02', '2C:F0:5D', '30:07:4D', '34:29:8F',
        '38:71:DE', '3C:84:6A', '40:A5:EF', '44:D9:E7', '48:3B:38',
        '4C:E1:73', '50:1A:C5', '54:AF:97', '58:8E:81', '5C:62:8B',
        '60:E3:27', '64:70:02', '68:FF:7B', '6C:5A:B0', '70:4F:57',
        '74:DA:38', '78:81:02', '7C:8A:E1', '80:EA:96', '84:16:F9',
        '88:C3:97', '8C:53:C3', '90:F6:52', '94:E9:79', '98:DA:C4',
        '9C:A6:15', 'A0:F3:C1', 'A4:B1:E9', 'A8:40:41', 'AC:84:C6',
        'B0:4E:26', 'B4:B0:24', 'B8:69:F4', 'BC:46:99', 'C0:06:C3',
        'C4:6E:1F', 'C8:0E:14', 'CC:32:E5', 'D0:76:E7', 'D4:6E:0E',
        'D8:0D:17', 'DC:9F:DB', 'E0:28:6D', 'E4:9A:DC', 'E8:DE:27',
        'EC:08:6B', 'F0:F2:49', 'F4:28:53', 'F8:1A:67', 'FC:7C:02'
    ],

    # Linksys Velop Mesh Systems
    'linksys_velop': [
        '6C:BE:E9', '13:10:47', '98:9E:64', '94:10:3E', 'C4:41:1E',  # Original entries
        '00:0F:66', '00:13:10', '00:14:BF', '00:16:B6', '00:18:39',  # Additional Linksys/Cisco prefixes
        '00:1A:70', '00:1C:10', '00:1D:7E', '00:1E:E5', '00:21:29',
        '00:22:6B', '00:23:04', '00:24:13', '00:25:45', '00:40:96',
        '08:86:3B', '10:05:CA', '14:91:82', '18:1B:EB', '1C:DF:0F',
        '20:AA:4B', '24:F2:7F', '28:F0:76', '2C:AB:A4', '30:23:03',
        '34:A8:4E', '38:2A:68', '3C:1E:04', '40:B0:FA', '44:32:C8',
        '48:F8:B3', '4C:00:82', '50:3D:E5', '54:78:1A', '58:6D:8F',
        '5C:50:15', '60:38:E0', '64:1C:B0', '68:7F:74', '6C:50:4D',
        '70:1A:04', '74:E2:F5', '78:CA:39', '7C:34:79', '80:69:1A',
        '84:B5:17', '88:CB:87', '8C:04:BA', '90:35:5B', '94:44:52',
        '98:FC:11', '9C:97:26', 'A0:55:4F', 'A4:18:75', 'A8:9C:ED',
        'AC:1D:DF', 'B0:10:41', 'B4:3A:28', 'B8:55:10', 'BC:67:78',
        'C0:56:27', 'C4:7C:8D', 'C8:D7:19', 'CC:5D:4E', 'D0:59:E4',
        'D4:CA:6D', 'D8:FE:E3', 'DC:85:DE', 'E0:1C:41', 'E4:F4:C6',
        'E8:98:6D', 'EC:E1:A9', 'F0:92:1C', 'F4:EC:38', 'F8:E7:1E'
    ],

    # Ubiquiti Networks - UniFi, AmpliFi, EdgeRouter
    'ubiquiti': [
        '78:8A:20', '24:5A:4C', 'F0:9F:C2', '44:D9:E7', 'E0:63:DA',  # Original entries
        '04:18:D6', '68:72:51', 'B4:FB:E4', 'DC:9F:DB', '80:2A:A8',  # Additional Ubiquiti prefixes
        '00:15:6D', '00:27:22', '04:18:D6', '18:E8:29', '24:A4:3C',
        '44:D9:E7', '68:72:51', '6C:88:14', '74:83:C2', '78:8A:20',
        '80:2A:A8', 'B4:FB:E4', 'DC:9F:DB', 'E0:63:DA', 'F0:9F:C2',
        '24:5A:4C', '68:D7:9A', '70:A7:41', '74:AC:B9', '78:45:58',
        '80:2A:A8', '84:B5:9C', '88:1F:A1', '8C:59:C3', '90:9A:4A',
        '94:3E:EA', '98:FA:9B', '9C:93:4E', 'A0:F3:E4', 'A4:2B:8C',
        'A8:40:25', 'AC:8B:A9', 'B0:C5:54', 'B4:E6:2D', 'B8:27:EB',
        'BC:DD:C2', 'C0:4A:00', 'C4:A8:1D', 'C8:7F:54', 'CC:2D:A0',
        'D0:21:F9', 'D4:CA:6D', 'D8:B3:70', 'DC:2C:26', 'E0:22:F0',
        'E4:38:7E', 'E8:CC:18', 'EC:B9:70', 'F0:27:2D', 'F4:92:BF',
        'F8:AB:05', 'FC:EC:DA'
    ],

    # MikroTik RouterOS Devices
    'mikrotik': [
        '6C:3B:6B', '48:8F:5A', '2C:C8:1B', '4C:5E:0C', 'E4:8D:8C',  # Original entries
        '00:0C:42', '18:FD:74', '2C:C8:1B', '4C:5E:0C', '6C:3B:6B',  # Additional MikroTik prefixes
        '74:4D:28', '7C:2F:80', '8C:59:C3', 'B8:69:F4', 'DC:2C:6E',
        'E4:8D:8C', '48:8F:5A', '08:55:31', '18:FD:74', '00:0C:42',
        '6C:3B:6B', '4C:5E:0C', 'E4:8D:8C', '2C:C8:1B', '48:8F:5A',
        'B8:69:F4', 'DC:2C:6E', '74:4D:28', '8C:59:C3', '18:FD:74',
        '7C:2F:80', '00:0C:42', '08:55:31', '84:1B:5E', '90:5A:68',
        '94:E3:6D', '98:DA:C4', '9C:A6:15', 'A0:F3:C1', 'A4:B1:E9',
        'A8:40:41', 'AC:84:C6', 'B0:4E:26', 'B4:B0:24', 'B8:69:F4',
        'BC:46:99', 'C0:06:C3', 'C4:6E:1F', 'C8:0E:14', 'CC:32:E5',
        'D0:76:E7', 'D4:6E:0E', 'D8:0D:17', 'DC:9F:DB'
    ],

    # Aruba HPE Networks
    'aruba_hpe': [
        '70:3A:CB', '6C:F3:7F', '24:DE:C6', '94:B4:0F', '20:4C:03',  # Original entries
        '00:0B:86', '00:1A:1E', '00:24:6C', '6C:F3:7F', '70:3A:CB',  # Additional Aruba/HPE prefixes
        '78:9C:85', '84:D4:7E', '8C:DC:D4', '94:B4:0F', '9C:1C:12',
        'A4:5D:36', 'B0:5A:DA', 'B8:D9:CE', 'C0:E4:34', 'D8:C7:C8',
        'E0:07:1B', 'E8:BA:70', 'F0:5C:19', 'F8:0A:CB', '00:0B:86',
        '00:1A:1E', '00:24:6C', '18:64:72', '20:4C:03', '24:DE:C6',
        '40:E3:D6', '54:75:D0', '6C:C2:17', '70:3A:CB', '7C:69:F6',
        '84:D4:7E', '8C:DC:D4', '94:B4:0F', '9C:1C:12', 'A4:5D:36',
        'B0:5A:DA', 'B8:D9:CE', 'C0:E4:34', 'D8:C7:C8', 'E0:07:1B',
        'E8:BA:70', 'F0:5C:19', 'F8:0A:CB', '6C:F3:7F', '20:4C:03'
    ],

    # Ruckus Networks (CommScope)
    'ruckus': [
        '50:91:E3', '2C:36:F8', '94:3E:EA', 'BC:14:85', '58:93:96',  # Original entries
        '2C:36:F8', '50:91:E3', '58:93:96', '94:3E:EA', 'BC:14:85',  # Additional Ruckus prefixes
        'C4:B9:CD', 'E0:5F:B9', 'F4:28:53', '00:0F:9F', '00:14:7F',
        '00:21:91', '00:24:DC', '78:BC:1A', '84:1B:5E', '90:5A:68',
        '2C:36:F8', '50:91:E3', '58:93:96', '94:3E:EA', 'BC:14:85',
        'C4:B9:CD', 'E0:5F:B9', 'F4:28:53', '00:0F:9F', '00:14:7F',
        '00:21:91', '00:24:DC', '78:BC:1A', '84:1B:5E', '90:5A:68',
        '94:E3:6D', '98:DA:C4', '9C:A6:15', 'A0:F3:C1', 'A4:B1:E9',
        'A8:40:41', 'AC:84:C6', 'B0:4E:26', 'B4:B0:24', 'BC:46:99'
    ],

    # Cisco Meraki Cloud Managed Networks
    'cisco_meraki': [
        '00:18:0A', 'E0:55:3D', '88:15:44', '0C:8D:DB', '34:56:FE',  # Original entries
        '00:18:0A', '0C:8D:DB', '34:56:FE', '88:15:44', 'E0:55:3D',  # Additional Cisco Meraki prefixes
        '00:1D:71', '00:24:DC', 'E0:CB:BC', 'F4:39:09', '58:97:1E',
        '8C:7C:92', 'AC:17:C8', 'E0:CB:BC', 'F4:39:09', '58:97:1E',
        '00:1D:71', '00:24:DC', '8C:7C:92', 'AC:17:C8', '00:18:0A',
        '0C:8D:DB', '34:56:FE', '88:15:44', 'E0:55:3D', 'E0:CB:BC',
        'F4:39:09', '58:97:1E', '8C:7C:92', 'AC:17:C8', '00:1D:71',
        '00:24:DC', '2C:BE:08', '4C:79:6E', '74:86:E2', '8C:FE:A3',
        'A4:56:02', 'BC:67:1C', 'D4:20:B0', 'EC:1F:72', '2C:BE:08',
        '4C:79:6E', '74:86:E2', '8C:FE:A3', 'A4:56:02', 'BC:67:1C'
    ],

    # EnGenius Wireless Access Points
    'engenius': [
        '88:DC:96', '50:2B:73', '02:CF:7F', '00:02:6F',  # Original entries
        '00:02:6F', '02:CF:7F', '50:2B:73', '88:DC:96',  # Additional EnGenius prefixes
        '00:02:6F', '88:DC:96', '50:2B:73', '02:CF:7F',
        '74:EA:3A', 'AC:9E:17', 'C8:D3:A3', 'DC:EF:09',
        'F0:7D:68', '74:EA:3A', 'AC:9E:17', 'C8:D3:A3',
        'DC:EF:09', 'F0:7D:68', '88:DC:96', '50:2B:73',
        '02:CF:7F', '00:02:6F', '74:EA:3A', 'AC:9E:17',
        'C8:D3:A3', 'DC:EF:09', 'F0:7D:68', '04:F0:21',
        '6C:72:20', '88:6B:0E', 'AC:83:F3', 'D0:17:C2',
        'F4:AF:E7', '04:F0:21', '6C:72:20', '88:6B:0E'
    ],

    # D-Link WiFi Routers and Access Points
    'dlink': [
        'CC:B2:55', 'B8:A3:86', '34:08:04', '14:D6:4D', '84:C9:B2',  # Original entries
        '00:05:5D', '00:0F:3D', '00:11:95', '00:13:46', '00:15:E9',  # Additional D-Link prefixes
        '00:17:9A', '00:19:5B', '00:1B:11', '00:1C:F0', '00:1E:58',
        '00:21:91', '00:22:B0', '00:24:01', '00:26:5A', '14:D6:4D',
        '1C:7E:E5', '1C:AF:F7', '28:10:7B', '2C:B0:5D', '34:08:04',
        '40:61:86', '48:EE:0C', '50:C7:BF', '54:78:1A', '5C:F4:AB',
        '60:C5:47', '6C:19:8F', '70:62:B8', '78:54:2E', '7C:8B:CA',
        '84:C9:B2', '8C:BE:BE', '90:94:E4', '94:44:52', '9C:D6:43',
        'A0:AB:1B', 'A8:57:4E', 'B0:C7:45', 'B8:A3:86', 'C0:A0:BB',
        'C8:BE:19', 'CC:B2:55', 'D0:67:E5', 'D8:FE:E3', 'E0:91:F5',
        'E8:CC:18', 'F0:7D:68', 'F8:E7:1E', 'FC:75:16'
    ],

    # Netgear General (Non-Orbi) Products
    'netgear_general': [
        '10:0D:7F', '28:C6:8E', 'B0:7F:B9', '4C:60:DE',  # Original entries
        '00:09:5B', '00:0F:B5', '00:14:6C', '00:1B:2F', '00:1E:2A',
        '00:22:3F', '00:24:B2', '00:26:F2', '04:A1:51', '08:BD:43',
        '10:0D:7F', '20:4E:7F', '28:C6:8E', '2C:30:33', '30:46:9A',
        '44:94:FC', '4C:60:DE', '6C:B0:CE', '70:4F:57', '74:44:01',
        '78:D2:94', '84:A4:23', '9C:3D:CF', 'A0:04:60', 'A0:21:B7',
        'A0:63:91', 'A4:2B:B0', 'B0:39:56', 'B0:7F:B9', 'C0:3F:0E',
        'C4:04:15', 'CC:40:D0', 'DC:EF:09', 'E0:46:9A', 'E0:91:F5',
        'FC:94:E3', '1C:BD:B9', '1C:C1:DE', '3C:37:86', '40:0D:10',
        '50:6A:03', '6C:CD:D6', '9C:5C:8E', 'B4:75:0E', '34:98:B5'
    ],

    # Plume Adaptive WiFi (Plume Design)
    'plume_adaptive': [
        '74:DA:88', '78:28:CA', 'A0:40:A0',  # Original entries
        '74:DA:88', '78:28:CA', 'A0:40:A0',  # Additional Plume prefixes
        'B8:D7:AF', 'C4:93:D9', 'E0:1C:FC',
        '24:F5:AA', '58:D9:D5', '9C:30:5B',
        'A8:81:95', 'C0:C9:E3', 'E8:6A:64',
        '04:D3:B0', '50:1A:C5', 'B0:BE:76',
        'EC:01:EE', '74:DA:88', '78:28:CA',
        'A0:40:A0', 'B8:D7:AF', 'C4:93:D9'
    ],

    # Xfinity Pods (Comcast)
    'xfinity_pods': [
        'A8:4E:3F', '00:35:1A', '8C:3B:AD',  # Original entries
        'A8:4E:3F', '00:35:1A', '8C:3B:AD',
        '70:56:81', 'C8:69:CD', '40:B4:CD',
        'BC:E6:43', '8C:85:90', 'DC:A6:32',
        '88:E9:FE', '28:6C:07', '3C:22:FB',
        '90:72:40', 'D0:04:01', 'AC:BC:32',
        '34:D2:70', 'A8:4E:3F', '00:35:1A',
        '8C:3B:AD', '70:56:81', 'C8:69:CD'
    ],

    # Amazon AmpliFi (acquired by Amazon)
    'amazon_amplifi': [
        '74:C6:3B', 'E4:95:6E',  # Original entries
        '74:C6:3B', 'E4:95:6E',  # Additional AmpliFi prefixes
        'DC:9F:DB', '44:D9:E7', 'F0:9F:C2',
        '24:5A:4C', '78:8A:20', 'E0:63:DA',
        'B4:FB:E4', '04:18:D6', '68:72:51',
        '80:2A:A8', '74:C6:3B', 'E4:95:6E',
        'DC:9F:DB', '44:D9:E7', 'F0:9F:C2'
    ],

    # Tenda WiFi Routers
    'tenda': [
        'C8:3A:35', 'FC:7C:02', '98:DE:D0',  # Original entries
        'C8:3A:35', 'FC:7C:02', '98:DE:D0',  # Additional Tenda prefixes
        '00:B0:0C', '74:25:8A', 'A4:2B:8C',
        'C8:3A:35', 'FC:7C:02', '98:DE:D0',
        '00:B0:0C', '74:25:8A', 'A4:2B:8C',
        'E0:05:C6', 'F4:EC:38', '34:96:72',
        '5C:CF:7F', 'B0:E5:ED', 'D4:6E:0E',
        'E8:DE:27', '10:BF:48', '50:BD:5F',
        '8C:21:0A', 'C8:3A:35', 'FC:7C:02'
    ],

    # Xiaomi Mi Router and Mesh
    'xiaomi_mesh': [
        '34:CE:00', '64:64:4A', 'F8:59:71',  # Original entries
        '34:CE:00', '64:64:4A', 'F8:59:71',  # Additional Xiaomi prefixes
        '50:8F:4C', '78:11:DC', 'A0:86:C6',
        'B0:E2:35', 'C4:0B:CB', 'D4:97:0B',
        'E8:AB:FA', 'F0:B4:29', 'F8:59:71',
        '04:CF:8C', '14:75:90', '28:E3:1F',
        '3C:BD:D8', '50:EC:50', '68:DF:DD',
        '7C:1D:D9', '8C:53:C3', '98:FA:9B',
        'A4:DA:32', 'B8:70:F4', 'C8:FF:28',
        'DC:44:27', 'F0:B4:29', '34:CE:00'
    ],

    # Honor/Huawei WiFi Routers
    'honor_huawei': [
        '00:E0:FC', '98:F4:28', 'A0:8C:FD',  # Original entries
        '00:E0:FC', '98:F4:28', 'A0:8C:FD',  # Additional Huawei/Honor prefixes
        '00:25:9E', '04:BD:88', '10:47:80',
        '18:CF:5E', '20:76:93', '28:31:52',
        '30:FC:68', '3C:FA:43', '44:00:10',
        '4C:54:99', '54:25:EA', '5C:C9:D3',
        '64:3E:8C', '6C:92:BF', '74:A7:22',
        '7C:A7:B0', '84:A8:E4', '8C:34:FD',
        '94:04:9C', '9C:28:EF', 'A4:C4:94',
        'AC:E2:15', 'B4:CD:27', 'BC:76:70',
        'C4:6A:B7', 'CC:E6:7F', 'D4:20:B0',
        'DC:D2:FC', 'E4:C7:22', 'EC:23:3D',
        'F4:4E:E3', 'FC:48:EF', '98:F4:28'
    ],

    # WiFi 6E and WiFi 7 Manufacturers
    'wifi6e_wifi7_general': [
        # Various next-gen WiFi manufacturers
        '70:4F:57', '6C:CD:D6', '30:87:30', '50:6A:03', '40:0D:10',
        'B4:75:0E', '34:98:B5', '1C:BD:B9', 'FC:94:E3', 'E0:91:F5',
        '84:A4:23', 'A0:63:91', '70:4F:57', '6C:B0:CE', '44:94:FC',
        '30:46:9A', '2C:30:33', 'E0:46:9A', '6C:19:8F', 'C0:3F:0E',
        '08:BD:43', '74:44:01', 'B0:39:56', '20:E5:2A', 'C4:04:15',
        '84:1B:5E', '40:16:7E', '9C:3D:CF', 'A0:40:A0', '10:0D:7F',
        '28:C6:8E', 'B0:7F:B9', '4C:60:DE', 'DC:EF:09', 'CC:40:D0'
    ],

    # Additional Mesh Router Brands
    'additional_mesh_brands': [
        # Portal WiFi
        '68:A4:0E', '84:16:0C', 'A0:8C:FD', 'B4:2E:99', 'C8:D3:A3',
        # Securifi Almond
        'F0:7D:68', '74:EA:3A', 'AC:9E:17', 'DC:EF:09', 'C8:D3:A3',
        # Luma WiFi
        '44:61:32', '70:B3:D5', '9C:65:F9', 'C0:14:FE', 'E4:A7:A0',
        # Gryphon Router
        '00:1E:C7', '2C:AB:A4', '58:6D:8F', '84:B5:17', 'B0:10:41',
        # Samsung SmartThings WiFi
        '28:6D:CD', '5C:0A:5B', '88:36:6C', 'B4:E6:2D', 'E0:91:F5',
        # Norton Core Router
        '00:50:56', '00:0C:29', '00:05:69', '00:1C:14', '00:50:56'
    ],

    # Industrial and Enterprise Mesh
    'industrial_enterprise': [
        # Cambium Networks
        '00:04:56', '00:80:A1', '58:C1:7A', '84:1B:5E', 'B8:59:9F',
        # Cradlepoint
        '00:30:44', '8C:0E:E3', 'A4:93:4C', 'C0:EE:40', 'E4:E4:AB',
        # Peplink
        '00:15:FF', '00:1C:B5', '30:D1:7E', '6C:3B:E5', 'A8:1E:84',
        # SonicWall
        '00:06:B1', '00:17:C5', '2C:8A:72', '78:D2:94', 'C0:EA:E4',
        # Fortinet FortiGate
        '00:09:0F', '70:4C:A5', '90:6C:AC', 'A0:1D:48', 'B8:EE:65'
    ]
}
    
    def identify_mesh_brand(self, bssids: List[str]) -> Optional[str]:
        """Identify mesh system brand from BSSIDs"""
        for bssid in bssids:
            oui = ':'.join(bssid.split(':')[:3]).upper()
            for brand, ouis in self.oui_database.items():
                if oui in [o.upper() for o in ouis]:
                    return brand
        return None
    
    def analyze_mesh_topology(self, same_ssid_aps: List[APScan]) -> Dict:
        """Analyze network structure - mesh vs single AP/WAP with appropriate evaluation"""
        if len(same_ssid_aps) <= 1:
            # Single AP - use signal strength analysis
            ap = same_ssid_aps[0] if same_ssid_aps else None
            if ap:
                if ap.signal > -50:
                    quality = "excellent"
                    quality_reason = f"Strong signal ({ap.signal}dBm) indicates good placement"
                elif ap.signal > -60:
                    quality = "good"
                    quality_reason = f"Good signal strength ({ap.signal}dBm)"
                elif ap.signal > -75:
                    quality = "fair"
                    quality_reason = f"Moderate signal ({ap.signal}dBm) - consider moving closer or improving placement"
                else:
                    quality = "poor"
                    quality_reason = f"Weak signal ({ap.signal}dBm) - poor placement or too far from AP"
                
                return {
                    'type': 'single_ap',
                    'nodes': 1,
                    'signal_quality': quality,
                    'signal_reason': quality_reason,
                    'signal_strength': ap.signal
                }
            else:
                return {'type': 'single_ap', 'nodes': 0}
        
        # Multiple APs - determine if it's a mesh or multiple standalone APs
        mesh_nodes = {}
        standalone_aps = []
        
        for ap in same_ssid_aps:
            base_mac = ':'.join(ap.bssid.split(':')[:-1])
            
            # Check if this looks like a mesh node (same base MAC with different radios)
            if base_mac in mesh_nodes:
                # This is another radio on the same mesh node
                mesh_nodes[base_mac]['radios'].append({
                    'bssid': ap.bssid,
                    'freq': ap.freq,
                    'signal': ap.signal,
                    'band': self._determine_band(ap.freq)
                })
                mesh_nodes[base_mac]['bands'].add(self._determine_band(ap.freq))
                mesh_nodes[base_mac]['strongest_signal'] = max(
                    mesh_nodes[base_mac]['strongest_signal'], ap.signal
                )
            else:
                # Check if any existing mesh node has a similar base MAC (mesh detection)
                is_mesh_node = False
                for existing_base in mesh_nodes.keys():
                    # If base MACs are very similar, likely same mesh system
                    if self._is_likely_same_mesh_system([base_mac, existing_base]):
                        is_mesh_node = True
                        break
                
                if is_mesh_node or len([a for a in same_ssid_aps if ':'.join(a.bssid.split(':')[:-1]) == base_mac]) > 1:
                    # This is a mesh node
                    mesh_nodes[base_mac] = {
                        'base_mac': base_mac,
                        'radios': [{
                            'bssid': ap.bssid,
                            'freq': ap.freq,
                            'signal': ap.signal,
                            'band': self._determine_band(ap.freq)
                        }],
                        'bands': {self._determine_band(ap.freq)},
                        'strongest_signal': ap.signal
                    }
                else:
                    # This looks like a standalone AP
                    standalone_aps.append(ap)
        
        # If we have mesh nodes, analyze as mesh
        if mesh_nodes:
            return self._analyze_mesh_system(mesh_nodes, same_ssid_aps)
        else:
            # Multiple standalone APs with same SSID
            return self._analyze_multiple_aps(same_ssid_aps)
    
    def _determine_band(self, freq: int) -> str:
        """Determine frequency band from frequency"""
        if 2400 <= freq <= 2500:
            return '2.4GHz'
        elif 5000 <= freq <= 5999:
            return '5GHz'
        elif 6000 <= freq <= 7125:
            return '6GHz'
        else:
            return 'other'
    
    def _is_likely_same_mesh_system(self, base_macs: List[str]) -> bool:
        """Check if base MACs likely belong to same mesh system"""
        # Simple heuristic: if OUI matches and MACs are in sequence
        if len(base_macs) < 2:
            return False
        
        ouis = [':'.join(mac.split(':')[:3]) for mac in base_macs]
        return len(set(ouis)) == 1  # Same manufacturer
    
    def _analyze_mesh_system(self, mesh_nodes: Dict, same_ssid_aps: List[APScan]) -> Dict:
        """Analyze actual mesh system topology and health with proper spatial analysis"""
        total_nodes = len(mesh_nodes)
        brand = self.identify_mesh_brand([ap.bssid for ap in same_ssid_aps])
        
        # Determine mesh type
        all_bands = set()
        for node in mesh_nodes.values():
            all_bands.update(node['bands'])
        
        if len(all_bands) >= 3:
            mesh_type = 'tri_band'
        elif len(all_bands) == 2:
            mesh_type = 'dual_band'
        else:
            mesh_type = 'single_band'
        
        # SOPHISTICATED SPATIAL ANALYSIS
        signals = [node['strongest_signal'] for node in mesh_nodes.values()]
        sorted_signals = sorted(signals, reverse=True)
        signal_range = max(signals) - min(signals)
        
        # Analyze signal distribution and coverage quality
        coverage_analysis = self._perform_spatial_coverage_analysis(sorted_signals, mesh_nodes)
        
        # VENN DIAGRAM ANALYSIS - RESTORED!
        venn_data = self._generate_venn_analysis(mesh_nodes)
        
        # Convert sets to lists for JSON serialization
        for node in mesh_nodes.values():
            if isinstance(node['bands'], set):
                node['bands'] = list(node['bands'])
        
        result = {
            'type': 'mesh',
            'brand': brand or 'unknown',
            'mesh_type': mesh_type,
            'total_nodes': total_nodes,
            'total_radios': len(same_ssid_aps),
            'bands': sorted(list(all_bands)),
            'signal_range': signal_range,
            'mesh_nodes': mesh_nodes,
            'signal_distribution': sorted_signals,
            'coverage_analysis': coverage_analysis,
            'venn_analysis': venn_data  # ADDED: Venn diagram data
        }
        
        # Legacy fields for compatibility
        result['topology_health'] = coverage_analysis['topology_classification']
        result['coverage_reason'] = coverage_analysis['summary']
        result['coverage_health'] = coverage_analysis['spatial_distribution']
        result['coverage_details'] = {
            'signal_range': signal_range,
            'strongest_node': max(signals),
            'weakest_node': min(signals),
            'total_nodes': total_nodes,
            'radios_per_node': len(same_ssid_aps) / total_nodes
        }
        
        return result
    
    def _generate_venn_analysis(self, mesh_nodes: Dict) -> Dict:
        """Generate Venn diagram analysis for mesh overlap visualization"""
        try:
            venn_calculator = MeshVennCalculator()
            
            # Prepare nodes data for Venn analysis
            nodes_for_venn = []
            for i, (node_id, node_data) in enumerate(mesh_nodes.items()):
                node_for_venn = {
                    'id': i,
                    'label': f"Node {node_id[-8:]}",
                    'signal': node_data['strongest_signal'],
                    'bssid': node_id,
                    'radios': len(node_data['radios']),
                    'bands': list(node_data['bands']) if isinstance(node_data['bands'], set) else node_data['bands']
                }
                nodes_for_venn.append(node_for_venn)
            
            # Generate Venn diagram data
            venn_data = venn_calculator.generate_venn_data(nodes_for_venn)
            
            # Get overlap quality assessment
            quality_assessment = venn_calculator.get_overlap_quality_assessment(venn_data)
            
            return {
                'venn_diagram': venn_data,
                'overlap_quality': quality_assessment,
                'total_nodes': len(nodes_for_venn),
                'overlap_count': venn_data.get('overlap_count', 0),
                'coverage_efficiency': quality_assessment.get('score', 0)
            }
            
        except Exception as e:
            # Fallback if Venn calculator fails
            return {
                'venn_diagram': {'nodes': [], 'overlaps': [], 'total_coverage': 0},
                'overlap_quality': {'quality': 'unavailable', 'score': 0, 'description': f'Venn analysis failed: {str(e)}'},
                'total_nodes': len(mesh_nodes),
                'overlap_count': 0,
                'coverage_efficiency': 0
            }
    
    def _perform_spatial_coverage_analysis(self, sorted_signals: List[int], mesh_nodes: Dict) -> Dict:
        """Perform sophisticated spatial coverage analysis based on signal distribution patterns"""
        
        # Calculate signal gradients and gaps
        signal_gaps = []
        for i in range(len(sorted_signals) - 1):
            gap = sorted_signals[i] - sorted_signals[i + 1]
            signal_gaps.append(gap)
        
        max_gap = max(signal_gaps) if signal_gaps else 0
        avg_gap = sum(signal_gaps) / len(signal_gaps) if signal_gaps else 0
        
        # Analyze coverage zones based on signal strength
        zones = self._classify_coverage_zones(sorted_signals)
        
        # Detect coverage problems
        coverage_issues = self._detect_coverage_issues(sorted_signals, signal_gaps, zones)
        
        # Overall topology assessment
        topology_assessment = self._assess_mesh_topology(sorted_signals, signal_gaps, zones, coverage_issues)
        
        return {
            'sorted_signals': sorted_signals,
            'signal_gaps': signal_gaps,
            'max_signal_gap': max_gap,
            'avg_signal_gap': avg_gap,
            'coverage_zones': zones,
            'coverage_issues': coverage_issues,
            'topology_classification': topology_assessment['classification'],
            'summary': topology_assessment['summary'],
            'spatial_distribution': topology_assessment['distribution_analysis'],
            'recommendations': topology_assessment['recommendations'],
            'coverage_quality_score': topology_assessment['quality_score']
        }
    
    def _classify_coverage_zones(self, sorted_signals: List[int]) -> Dict:
        """Classify coverage into spatial zones based on signal strength"""
        zones = {
            'primary': [],      # > -50dBm (excellent, close range)
            'secondary': [],    # -50 to -65dBm (good, medium range)
            'tertiary': [],     # -65 to -80dBm (fair, extended range)
            'fringe': []        # < -80dBm (poor, maximum range)
        }
        
        for signal in sorted_signals:
            if signal > -50:
                zones['primary'].append(signal)
            elif signal > -65:
                zones['secondary'].append(signal)
            elif signal > -80:
                zones['tertiary'].append(signal)
            else:
                zones['fringe'].append(signal)
        
        return zones
    
    def _detect_coverage_issues(self, sorted_signals: List[int], signal_gaps: List[int], zones: Dict) -> List[Dict]:
        """Detect specific coverage and distribution issues"""
        issues = []
        
        # Large signal gap detection (potential dead zones)
        for i, gap in enumerate(signal_gaps):
            if gap > 25:
                issues.append({
                    'type': 'large_coverage_gap',
                    'severity': 'high' if gap > 35 else 'medium',
                    'details': f"{gap}dB gap between node {i+1} ({sorted_signals[i]}dBm) and node {i+2} ({sorted_signals[i+1]}dBm)",
                    'impact': 'Potential dead zone or weak coverage area',
                    'location': f"Between {self._signal_to_distance_estimate(sorted_signals[i])} and {self._signal_to_distance_estimate(sorted_signals[i+1])}"
                })
        
        # Coverage zone analysis
        if not zones['secondary'] and zones['primary'] and zones['tertiary']:
            issues.append({
                'type': 'missing_intermediate_coverage',
                'severity': 'medium',
                'details': 'No medium-range coverage detected',
                'impact': 'May have coverage gaps between close and distant areas',
                'location': 'Medium-range areas (adjacent rooms/floors)'
            })
        
        # Clustering detection
        if len(zones['primary']) > len(sorted_signals) * 0.6:
            issues.append({
                'type': 'node_clustering',
                'severity': 'low',
                'details': f"{len(zones['primary'])} of {len(sorted_signals)} nodes in primary zone",
                'impact': 'Possible over-concentration of nodes in small area',
                'location': 'Primary coverage area'
            })
        
        # Extended range without intermediate coverage
        if zones['fringe'] and not zones['tertiary']:
            issues.append({
                'type': 'isolated_distant_node',
                'severity': 'medium',
                'details': f"Distant node at {min(sorted_signals)}dBm without intermediate coverage",
                'impact': 'Isolated coverage with potential gap to main mesh',
                'location': f"~{self._signal_to_distance_estimate(min(sorted_signals))}"
            })
        
        return issues
    
    def _assess_mesh_topology(self, sorted_signals: List[int], signal_gaps: List[int], zones: Dict, issues: List[Dict]) -> Dict:
        """Comprehensive mesh topology assessment"""
        
        # Calculate quality score (0-100)
        quality_score = 100
        
        # Penalize for coverage issues
        for issue in issues:
            if issue['severity'] == 'high':
                quality_score -= 25
            elif issue['severity'] == 'medium':
                quality_score -= 15
            elif issue['severity'] == 'low':
                quality_score -= 5
        
        # Reward good signal distribution
        if len(zones['secondary']) > 0:
            quality_score += 10  # Good intermediate coverage
        
        if max(signal_gaps) < 20:
            quality_score += 15  # Smooth signal transitions
        
        # Node count assessment
        node_count = len(sorted_signals)
        if node_count >= 4:
            base_rating = "excellent_nodes"
            node_assessment = f"{node_count} nodes detected - excellent for comprehensive coverage"
        elif node_count == 3:
            base_rating = "good_nodes"
            node_assessment = f"{node_count} nodes detected - good for most home sizes"
        elif node_count == 2:
            base_rating = "basic_nodes"
            node_assessment = f"{node_count} nodes detected - basic mesh configuration"
        else:
            base_rating = "single_node"
            node_assessment = f"{node_count} node detected - not a true mesh"
        
        # Distribution analysis
        max_gap = max(signal_gaps) if signal_gaps else 0
        
        if max_gap > 30:
            distribution = "poor_distribution"
            dist_analysis = f"Large signal gaps detected (max {max_gap}dB) - potential coverage holes"
        elif max_gap > 20:
            distribution = "uneven_distribution"
            dist_analysis = f"Moderate signal gaps (max {max_gap}dB) - some coverage irregularities"
        elif max_gap > 10:
            distribution = "good_distribution"
            dist_analysis = f"Well-spaced nodes (max gap {max_gap}dB) - good coverage continuity"
        else:
            distribution = "excellent_distribution"
            dist_analysis = f"Smooth signal transitions (max gap {max_gap}dB) - excellent spatial distribution"
        
        # Overall classification
        high_severity_issues = [i for i in issues if i['severity'] == 'high']
        medium_severity_issues = [i for i in issues if i['severity'] == 'medium']
        
        if high_severity_issues:
            classification = "topology_issues"
            summary = f"{node_assessment} but significant coverage gaps detected"
        elif medium_severity_issues and node_count < 3:
            classification = "basic_topology"
            summary = f"{node_assessment} with some coverage limitations"
        elif medium_severity_issues:
            classification = "good_topology"
            summary = f"{node_assessment} with minor coverage irregularities"
        elif node_count >= 4 and quality_score > 85:
            classification = "excellent_topology"
            summary = f"{node_assessment} with excellent spatial distribution"
        elif node_count >= 3 and quality_score > 75:
            classification = "good_topology" 
            summary = f"{node_assessment} with good spatial coverage"
        else:
            classification = "basic_topology"
            summary = f"{node_assessment} - adequate but could be optimized"
        
        # Recommendations
        recommendations = []
        for issue in issues:
            if issue['type'] == 'large_coverage_gap':
                recommendations.append(f"Consider adding a node in {issue['location']} to eliminate coverage gap")
            elif issue['type'] == 'missing_intermediate_coverage':
                recommendations.append("Add intermediate nodes for smoother coverage transitions")
            elif issue['type'] == 'node_clustering':
                recommendations.append("Consider relocating some nodes for better spatial distribution")
            elif issue['type'] == 'isolated_distant_node':
                recommendations.append("Add intermediate nodes to bridge coverage to distant areas")
        
        if not recommendations and quality_score > 90:
            recommendations.append("Excellent mesh topology - no improvements needed")
        elif not recommendations:
            recommendations.append("Good mesh topology - minor optimizations possible")
        
        return {
            'classification': classification,
            'summary': summary,
            'distribution_analysis': dist_analysis,
            'quality_score': max(0, min(100, quality_score)),
            'recommendations': recommendations,
            'node_assessment': node_assessment,
            'distribution_quality': distribution
        }
    
    def _signal_to_distance_estimate(self, signal_dbm: int) -> str:
        """Estimate approximate distance/location based on signal strength"""
        if signal_dbm > -40:
            return "very close (same room)"
        elif signal_dbm > -50:
            return "close (adjacent room)"
        elif signal_dbm > -65:
            return "medium range (different floor/far room)"
        elif signal_dbm > -80:
            return "extended range (distant area)"
        else:
            return "maximum range (basement/garage/far areas)"
    
    def _analyze_multiple_aps(self, same_ssid_aps: List[APScan]) -> Dict:
        """Analyze multiple standalone APs with same SSID"""
        signals = [ap.signal for ap in same_ssid_aps]
        strongest_signal = max(signals)
        
        if strongest_signal > -50:
            quality = "excellent"
            quality_reason = f"Strong signals available ({strongest_signal}dBm) from multiple APs"
        elif strongest_signal > -60:
            quality = "good" 
            quality_reason = f"Good signal options ({strongest_signal}dBm) from {len(same_ssid_aps)} APs"
        elif strongest_signal > -75:
            quality = "fair"
            quality_reason = f"Moderate signals ({strongest_signal}dBm) - consider moving closer to APs"
        else:
            quality = "poor"
            quality_reason = f"Weak signals from all APs ({strongest_signal}dBm) - poor coverage area"
        
        # Convert APScan objects to dictionaries for JSON serialization
        ap_list = [ap.to_dict() for ap in same_ssid_aps]
        
        return {
            'type': 'multiple_aps',
            'nodes': len(same_ssid_aps),
            'signal_quality': quality,
            'signal_reason': quality_reason,
            'strongest_signal': strongest_signal,
            'ap_list': ap_list
        }

class ProblemDetector:
    """Detect WiFi connection problems from logs and events"""
    
    def __init__(self, history_tracker):
        self.history = history_tracker
    
    def analyze_connection_patterns(self, window_hours: int = 24) -> Dict:
        """Analyze connection patterns for problems"""
        events = self.history.get_recent_events(window_hours)
        
        patterns = {
            'roaming_loops': [],
            'auth_failure_clusters': [],
            'rapid_disconnects': [],
            'time_based_issues': {},
            'bssid_specific_problems': {}
        }
        
        self._detect_roaming_loops(events, patterns)
        self._detect_auth_clusters(events, patterns)
        self._detect_rapid_cycles(events, patterns)
        self._analyze_time_patterns(events, patterns)
        self._analyze_bssid_problems(events, patterns)
        
        return patterns
    
    def _detect_roaming_loops(self, events: List[ConnectionEvent], patterns: Dict):
        """Detect roaming loops between BSSIDs"""
        connects = [e for e in events if e.event_type == 'connect']
        
        for i in range(len(connects) - 3):
            bssids = [connects[j].bssid for j in range(i, i + 4)]
            if (bssids[0] == bssids[2] and bssids[1] == bssids[3] and bssids[0] != bssids[1]):
                time_span = connects[i + 3].timestamp - connects[i].timestamp
                if time_span < 300:  # 5 minutes
                    patterns['roaming_loops'].append({
                        'bssids': [bssids[0], bssids[1]],
                        'time_span': time_span,
                        'start_time': connects[i].timestamp
                    })
    
    def _detect_auth_clusters(self, events: List[ConnectionEvent], patterns: Dict):
        """Detect clusters of authentication failures"""
        auth_failures = [e for e in events if e.event_type == 'auth_timeout']
        
        for bssid in set(e.bssid for e in auth_failures):
            bssid_failures = [e for e in auth_failures if e.bssid == bssid]
            
            if len(bssid_failures) >= 3:
                timestamps = sorted([e.timestamp for e in bssid_failures])
                clusters = []
                current_cluster = [timestamps[0]]
                
                for i in range(1, len(timestamps)):
                    if timestamps[i] - timestamps[i-1] < 300:  # Within 5 minutes
                        current_cluster.append(timestamps[i])
                    else:
                        if len(current_cluster) >= 3:
                            clusters.append(current_cluster)
                        current_cluster = [timestamps[i]]
                
                if len(current_cluster) >= 3:
                    clusters.append(current_cluster)
                
                for cluster in clusters:
                    patterns['auth_failure_clusters'].append({
                        'bssid': bssid,
                        'failure_count': len(cluster),
                        'time_span': cluster[-1] - cluster[0],
                        'start_time': cluster[0]
                    })
    
    def _detect_rapid_cycles(self, events: List[ConnectionEvent], patterns: Dict):
        """Detect rapid disconnect/reconnect cycles"""
        for i in range(len(events) - 1):
            if (events[i].event_type == 'disconnect' and 
                events[i + 1].event_type == 'connect' and
                events[i + 1].timestamp - events[i].timestamp < 60):
                
                patterns['rapid_disconnects'].append({
                    'bssid': events[i].bssid,
                    'cycle_duration': events[i + 1].timestamp - events[i].timestamp
                })
    
    def _analyze_time_patterns(self, events: List[ConnectionEvent], patterns: Dict):
        """Analyze time-based problem patterns"""
        hourly_problems = defaultdict(list)
        
        for event in events:
            if event.event_type in ['auth_timeout', 'disconnect']:
                hour = datetime.fromtimestamp(event.timestamp).hour
                hourly_problems[hour].append(event)
        
        for hour, hour_events in hourly_problems.items():
            if len(hour_events) >= 5:
                patterns['time_based_issues'][hour] = {
                    'problem_count': len(hour_events),
                    'problem_types': list(set(e.event_type for e in hour_events)),
                    'affected_bssids': list(set(e.bssid for e in hour_events))
                }
    
    def _analyze_bssid_problems(self, events: List[ConnectionEvent], patterns: Dict):
        """Analyze per-BSSID specific problems"""
        bssid_events = defaultdict(list)
        
        for event in events:
            bssid_events[event.bssid].append(event)
        
        for bssid, bssid_event_list in bssid_events.items():
            problem_events = [e for e in bssid_event_list 
                            if e.event_type in ['auth_timeout', 'disconnect']]
            
            if len(problem_events) >= 3:
                patterns['bssid_specific_problems'][bssid] = {
                    'total_problems': len(problem_events),
                    'auth_failures': len([e for e in problem_events if e.event_type == 'auth_timeout']),
                    'disconnects': len([e for e in problem_events if e.event_type == 'disconnect']),
                    'problem_rate': len(problem_events) / len(bssid_event_list) if bssid_event_list else 0
                }

class NetworkAnalyzer:
    def __init__(self, interface: str):
        self.interface = interface
        self.signal_history = defaultdict(lambda: deque(maxlen=10))
        
        # Initialize logging first
        data_dir = self._get_data_dir()
        self.log_manager = LogManager(Path(data_dir))
        
        # Initialize components with logging
        self.history_tracker = HistoryTracker(data_dir, self.log_manager)
        self.mesh_intelligence = MeshIntelligence()
        self.problem_detector = ProblemDetector(self.history_tracker)
        self.connection_history = deque(maxlen=20)
        # Initialize optional modules - Matt is testing some new functionality -  the new detector classes
        self.roaming_detector = None
        self.power_detective = None
        
        if ROAMING_DETECTOR_AVAILABLE:
            self.roaming_detector = MeshRoamingDetector(self.interface)
            print("✅ Roaming detector module loaded")
        
        if POWER_DETECTIVE_AVAILABLE:
            self.power_detective = MeshPowerDetective(self.interface)
            print("✅ Power detective module loaded")
        
        # Log session start
        self.log_manager.log_analysis_start(interface)
        
        # Start background monitoring
        self._monitoring = True
        self._monitor_thread = threading.Thread(target=self._background_monitor, daemon=True)
        self._monitor_thread.start()
    
    def _format_power_data_for_html(self, power_issues):
        """Format power issues data for HTML reporter"""
        if not power_issues:
            return {'issues_found': False}
        
        # Count issues by severity
        severity_counts = {'high': 0, 'medium': 0, 'low': 0, 'info': 0}
        total_issues = 0
        
        for category_issues in power_issues.values():
            for issue in category_issues:
                severity = issue.get('severity', 'low')
                if severity in severity_counts:
                    severity_counts[severity] += 1
                total_issues += 1
        
        return {
            'issues_found': total_issues > 0,
            'severity_counts': severity_counts,
            'total_issues': total_issues
        }
    
    def _get_data_dir(self) -> str:
        """Get data directory path"""
        if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
            sudo_user = os.environ['SUDO_USER']
            import pwd
            real_user_home = pwd.getpwnam(sudo_user).pw_dir
            return os.path.join(real_user_home, ".mesh_analyzer")
        else:
            home = os.path.expanduser("~")
            return os.path.join(home, ".mesh_analyzer")
        
    def _background_monitor(self):
        """Background thread to monitor connection events"""
        last_connection = None
        connection_start = None
        
        while self._monitoring:
            try:
                current = self.get_current_connection()
                
                if current and (not last_connection or current['bssid'] != last_connection['bssid']):
                    # New connection
                    if last_connection and connection_start:
                        duration = time.time() - connection_start
                        self.history_tracker.record_event(ConnectionEvent(
                            timestamp=time.time(),
                            bssid=last_connection['bssid'],
                            event_type='disconnect',
                            signal=last_connection['signal'],
                            duration=duration
                        ))
                    
                    if current:
                        self.history_tracker.record_event(ConnectionEvent(
                            timestamp=time.time(),
                            bssid=current['bssid'],
                            event_type='connect',
                            signal=current['signal']
                        ))
                        connection_start = time.time()
                        last_connection = current
                
                elif not current and last_connection:
                    # Disconnected
                    if connection_start:
                        duration = time.time() - connection_start
                        self.history_tracker.record_event(ConnectionEvent(
                            timestamp=time.time(),
                            bssid=last_connection['bssid'],
                            event_type='disconnect',
                            signal=last_connection['signal'],
                            duration=duration
                        ))
                    last_connection = None
                    connection_start = None
                
                time.sleep(10)  # Check every 10 seconds
                
            except Exception:
                time.sleep(30)

    def run_cmd(self, cmd: str, timeout: int = 8) -> str:
        """Execute command with timeout and logging"""
        try:
            start_time = time.time()
            result = subprocess.run(cmd, shell=True, text=True, 
                                  capture_output=True, timeout=timeout)
            duration = time.time() - start_time
            
            output = result.stdout.strip()
            if self.log_manager:
                self.log_manager.log_command_execution(cmd, output, duration)
            
            return output
        except Exception as e:
            if self.log_manager:
                self.log_manager.log_error(e, f"run_cmd: {cmd}")
            return ""

    def get_current_connection(self) -> Optional[Dict]:
        """Get current connection details"""
        link_output = self.run_cmd(f"iw dev {self.interface} link")
        if "Connected to" not in link_output:
            return None
            
        bssid_match = re.search(r"Connected to ([0-9A-Fa-f:]{17})", link_output)
        ssid_match = re.search(r"SSID:\s*(.*)", link_output)
        freq_match = re.search(r"freq:\s*(\d+)", link_output)
        signal_match = re.search(r"signal:\s*(-?\d+)", link_output)
        
        if not all([bssid_match, ssid_match, freq_match]):
            return None
        
        # Clean BSSID
        bssid_raw = bssid_match.group(1)
        bssid_clean = bssid_raw.split('(')[0].strip().upper()
        
        if len(bssid_clean) != 17 or bssid_clean.count(':') != 5:
            return None
            
        return {
            'ssid': ssid_match.group(1).strip(),
            'bssid': bssid_clean,
            'freq': int(freq_match.group(1)),
            'signal': int(signal_match.group(1)) if signal_match else -100
        }

    def comprehensive_scan(self) -> List[APScan]:
        """Perform detailed network scan with logging"""
        scan_start_time = time.time()
        aps = {}
        current_time = time.time()
        
        # Primary scan with iw
        scan_output = self.run_cmd(f"iw dev {self.interface} scan flush", timeout=15)
        if not scan_output:
            scan_output = self.run_cmd(f"iw dev {self.interface} scan", timeout=12)
        
        current_ap = {}
        for line in scan_output.split('\n'):
            line = line.strip()
            
            if line.startswith('BSS '):
                if current_ap and 'bssid' in current_ap:
                    ap = self._parse_ap_data(current_ap, current_time)
                    if ap and ap.ssid != '<hidden>':  # Filter hidden SSIDs
                        aps[ap.bssid] = ap
                        
                # Extract BSSID
                bss_part = line[4:].strip()
                if len(bss_part) >= 17:
                    bssid = bss_part[:17].upper()
                    if bssid.count(':') == 5:
                        current_ap = {'bssid': bssid, 'capabilities': set()}
                    else:
                        current_ap = {}
                else:
                    current_ap = {}
                
            elif current_ap:
                if 'SSID:' in line:
                    current_ap['ssid'] = line.split('SSID: ', 1)[1] if ': ' in line else ''
                elif 'freq:' in line:
                    freq_match = re.search(r'freq: (\d+)', line)
                    if freq_match:
                        current_ap['freq'] = int(freq_match.group(1))
                elif 'signal:' in line:
                    signal_match = re.search(r'signal: (-?\d+\.\d+)', line)
                    if signal_match:
                        current_ap['signal'] = int(float(signal_match.group(1)))
        
        # Handle last AP
        if current_ap and 'bssid' in current_ap:
            ap = self._parse_ap_data(current_ap, current_time)
            if ap and ap.ssid != '<hidden>':
                aps[ap.bssid] = ap
        
        scan_duration = time.time() - scan_start_time
        ap_list = list(aps.values())
        
        # Log scan results
        if self.log_manager:
            self.log_manager.log_network_scan(len(ap_list), scan_duration)
        
        return ap_list

    def _parse_ap_data(self, ap_data: dict, timestamp: float) -> Optional[APScan]:
        """Create APScan from parsed data"""
        try:
            return APScan(
                ssid=ap_data.get('ssid', '<hidden>'),
                bssid=ap_data['bssid'],
                freq=ap_data.get('freq', 0),
                signal=ap_data.get('signal', -100),
                capabilities=ap_data.get('capabilities', set()),
                last_seen=timestamp
            )
        except KeyError:
            return None

    def _analyze_available_alternatives(self, current_conn: Dict) -> List[Dict]:
        """Analyze available BSSID alternatives with smarter band-aware scoring"""
        same_ssid_aps = [ap for ap in getattr(self, '_current_aps', []) if ap.ssid == current_conn['ssid']]
        
        alternatives = []
        current_bssid = current_conn['bssid'].upper()
        current_band = self._get_band_from_freq(current_conn['freq'])
        current_signal = current_conn['signal']
        
        for ap in same_ssid_aps:
            if ap.bssid.upper() == current_bssid:
                continue
                
            # Get historical performance
            history = self.history_tracker.get_bssid_performance(ap.bssid)
            alt_band = self._get_band_from_freq(ap.freq)
            
            # Score this alternative with smarter logic
            score = 100
            recommendation_reasons = []
            
            # Historical performance scoring
            if history and history.stability_score > 0:
                score += min(history.stability_score * 0.3, 30)
                recommendation_reasons.append(f"Stability: {history.stability_score:.0f}%")
            else:
                recommendation_reasons.append("No historical data")
            
            # Smart signal evaluation - consider both strength and band capabilities
            signal_diff = ap.signal - current_signal
            
            # Only recommend if there's a compelling reason
            compelling_reason = False
            
            # Case 1: Significantly stronger signal (>15dB) on any band
            if signal_diff > 15:
                score += 25
                compelling_reason = True
                recommendation_reasons.append(f"Major signal boost (+{signal_diff}dB)")
            
            # Case 2: Current signal is weak (<-70dBm) and alternative is stronger
            elif current_signal < -70 and signal_diff > 5:
                score += 20
                compelling_reason = True
                recommendation_reasons.append(f"Escape weak signal zone (+{signal_diff}dB)")
            
            # Case 3: Moving to 5GHz from 2.4GHz with good signal
            elif current_band == '2.4GHz' and alt_band == '5GHz' and ap.signal > -65:
                score += 15
                compelling_reason = True
                recommendation_reasons.append(f"5GHz upgrade opportunity ({ap.signal}dBm)")
            
            # Case 4: Current 6GHz signal is marginal (<-60dBm) and 5GHz/2.4GHz is much stronger
            elif current_band == '6GHz' and current_signal < -60 and signal_diff > 10:
                score += 10
                compelling_reason = True
                recommendation_reasons.append(f"6GHz signal marginal, better alternative (+{signal_diff}dB)")
            
            # Otherwise, be conservative about recommendations
            else:
                # Penalize downgrades from high-performance bands with good signals
                if current_band == '6GHz' and current_signal > -60 and alt_band in ['2.4GHz', '5GHz']:
                    score -= 30
                    recommendation_reasons.append(f"Potential speed downgrade from {current_band}")
                elif current_band == '5GHz' and current_signal > -65 and alt_band == '2.4GHz':
                    score -= 20
                    recommendation_reasons.append(f"Potential speed downgrade from {current_band}")
                else:
                    recommendation_reasons.append(f"Minimal benefit (+{signal_diff}dB)")
            
            # Band-specific bonuses only when it makes sense
            if alt_band == '5GHz' and (current_band == '2.4GHz' or (current_band == '6GHz' and current_signal < -65)):
                score += 5
                recommendation_reasons.append("Good speed/range balance")
            elif alt_band == '6GHz' and current_band != '6GHz' and ap.signal > -55:
                score += 10
                recommendation_reasons.append("Maximum speed potential")
            elif alt_band == '2.4GHz' and current_signal < -75:
                score += 5
                recommendation_reasons.append("Better range/penetration")
            
            # Signal quality assessment
            if ap.signal > -50:
                recommendation_reasons.append(f"Excellent signal ({ap.signal}dBm)")
            elif ap.signal > -60:
                recommendation_reasons.append(f"Good signal ({ap.signal}dBm)")
            elif ap.signal > -70:
                recommendation_reasons.append(f"Fair signal ({ap.signal}dBm)")
            else:
                recommendation_reasons.append(f"Weak signal ({ap.signal}dBm)")
                score -= 15
            
            # Determine overall recommendation based on compelling reasons
            if compelling_reason and score >= 120:
                recommendation = "EXCELLENT"
            elif compelling_reason and score >= 100:
                recommendation = "GOOD"
            elif score >= 90:
                recommendation = "FAIR"
            else:
                recommendation = "POOR"
            
            alternatives.append({
                'bssid': ap.bssid,
                'signal': ap.signal,
                'freq': ap.freq,
                'score': score,
                'recommendation': recommendation,
                'reasons': recommendation_reasons,
                'signal_diff': signal_diff,
                'stability_score': history.stability_score if history else None,
                'compelling_reason': compelling_reason,
                'band': alt_band
            })
        
        # Sort by score (best first)
        alternatives.sort(key=lambda x: x['score'], reverse=True)
        return alternatives[:5]  # Show top 5

    def _get_band_from_freq(self, freq: int) -> str:
        """Get band name from frequency"""
        if 2400 <= freq <= 2500:
            return '2.4GHz'
        elif 5000 <= freq <= 5999:
            return '5GHz'
        elif 6000 <= freq <= 7125:
            return '6GHz'
        else:
            return f'{freq}MHz'

    def generate_html_report(self):
        """Generate interactive HTML report of mesh analysis with Venn overlap"""
        try:
            print("\n🌐 GENERATING HTML REPORT")
            print("─" * 60)
            
            # Get current connection
            current_conn = self.get_current_connection()
            
            # Use existing scan data or perform new scan
            if not hasattr(self, '_current_aps') or not self._current_aps:
                print("🔍 Scanning networks for HTML report...")
                aps = self.comprehensive_scan()
                self._current_aps = aps
            else:
                aps = self._current_aps
            
            # Prepare comprehensive analysis data
            analysis_data = {}
            
            if current_conn:
                same_ssid_aps = [ap for ap in aps if ap.ssid == current_conn['ssid']]
                
                # Mesh topology analysis
                print("📊 Analyzing mesh topology...")
                mesh_analysis = self.mesh_intelligence.analyze_mesh_topology(same_ssid_aps)
                analysis_data['mesh_analysis'] = mesh_analysis
                
                # Alternative options analysis
                if len(same_ssid_aps) > 1:
                    print("🔍 Evaluating alternatives...")
                    alternatives = self._analyze_available_alternatives(current_conn)
                    analysis_data['alternatives'] = alternatives
                else:
                    analysis_data['alternatives'] = []
                
                # Historical performance data
                print("📈 Gathering historical data...")
                current_history = self.history_tracker.get_bssid_performance(current_conn['bssid'])
                if current_history:
                    analysis_data['historical_data'] = {
                        'stability_score': current_history.stability_score,
                        'total_connections': current_history.total_connections,
                        'success_rate': (current_history.successful_connections / max(current_history.total_connections, 1) * 100),
                        'avg_signal': current_history.avg_signal,
                        'auth_failures': current_history.auth_failures,
                        'disconnects': current_history.disconnects
                    }
                else:
                    analysis_data['historical_data'] = {}
                
                # Problem pattern detection
                print("🚨 Detecting problems...")
                problems = self.problem_detector.analyze_connection_patterns(24)
                analysis_data['problems'] = problems
            else:
                # No connection - provide empty data
                analysis_data = {
                    'mesh_analysis': {'type': 'no_connection'},
                    'alternatives': [],
                    'historical_data': {},
                    'problems': {}
                }
            
            # Include roaming and power data if available
            analysis_data['roaming_data'] = getattr(self, 'roaming_data', {})
            analysis_data['power_data'] = getattr(self, 'power_data', {})
            
            # Generate the HTML report
            print("📝 Generating HTML visualization with mesh overlap analysis...")
            
            # Check if we have the updated HTML reporter
            if UPDATED_HTML_REPORTER_AVAILABLE:
                reporter = MeshHTMLReporter()
                report_path = reporter.generate_report(analysis_data, current_conn)
            else:
                # Fallback to basic HTML generation
                report_path = self._generate_basic_html_report(analysis_data, current_conn)
            
            if report_path:
                print(f"✅ HTML Report Generated Successfully!")
                print(f"   📁 Location: {report_path}")
                print(f"   🌐 Open in browser: file://{report_path}")
                print(f"   📊 Report includes: mesh topology, signal analysis, recommendations, historical data")
                
                # Log the report generation
                if self.log_manager:
                    self.log_manager.analysis_logger.info(f"HTML report generated: {report_path}")
            else:
                print("❌ Failed to generate HTML report")
            
            return report_path
            
        except Exception as e:
            print(f"❌ Error generating HTML report: {e}")
            if hasattr(self, 'log_manager'):
                self.log_manager.log_error(e, "generate_html_report")
            import traceback
            traceback.print_exc()
            return None

    def _generate_basic_html_report(self, analysis_data, current_conn):
        """Fallback basic HTML report generator"""
        try:
            from datetime import datetime
            from pathlib import Path
            
            # Create reports directory - FIXED: Use same logic as data_dir for consistency
            data_dir = Path(self._get_data_dir())
            reports_dir = data_dir / "reports" 
            reports_dir.mkdir(parents=True, exist_ok=True)
            
            # Fix permissions if running as sudo
            if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
                sudo_user = os.environ['SUDO_USER']
                import pwd
                user_info = pwd.getpwnam(sudo_user)
                os.chown(reports_dir, user_info.pw_uid, user_info.pw_gid)
            
            # Generate filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"mesh_analysis_{timestamp}.html"
            report_path = reports_dir / filename
            
            # Basic HTML content
            html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WiFi Mesh Analysis Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }}
        .header {{ background: #2c3e50; color: white; padding: 20px; border-radius: 5px; text-align: center; margin-bottom: 20px; }}
        .section {{ margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }}
        .good {{ background: #d4edda; border-color: #c3e6cb; }}
        .warning {{ background: #fff3cd; border-color: #ffeaa7; }}
        .error {{ background: #f8d7da; border-color: #f5c6cb; }}
        pre {{ background: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>WiFi Mesh Network Analysis</h1>
            <p>Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        </div>
        
        <div class="section">
            <h2>Current Connection</h2>
            {self._format_connection_html(current_conn)}
        </div>
        
        <div class="section">
            <h2>Network Analysis</h2>
            {self._format_mesh_analysis_html(analysis_data.get('mesh_analysis', {}))}
        </div>
        
        <div class="section">
            <h2>Analysis Data</h2>
            <pre>{json.dumps(analysis_data, indent=2, default=str)}</pre>
        </div>
    </div>
</body>
</html>"""
            
            # Write file
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            return str(report_path)
            
        except Exception as e:
            print(f"❌ Error in basic HTML generation: {e}")
            return None

    def _format_connection_html(self, current_conn):
        """Format current connection for basic HTML"""
        if not current_conn:
            return "<p>Not connected to any network</p>"
        
        return f"""
        <p><strong>SSID:</strong> {current_conn.get('ssid', 'Unknown')}</p>
        <p><strong>BSSID:</strong> {current_conn.get('bssid', 'Unknown')}</p>
        <p><strong>Signal:</strong> {current_conn.get('signal', -100)} dBm</p>
        <p><strong>Frequency:</strong> {current_conn.get('freq', 0)} MHz</p>
        """

    def _format_mesh_analysis_html(self, mesh_analysis):
        """Format mesh analysis for basic HTML"""
        if not mesh_analysis:
            return "<p>No mesh analysis data available</p>"
        
        network_type = mesh_analysis.get('type', 'unknown')
        
        if network_type == 'mesh':
            return f"""
            <p><strong>Network Type:</strong> Mesh ({mesh_analysis.get('total_nodes', 0)} nodes)</p>
            <p><strong>Brand:</strong> {mesh_analysis.get('brand', 'Unknown')}</p>
            <p><strong>Mesh Type:</strong> {mesh_analysis.get('mesh_type', 'Unknown')}</p>
            <p><strong>Total Radios:</strong> {mesh_analysis.get('total_radios', 0)}</p>
            <p><strong>Bands:</strong> {', '.join(mesh_analysis.get('bands', []))}</p>
            <p><strong>Topology Health:</strong> {mesh_analysis.get('topology_health', 'Unknown')}</p>
            """
        else:
            return f"""
            <p><strong>Network Type:</strong> {network_type.replace('_', ' ').title()}</p>
            <p><strong>Signal Quality:</strong> {mesh_analysis.get('signal_quality', 'Unknown')}</p>
            """

    def run_analysis(self):
        """Run complete network analysis WITHOUT auto-generating HTML"""
        try:
            print("🧠 WiFi Mesh Network Analyzer")
            print("=" * 60)
            print("🔍 Analysis: Signal Intelligence • Mesh Topology • Historical Tracking • Pattern Recognition • Venn Overlap")
            print("=" * 60)
            
            # Get current connection
            current_conn = self.get_current_connection()
            print(f"📡 Interface: {self.interface}")
            
            if current_conn:
                print(f"🔗 Connected: {current_conn['ssid']} | {current_conn['bssid']} | " +
                      f"{current_conn['freq']} MHz | {current_conn['signal']} dBm")
            else:
                print("❌ Not connected to any network")
            print("")
            
            # Scan networks
            print("📊 NETWORK SCANNING")
            print("─" * 60)
            print("🔍 Scanning networks with historical analysis...")
            aps = self.comprehensive_scan()
            self._current_aps = aps
            print(f"📡 Found {len(aps)} access points")
            
            # Enhanced mesh analysis
            if current_conn:
                same_ssid_aps = [ap for ap in aps if ap.ssid == current_conn['ssid']]
                if len(same_ssid_aps) > 1:
                    print("\n📊 MESH INTELLIGENCE")
                    print("─" * 60)
                    mesh_analysis = self.mesh_intelligence.analyze_mesh_topology(same_ssid_aps)
                    
                    # Log mesh analysis
                    if self.log_manager:
                        self.log_manager.log_mesh_analysis(mesh_analysis)
                    
                    self._display_mesh_analysis(mesh_analysis, current_conn)
                else:
                    print("\n📊 SINGLE ACCESS POINT NETWORK")
                    print("─" * 60)
            
            # Historical performance analysis
            print("\n📊 HISTORICAL PERFORMANCE")
            print("─" * 60)
            self._display_historical_analysis(current_conn)
            
            # Smart problem detection
            print("\n📊 PROBLEM DETECTION")
            print("─" * 60)
            connection_patterns = self.problem_detector.analyze_connection_patterns(24)
            
            # Log problem detection
            if self.log_manager:
                self.log_manager.log_problems_detected(connection_patterns)
            
            self._display_pattern_analysis(connection_patterns)
            
            # Recommendations
            if current_conn and len(same_ssid_aps) > 1:
                print("\n📊 RECOMMENDATIONS")
                print("─" * 60)
                alternatives = self._analyze_available_alternatives(current_conn)
                
                # Log performance metrics and recommendations
                if self.log_manager:
                    self.log_manager.log_performance_metrics(current_conn, alternatives)
                    
                    # Create recommendation data for logging
                    recommendations = self._create_recommendations_data(alternatives, current_conn)
                    self.log_manager.log_recommendations(recommendations)
                
                self._display_recommendations(alternatives, current_conn)
        
        except Exception as e:
            print(f"❌ Analysis error: {e}")
            if self.log_manager:
                self.log_manager.log_error(e, "run_analysis")

    def _display_mesh_analysis(self, mesh_analysis: Dict, current_conn: Dict):
        """Display mesh analysis results with clear BSSID connections"""
        
        if mesh_analysis['type'] == 'single_ap':
            print(f"📡 Network Type: Single Access Point")
            if 'signal_quality' in mesh_analysis:
                quality = mesh_analysis['signal_quality'].replace('_', ' ').title()
                reason = mesh_analysis['signal_reason']
                
                if mesh_analysis['signal_quality'] == 'excellent':
                    emoji = "🟢"
                elif mesh_analysis['signal_quality'] == 'good':
                    emoji = "🟡"
                elif mesh_analysis['signal_quality'] == 'fair':
                    emoji = "🟠"
                else:
                    emoji = "🔴"
                
                print(f"📶 Signal Quality: {emoji} {quality}")
                print(f"   📊 Analysis: {reason}")
                
                if mesh_analysis['signal_quality'] in ['fair', 'poor']:
                    print(f"   💡 Recommendations:")
                    if mesh_analysis['signal_quality'] == 'poor':
                        print(f"      1. Move closer to the access point")
                        print(f"      2. Check for physical obstructions")
                        print(f"      3. Consider relocating the AP to a more central location")
                        print(f"      4. Verify AP placement is elevated and away from interference")
                    else:
                        print(f"      1. Minor positioning adjustments may help")
                        print(f"      2. Check for interference sources nearby")
            return
        
        elif mesh_analysis['type'] == 'multiple_aps':
            print(f"📡 Network Type: Multiple Access Points (Same SSID)")
            print(f"🏠 Configuration: {mesh_analysis['nodes']} standalone APs")
            
            quality = mesh_analysis['signal_quality'].replace('_', ' ').title()
            reason = mesh_analysis['signal_reason']
            
            if mesh_analysis['signal_quality'] == 'excellent':
                emoji = "🟢"
            elif mesh_analysis['signal_quality'] == 'good':
                emoji = "🟡"
            elif mesh_analysis['signal_quality'] == 'fair':
                emoji = "🟠"
            else:
                emoji = "🔴"
            
            print(f"📶 Coverage Quality: {emoji} {quality}")
            print(f"   📊 Analysis: {reason}")
            return
        
        # Mesh system analysis
        print(f"🏷️  Brand: {mesh_analysis.get('brand', 'Unknown').replace('_', ' ').title()}")
        print(f"🔧 Type: {mesh_analysis['mesh_type'].replace('_', '-').title()} Mesh")
        print(f"🏠 Topology: {mesh_analysis['total_nodes']} nodes, {mesh_analysis['total_radios']} radios")
        print(f"   ℹ️  Note: Only shows nodes visible from your current location")
        print(f"   📊 Why some nodes may be missing:")
        print(f"      • Distant nodes (basement, far rooms) may be too weak to detect")
        print(f"      • Nodes powered off or disconnected from mesh")
        print(f"      • Interference blocking weak signals from remote areas")
        print(f"      • Your device's WiFi antenna limitations")
        
        # Enhanced mesh topology analysis with spatial intelligence
        topology_health = mesh_analysis['topology_health'].replace('_', ' ').title()
        coverage_analysis = mesh_analysis.get('coverage_analysis', {})
        quality_score = coverage_analysis.get('coverage_quality_score', 0)
        
        if mesh_analysis['topology_health'] in ['excellent_topology', 'good_topology']:
            emoji = "🟢"
        elif mesh_analysis['topology_health'] == 'basic_topology':
            emoji = "🟡"
        else:
            emoji = "🟠"
        
        print(f"📶 Mesh Topology: {emoji} {topology_health} (Quality Score: {quality_score:.0f}/100)")
        print(f"   📊 Analysis: {mesh_analysis.get('coverage_reason', 'Analysis pending')}")
        
        # Show spatial coverage with current connection context
        zones = coverage_analysis.get('coverage_zones', {})
        mesh_nodes = mesh_analysis.get('mesh_nodes', {})
        
        if zones:
            print(f"\n🗺️  SPATIAL COVERAGE ANALYSIS:")
            print(f"   📍 Coverage Zones & Your Connection:")
            
            # Find which node/radio the user is connected to
            current_node_info = None
            current_radio_info = None
            
            for node_id, node_data in mesh_nodes.items():
                for radio in node_data.get('radios', []):
                    if radio['bssid'] == current_conn['bssid']:
                        current_node_info = node_data
                        current_radio_info = radio
                        break
                if current_node_info:
                    break
            
            # Display zones with current connection context
            if zones.get('primary'):
                signals = zones['primary']
                print(f"      🟢 Primary Zone: {len(signals)} nodes ({min(signals)} to {max(signals)}dBm)")
                print(f"         └─ Excellent coverage area (same room/very close)")
                
                if current_radio_info and current_radio_info['signal'] in signals:
                    print(f"         🔗 YOU ARE HERE: Connected to {current_conn['bssid']} at {current_conn['signal']}dBm")
                    if len(signals) > 1:
                        other_signals = [s for s in signals if s != current_conn['signal']]
                        if other_signals:
                            print(f"         💡 {len(other_signals)} other excellent nodes available in this zone")
            
            if zones.get('secondary'):
                signals = zones['secondary']
                print(f"      🟡 Secondary Zone: {len(signals)} nodes ({min(signals)} to {max(signals)}dBm)")
                print(f"         └─ Good coverage area (adjacent rooms/floors)")
                
                if current_radio_info and current_radio_info['signal'] in signals:
                    print(f"         🔗 YOU ARE HERE: Connected to {current_conn['bssid']} at {current_conn['signal']}dBm")
                    primary_available = len(zones.get('primary', []))
                    if primary_available > 0:
                        print(f"         💡 Consider moving closer - {primary_available} stronger nodes available")
            
            if zones.get('tertiary'):
                signals = zones['tertiary']
                print(f"      🟠 Tertiary Zone: {len(signals)} nodes ({min(signals)} to {max(signals)}dBm)")
                print(f"         └─ Extended coverage area (distant rooms)")
                
                if current_radio_info and current_radio_info['signal'] in signals:
                    print(f"         🔗 YOU ARE HERE: Connected to {current_conn['bssid']} at {current_conn['signal']}dBm")
                    better_zones = len(zones.get('primary', [])) + len(zones.get('secondary', []))
                    if better_zones > 0:
                        print(f"         💡 {better_zones} stronger nodes available - consider moving closer to mesh")
            
            if zones.get('fringe'):
                signals = zones['fringe']
                print(f"      🔴 Fringe Zone: {len(signals)} nodes ({min(signals)} to {max(signals)}dBm)")
                print(f"         └─ Maximum range coverage (basement/garage/far areas)")
                
                if current_radio_info and current_radio_info['signal'] in signals:
                    print(f"         🔗 YOU ARE HERE: Connected to {current_conn['bssid']} at {current_conn['signal']}dBm")
                    print(f"         ⚠️  You're at maximum range - consider moving closer for better performance")
                    better_zones = len(zones.get('primary', [])) + len(zones.get('secondary', [])) + len(zones.get('tertiary', []))
                    if better_zones > 0:
                        print(f"         💡 {better_zones} stronger nodes available")
            
            # If current connection not found in any zone, show fallback info
            if not current_radio_info:
                print(f"   🔗 Current Connection: {current_conn['bssid']} at {current_conn['signal']}dBm")
                print(f"      📊 Note: Unable to match current BSSID to detected mesh nodes")
        
        print(f"📡 Bands: {', '.join(mesh_analysis['bands'])}")
        
        # VENN DIAGRAM ANALYSIS - RESTORED!
        venn_analysis = mesh_analysis.get('venn_analysis', {})
        if venn_analysis and venn_analysis.get('venn_diagram'):
            print(f"\n🔄 VENN OVERLAP ANALYSIS:")
            overlap_quality = venn_analysis.get('overlap_quality', {})
            quality = overlap_quality.get('quality', 'unknown')
            score = overlap_quality.get('score', 0)
            
            if quality == 'excellent':
                quality_emoji = "🟢"
            elif quality == 'good':
                quality_emoji = "🟡"
            elif quality == 'fair':
                quality_emoji = "🟠"
            else:
                quality_emoji = "🔴"
            
            print(f"   {quality_emoji} Coverage Overlap Quality: {quality.title()} (Score: {score}/100)")
            print(f"   📊 {overlap_quality.get('description', 'No description available')}")
            
            venn_data = venn_analysis['venn_diagram']
            overlap_count = venn_data.get('overlap_count', 0)
            if overlap_count > 0:
                print(f"   🔗 Detected {overlap_count} node overlaps")
                overlaps = venn_data.get('overlaps', [])
                for overlap in overlaps[:3]:  # Show top 3 overlaps
                    print(f"      • {overlap.get('node1_label', 'Node')} ↔ {overlap.get('node2_label', 'Node')}: {overlap.get('overlap_percentage', 0):.1f}% overlap")
            else:
                print(f"   ⚠️  No significant node overlaps detected - potential coverage gaps")

    def _display_historical_analysis(self, current_conn: Optional[Dict]):
        """Display detailed historical performance analysis with context"""
        if not current_conn:
            print("📊 Connect to a network for historical analysis")
            return
        
        # Current BSSID history with detailed breakdown
        current_history = self.history_tracker.get_bssid_performance(current_conn['bssid'])
        if current_history:
            print(f"📈 Current BSSID Performance Analysis ({current_conn['bssid']}):")
            
            stability = current_history.stability_score
            if stability >= 90:
                stability_rating = "Excellent"
                stability_emoji = "🟢"
            elif stability >= 75:
                stability_rating = "Good"
                stability_emoji = "🟡"
            elif stability >= 60:
                stability_rating = "Fair" 
                stability_emoji = "🟠"
            else:
                stability_rating = "Poor"
                stability_emoji = "🔴"
            
            print(f"   {stability_emoji} Stability Score: {stability:.1f}/100 ({stability_rating})")
            print(f"   🔄 Connection History: {current_history.total_connections} total attempts")
            
            success_rate = (current_history.successful_connections/max(current_history.total_connections,1)*100)
            print(f"   ✅ Success Rate: {success_rate:.1f}%")
            
        else:
            print(f"📊 No historical data for current BSSID ({current_conn['bssid']})")
            print(f"   📝 This appears to be a new connection")

    def _display_pattern_analysis(self, patterns: Dict):
        """Display smart problem detection results"""
        total_issues = (len(patterns['roaming_loops']) + 
                       len(patterns['auth_failure_clusters']) + 
                       len(patterns['rapid_disconnects']))
        
        if total_issues == 0:
            print("✅ No problematic patterns detected")
        else:
            print(f"🚨 {total_issues} problematic patterns detected:")
            if patterns['roaming_loops']:
                print(f"   🔄 Roaming Loops: {len(patterns['roaming_loops'])}")
            if patterns['auth_failure_clusters']:
                print(f"   🔐 Auth Failure Clusters: {len(patterns['auth_failure_clusters'])}")
            if patterns['rapid_disconnects']:
                print(f"   ⚡ Rapid Reconnects: {len(patterns['rapid_disconnects'])}")

    def _display_recommendations(self, alternatives: List[Dict], current_conn: Dict):
        """Display smart, realistic recommendations"""
        if not alternatives:
            print("📊 Current BSSID appears to be the best available option")
            return
        
        best = alternatives[0]
        should_recommend = (
            best.get('compelling_reason', False) and 
            best['score'] > 110 and 
            (best['signal_diff'] > 5 or current_conn['signal'] < -70)
        )
        
        if should_recommend:
            print("💡 PERFORMANCE OPTIMIZATION OPPORTUNITY:")
            print(f"   🎯 Recommended BSSID: {best['bssid']}")
            print(f"   📈 Expected improvement: {best['signal_diff']:+d}dB signal strength")
            print(f"   🏆 Quality rating: {best['recommendation']}")
        else:
            print("✅ CURRENT CONNECTION IS OPTIMAL")
            print(f"   📊 Analysis: Your current connection is performing well")

    def _create_recommendations_data(self, alternatives: List[Dict], current_conn: Dict) -> Dict:
        """Create structured recommendation data for logging"""
        if not alternatives:
            return {'action_recommended': False, 'reason': 'No beneficial alternatives found'}
        
        best = alternatives[0]
        if best['score'] > 110 and best['signal_diff'] > 5:
            return {
                'action_recommended': True,
                'action': 'Switch to stronger radio/node',
                'target_bssid': best['bssid'],
                'signal_improvement': best['signal_diff'],
                'priority': 'HIGH' if best['signal_diff'] > 15 else 'MODERATE',
                'score': best['score']
            }
        else:
            return {'action_recommended': False, 'reason': 'Current connection is optimal'}

    def create_log_archive(self) -> str:
        """Create and return path to compressed log archive"""
        try:
            archive_path = self.log_manager.create_analysis_archive()
            if archive_path:
                print(f"\n📦 Log archive created: {archive_path}")
            return archive_path
        except Exception as e:
            print(f"❌ Error creating log archive: {e}")
            return ""

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="WiFi Mesh Network Analyzer - Analysis and Recommendations with Venn Overlap")
    parser.add_argument("--monitor", action="store_true", 
                       help="Continuous monitoring mode")
    parser.add_argument("--storage-info", action="store_true",
                       help="Show history storage information")
    parser.add_argument("--scan-interval", type=int, default=60,
                       help="Scan interval in seconds for monitoring mode (default: 60)")
    parser.add_argument("--reset-history", action="store_true",
                       help="Reset corrupted history files")
    parser.add_argument("--create-archive", action="store_true",
                       help="Create compressed archive of logs after analysis")
    parser.add_argument("--archive-only", action="store_true", 
                       help="Create archive without running new analysis")
    parser.add_argument("--html-report", action="store_true",
                       help="Generate interactive HTML report after analysis")
    # Here we go, folks, Matt adding more cool functionality to test in this bad boy - 5 new command-line options.
    parser.add_argument("--detect-dropouts", action="store_true",
                       help="Detect micro-dropouts and connection interruptions")
    parser.add_argument("--roaming-test", action="store_true", 
                       help="Run roaming quality test (walk around during test)")
    parser.add_argument("--monitor-roaming", action="store_true",
                       help="Continuously monitor roaming events")
    parser.add_argument("--check-power", action="store_true",
                       help="Check for WiFi power management issues")
    args = parser.parse_args()
    
    # Find Wi-Fi interface
    iface_cmd = ("nmcli -t --escape no -f DEVICE,TYPE device status "
                "| awk -F: '$2==\"wifi\"{print $1;exit}'")
    interface = subprocess.run(iface_cmd, shell=True, text=True, 
                              capture_output=True).stdout.strip()
    
    if not interface:
        print("❌ No Wi-Fi interface found")
        return
    
    analyzer = NetworkAnalyzer(interface)
    
    try:
        if args.archive_only:
            # Just create archive without new analysis
            print("📦 Creating log archive from existing data...")
            archive_path = analyzer.create_log_archive()
            if archive_path:
                print(f"✅ Archive ready: {archive_path}")
            else:
                print("❌ Failed to create archive")
                
        if args.storage_info:
            # Show storage information
            storage_info = {
                'storage_path': str(analyzer.history_tracker.data_dir),
                'bssid_count': len(analyzer.history_tracker.bssid_history),
                'event_count': len(analyzer.history_tracker.connection_events),
                'storage_exists': analyzer.history_tracker.data_dir.exists(),
                'history_file_exists': analyzer.history_tracker.history_file.exists(),
                'events_file_exists': analyzer.history_tracker.events_file.exists()
            }
            
            print("📁 Mesh Analyzer Storage Information")
            print("=" * 50)
            print(f"📂 Storage Location: {storage_info['storage_path']}")
            print(f"📊 BSSID Records: {storage_info['bssid_count']}")
            print(f"📈 Connection Events: {storage_info['event_count']}")
            print(f"💾 Directory Exists: {'✅' if storage_info['storage_exists'] else '❌'}")
            print(f"📄 History File: {'✅' if storage_info['history_file_exists'] else '❌'}")
            print(f"📄 Events File: {'✅' if storage_info['events_file_exists'] else '❌'}")
            
        if args.reset_history:
            # Reset corrupted history files
            print("🔄 Resetting Mesh Analyzer History")
            print("=" * 40)
            
            if analyzer.history_tracker.history_file.exists() or analyzer.history_tracker.events_file.exists():
                print("📦 Backing up existing files...")
                analyzer.history_tracker._backup_and_reset_corrupted_files()
                print("✅ History reset complete - fresh tracking will begin")
            else:
                print("📂 No existing history files found")
                print("💡 History tracking will start automatically on next run")
                
        if args.monitor:
            # Continuous monitoring mode
            print("🔄 Continuous monitoring mode (Ctrl+C to stop)")
            while True:
                analyzer.run_analysis()
                print(f"\n⏰ Next scan in {args.scan_interval} seconds...\n")
                time.sleep(args.scan_interval)
        
        # Matt adding yet more oddly commented features - roaming issue detection, redux.
        if args.detect_dropouts:
            if analyzer.roaming_detector:
                print("\n🔍 MICRO-DROPOUT DETECTION")
                print("=" * 60)
                analyzer.roaming_detector.detect_microdropouts(duration=30)
            else:
                print("❌ Roaming detector module not available")
                print("💡 Make sure mesh_roaming_detector.py is in the same directory")
                
        if args.roaming_test:
            if analyzer.roaming_detector:
                print("\n🚶 ROAMING QUALITY TEST")
                print("=" * 60)
                roaming_data = analyzer.roaming_detector.measure_roaming_performance(walk_test=True)
                analyzer.roaming_data = roaming_data
            else:
                print("❌ Roaming detector module not available")
                print("💡 Make sure mesh_roaming_detector.py is in the same directory")

        if args.monitor_roaming:
            if analyzer.roaming_detector:
                print("\n📊 CONTINUOUS ROAMING MONITOR")
                print("=" * 60)
                analyzer.roaming_detector.continuous_quality_monitor()
            else:
                print("❌ Roaming detector module not available")
                print("💡 Make sure mesh_roaming_detector.py is in the same directory")

        # Matt adding yet more poorly commented features - scan of all WiFi power management settings. 
        if args.check_power:
            if analyzer.power_detective:
                print("\n🔋 WIFI POWER MANAGEMENT CHECK")
                print("=" * 60)
                # Capture the power issues data
                power_issues = analyzer.power_detective.check_all_power_issues()
                
                # Format and store for HTML reporter
                analyzer.power_data = analyzer._format_power_data_for_html(power_issues)
                
            else:
                print("❌ Power detective module not available")
                print("💡 Make sure mesh_power_detective.py is in the same directory")
        
        if args.html_report:
            # Generate HTML report after analysis - FIXED: No duplicate generation
            analyzer.run_analysis()
            print("\n" + "="*60)
            analyzer.generate_html_report()
            
        elif not any([args.archive_only, args.storage_info, args.reset_history, args.monitor, 
                     args.detect_dropouts, args.roaming_test, args.monitor_roaming, args.check_power]):
            # Default: Single analysis run only if no other options specified
            analyzer.run_analysis()
            
            # Create archive if requested
            if args.create_archive:
                print("\n" + "="*60)
                archive_path = analyzer.create_log_archive()
                if archive_path:
                    print(f"✅ Analysis complete with archived logs: {archive_path}")
                else:
                    print("⚠️ Analysis complete but archive creation failed")
                    
    except KeyboardInterrupt:
        analyzer._monitoring = False
        print("\n👋 Analysis stopped")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        if hasattr(analyzer, 'log_manager'):
            analyzer.log_manager.log_error(e, "main")

if __name__ == "__main__":
    main()
