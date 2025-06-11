#!/usr/bin/env python3
"""
WiFi Mesh HTML Report Generator
Save this file as: mesh_html_reporter.py
Put it in the same folder as your main analyzer script
"""

import json
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import os

# Import the Venn calculator
try:
    from mesh_venn_calculator import MeshVennCalculator
except ImportError:
    # Fallback if file not found
    class MeshVennCalculator:
        def generate_venn_data(self, nodes_data):
            return {'nodes': nodes_data, 'overlaps': [], 'total_coverage': 0}
        def get_overlap_quality_assessment(self, venn_data):
            return {'quality': 'unknown', 'score': 0, 'description': 'Venn calculator not available'}

class MeshHTMLReporter:
    """Generate interactive HTML reports from mesh analysis data"""
    
    def __init__(self, output_dir: str = None):
        if output_dir is None:
            # Use same directory structure as main analyzer
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


# Integration function for your existing NetworkAnalyzer
def add_html_reporting_to_analyzer():
    """
    Function to integrate HTML reporting into your existing NetworkAnalyzer class.
    Call this after creating your NetworkAnalyzer instance.
    """
    
    def generate_html_report(self):
        """Add this method to your NetworkAnalyzer class"""
        try:
            # Get current connection
            current_conn = self.get_current_connection()
            
            # Perform scans and analysis
            aps = self.comprehensive_scan()
            self._current_aps = aps
            
            # Prepare analysis data
            analysis_data = {}
            
            if current_conn:
                same_ssid_aps = [ap for ap in aps if ap.ssid == current_conn['ssid']]
                
                # Mesh analysis
                mesh_analysis = self.mesh_intelligence.analyze_mesh_topology(same_ssid_aps)
                analysis_data['mesh_analysis'] = mesh_analysis
                
                # Alternatives analysis
                if len(same_ssid_aps) > 1:
                    alternatives = self._analyze_available_alternatives(current_conn)
                    analysis_data['alternatives'] = alternatives
                
                # Historical data
                current_history = self.history_tracker.get_bssid_performance(current_conn['bssid'])
                if current_history:
                    analysis_data['historical_data'] = {
                        'stability_score': current_history.stability_score,
                        'total_connections': current_history.total_connections,
                        'success_rate': (current_history.successful_connections / max(current_history.total_connections, 1) * 100),
                        'avg_signal': current_history.avg_signal
                    }
                
                # Problem detection
                problems = self.problem_detector.analyze_connection_patterns(24)
                analysis_data['problems'] = problems
            
            # Generate HTML report
            reporter = MeshHTMLReporter()
            report_path = reporter.generate_report(analysis_data, current_conn)
            
            print(f"\n📊 HTML REPORT GENERATED")
            print(f"   📁 Location: {report_path}")
            print(f"   🌐 Open in browser: file://{report_path}")
            
            return report_path
            
        except Exception as e:
            print(f"❌ Error generating HTML report: {e}")
            if hasattr(self, 'log_manager'):
                self.log_manager.log_error(e, "generate_html_report")
            return None
    
    return generate_html_report


if __name__ == "__main__":
    # Example usage - this would be called from your main script
    print("WiFi Mesh HTML Report Generator")
    print("This module is designed to integrate with your existing NetworkAnalyzer")
    print("Import and use add_html_reporting_to_analyzer() to add HTML reporting capability")
