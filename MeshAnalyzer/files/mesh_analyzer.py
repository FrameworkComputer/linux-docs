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

class MeshHTMLReporter:
    """Generate interactive HTML reports from mesh analysis data"""
    
    def __init__(self, output_dir: str = None):
        if output_dir is None:
            # Use same directory structure as main analyzer
            import os
            if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
                sudo_user = os.environ['SUDO_USER']
                import pwd
                real_user_home = pwd.getpwnam(sudo_user).pw_dir
                output_dir = os.path.join(real_user_home, ".mesh_analyzer", "reports")
            else:
                home = os.path.expanduser("~")
                output_dir = os.path.join(home, ".mesh_analyzer", "reports")
        
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize Venn calculator
        self.venn_calc = MeshVennCalculator()
        
        # Fix permissions if running as sudo
        if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
            sudo_user = os.environ['SUDO_USER']
            import pwd
            user_info = pwd.getpwnam(sudo_user)
            os.chown(self.output_dir, user_info.pw_uid, user_info.pw_gid)
    
    def generate_report(self, analysis_data: Dict, current_connection: Optional[Dict] = None) -> str:
        """Generate complete HTML report from analysis data"""
        
        # Extract mesh analysis results
        mesh_analysis = analysis_data.get('mesh_analysis', {})
        alternatives = analysis_data.get('alternatives', [])
        historical_data = analysis_data.get('historical_data', {})
        problems = analysis_data.get('problems', {})
        
        # Determine report type and generate appropriate HTML
        if mesh_analysis.get('type') == 'mesh':
            html_content = self._generate_mesh_report(
                mesh_analysis, alternatives, current_connection, historical_data, problems
            )
        elif mesh_analysis.get('type') == 'single_ap':
            html_content = self._generate_single_ap_report(
                mesh_analysis, current_connection, historical_data
            )
        else:
            html_content = self._generate_multiple_ap_report(
                mesh_analysis, alternatives, current_connection, historical_data
            )
        
        # Save report with timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        filename = f"mesh_analysis_{timestamp}.html"
        filepath = self.output_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        # Fix file permissions if running as sudo
        import os
        if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
            sudo_user = os.environ['SUDO_USER']
            import pwd
            user_info = pwd.getpwnam(sudo_user)
            os.chown(filepath, user_info.pw_uid, user_info.pw_gid)
        
        return str(filepath)
    
    def _generate_mesh_report(self, mesh_analysis: Dict, alternatives: List[Dict], 
                            current_conn: Optional[Dict], historical_data: Dict, 
                            problems: Dict) -> str:
        """Generate HTML for mesh network analysis"""
        
        # Extract zone data correctly
        coverage_analysis = mesh_analysis.get('coverage_analysis', {})
        zones = coverage_analysis.get('coverage_zones', {})
        mesh_nodes = mesh_analysis.get('mesh_nodes', {})
        
        # Process nodes into visualization format
        nodes_data = self._process_mesh_nodes(mesh_nodes, current_conn, zones)
        
        # Generate Venn diagram data using the calculator
        venn_data = self.venn_calc.generate_venn_data(nodes_data)
        overlap_assessment = self.venn_calc.get_overlap_quality_assessment(venn_data)
        
        # Generate coverage issues summary
        issues_summary = self._format_coverage_issues(coverage_analysis.get('coverage_issues', []))
        
        # Create recommendations summary
        recommendations = self._format_recommendations(alternatives, current_conn)
        
        # Historical performance summary
        historical_summary = self._format_historical_data(historical_data)
        
        # Problem detection summary
        problems_summary = self._format_problems(problems)
        
        # Format overlap analysis
        overlap_summary = self._format_overlap_analysis(overlap_assessment, venn_data)
        
        html = self._get_base_html_template()
        
        # Replace template variables
        html = html.replace('{{TITLE}}', f"WiFi Mesh Analysis - {mesh_analysis.get('brand', 'Unknown').title()} Network")
        html = html.replace('{{MESH_TYPE}}', mesh_analysis.get('mesh_type', 'unknown').replace('_', '-').title())
        html = html.replace('{{TOTAL_NODES}}', str(mesh_analysis.get('total_nodes', 0)))
        html = html.replace('{{TOTAL_RADIOS}}', str(mesh_analysis.get('total_radios', 0)))
        html = html.replace('{{TOPOLOGY_HEALTH}}', mesh_analysis.get('topology_health', 'unknown').replace('_', ' ').title())
        html = html.replace('{{QUALITY_SCORE}}', str(coverage_analysis.get('coverage_quality_score', 0)))
        html = html.replace('{{NODES_DATA}}', json.dumps(nodes_data))
        html = html.replace('{{ZONES_DATA}}', json.dumps(zones))
        html = html.replace('{{VENN_DATA}}', json.dumps(venn_data))
        html = html.replace('{{CURRENT_CONNECTION}}', json.dumps(current_conn or {}))
        html = html.replace('{{ISSUES_SUMMARY}}', issues_summary)
        html = html.replace('{{RECOMMENDATIONS}}', recommendations)
        html = html.replace('{{HISTORICAL_SUMMARY}}', historical_summary)
        html = html.replace('{{PROBLEMS_SUMMARY}}', problems_summary)
        html = html.replace('{{OVERLAP_SUMMARY}}', overlap_summary)
        html = html.replace('{{TIMESTAMP}}', datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        return html
    
    def _process_mesh_nodes(self, mesh_nodes: Dict, current_conn: Optional[Dict], zones: Dict) -> List[Dict]:
        """Process mesh nodes into visualization format"""
        nodes_data = []
        node_positions = self._calculate_node_positions(len(mesh_nodes))
        
        for i, (base_mac, node_info) in enumerate(mesh_nodes.items()):
            strongest_signal = node_info.get('strongest_signal', -100)
            
            # Determine zone based on signal strength (matching your algorithm)
            if strongest_signal > -50:
                zone = 'primary'
            elif strongest_signal > -65:
                zone = 'secondary'
            elif strongest_signal > -80:
                zone = 'tertiary'
            else:
                zone = 'fringe'
            
            # Check if this is the current connection
            is_current = False
            if current_conn:
                for radio in node_info.get('radios', []):
                    if radio.get('bssid') == current_conn.get('bssid'):
                        is_current = True
                        break
            
            nodes_data.append({
                'id': i + 1,
                'base_mac': base_mac,
                'label': f"Node {i + 1}",
                'signal': strongest_signal,
                'zone': zone,
                'current': is_current,
                'position': node_positions[i],
                'radios': node_info.get('radios', []),
                'bands': list(node_info.get('bands', []))
            })
        
        return nodes_data
    
    def _calculate_node_positions(self, node_count: int) -> List[Dict]:
        """Calculate optimal positions for nodes in the visualization"""
        positions = []
        
        if node_count == 1:
            positions = [{'x': 50, 'y': 50}]
        elif node_count == 2:
            positions = [
                {'x': 30, 'y': 40},
                {'x': 70, 'y': 60}
            ]
        elif node_count == 3:
            positions = [
                {'x': 25, 'y': 30},
                {'x': 50, 'y': 60},
                {'x': 75, 'y': 35}
            ]
        elif node_count == 4:
            positions = [
                {'x': 25, 'y': 25},
                {'x': 50, 'y': 40},
                {'x': 75, 'y': 65},
                {'x': 85, 'y': 85}
            ]
        else:
            # For more than 4 nodes, distribute in a spiral
            import math
            angle_step = 2 * math.pi / node_count
            for i in range(node_count):
                angle = i * angle_step
                radius = 30 + (i * 10)  # Increasing radius
                x = 50 + radius * math.cos(angle)
                y = 50 + radius * math.sin(angle)
                positions.append({
                    'x': max(10, min(90, x)),
                    'y': max(10, min(90, y))
                })
        
        return positions
    
    def _format_coverage_issues(self, issues: List[Dict]) -> str:
        """Format coverage issues for HTML display"""
        if not issues:
            return "<div class='no-issues'>✅ No significant coverage issues detected</div>"
        
        html_parts = ["<div class='issues-list'>"]
        
        for issue in issues:
            severity_class = f"issue-{issue.get('severity', 'low')}"
            severity_emoji = {
                'high': '🔴',
                'medium': '🟡', 
                'low': '🟠'
            }.get(issue.get('severity', 'low'), '🟠')
            
            html_parts.append(f"""
                <div class='issue-item {severity_class}'>
                    <div class='issue-header'>
                        {severity_emoji} {issue.get('type', '').replace('_', ' ').title()}
                    </div>
                    <div class='issue-details'>{issue.get('details', '')}</div>
                    <div class='issue-impact'>Impact: {issue.get('impact', '')}</div>
                    {f"<div class='issue-location'>Location: {issue.get('location', '')}</div>" if issue.get('location') else ''}
                </div>
            """)
        
        html_parts.append("</div>")
        return '\n'.join(html_parts)
    
    def _format_recommendations(self, alternatives: List[Dict], current_conn: Optional[Dict]) -> str:
        """Format recommendations for HTML display"""
        if not alternatives:
            return "<div class='no-recommendations'>✅ Current connection is optimal</div>"
        
        best = alternatives[0]
        
        if not best.get('compelling_reason', False) or best.get('score', 0) < 110:
            return "<div class='no-recommendations'>✅ Current connection is performing well - no changes recommended</div>"
        
        html_parts = ["<div class='recommendations-list'>"]
        
        html_parts.append(f"""
            <div class='recommendation-main'>
                <h4>💡 Recommended Optimization</h4>
                <div class='rec-target'>Target: {best.get('bssid', '')}</div>
                <div class='rec-improvement'>Signal: {current_conn.get('signal', 0)}dBm → {best.get('signal', 0)}dBm ({best.get('signal_diff', 0):+d}dB)</div>
                <div class='rec-rating'>Rating: {best.get('recommendation', 'Unknown')}</div>
                <div class='rec-reasons'>
                    <strong>Reasons:</strong>
                    <ul>
                        {''.join(f"<li>{reason}</li>" for reason in best.get('reasons', []))}
                    </ul>
                </div>
            </div>
        """)
        
        if len(alternatives) > 1:
            html_parts.append("<div class='alternative-options'><h5>Other Options:</h5>")
            for alt in alternatives[1:3]:  # Show top 2 alternatives
                html_parts.append(f"""
                    <div class='alt-option'>
                        <span class='alt-bssid'>{alt.get('bssid', '')}</span>
                        <span class='alt-signal'>{alt.get('signal', 0)}dBm ({alt.get('signal_diff', 0):+d}dB)</span>
                        <span class='alt-rating'>{alt.get('recommendation', '')}</span>
                    </div>
                """)
            html_parts.append("</div>")
        
        html_parts.append("</div>")
        return '\n'.join(html_parts)
    
    def _format_historical_data(self, historical_data: Dict) -> str:
        """Format historical performance data"""
        if not historical_data:
            return "<div class='no-history'>📊 No historical data available</div>"
        
        stability = historical_data.get('stability_score', 0)
        total_connections = historical_data.get('total_connections', 0)
        success_rate = historical_data.get('success_rate', 0)
        avg_signal = historical_data.get('avg_signal', 0)
        
        stability_class = 'excellent' if stability >= 90 else 'good' if stability >= 75 else 'fair' if stability >= 60 else 'poor'
        
        return f"""
            <div class='historical-summary'>
                <div class='history-item'>
                    <span class='history-label'>Stability Score:</span>
                    <span class='history-value stability-{stability_class}'>{stability:.1f}/100</span>
                </div>
                <div class='history-item'>
                    <span class='history-label'>Success Rate:</span>
                    <span class='history-value'>{success_rate:.1f}%</span>
                </div>
                <div class='history-item'>
                    <span class='history-label'>Total Connections:</span>
                    <span class='history-value'>{total_connections}</span>
                </div>
                <div class='history-item'>
                    <span class='history-label'>Average Signal:</span>
                    <span class='history-value'>{avg_signal:.1f}dBm</span>
                </div>
            </div>
        """
    
    def _format_problems(self, problems: Dict) -> str:
        """Format detected problems"""
        if not problems:
            return "<div class='no-problems'>✅ No problematic patterns detected</div>"
        
        total_issues = (len(problems.get('roaming_loops', [])) + 
                       len(problems.get('auth_failure_clusters', [])) + 
                       len(problems.get('rapid_disconnects', [])))
        
        if total_issues == 0:
            return "<div class='no-problems'>✅ No problematic patterns detected</div>"
        
        html_parts = [f"<div class='problems-summary'>🚨 {total_issues} issues detected:"]
        
        if problems.get('roaming_loops'):
            html_parts.append(f"<div class='problem-item'>🔄 Roaming Loops: {len(problems['roaming_loops'])}</div>")
        
        if problems.get('auth_failure_clusters'):
            html_parts.append(f"<div class='problem-item'>🔐 Auth Failure Clusters: {len(problems['auth_failure_clusters'])}</div>")
        
        if problems.get('rapid_disconnects'):
            html_parts.append(f"<div class='problem-item'>⚡ Rapid Reconnects: {len(problems['rapid_disconnects'])}</div>")
        
        html_parts.append("</div>")
        return '\n'.join(html_parts)
    
    def _format_overlap_analysis(self, overlap_assessment: Dict, venn_data: Dict) -> str:
        """Format mesh overlap analysis"""
        quality = overlap_assessment.get('quality', 'unknown')
        score = overlap_assessment.get('score', 0)
        description = overlap_assessment.get('description', 'No overlap analysis available')
        
        quality_emoji = {
            'excellent': '🟢',
            'good': '🟡',
            'fair': '🟠',
            'poor': '🔴',
            'single_node': '⚪'
        }.get(quality, '⚪')
        
        html_parts = [f"<div class='overlap-analysis'>"]
        html_parts.append(f"<div class='overlap-score'>{quality_emoji} Overlap Quality: {quality.title()} ({score}/100)</div>")
        html_parts.append(f"<div class='overlap-description'>{description}</div>")
        
        overlaps = venn_data.get('overlaps', [])
        if overlaps:
            html_parts.append("<div class='overlap-details'><strong>Node Overlaps:</strong>")
            for overlap in overlaps[:5]:  # Show top 5 overlaps
                html_parts.append(f"<div class='overlap-item'>• {overlap['node1_label']} ↔ {overlap['node2_label']}: {overlap['overlap_percentage']:.1f}% overlap</div>")
            html_parts.append("</div>")
        
        html_parts.append("</div>")
        return '\n'.join(html_parts)
    
    def _generate_single_ap_report(self, mesh_analysis: Dict, current_conn: Optional[Dict], historical_data: Dict) -> str:
        """Generate HTML for single AP analysis"""
        # Use the basic template with simplified data
        quality = mesh_analysis.get('signal_quality', 'unknown')
        signal_strength = mesh_analysis.get('signal_strength', -100)
        reason = mesh_analysis.get('signal_reason', 'No analysis available')
        
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Single AP Analysis</title>
    <style>
        body {{ font-family: 'Segoe UI', sans-serif; margin: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }}
        .container {{ max-width: 800px; margin: 0 auto; background: rgba(255,255,255,0.95); border-radius: 20px; padding: 30px; }}
        h1 {{ text-align: center; color: #2c3e50; }}
        .card {{ background: #f8f9fa; padding: 20px; border-radius: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Single Access Point Analysis</h1>
        <div class="card">
            <h3>📶 Signal Quality: {quality.replace('_', ' ').title()}</h3>
            <p><strong>Signal Strength:</strong> {signal_strength}dBm</p>
            <p><strong>Analysis:</strong> {reason}</p>
        </div>
        <div class="card">
            <h3>📈 Historical Performance</h3>
            {self._format_historical_data(historical_data)}
        </div>
    </div>
</body>
</html>"""
        return html
    
    def _generate_multiple_ap_report(self, mesh_analysis: Dict, alternatives: List[Dict], 
                                   current_conn: Optional[Dict], historical_data: Dict) -> str:
        """Generate HTML for multiple standalone APs"""
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Multiple APs Analysis</title>
    <style>
        body {{ font-family: 'Segoe UI', sans-serif; margin: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }}
        .container {{ max-width: 1000px; margin: 0 auto; background: rgba(255,255,255,0.95); border-radius: 20px; padding: 30px; }}
        h1 {{ text-align: center; color: #2c3e50; }}
        .card {{ background: #f8f9fa; padding: 20px; border-radius: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Multiple Access Points Analysis ({mesh_analysis.get('nodes', 0)} APs)</h1>
        <div class="card">
            <h3>💡 Recommendations</h3>
            {self._format_recommendations(alternatives, current_conn)}
        </div>
        <div class="card">
            <h3>📈 Historical Performance</h3>
            {self._format_historical_data(historical_data)}
        </div>
    </div>
</body>
</html>"""
        return html
    
    def _get_base_html_template(self) -> str:
        """Get the main HTML template for mesh analysis"""
        return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITLE}}</title>
    <style>
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
        }
        
        h1 {
            text-align: center;
            color: #2c3e50;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }
        
        .mesh-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .info-card {
            background: linear-gradient(135deg, #f8f9fa, #e9ecef);
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            border-left: 5px solid #3498db;
        }
        
        .info-title {
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
        }
        
        .info-value {
            font-size: 1.2em;
            color: #34495e;
        }
        
        .visualization-container {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .chart-container {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            border: 2px solid #e3f2fd;
        }
        
        .chart-title {
            font-size: 1.4em;
            font-weight: bold;
            margin-bottom: 20px;
            color: #2c3e50;
            text-align: center;
        }
        
        .signal-map {
            position: relative;
            width: 100%;
            height: 400px;
            background: linear-gradient(45deg, #f0f2f5 25%, transparent 25%), 
                        linear-gradient(-45deg, #f0f2f5 25%, transparent 25%), 
                        linear-gradient(45deg, transparent 75%, #f0f2f5 75%), 
                        linear-gradient(-45deg, transparent 75%, #f0f2f5 75%);
            background-size: 20px 20px;
            background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
            border-radius: 15px;
            border: 3px solid #34495e;
            overflow: hidden;
        }
        
        .node {
            position: absolute;
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            color: white;
            font-size: 11px;
            text-shadow: 1px 1px 2px rgba(0,0,0,0.7);
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        
        .node:hover {
            transform: scale(1.2);
            z-index: 100;
        }
        
        .node.primary { background: radial-gradient(circle, #27ae60, #16a085); }
        .node.secondary { background: radial-gradient(circle, #f39c12, #e67e22); }
        .node.tertiary { background: radial-gradient(circle, #e74c3c, #c0392b); }
        .node.fringe { background: radial-gradient(circle, #8e44ad, #6c3483); }
        .node.current { 
            background: radial-gradient(circle, #3498db, #2980b9);
            animation: currentPulse 2s infinite;
            border: 3px solid #fff;
        }
        
        @keyframes currentPulse {
            0% { box-shadow: 0 0 0 0 rgba(52, 152, 219, 0.7); }
            70% { box-shadow: 0 0 0 20px rgba(52, 152, 219, 0); }
            100% { box-shadow: 0 0 0 0 rgba(52, 152, 219, 0); }
        }
        
        .coverage-circle {
            position: absolute;
            border-radius: 50%;
            opacity: 0.15;
            pointer-events: none;
            border: 2px solid rgba(255,255,255,0.3);
        }
        
        .coverage-primary { background: radial-gradient(circle, rgba(39, 174, 96, 0.3), transparent 70%); }
        .coverage-secondary { background: radial-gradient(circle, rgba(243, 156, 18, 0.3), transparent 70%); }
        .coverage-tertiary { background: radial-gradient(circle, rgba(231, 76, 60, 0.3), transparent 70%); }
        .coverage-fringe { background: radial-gradient(circle, rgba(142, 68, 173, 0.3), transparent 70%); }
        
        .signal-bar-chart {
            display: flex;
            align-items: end;
            gap: 20px;
            height: 300px;
            padding: 20px;
            background: linear-gradient(to top, #ecf0f1 0%, #bdc3c7 100%);
            border-radius: 10px;
        }
        
        .signal-bar {
            flex: 1;
            background: linear-gradient(to top, #e74c3c, #f1c40f, #27ae60);
            border-radius: 8px 8px 0 0;
            position: relative;
            min-height: 20px;
            transition: all 0.3s ease;
            cursor: pointer;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        
        .signal-bar:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.3);
        }
        
        .signal-label {
            position: absolute;
            bottom: -50px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 11px;
            font-weight: bold;
            color: #2c3e50;
            text-align: center;
            width: 100px;
            line-height: 1.2;
        }
        
        .signal-value {
            position: absolute;
            top: -35px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0,0,0,0.8);
            color: white;
            padding: 5px 8px;
            border-radius: 5px;
            font-size: 12px;
            font-weight: bold;
            opacity: 0;
            transition: opacity 0.3s ease;
            white-space: nowrap;
        }
        
        .signal-bar:hover .signal-value {
            opacity: 1;
        }
        
        .venn-diagram {
            position: relative;
            width: 100%;
            height: 400px;
            overflow: hidden;
            background: linear-gradient(45deg, #f9f9f9 25%, transparent 25%), 
                        linear-gradient(-45deg, #f9f9f9 25%, transparent 25%), 
                        linear-gradient(45deg, transparent 75%, #f9f9f9 75%), 
                        linear-gradient(-45deg, transparent 75%, #f9f9f9 75%);
            background-size: 15px 15px;
            border-radius: 15px;
            border: 2px solid #ddd;
        }
        
        .venn-node {
            position: absolute;
            border-radius: 50%;
            opacity: 0.4;
            border: 3px solid;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 12px;
            color: white;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
            transition: opacity 0.3s ease;
            cursor: pointer;
        }
        
        .venn-node:hover {
            opacity: 0.7;
            z-index: 10;
        }
        
        .venn-primary { 
            background: rgba(39, 174, 96, 0.4);
            border-color: #27ae60;
        }
        .venn-secondary { 
            background: rgba(243, 156, 18, 0.4);
            border-color: #f39c12;
        }
        .venn-tertiary { 
            background: rgba(231, 76, 60, 0.4);
            border-color: #e74c3c;
        }
        .venn-fringe { 
            background: rgba(142, 68, 173, 0.4);
            border-color: #8e44ad;
        }
        
        .venn-current {
            border-color: #3498db !important;
            border-width: 5px !important;
            animation: vennPulse 2s infinite;
        }
        
        @keyframes vennPulse {
            0% { box-shadow: 0 0 0 0 rgba(52, 152, 219, 0.4); }
            70% { box-shadow: 0 0 0 15px rgba(52, 152, 219, 0); }
            100% { box-shadow: 0 0 0 0 rgba(52, 152, 219, 0); }
        }
        
        .legend {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px;
            background: linear-gradient(135deg, #f8f9fa, #e9ecef);
            border-radius: 10px;
            border-left: 4px solid;
        }
        
        .legend-primary { border-left-color: #27ae60; }
        .legend-secondary { border-left-color: #f39c12; }
        .legend-tertiary { border-left-color: #e74c3c; }
        .legend-fringe { border-left-color: #8e44ad; }
        .legend-current { border-left-color: #3498db; }
        
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        
        .summary-section {
            background: linear-gradient(135deg, #e8f5e8, #f0f8f0);
            border: 2px solid #27ae60;
            border-radius: 15px;
            padding: 20px;
            margin-top: 30px;
        }
        
        .summary-title {
            font-size: 1.3em;
            font-weight: bold;
            color: #27ae60;
            margin-bottom: 15px;
        }
        
        .tooltip {
            position: absolute;
            background: rgba(0,0,0,0.9);
            color: white;
            padding: 10px;
            border-radius: 8px;
            font-size: 12px;
            pointer-events: none;
            z-index: 1000;
            opacity: 0;
            transition: opacity 0.3s ease;
            max-width: 200px;
        }
        
        .timestamp {
            text-align: center;
            color: #7f8c8d;
            margin-top: 20px;
            font-style: italic;
        }
        
        @media (max-width: 768px) {
            .visualization-container, .mesh-info {
                grid-template-columns: 1fr;
            }
            
            .container {
                padding: 15px;
            }
            
            h1 {
                font-size: 2em;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>{{TITLE}}</h1>
        
        <div class="mesh-info">
            <div class="info-card">
                <div class="info-title">Mesh Type</div>
                <div class="info-value">{{MESH_TYPE}}</div>
            </div>
            <div class="info-card">
                <div class="info-title">Total Nodes</div>
                <div class="info-value">{{TOTAL_NODES}}</div>
            </div>
            <div class="info-card">
                <div class="info-title">Total Radios</div>
                <div class="info-value">{{TOTAL_RADIOS}}</div>
            </div>
            <div class="info-card">
                <div class="info-title">Topology Health</div>
                <div class="info-value">{{TOPOLOGY_HEALTH}}</div>
            </div>
            <div class="info-card">
                <div class="info-title">Quality Score</div>
                <div class="info-value">{{QUALITY_SCORE}}/100</div>
            </div>
        </div>
        
        <div class="visualization-container">
            <div class="chart-container">
                <div class="chart-title">🗺️ Mesh Network Topology</div>
                <div class="signal-map" id="signalMap">
                    <div class="tooltip" id="tooltip"></div>
                </div>
            </div>
            
            <div class="chart-container">
                <div class="chart-title">📊 Signal Strength Distribution</div>
                <div class="signal-bar-chart" id="signalChart"></div>
            </div>
            
            <div class="chart-container">
                <div class="chart-title">🔗 Mesh Coverage Overlap</div>
                <div class="venn-diagram" id="vennDiagram">
                    <div class="tooltip" id="vennTooltip"></div>
                </div>
            </div>
        </div>
        
        <div class="legend">
            <div class="legend-item legend-primary">
                <div class="legend-color" style="background: radial-gradient(circle, #27ae60, #16a085);"></div>
                <span><strong>Primary Zone:</strong> > -50dBm (Excellent)</span>
            </div>
            <div class="legend-item legend-secondary">
                <div class="legend-color" style="background: radial-gradient(circle, #f39c12, #e67e22);"></div>
                <span><strong>Secondary Zone:</strong> -50 to -65dBm (Good)</span>
            </div>
            <div class="legend-item legend-tertiary">
                <div class="legend-color" style="background: radial-gradient(circle, #e74c3c, #c0392b);"></div>
                <span><strong>Tertiary Zone:</strong> -65 to -80dBm (Fair)</span>
            </div>
            <div class="legend-item legend-fringe">
                <div class="legend-color" style="background: radial-gradient(circle, #8e44ad, #6c3483);"></div>
                <span><strong>Fringe Zone:</strong> < -80dBm (Poor)</span>
            </div>
            <div class="legend-item legend-current">
                <div class="legend-color" style="background: radial-gradient(circle, #3498db, #2980b9);"></div>
                <span><strong>Current Connection:</strong> Active mesh node</span>
            </div>
        </div>
        
        <div class="summary-section">
            <div class="summary-title">🔗 Mesh Overlap Analysis</div>
            {{OVERLAP_SUMMARY}}
        </div>
        
        <div class="summary-section">
            <div class="summary-title">📊 Coverage Issues</div>
            {{ISSUES_SUMMARY}}
        </div>
        
        <div class="summary-section">
            <div class="summary-title">💡 Recommendations</div>
            {{RECOMMENDATIONS}}
        </div>
        
        <div class="summary-section">
            <div class="summary-title">📈 Historical Performance</div>
            {{HISTORICAL_SUMMARY}}
        </div>
        
        <div class="summary-section">
            <div class="summary-title">🚨 Problem Detection</div>
            {{PROBLEMS_SUMMARY}}
        </div>
        
        <div class="timestamp">Generated: {{TIMESTAMP}}</div>
    </div>

    <script>
        // Data from Python analysis
        const nodesData = {{NODES_DATA}};
        const zonesData = {{ZONES_DATA}};
        const vennData = {{VENN_DATA}};
        const currentConnection = {{CURRENT_CONNECTION}};

        function signalToBarHeight(signal) {
            return Math.max(20, (signal + 100) * 2.8);
        }

        function updateSignalMap() {
            const map = document.getElementById('signalMap');
            map.innerHTML = '<div class="tooltip" id="tooltip"></div>';
            
            nodesData.forEach(node => {
                // Add coverage circle
                const coverage = document.createElement('div');
                coverage.className = `coverage-circle coverage-${node.zone}`;
                const radius = Math.max(60, (node.signal + 100) * 1.8);
                coverage.style.width = `${radius}px`;
                coverage.style.height = `${radius}px`;
                coverage.style.left = `${node.position.x}%`;
                coverage.style.top = `${node.position.y}%`;
                coverage.style.transform = 'translate(-50%, -50%)';
                map.appendChild(coverage);
                
                // Add node marker
                const nodeEl = document.createElement('div');
                nodeEl.className = `node ${node.zone} ${node.current ? 'current' : ''}`;
                nodeEl.style.left = `${node.position.x}%`;
                nodeEl.style.top = `${node.position.y}%`;
                nodeEl.style.transform = 'translate(-50%, -50%)';
                
                nodeEl.innerHTML = `
                    <div style="font-size: 11px;">${node.signal}dBm</div>
                    <div style="font-size: 9px;">${node.zone.toUpperCase()}</div>
                `;
                
                nodeEl.addEventListener('mouseenter', (e) => {
                    const tooltip = document.getElementById('tooltip');
                    const zoneDescription = {
                        'primary': 'Excellent (same room)',
                        'secondary': 'Good (adjacent room)', 
                        'tertiary': 'Fair (extended range)',
                        'fringe': 'Poor (maximum range)'
                    };
                    
                    tooltip.innerHTML = `
                        <strong>${node.label}</strong><br>
                        Base MAC: ${node.base_mac}<br>
                        Signal: ${node.signal}dBm<br>
                        Zone: ${zoneDescription[node.zone]}<br>
                        Radios: ${node.radios.length}<br>
                        Bands: ${node.bands.join(', ')}<br>
                        ${node.current ? '<strong>CURRENT CONNECTION</strong>' : ''}
                    `;
                    tooltip.style.opacity = '1';
                    tooltip.style.left = e.pageX + 10 + 'px';
                    tooltip.style.top = e.pageY - 10 + 'px';
                });
                
                nodeEl.addEventListener('mouseleave', () => {
                    document.getElementById('tooltip').style.opacity = '0';
                });
                
                map.appendChild(nodeEl);
            });
        }

        function updateSignalChart() {
            const chart = document.getElementById('signalChart');
            chart.innerHTML = '';
            
            const sortedNodes = [...nodesData].sort((a, b) => b.signal - a.signal);
            
            sortedNodes.forEach(node => {
                const bar = document.createElement('div');
                bar.className = 'signal-bar';
                bar.style.height = `${signalToBarHeight(node.signal)}px`;
                
                const colors = {
                    'primary': 'linear-gradient(to top, #27ae60, #2ecc71)',
                    'secondary': 'linear-gradient(to top, #f39c12, #f1c40f)',
                    'tertiary': 'linear-gradient(to top, #e74c3c, #ff6b6b)',
                    'fringe': 'linear-gradient(to top, #8e44ad, #9b59b6)'
                };
                bar.style.background = colors[node.zone];
                
                const label = document.createElement('div');
                label.className = 'signal-label';
                label.innerHTML = `${node.label}<br><strong>${node.zone.toUpperCase()}</strong>`;
                
                const value = document.createElement('div');
                value.className = 'signal-value';
                value.textContent = `${node.signal}dBm (${node.zone})`;
                
                bar.appendChild(label);
                bar.appendChild(value);
                chart.appendChild(bar);
            });
        }

        function updateVennDiagram() {
            const venn = document.getElementById('vennDiagram');
            venn.innerHTML = '<div class="tooltip" id="vennTooltip"></div>';
            
            if (!vennData.nodes || vennData.nodes.length < 2) {
                venn.innerHTML = '<div style="display: flex; align-items: center; justify-content: center; height: 100%; color: #666; font-size: 14px;">Need 2+ nodes for overlap diagram</div>';
                return;
            }
            
            // Use calculated Venn data from the calculator
            vennData.nodes.forEach((node) => {
                const vennNode = document.createElement('div');
                vennNode.className = `venn-node venn-${node.zone} ${node.current ? 'venn-current' : ''}`;
                
                // Use radius from calculator
                const radius = node.radius || 60;
                vennNode.style.width = `${radius}px`;
                vennNode.style.height = `${radius}px`;
                
                // Use position from calculator
                vennNode.style.left = `${node.position.x}%`;
                vennNode.style.top = `${node.position.y}%`;
                vennNode.style.transform = 'translate(-50%, -50%)';
                
                vennNode.innerHTML = `${node.label}<br>${node.signal}dBm`;
                
                vennNode.addEventListener('mouseenter', (e) => {
                    const tooltip = document.getElementById('vennTooltip');
                    const overlapsText = vennData.overlaps
                        .filter(o => o.node1_id === (node.id - 1) || o.node2_id === (node.id - 1))
                        .map(o => `${o.overlap_percentage.toFixed(1)}% with ${o.node1_id === (node.id - 1) ? o.node2_label : o.node1_label}`)
                        .join('<br>');
                    
                    tooltip.innerHTML = `
                        <strong>${node.label} Coverage</strong><br>
                        Signal: ${node.signal}dBm<br>
                        Zone: ${node.zone}<br>
                        Coverage: ~${Math.round(radius / 2)}m radius<br>
                        ${overlapsText ? `<br>Overlaps:<br>${overlapsText}` : 'No significant overlaps'}
                        ${node.current ? '<br><strong>CURRENT CONNECTION</strong>' : ''}
                    `;
                    tooltip.style.opacity = '1';
                    tooltip.style.left = e.pageX + 10 + 'px';
                    tooltip.style.top = e.pageY - 10 + 'px';
                });
                
                vennNode.addEventListener('mouseleave', () => {
                    document.getElementById('vennTooltip').style.opacity = '0';
                });
                
                venn.appendChild(vennNode);
            });
        }

        window.addEventListener('load', () => {
            updateSignalMap();
            updateSignalChart();
            updateVennDiagram();
        });
    </script>
</body>
</html>'''

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
            'eero': ['A0:21:B7', '68:1D:A0', 'B0:8E:86', 'F8:BB:BF', 'D8:8E:D4', 'E8:D3:EB'],
            'orbi_netgear': ['98:97:9A', '44:B1:3B', '9C:28:EF', 'A0:04:60', '04:A1:51'],
            'google_nest': ['A4:50:46', '64:FF:89', 'CC:52:AF', '6C:71:0D'],
            'asus': ['40:ED:00', '88:1F:A1', 'AC:9E:17', '2C:56:DC', '04:D4:C4'],
            'tp_link_deco': ['98:25:4A', '44:94:FC', 'B0:48:7A', '50:C7:BF', 'A4:2B:B0'],
            'linksys_velop': ['6C:BE:E9', '13:10:47', '98:9E:64', '94:10:3E', 'C4:41:1E'],
            'ubiquiti': ['78:8A:20', '24:5A:4C', 'F0:9F:C2', '44:D9:E7', 'E0:63:DA'],
            'mikrotik': ['6C:3B:6B', '48:8F:5A', '2C:C8:1B', '4C:5E:0C', 'E4:8D:8C'],
            'aruba_hpe': ['70:3A:CB', '6C:F3:7F', '24:DE:C6', '94:B4:0F', '20:4C:03'],
            'ruckus': ['50:91:E3', '2C:36:F8', '94:3E:EA', 'BC:14:85', '58:93:96'],
            'cisco_meraki': ['00:18:0A', 'E0:55:3D', '88:15:44', '0C:8D:DB', '34:56:FE'],
            'engenius': ['88:DC:96', '50:2B:73', '02:CF:7F', '00:02:6F'],
            'dlink': ['CC:B2:55', 'B8:A3:86', '34:08:04', '14:D6:4D', '84:C9:B2'],
            'netgear_general': ['10:0D:7F', '28:C6:8E', 'B0:7F:B9', '4C:60:DE'],
            'plume_adaptive': ['74:DA:88', '78:28:CA', 'A0:40:A0'],
            'xfinity_pods': ['A8:4E:3F', '00:35:1A', '8C:3B:AD'],
            'amazon_amplifi': ['74:C6:3B', 'E4:95:6E'],
            'tenda': ['C8:3A:35', 'FC:7C:02', '98:DE:D0'],
            'xiaomi_mesh': ['34:CE:00', '64:64:4A', 'F8:59:71'],
            'honor_huawei': ['00:E0:FC', '98:F4:28', 'A0:8C:FD']
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
            'coverage_analysis': coverage_analysis
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
        
        # Log session start
        self.log_manager.log_analysis_start(interface)
        
        # Start background monitoring
        self._monitoring = True
        self._monitor_thread = threading.Thread(target=self._background_monitor, daemon=True)
        self._monitor_thread.start()
    
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
                
                # Problem pattern detection
                print("🚨 Detecting problems...")
                problems = self.problem_detector.analyze_connection_patterns(24)
                analysis_data['problems'] = problems
            
            # Generate the HTML report with Venn overlap analysis
            print("📝 Generating HTML visualization with mesh overlap analysis...")
            reporter = MeshHTMLReporter()
            report_path = reporter.generate_report(analysis_data, current_conn)
            
            print(f"✅ HTML Report Generated Successfully!")
            print(f"   📁 Location: {report_path}")
            print(f"   🌐 Open in browser: file://{report_path}")
            print(f"   📊 Report includes: mesh topology, signal analysis, Venn overlap diagram, recommendations, historical data")
            
            # Log the report generation
            if self.log_manager:
                self.log_manager.analysis_logger.info(f"HTML report generated: {report_path}")
            
            return report_path
            
        except Exception as e:
            print(f"❌ Error generating HTML report: {e}")
            if hasattr(self, 'log_manager'):
                self.log_manager.log_error(e, "generate_html_report")
            return None

    def run_analysis(self):
        """Run complete network analysis"""
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
            
            # Generate HTML report automatically after analysis
            self.generate_html_report()
        
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
                
        elif args.storage_info:
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
            
        elif args.reset_history:
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
                
        elif args.monitor:
            # Continuous monitoring mode
            print("🔄 Continuous monitoring mode (Ctrl+C to stop)")
            while True:
                analyzer.run_analysis()
                print(f"\n⏰ Next scan in {args.scan_interval} seconds...\n")
                time.sleep(args.scan_interval)
        else:
            # Default: Single analysis run
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
