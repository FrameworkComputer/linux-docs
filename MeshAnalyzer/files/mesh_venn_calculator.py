#!/usr/bin/env python3
"""
Mesh Venn Diagram Calculator
Handles spatial overlap calculations for mesh nodes
"""

import math
from typing import Dict, List, Tuple, Optional

class MeshVennCalculator:
    """Calculate mesh node spatial overlaps and positioning for Venn diagrams"""
    
    def __init__(self):
        self.coverage_multiplier = 3.5  # Signal strength to coverage radius multiplier
        self.min_radius = 40  # Minimum coverage radius in pixels
        self.max_radius = 120  # Maximum coverage radius in pixels
    
    def calculate_coverage_radius(self, signal_dbm: int) -> int:
        """Calculate coverage radius based on signal strength"""
        # Convert signal strength to coverage radius
        # Stronger signals = larger coverage areas
        normalized_signal = max(0, signal_dbm + 100)  # -100dBm becomes 0, -50dBm becomes 50
        radius = self.min_radius + (normalized_signal * self.coverage_multiplier)
        return min(self.max_radius, max(self.min_radius, int(radius)))
    
    def calculate_optimal_positions(self, nodes_data: List[Dict]) -> List[Dict]:
        """Calculate optimal positions for nodes to show realistic overlaps"""
        node_count = len(nodes_data)
        
        if node_count == 1:
            return [{'x': 50, 'y': 50}]
        elif node_count == 2:
            return self._position_two_nodes(nodes_data)
        elif node_count == 3:
            return self._position_three_nodes(nodes_data)
        elif node_count == 4:
            return self._position_four_nodes(nodes_data)
        else:
            return self._position_many_nodes(nodes_data)
    
    def _position_two_nodes(self, nodes_data: List[Dict]) -> List[Dict]:
        """Position two nodes with appropriate overlap"""
        # Sort by signal strength
        sorted_nodes = sorted(nodes_data, key=lambda x: x['signal'], reverse=True)
        
        # Calculate radii
        radius1 = self.calculate_coverage_radius(sorted_nodes[0]['signal'])
        radius2 = self.calculate_coverage_radius(sorted_nodes[1]['signal'])
        
        # Position for 30-50% overlap
        overlap_distance = (radius1 + radius2) * 0.6  # 40% overlap
        
        positions = [
            {'x': 40, 'y': 50},
            {'x': 40 + (overlap_distance / 4), 'y': 50}
        ]
        
        return positions
    
    def _position_three_nodes(self, nodes_data: List[Dict]) -> List[Dict]:
        """Position three nodes in triangle formation with overlaps"""
        # Sort by signal strength
        sorted_indices = sorted(range(len(nodes_data)), key=lambda i: nodes_data[i]['signal'], reverse=True)
        
        # Triangle positions with overlaps
        base_positions = [
            {'x': 35, 'y': 35},   # Top-left
            {'x': 65, 'y': 35},   # Top-right
            {'x': 50, 'y': 65}    # Bottom-center
        ]
        
        # Adjust positions based on signal strengths for realistic overlaps
        positions = [None] * 3
        for i, orig_idx in enumerate(sorted_indices):
            positions[orig_idx] = base_positions[i]
        
        return positions
    
    def _position_four_nodes(self, nodes_data: List[Dict]) -> List[Dict]:
        """Position four nodes in diamond/square formation"""
        # Sort by signal strength
        sorted_indices = sorted(range(len(nodes_data)), key=lambda i: nodes_data[i]['signal'], reverse=True)
        
        # Diamond positions for maximum overlaps
        base_positions = [
            {'x': 40, 'y': 35},   # Top-left
            {'x': 60, 'y': 35},   # Top-right
            {'x': 35, 'y': 55},   # Bottom-left
            {'x': 65, 'y': 55}    # Bottom-right
        ]
        
        positions = [None] * 4
        for i, orig_idx in enumerate(sorted_indices):
            positions[orig_idx] = base_positions[i]
        
        return positions
    
    def _position_many_nodes(self, nodes_data: List[Dict]) -> List[Dict]:
        """Position 5+ nodes in clustered spiral for overlaps"""
        node_count = len(nodes_data)
        positions = []
        
        # Central cluster approach
        center_x, center_y = 50, 50
        
        for i in range(node_count):
            if i == 0:
                # Central node
                positions.append({'x': center_x, 'y': center_y})
            else:
                # Spiral outward
                angle = (i - 1) * (2 * math.pi / (node_count - 1))
                radius_offset = 15 + ((i - 1) * 5)  # Gradually increasing radius
                
                x = center_x + radius_offset * math.cos(angle)
                y = center_y + radius_offset * math.sin(angle)
                
                # Keep within bounds
                x = max(20, min(80, x))
                y = max(20, min(80, y))
                
                positions.append({'x': x, 'y': y})
        
        return positions
    
    def calculate_overlap_percentage(self, node1: Dict, node2: Dict) -> float:
        """Calculate overlap percentage between two nodes"""
        # Get positions and radii
        x1, y1 = node1['position']['x'], node1['position']['y']
        x2, y2 = node2['position']['x'], node2['position']['y']
        r1 = self.calculate_coverage_radius(node1['signal'])
        r2 = self.calculate_coverage_radius(node2['signal'])
        
        # Calculate distance between centers (scale from percentage to actual distance)
        distance = math.sqrt((x2 - x1)**2 + (y2 - y1)**2) * 4  # Scale factor
        
        # Check if circles overlap
        if distance >= r1 + r2:
            return 0.0  # No overlap
        
        if distance <= abs(r1 - r2):
            # One circle is completely inside the other
            smaller_area = math.pi * min(r1, r2)**2
            larger_area = math.pi * max(r1, r2)**2
            return smaller_area / larger_area * 100
        
        # Partial overlap calculation
        # Using intersection area formula for two circles
        a = r1**2 * math.acos((distance**2 + r1**2 - r2**2) / (2 * distance * r1))
        b = r2**2 * math.acos((distance**2 + r2**2 - r1**2) / (2 * distance * r2))
        c = 0.5 * math.sqrt((-distance + r1 + r2) * (distance + r1 - r2) * (distance - r1 + r2) * (distance + r1 + r2))
        
        intersection_area = a + b - c
        total_area = math.pi * r1**2 + math.pi * r2**2 - intersection_area
        
        return (intersection_area / total_area) * 100 if total_area > 0 else 0.0
    
    def generate_venn_data(self, nodes_data: List[Dict]) -> Dict:
        """Generate complete Venn diagram data with positions, radii, and overlaps"""
        if not nodes_data:
            return {'nodes': [], 'overlaps': [], 'total_coverage': 0}
        
        # Calculate optimal positions
        positions = self.calculate_optimal_positions(nodes_data)
        
        # Update nodes with positions and radii
        venn_nodes = []
        for i, node in enumerate(nodes_data):
            radius = self.calculate_coverage_radius(node['signal'])
            venn_node = {
                **node,
                'position': positions[i],
                'radius': radius,
                'coverage_area': math.pi * radius**2
            }
            venn_nodes.append(venn_node)
        
        # Calculate all pairwise overlaps
        overlaps = []
        for i in range(len(venn_nodes)):
            for j in range(i + 1, len(venn_nodes)):
                overlap_pct = self.calculate_overlap_percentage(venn_nodes[i], venn_nodes[j])
                if overlap_pct > 5:  # Only record significant overlaps
                    overlaps.append({
                        'node1_id': i,
                        'node2_id': j,
                        'overlap_percentage': overlap_pct,
                        'node1_label': venn_nodes[i]['label'],
                        'node2_label': venn_nodes[j]['label']
                    })
        
        # Calculate total coverage area (accounting for overlaps)
        total_coverage = sum(node['coverage_area'] for node in venn_nodes)
        
        return {
            'nodes': venn_nodes,
            'overlaps': overlaps,
            'total_coverage': total_coverage,
            'overlap_count': len(overlaps),
            'avg_overlap': sum(o['overlap_percentage'] for o in overlaps) / len(overlaps) if overlaps else 0
        }
    
    def get_overlap_quality_assessment(self, venn_data: Dict) -> Dict:
        """Assess the quality of mesh overlap coverage"""
        overlaps = venn_data['overlaps']
        nodes = venn_data['nodes']
        
        if len(nodes) < 2:
            return {
                'quality': 'single_node',
                'score': 100,
                'description': 'Single node - no overlap analysis needed'
            }
        
        # Calculate overlap metrics
        high_overlaps = [o for o in overlaps if o['overlap_percentage'] > 30]
        medium_overlaps = [o for o in overlaps if 15 <= o['overlap_percentage'] <= 30]
        low_overlaps = [o for o in overlaps if 5 <= o['overlap_percentage'] < 15]
        
        total_possible_overlaps = len(nodes) * (len(nodes) - 1) // 2
        actual_overlaps = len(overlaps)
        
        # Scoring
        score = 0
        
        # Reward good overlap coverage
        if actual_overlaps / total_possible_overlaps > 0.7:
            score += 30
        elif actual_overlaps / total_possible_overlaps > 0.5:
            score += 20
        else:
            score += 10
        
        # Reward balanced overlaps
        if high_overlaps and medium_overlaps:
            score += 25
        elif medium_overlaps:
            score += 15
        
        # Reward having some overlaps
        if actual_overlaps > 0:
            score += 20
        
        # Average overlap quality
        avg_overlap = venn_data['avg_overlap']
        if avg_overlap > 25:
            score += 25
        elif avg_overlap > 15:
            score += 15
        elif avg_overlap > 5:
            score += 10
        
        # Determine quality level
        if score >= 80:
            quality = 'excellent'
            description = f'Excellent mesh overlap - {actual_overlaps}/{total_possible_overlaps} node pairs overlapping'
        elif score >= 60:
            quality = 'good'
            description = f'Good mesh overlap - {actual_overlaps}/{total_possible_overlaps} node pairs with coverage overlap'
        elif score >= 40:
            quality = 'fair'
            description = f'Fair mesh overlap - some coverage gaps possible'
        else:
            quality = 'poor'
            description = f'Poor mesh overlap - significant coverage gaps likely'
        
        return {
            'quality': quality,
            'score': min(100, score),
            'description': description,
            'overlap_ratio': f'{actual_overlaps}/{total_possible_overlaps}',
            'avg_overlap_pct': round(avg_overlap, 1)
        }
