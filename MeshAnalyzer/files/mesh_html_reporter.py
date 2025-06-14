#!/usr/bin/env python3
"""
Enhanced HTML Reporter for WiFi Mesh Analysis
- Beautiful, responsive HTML reports
- Mesh topology visualization with Venn overlap analysis
- Signal analysis and recommendations
- Roaming and power management integration
- Modern dark theme with glassmorphism design
"""

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

class MeshHTMLReporter:
    """Enhanced HTML reporter with roaming and power support"""
    
    def __init__(self):
        # FIXED: Use same logic as main analyzer for consistent user directory
        if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
            sudo_user = os.environ['SUDO_USER']
            import pwd
            real_user_home = pwd.getpwnam(sudo_user).pw_dir
            data_dir = os.path.join(real_user_home, ".mesh_analyzer")
        else:
            home = os.path.expanduser("~")
            data_dir = os.path.join(home, ".mesh_analyzer")
            
        self.report_dir = Path(data_dir) / "reports"
        self.report_dir.mkdir(parents=True, exist_ok=True)
        
        # Fix permissions if running as sudo
        if os.geteuid() == 0 and 'SUDO_USER' in os.environ:
            sudo_user = os.environ['SUDO_USER']
            import pwd
            user_info = pwd.getpwnam(sudo_user)
            os.chown(self.report_dir, user_info.pw_uid, user_info.pw_gid)
    
    def generate_report(self, analysis_data: Dict, current_connection: Optional[Dict] = None) -> str:
        """Generate comprehensive HTML report"""
        try:
            # Extract data components
            mesh_analysis = analysis_data.get('mesh_analysis', {})
            alternatives = analysis_data.get('alternatives', [])
            historical_data = analysis_data.get('historical_data', {})
            problems = analysis_data.get('problems', {})
            
            # Generate the complete HTML content - PASS analysis_data as the 6th parameter
            html_content = self._generate_mesh_report(
                mesh_analysis, alternatives, current_connection, historical_data, problems, analysis_data
            )
            
            # Create filename and save
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"mesh_analysis_{timestamp}.html"
            report_path = self.report_dir / filename
            
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            return str(report_path)
            
        except Exception as e:
            print(f"❌ Error in HTML reporter: {e}")
            import traceback
            traceback.print_exc()
            return ""
    
    def _generate_mesh_report(self, mesh_analysis: Dict, alternatives: List[Dict], 
                            current_connection: Optional[Dict], historical_data: Dict, 
                            problems: Dict, analysis_data: Dict) -> str:
        """Generate the complete mesh analysis HTML report - NOW WITH analysis_data PARAMETER"""
        
        # Get additional data from analysis_data - THIS IS WHAT WAS MISSING
        roaming_data = analysis_data.get('roaming_data', {})
        power_data = analysis_data.get('power_data', {})
        
        # Generate HTML sections
        current_connection_html = self._generate_current_connection_section(current_connection)
        mesh_topology_html = self._generate_mesh_topology_section(mesh_analysis)
        alternatives_html = self._generate_alternatives_section(alternatives, current_connection)
        historical_html = self._generate_historical_section(historical_data)
        problems_html = self._generate_problems_section(problems)
        roaming_html = self._generate_roaming_section(roaming_data)
        power_html = self._generate_power_section(power_data)
        
        # Get page title and summary
        if current_connection:
            page_title = f"Mesh Analysis - {current_connection.get('ssid', 'Unknown Network')}"
            network_name = current_connection.get('ssid', 'Unknown Network')
        else:
            page_title = "WiFi Mesh Analysis Report"
            network_name = "No Active Connection"
        
        # Generate the complete HTML
        html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{page_title}</title>
    <style>
        {self._get_modern_css()}
    </style>
</head>
<body>
    <div class="container">
        <header class="main-header">
            <div class="header-content">
                <h1><span class="wifi-icon">📡</span> WiFi Mesh Network Analysis</h1>
                <div class="network-info">
                    <h2>{network_name}</h2>
                    <p class="timestamp">Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                </div>
            </div>
        </header>

        <main class="content-grid">
            {current_connection_html}
            {mesh_topology_html}
            {alternatives_html}
            {historical_html}
            {problems_html}
            {roaming_html}
            {power_html}
        </main>

        <footer class="report-footer">
            <p>📊 Generated by WiFi Mesh Network Analyzer with Venn Overlap Analysis</p>
            <p>🔍 Analysis includes: Mesh topology, signal optimization, historical tracking, problem detection</p>
        </footer>
    </div>

    <script>
        {self._get_interactive_javascript()}
    </script>
</body>
</html>"""

        return html_template
    
    def _generate_current_connection_section(self, current_connection: Optional[Dict]) -> str:
        """Generate current connection status section"""
        if not current_connection:
            return """
            <section class="card no-connection">
                <h3><span class="icon">❌</span> Connection Status</h3>
                <div class="status-disconnected">
                    <p>Not connected to any WiFi network</p>
                    <div class="recommendation">
                        <p>💡 Connect to a WiFi network to enable mesh analysis</p>
                    </div>
                </div>
            </section>
            """
        
        signal = current_connection.get('signal', -100)
        if signal > -50:
            signal_class = "excellent"
            signal_emoji = "🟢"
        elif signal > -60:
            signal_class = "good"
            signal_emoji = "🟡"
        elif signal > -75:
            signal_class = "fair"
            signal_emoji = "🟠"
        else:
            signal_class = "poor"
            signal_emoji = "🔴"
        
        band = self._get_band_from_freq(current_connection.get('freq', 0))
        
        return f"""
        <section class="card connection-status">
            <h3><span class="icon">🔗</span> Current Connection</h3>
            <div class="connection-details">
                <div class="detail-row">
                    <span class="label">Network (SSID):</span>
                    <span class="value">{current_connection.get('ssid', 'Unknown')}</span>
                </div>
                <div class="detail-row">
                    <span class="label">Access Point (BSSID):</span>
                    <span class="value">{current_connection.get('bssid', 'Unknown')}</span>
                </div>
                <div class="detail-row">
                    <span class="label">Signal Strength:</span>
                    <span class="value signal-{signal_class}">{signal_emoji} {signal} dBm</span>
                </div>
                <div class="detail-row">
                    <span class="label">Frequency:</span>
                    <span class="value">{current_connection.get('freq', 0)} MHz ({band})</span>
                </div>
            </div>
        </section>
        """
    
    def _generate_mesh_topology_section(self, mesh_analysis: Dict) -> str:
        """Generate mesh topology analysis section"""
        if not mesh_analysis:
            return """
            <section class="card">
                <h3><span class="icon">🏠</span> Network Topology</h3>
                <p>No topology analysis available</p>
            </section>
            """
        
        network_type = mesh_analysis.get('type', 'unknown')
        
        if network_type == 'mesh':
            return self._generate_mesh_system_html(mesh_analysis)
        elif network_type == 'single_ap':
            return self._generate_single_ap_html(mesh_analysis)
        elif network_type == 'multiple_aps':
            return self._generate_multiple_aps_html(mesh_analysis)
        else:
            return f"""
            <section class="card">
                <h3><span class="icon">🏠</span> Network Topology</h3>
                <p>Network type: {network_type.replace('_', ' ').title()}</p>
            </section>
            """
    
    def _generate_mesh_system_html(self, mesh_analysis: Dict) -> str:
        """Generate HTML for mesh system analysis"""
        brand = mesh_analysis.get('brand', 'unknown').replace('_', ' ').title()
        mesh_type = mesh_analysis.get('mesh_type', 'unknown').replace('_', '-').title()
        total_nodes = mesh_analysis.get('total_nodes', 0)
        total_radios = mesh_analysis.get('total_radios', 0)
        bands = mesh_analysis.get('bands', [])
        
        # Get topology health status
        topology_health = mesh_analysis.get('topology_health', 'unknown')
        coverage_analysis = mesh_analysis.get('coverage_analysis', {})
        quality_score = coverage_analysis.get('coverage_quality_score', 0)
        
        if topology_health in ['excellent_topology', 'good_topology']:
            health_class = "excellent"
            health_emoji = "🟢"
        elif topology_health == 'basic_topology':
            health_class = "good"
            health_emoji = "🟡"
        else:
            health_class = "warning"
            health_emoji = "🟠"
        
        # Generate coverage zones visualization
        zones_html = ""
        zones = coverage_analysis.get('coverage_zones', {})
        if zones:
            zones_html = """
            <div class="coverage-zones">
                <h4>📍 Coverage Zones</h4>
                <div class="zones-grid">
            """
            
            for zone_name, signals in zones.items():
                if signals:
                    zone_emoji = {
                        'primary': '🟢',
                        'secondary': '🟡', 
                        'tertiary': '🟠',
                        'fringe': '🔴'
                    }.get(zone_name, '⚪')
                    
                    zone_title = zone_name.title()
                    signal_range = f"{min(signals)} to {max(signals)}dBm" if len(signals) > 1 else f"{signals[0]}dBm"
                    
                    zones_html += f"""
                    <div class="zone-card">
                        <div class="zone-header">
                            <span class="zone-icon">{zone_emoji}</span>
                            <span class="zone-name">{zone_title}</span>
                        </div>
                        <div class="zone-details">
                            <div class="zone-stat">{len(signals)} nodes</div>
                            <div class="zone-range">{signal_range}</div>
                        </div>
                    </div>
                    """
            
            zones_html += """
                </div>
            </div>
            """
        
        # Generate Venn diagram section - RESTORED WITH VISUAL SVG!
        venn_html = ""
        venn_analysis = mesh_analysis.get('venn_analysis', {})
        if venn_analysis and venn_analysis.get('venn_diagram'):
            venn_html = """
            <div class="venn-analysis">
                <h4>🔄 Venn Overlap Analysis</h4>
                <div class="venn-summary">
            """
            
            overlap_quality = venn_analysis.get('overlap_quality', {})
            quality = overlap_quality.get('quality', 'unknown')
            score = overlap_quality.get('score', 0)
            
            quality_class = {
                'excellent': 'excellent',
                'good': 'good', 
                'fair': 'warning',
                'poor': 'poor'
            }.get(quality, 'poor')
            
            venn_html += f"""
                    <div class="venn-quality {quality_class}">
                        <span class="quality-score">{score}/100</span>
                        <span class="quality-label">Overlap Quality</span>
                    </div>
                    <div class="venn-description">
                        <p>{overlap_quality.get('description', 'No description available')}</p>
                    </div>
                </div>
            """
            
            # Generate VISUAL SVG Venn diagram - THIS IS WHAT WAS MISSING!
            venn_data = venn_analysis['venn_diagram']
            overlaps = venn_data.get('overlaps', [])
            nodes = venn_data.get('nodes', [])
            
            if nodes and len(nodes) >= 2:
                venn_svg = self._generate_venn_svg(nodes, overlaps)
                venn_html += f"""
                <div class="venn-diagram-container">
                    <h5>Visual Coverage Overlap:</h5>
                    <div class="venn-svg-wrapper">
                        {venn_svg}
                    </div>
                </div>
                """
            
            # Show overlap details
            if overlaps:
                venn_html += """
                <div class="overlap-list">
                    <h5>Node Overlap Details:</h5>
                """
                for overlap in overlaps[:5]:  # Show top 5
                    overlap_pct = overlap.get('overlap_percentage', 0)
                    venn_html += f"""
                    <div class="overlap-item">
                        <span class="overlap-nodes">{overlap.get('node1_label', 'Node')} ↔ {overlap.get('node2_label', 'Node')}</span>
                        <span class="overlap-percentage">{overlap_pct:.1f}%</span>
                    </div>
                    """
                venn_html += "</div>"
            else:
                venn_html += """
                <div class="no-overlaps">
                    <p>⚠️ No significant overlaps detected - potential coverage gaps</p>
                </div>
                """
            
            venn_html += "</div>"
        
        # Generate mesh nodes details
        nodes_html = ""
        mesh_nodes = mesh_analysis.get('mesh_nodes', {})
        if mesh_nodes:
            nodes_html = """
            <div class="mesh-nodes">
                <h4>🏠 Detected Mesh Nodes</h4>
                <div class="nodes-grid">
            """
            
            for node_id, node_data in mesh_nodes.items():
                radios = node_data.get('radios', [])
                strongest_signal = node_data.get('strongest_signal', -100)
                
                if strongest_signal > -50:
                    node_class = "excellent"
                elif strongest_signal > -65:
                    node_class = "good"
                elif strongest_signal > -80:
                    node_class = "fair"
                else:
                    node_class = "poor"
                
                nodes_html += f"""
                <div class="node-card {node_class}">
                    <div class="node-header">
                        <h5>Node {node_id[-8:]}</h5>
                        <span class="node-signal">{strongest_signal}dBm</span>
                    </div>
                    <div class="node-radios">
                """
                
                for radio in radios:
                    band = self._get_band_from_freq(radio.get('freq', 0))
                    nodes_html += f"""
                        <div class="radio-info">
                            <span class="radio-band">{band}</span>
                            <span class="radio-signal">{radio.get('signal', -100)}dBm</span>
                        </div>
                    """
                
                nodes_html += """
                    </div>
                </div>
                """
            
            nodes_html += """
                </div>
            </div>
            """
        
        return f"""
        <section class="card mesh-topology">
            <h3><span class="icon">🏠</span> Mesh Network Topology</h3>
            
            <div class="topology-overview">
                <div class="topology-stats">
                    <div class="stat-item">
                        <span class="stat-label">Brand:</span>
                        <span class="stat-value">{brand}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Type:</span>
                        <span class="stat-value">{mesh_type} Mesh</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Nodes:</span>
                        <span class="stat-value">{total_nodes}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Radios:</span>
                        <span class="stat-value">{total_radios}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Bands:</span>
                        <span class="stat-value">{', '.join(bands)}</span>
                    </div>
                </div>
                
                <div class="topology-health {health_class}">
                    <div class="health-score">
                        <span class="health-emoji">{health_emoji}</span>
                        <span class="health-text">Health Score: {quality_score:.0f}/100</span>
                    </div>
                    <div class="health-status">{topology_health.replace('_', ' ').title()}</div>
                </div>
            </div>
            
            {zones_html}
            {venn_html}
            {nodes_html}
            
            <div class="topology-note">
                <p>ℹ️ Only shows nodes visible from your current location. Distant or weak nodes may not appear.</p>
            </div>
        </section>
        """
    
    def _generate_venn_svg(self, nodes: List[Dict], overlaps: List[Dict]) -> str:
        """Generate SVG Venn diagram visualization - THE MISSING VISUAL COMPONENT!"""
        if len(nodes) < 2:
            return "<p>Need at least 2 nodes for Venn diagram</p>"
        
        # SVG dimensions
        width = 400
        height = 300
        
        # Calculate circle positions and sizes based on signal strength
        circles = []
        for i, node in enumerate(nodes[:4]):  # Max 4 nodes for visual clarity
            signal = node.get('signal', -100)
            # Convert signal to radius (stronger signal = larger circle)
            radius = max(30, min(80, (100 + signal) * 2))
            
            # Position circles in a pattern
            if i == 0:
                x, y = width * 0.3, height * 0.4
            elif i == 1:
                x, y = width * 0.7, height * 0.4
            elif i == 2:
                x, y = width * 0.3, height * 0.7
            else:
                x, y = width * 0.7, height * 0.7
            
            # Color based on signal strength
            if signal > -50:
                color = "#4ade80"  # Green
                opacity = "0.6"
            elif signal > -65:
                color = "#fbbf24"  # Yellow
                opacity = "0.5"
            elif signal > -80:
                color = "#fb923c"  # Orange
                opacity = "0.4"
            else:
                color = "#f87171"  # Red
                opacity = "0.3"
            
            circles.append({
                'x': x, 'y': y, 'r': radius,
                'color': color, 'opacity': opacity,
                'label': node.get('label', f'Node {i+1}'),
                'signal': signal
            })
        
        # Generate SVG
        svg = f"""
        <svg width="{width}" height="{height}" viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <style>
                    .node-circle {{ stroke: #333; stroke-width: 2; }}
                    .node-label {{ font-family: Arial, sans-serif; font-size: 12px; fill: #333; text-anchor: middle; }}
                    .signal-label {{ font-family: Arial, sans-serif; font-size: 10px; fill: #666; text-anchor: middle; }}
                </style>
            </defs>
            
            <!-- Background -->
            <rect width="{width}" height="{height}" fill="#f8f9fa" stroke="#ddd" stroke-width="1" rx="10"/>
            
            <!-- Node circles -->
        """
        
        for circle in circles:
            svg += f"""
            <circle cx="{circle['x']}" cy="{circle['y']}" r="{circle['r']}" 
                    fill="{circle['color']}" fill-opacity="{circle['opacity']}" 
                    class="node-circle" />
            """
        
        # Add labels
        for circle in circles:
            svg += f"""
            <text x="{circle['x']}" y="{circle['y'] - 5}" class="node-label">{circle['label']}</text>
            <text x="{circle['x']}" y="{circle['y'] + 10}" class="signal-label">{circle['signal']}dBm</text>
            """
        
        # Add title
        svg += f"""
            <text x="{width/2}" y="25" style="font-family: Arial, sans-serif; font-size: 14px; font-weight: bold; fill: #333; text-anchor: middle;">
                Mesh Node Coverage Overlap
            </text>
            
            <!-- Legend -->
            <g transform="translate(10, {height - 60})">
                <text x="0" y="0" style="font-family: Arial, sans-serif; font-size: 10px; fill: #666;">Circle size = signal strength</text>
                <text x="0" y="15" style="font-family: Arial, sans-serif; font-size: 10px; fill: #666;">Overlapping areas = good coverage</text>
                <text x="0" y="30" style="font-family: Arial, sans-serif; font-size: 10px; fill: #666;">Colors: Green=Excellent, Yellow=Good, Orange=Fair, Red=Poor</text>
            </g>
        </svg>
        """
        
        return svg
    
    def _generate_single_ap_html(self, mesh_analysis: Dict) -> str:
        """Generate HTML for single access point"""
        signal_quality = mesh_analysis.get('signal_quality', 'unknown')
        signal_reason = mesh_analysis.get('signal_reason', 'No analysis available')
        
        if signal_quality == 'excellent':
            quality_class = "excellent"
            quality_emoji = "🟢"
        elif signal_quality == 'good':
            quality_class = "good"
            quality_emoji = "🟡"
        elif signal_quality == 'fair':
            quality_class = "warning"
            quality_emoji = "🟠"
        else:
            quality_class = "poor"
            quality_emoji = "🔴"
        
        return f"""
        <section class="card single-ap">
            <h3><span class="icon">📡</span> Single Access Point Network</h3>
            
            <div class="ap-analysis">
                <div class="quality-indicator {quality_class}">
                    <span class="quality-emoji">{quality_emoji}</span>
                    <span class="quality-text">{signal_quality.replace('_', ' ').title()}</span>
                </div>
                
                <div class="analysis-details">
                    <p>{signal_reason}</p>
                </div>
            </div>
        </section>
        """
    
    def _generate_multiple_aps_html(self, mesh_analysis: Dict) -> str:
        """Generate HTML for multiple access points"""
        nodes = mesh_analysis.get('nodes', 0)
        signal_quality = mesh_analysis.get('signal_quality', 'unknown')
        signal_reason = mesh_analysis.get('signal_reason', 'No analysis available')
        
        if signal_quality == 'excellent':
            quality_class = "excellent"
            quality_emoji = "🟢"
        elif signal_quality == 'good':
            quality_class = "good"
            quality_emoji = "🟡"
        elif signal_quality == 'fair':
            quality_class = "warning"
            quality_emoji = "🟠"
        else:
            quality_class = "poor"
            quality_emoji = "🔴"
        
        return f"""
        <section class="card multiple-aps">
            <h3><span class="icon">📡</span> Multiple Access Points</h3>
            
            <div class="aps-analysis">
                <div class="aps-count">
                    <span class="count-number">{nodes}</span>
                    <span class="count-label">Access Points</span>
                </div>
                
                <div class="quality-indicator {quality_class}">
                    <span class="quality-emoji">{quality_emoji}</span>
                    <span class="quality-text">{signal_quality.replace('_', ' ').title()}</span>
                </div>
                
                <div class="analysis-details">
                    <p>{signal_reason}</p>
                </div>
            </div>
        </section>
        """
    
    def _generate_alternatives_section(self, alternatives: List[Dict], current_connection: Optional[Dict]) -> str:
        """Generate alternatives analysis section"""
        if not alternatives or not current_connection:
            return """
            <section class="card alternatives">
                <h3><span class="icon">🎯</span> Connection Alternatives</h3>
                <div class="no-alternatives">
                    <p>✅ Current connection appears optimal or no alternatives available</p>
                </div>
            </section>
            """
        
        # Check if any alternatives are compelling
        compelling_alternatives = [alt for alt in alternatives if alt.get('compelling_reason', False)]
        
        alternatives_html = """
        <section class="card alternatives">
            <h3><span class="icon">🎯</span> Connection Alternatives</h3>
        """
        
        if compelling_alternatives:
            best = compelling_alternatives[0]
            alternatives_html += f"""
            <div class="recommendation-banner excellent">
                <div class="recommendation-header">
                    <span class="rec-icon">💡</span>
                    <span class="rec-title">Performance Optimization Opportunity</span>
                </div>
                <div class="recommendation-details">
                    <p><strong>Recommended BSSID:</strong> {best['bssid']}</p>
                    <p><strong>Expected Improvement:</strong> {best['signal_diff']:+d}dB signal strength</p>
                    <p><strong>Quality Rating:</strong> {best['recommendation']}</p>
                </div>
            </div>
            """
        else:
            alternatives_html += """
            <div class="recommendation-banner good">
                <div class="recommendation-header">
                    <span class="rec-icon">✅</span>
                    <span class="rec-title">Current Connection is Optimal</span>
                </div>
                <div class="recommendation-details">
                    <p>Your current connection is performing well among available options.</p>
                </div>
            </div>
            """
        
        # Show top alternatives
        alternatives_html += """
        <div class="alternatives-list">
            <h4>📊 Available Options</h4>
            <div class="alternatives-grid">
        """
        
        for i, alt in enumerate(alternatives[:3], 1):
            band = self._get_band_from_freq(alt.get('freq', 0))
            
            if alt['recommendation'] == 'EXCELLENT':
                alt_class = "excellent"
                alt_emoji = "🟢"
            elif alt['recommendation'] == 'GOOD':
                alt_class = "good"
                alt_emoji = "🟡"
            elif alt['recommendation'] == 'FAIR':
                alt_class = "fair"
                alt_emoji = "🟠"
            else:
                alt_class = "poor"
                alt_emoji = "🔴"
            
            reasons_html = ""
            for reason in alt.get('reasons', []):
                reasons_html += f"<li>{reason}</li>"
            
            alternatives_html += f"""
            <div class="alternative-card {alt_class}">
                <div class="alt-header">
                    <span class="alt-emoji">{alt_emoji}</span>
                    <span class="alt-title">Option {i}</span>
                    <span class="alt-rating">{alt['recommendation']}</span>
                </div>
                <div class="alt-details">
                    <div class="alt-stat">
                        <span class="stat-label">BSSID:</span>
                        <span class="stat-value">{alt['bssid']}</span>
                    </div>
                    <div class="alt-stat">
                        <span class="stat-label">Signal:</span>
                        <span class="stat-value">{alt['signal']}dBm ({band})</span>
                    </div>
                    <div class="alt-stat">
                        <span class="stat-label">Difference:</span>
                        <span class="stat-value">{alt['signal_diff']:+d}dB</span>
                    </div>
                    <div class="alt-stat">
                        <span class="stat-label">Score:</span>
                        <span class="stat-value">{alt['score']:.0f}/100</span>
                    </div>
                </div>
                <div class="alt-reasons">
                    <ul>{reasons_html}</ul>
                </div>
            </div>
            """
        
        alternatives_html += """
            </div>
        </div>
        </section>
        """
        
        return alternatives_html
    
    def _generate_historical_section(self, historical_data: Dict) -> str:
        """Generate historical performance section"""
        if not historical_data:
            return """
            <section class="card historical">
                <h3><span class="icon">📈</span> Historical Performance</h3>
                <div class="no-history">
                    <p>📊 No historical data available for current connection</p>
                    <p>🕐 Data will be collected over time for performance tracking</p>
                </div>
            </section>
            """
        
        stability_score = historical_data.get('stability_score', 0)
        success_rate = historical_data.get('success_rate', 0)
        total_connections = historical_data.get('total_connections', 0)
        avg_signal = historical_data.get('avg_signal', 0)
        
        if stability_score >= 90:
            stability_class = "excellent"
            stability_emoji = "🟢"
        elif stability_score >= 75:
            stability_class = "good"
            stability_emoji = "🟡"
        elif stability_score >= 60:
            stability_class = "fair"
            stability_emoji = "🟠"
        else:
            stability_class = "poor"
            stability_emoji = "🔴"
        
        return f"""
        <section class="card historical">
            <h3><span class="icon">📈</span> Historical Performance</h3>
            
            <div class="history-overview">
                <div class="stability-score {stability_class}">
                    <span class="stability-emoji">{stability_emoji}</span>
                    <div class="stability-details">
                        <span class="stability-number">{stability_score:.1f}/100</span>
                        <span class="stability-label">Stability Score</span>
                    </div>
                </div>
                
                <div class="history-stats">
                    <div class="history-stat">
                        <span class="stat-number">{success_rate:.1f}%</span>
                        <span class="stat-label">Success Rate</span>
                    </div>
                    <div class="history-stat">
                        <span class="stat-number">{total_connections}</span>
                        <span class="stat-label">Total Connections</span>
                    </div>
                    <div class="history-stat">
                        <span class="stat-number">{avg_signal:.0f}dBm</span>
                        <span class="stat-label">Avg Signal</span>
                    </div>
                </div>
            </div>
            
            <div class="history-note">
                <p>📊 Performance data collected over time from actual usage patterns</p>
            </div>
        </section>
        """
    
    def _generate_problems_section(self, problems: Dict) -> str:
        """Generate problems detection section"""
        if not problems:
            return """
            <section class="card problems">
                <h3><span class="icon">🚨</span> Problem Detection</h3>
                <div class="no-problems">
                    <p>✅ No problematic patterns detected in recent activity</p>
                </div>
            </section>
            """
        
        total_issues = (
            len(problems.get('roaming_loops', [])) +
            len(problems.get('auth_failure_clusters', [])) +
            len(problems.get('rapid_disconnects', []))
        )
        
        if total_issues == 0:
            return """
            <section class="card problems">
                <h3><span class="icon">🚨</span> Problem Detection</h3>
                <div class="no-problems">
                    <p>✅ No problematic patterns detected in recent activity</p>
                </div>
            </section>
            """
        
        problems_html = f"""
        <section class="card problems warning">
            <h3><span class="icon">🚨</span> Problem Detection</h3>
            
            <div class="problems-summary">
                <div class="problems-count">
                    <span class="count-number">{total_issues}</span>
                    <span class="count-label">Issues Detected</span>
                </div>
            </div>
            
            <div class="problems-list">
        """
        
        if problems.get('roaming_loops'):
            problems_html += f"""
                <div class="problem-item">
                    <span class="problem-icon">🔄</span>
                    <span class="problem-text">Roaming Loops: {len(problems['roaming_loops'])}</span>
                </div>
            """
        
        if problems.get('auth_failure_clusters'):
            problems_html += f"""
                <div class="problem-item">
                    <span class="problem-icon">🔐</span>
                    <span class="problem-text">Auth Failure Clusters: {len(problems['auth_failure_clusters'])}</span>
                </div>
            """
        
        if problems.get('rapid_disconnects'):
            problems_html += f"""
                <div class="problem-item">
                    <span class="problem-icon">⚡</span>
                    <span class="problem-text">Rapid Reconnects: {len(problems['rapid_disconnects'])}</span>
                </div>
            """
        
        problems_html += """
            </div>
        </section>
        """
        
        return problems_html
    
    def _generate_roaming_section(self, roaming_data: Dict) -> str:
        """Generate roaming analysis section"""
        if not roaming_data:
            return """
            <section class="card roaming">
                <h3><span class="icon">🚶</span> Roaming Analysis</h3>
                <div class="no-roaming-data">
                    <p>📊 No roaming analysis data available</p>
                    <p>💡 Use --roaming-test to generate roaming performance data</p>
                </div>
            </section>
            """
        
        return f"""
        <section class="card roaming">
            <h3><span class="icon">🚶</span> Roaming Analysis</h3>
            <div class="roaming-content">
                <p>🔍 Roaming analysis data available</p>
                <pre>{json.dumps(roaming_data, indent=2)}</pre>
            </div>
        </section>
        """
    
    def _generate_power_section(self, power_data: Dict) -> str:
        """Generate power management section"""
        if not power_data or not power_data.get('issues_found'):
            return """
            <section class="card power">
                <h3><span class="icon">🔋</span> Power Management</h3>
                <div class="no-power-issues">
                    <p>✅ No power management issues detected</p>
                </div>
            </section>
            """
        
        severity_counts = power_data.get('severity_counts', {})
        total_issues = power_data.get('total_issues', 0)
        
        return f"""
        <section class="card power warning">
            <h3><span class="icon">🔋</span> Power Management Issues</h3>
            
            <div class="power-summary">
                <div class="issues-count">
                    <span class="count-number">{total_issues}</span>
                    <span class="count-label">Issues Found</span>
                </div>
                
                <div class="severity-breakdown">
                    <div class="severity-item high">
                        <span class="severity-number">{severity_counts.get('high', 0)}</span>
                        <span class="severity-label">High</span>
                    </div>
                    <div class="severity-item medium">
                        <span class="severity-number">{severity_counts.get('medium', 0)}</span>
                        <span class="severity-label">Medium</span>
                    </div>
                    <div class="severity-item low">
                        <span class="severity-number">{severity_counts.get('low', 0)}</span>
                        <span class="severity-label">Low</span>
                    </div>
                </div>
            </div>
            
            <div class="power-note">
                <p>💡 These issues require manual configuration changes</p>
            </div>
        </section>
        """
    
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
    
    def _get_modern_css(self) -> str:
        """Return modern CSS with dark theme and glassmorphism"""
        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: #ffffff;
            min-height: 100vh;
            line-height: 1.6;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        .main-header {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 30px;
            text-align: center;
        }

        .main-header h1 {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 15px;
            background: linear-gradient(135deg, #00d4ff, #7b68ee);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .wifi-icon {
            font-size: 2rem;
            margin-right: 15px;
        }

        .network-info h2 {
            font-size: 1.5rem;
            color: #00d4ff;
            margin-bottom: 10px;
        }

        .timestamp {
            color: rgba(255, 255, 255, 0.7);
            font-size: 0.9rem;
        }

        .content-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }

        .card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 25px;
            transition: all 0.3s ease;
        }

        .card:hover {
            transform: translateY(-5px);
            border-color: rgba(0, 212, 255, 0.3);
            box-shadow: 0 20px 40px rgba(0, 212, 255, 0.1);
        }

        .card h3 {
            font-size: 1.3rem;
            font-weight: 600;
            margin-bottom: 20px;
            color: #00d4ff;
            display: flex;
            align-items: center;
        }

        .icon {
            font-size: 1.5rem;
            margin-right: 10px;
        }

        .connection-details, .topology-stats {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .detail-row, .stat-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .label, .stat-label {
            color: rgba(255, 255, 255, 0.8);
            font-weight: 500;
        }

        .value, .stat-value {
            font-weight: 600;
            color: #ffffff;
        }

        .signal-excellent { color: #4ade80; }
        .signal-good { color: #fbbf24; }
        .signal-fair { color: #fb923c; }
        .signal-poor { color: #f87171; }

        .excellent {
            border-color: rgba(74, 222, 128, 0.3);
            background: rgba(74, 222, 128, 0.05);
        }

        .good {
            border-color: rgba(251, 191, 36, 0.3);
            background: rgba(251, 191, 36, 0.05);
        }

        .warning, .fair {
            border-color: rgba(251, 146, 60, 0.3);
            background: rgba(251, 146, 60, 0.05);
        }

        .poor {
            border-color: rgba(248, 113, 113, 0.3);
            background: rgba(248, 113, 113, 0.05);
        }

        .topology-overview {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 25px;
        }

        .topology-health {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
        }

        .health-score {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.1rem;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .health-emoji {
            font-size: 1.5rem;
        }

        .coverage-zones, .mesh-nodes, .venn-analysis {
            margin-top: 25px;
        }

        .coverage-zones h4, .mesh-nodes h4, .venn-analysis h4 {
            color: #00d4ff;
            margin-bottom: 15px;
            font-size: 1.1rem;
        }

        .venn-summary {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-bottom: 20px;
            padding: 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .venn-quality {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 15px;
            border-radius: 10px;
            min-width: 80px;
        }

        .quality-score {
            font-size: 1.5rem;
            font-weight: 700;
            color: #fff;
        }

        .quality-label {
            font-size: 0.8rem;
            color: rgba(255, 255, 255, 0.8);
        }

        .venn-description {
            flex: 1;
            color: rgba(255, 255, 255, 0.9);
        }

        .venn-diagram-container {
            margin-top: 20px;
            padding: 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .venn-diagram-container h5 {
            color: #00d4ff;
            margin-bottom: 15px;
            font-size: 1rem;
        }

        .venn-svg-wrapper {
            display: flex;
            justify-content: center;
            align-items: center;
            background: rgba(255, 255, 255, 0.9);
            border-radius: 10px;
            padding: 10px;
            margin-bottom: 15px;
        }

        .venn-svg-wrapper svg {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
        }

        .overlap-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .overlap-list h5 {
            color: #00d4ff;
            margin-bottom: 10px;
            font-size: 1rem;
        }

        .overlap-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .overlap-nodes {
            color: rgba(255, 255, 255, 0.9);
        }

        .overlap-percentage {
            font-weight: 600;
            color: #00d4ff;
        }

        .no-overlaps {
            padding: 20px;
            text-align: center;
            background: rgba(251, 146, 60, 0.05);
            border: 1px solid rgba(251, 146, 60, 0.2);
            border-radius: 10px;
            color: rgba(255, 255, 255, 0.8);
        }

        .zones-grid, .nodes-grid, .alternatives-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }

        .zone-card, .node-card, .alternative-card {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            padding: 15px;
            transition: all 0.2s ease;
        }

        .zone-card:hover, .node-card:hover, .alternative-card:hover {
            background: rgba(255, 255, 255, 0.06);
            border-color: rgba(0, 212, 255, 0.3);
        }

        .zone-header, .node-header, .alt-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .zone-icon, .alt-emoji {
            font-size: 1.2rem;
        }

        .recommendation-banner {
            padding: 20px;
            border-radius: 15px;
            margin-bottom: 25px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .recommendation-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 12px;
        }

        .rec-icon {
            font-size: 1.5rem;
        }

        .rec-title {
            font-size: 1.2rem;
            font-weight: 600;
        }

        .recommendation-details {
            color: rgba(255, 255, 255, 0.9);
        }

        .alternatives-list h4 {
            color: #00d4ff;
            margin-bottom: 15px;
            font-size: 1.1rem;
        }

        .alt-details {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 12px;
        }

        .alt-stat {
            display: flex;
            justify-content: space-between;
            font-size: 0.9rem;
        }

        .alt-reasons ul {
            list-style: none;
            font-size: 0.85rem;
            color: rgba(255, 255, 255, 0.8);
        }

        .alt-reasons li {
            margin-bottom: 4px;
            padding-left: 8px;
            position: relative;
        }

        .alt-reasons li::before {
            content: "•";
            color: #00d4ff;
            position: absolute;
            left: 0;
        }

        .stability-score {
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 20px;
            border-radius: 15px;
            margin-bottom: 20px;
        }

        .stability-details {
            display: flex;
            flex-direction: column;
        }

        .stability-number {
            font-size: 1.5rem;
            font-weight: 700;
        }

        .stability-label {
            font-size: 0.9rem;
            color: rgba(255, 255, 255, 0.8);
        }

        .history-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
        }

        .history-stat {
            text-align: center;
            padding: 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .stat-number {
            display: block;
            font-size: 1.3rem;
            font-weight: 700;
            color: #00d4ff;
        }

        .problems-summary, .power-summary {
            display: flex;
            align-items: center;
            gap: 30px;
            margin-bottom: 20px;
        }

        .problems-count, .issues-count, .count-number {
            text-align: center;
        }

        .count-number {
            display: block;
            font-size: 2rem;
            font-weight: 700;
            color: #fb923c;
        }

        .count-label {
            font-size: 0.9rem;
            color: rgba(255, 255, 255, 0.8);
        }

        .problems-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .problem-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 8px;
            border: 1px solid rgba(251, 146, 60, 0.2);
        }

        .problem-icon {
            font-size: 1.2rem;
        }

        .severity-breakdown {
            display: flex;
            gap: 15px;
        }

        .severity-item {
            text-align: center;
            padding: 10px 15px;
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .severity-item.high {
            border-color: rgba(248, 113, 113, 0.3);
            background: rgba(248, 113, 113, 0.05);
        }

        .severity-item.medium {
            border-color: rgba(251, 146, 60, 0.3);
            background: rgba(251, 146, 60, 0.05);
        }

        .severity-item.low {
            border-color: rgba(251, 191, 36, 0.3);
            background: rgba(251, 191, 36, 0.05);
        }

        .severity-number {
            display: block;
            font-size: 1.2rem;
            font-weight: 600;
        }

        .severity-label {
            font-size: 0.8rem;
            color: rgba(255, 255, 255, 0.8);
        }

        .topology-note, .history-note, .power-note {
            margin-top: 20px;
            padding: 15px;
            background: rgba(0, 212, 255, 0.05);
            border: 1px solid rgba(0, 212, 255, 0.2);
            border-radius: 10px;
            font-size: 0.9rem;
            color: rgba(255, 255, 255, 0.9);
        }

        .no-connection, .no-alternatives, .no-history, .no-problems, .no-roaming-data, .no-power-issues {
            text-align: center;
            padding: 30px;
            color: rgba(255, 255, 255, 0.8);
        }

        .report-footer {
            text-align: center;
            padding: 25px;
            background: rgba(255, 255, 255, 0.02);
            border-radius: 15px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            color: rgba(255, 255, 255, 0.7);
            font-size: 0.9rem;
        }

        .report-footer p {
            margin-bottom: 5px;
        }

        pre {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 8px;
            overflow-x: auto;
            font-size: 0.8rem;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        @media (max-width: 768px) {
            .container {
                padding: 15px;
            }

            .content-grid {
                grid-template-columns: 1fr;
                gap: 20px;
            }

            .topology-overview {
                grid-template-columns: 1fr;
            }

            .zones-grid, .nodes-grid, .alternatives-grid {
                grid-template-columns: 1fr;
            }

            .main-header h1 {
                font-size: 2rem;
            }

            .history-stats {
                grid-template-columns: 1fr;
            }

            .problems-summary, .power-summary {
                flex-direction: column;
                gap: 15px;
            }

            .severity-breakdown {
                justify-content: center;
            }
        }
        """
    
    def _get_interactive_javascript(self) -> str:
        """Return interactive JavaScript for the report"""
        return """
        // Add smooth scrolling and interactive features
        document.addEventListener('DOMContentLoaded', function() {
            // Add click-to-copy functionality for BSSIDs
            const bssids = document.querySelectorAll('.stat-value, .value');
            bssids.forEach(element => {
                if (element.textContent.match(/[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}/)) {
                    element.style.cursor = 'pointer';
                    element.title = 'Click to copy BSSID';
                    element.addEventListener('click', function() {
                        navigator.clipboard.writeText(this.textContent).then(() => {
                            const original = this.textContent;
                            this.textContent = '✓ Copied!';
                            setTimeout(() => {
                                this.textContent = original;
                            }, 1000);
                        });
                    });
                }
            });

            // Add smooth hover effects
            const cards = document.querySelectorAll('.card');
            cards.forEach(card => {
                card.addEventListener('mouseenter', function() {
                    this.style.transform = 'translateY(-5px) scale(1.02)';
                });
                card.addEventListener('mouseleave', function() {
                    this.style.transform = 'translateY(0) scale(1)';
                });
            });

            // Auto-refresh timestamp
            const timestamp = document.querySelector('.timestamp');
            if (timestamp) {
                setInterval(() => {
                    const now = new Date();
                    const timeStr = now.toLocaleString();
                    timestamp.textContent = 'Generated: ' + timeStr + ' (Auto-updated)';
                }, 60000); // Update every minute
            }
        });
        """


# Example usage and integration
if __name__ == "__main__":
    print("WiFi Mesh HTML Report Generator")
    print("This module provides HTML reporting for the WiFi Mesh Network Analyzer")
    print("Usage: Import MeshHTMLReporter and call generate_report() with analysis data")
