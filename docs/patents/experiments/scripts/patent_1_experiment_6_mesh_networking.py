#!/usr/bin/env python3
"""
Patent #1 Experiment 6: AI2AI Mesh Networking Algorithms Validation

Validates the adaptive mesh networking algorithms:
1. Adaptive hop limit based on battery/network density
2. Message forwarding logic
3. Network resilience under failures
4. Battery-adaptive behavior

Tests:
1. Message delivery success rate (1-hop, 2-hop, 3-hop)
2. Battery-adaptive hop limit effectiveness
3. Network density vs. discovery rate
4. Mesh resilience under node failures

Compares AVRAI's adaptive mesh networking against baseline fixed hop limit.

Date: January 3, 2026
"""

import sys
import os
from pathlib import Path
import numpy as np
import pandas as pd
import json
from typing import List, Dict, Any, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
from datetime import datetime
from scipy import stats

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_1'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


class BatteryState(Enum):
    """Battery state enum."""
    CHARGING = "charging"
    DISCHARGING = "discharging"
    FULL = "full"
    UNKNOWN = "unknown"


class MessagePriority(Enum):
    """Message priority enum."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class NetworkNode:
    """Represents a node in the mesh network."""
    node_id: str
    battery_level: float  # 0.0 to 1.0
    battery_state: BatteryState
    is_charging: bool
    is_active: bool = True  # False if node has failed
    position: Tuple[float, float] = (0.0, 0.0)  # (x, y) coordinates


@dataclass
class Message:
    """Represents a message in the network."""
    message_id: str
    origin_node: str
    target_node: str
    priority: MessagePriority
    current_hop: int
    path: List[str]  # Nodes this message has traversed


def calculate_max_hops_avrai(
    battery_level: float,
    battery_state: BatteryState,
    is_charging: bool,
    network_density: int,
    priority: MessagePriority = MessagePriority.MEDIUM
) -> Optional[int]:
    """
    AVRAI's adaptive hop limit calculation.
    
    Matches AdaptiveMeshHopPolicy.calculateMaxHops() logic:
    - Battery level affects max hops
    - Charging allows more hops
    - Network density affects hop limit
    - Priority affects hop limit
    """
    # Base hop limit
    base_hops = 2
    
    # Battery factor (lower battery = fewer hops)
    if battery_level < 0.2:  # Critical battery
        battery_factor = 0.5
    elif battery_level < 0.5:  # Low battery
        battery_factor = 0.75
    else:
        battery_factor = 1.0
    
    # Charging bonus (charging allows more hops)
    if is_charging or battery_state == BatteryState.FULL:
        charging_bonus = 1
    else:
        charging_bonus = 0
    
    # Network density factor (more dense = can use more hops)
    if network_density < 3:
        density_factor = 0.75  # Sparse network
    elif network_density < 10:
        density_factor = 1.0  # Normal network
    else:
        density_factor = 1.25  # Dense network
    
    # Priority factor
    priority_factors = {
        MessagePriority.LOW: 0.75,
        MessagePriority.MEDIUM: 1.0,
        MessagePriority.HIGH: 1.25,
        MessagePriority.CRITICAL: 1.5,
    }
    priority_factor = priority_factors.get(priority, 1.0)
    
    # Calculate max hops
    max_hops = int(base_hops * battery_factor * density_factor * priority_factor) + charging_bonus
    
    # Minimum 1 hop (always allow direct connections)
    max_hops = max(1, max_hops)
    
    # Maximum 5 hops (prevent excessive forwarding)
    max_hops = min(5, max_hops)
    
    return max_hops


def calculate_max_hops_baseline(
    priority: MessagePriority = MessagePriority.MEDIUM
) -> int:
    """
    Baseline: Fixed hop limit (2 hops for all messages).
    
    This is what most systems would use - simple fixed limit.
    """
    return 2


def should_forward_message_avrai(
    current_hop: int,
    max_hops: Optional[int],
    priority: MessagePriority
) -> bool:
    """
    AVRAI's message forwarding logic.
    
    Matches AdaptiveMeshNetworkingService.shouldForwardMessage():
    - Always allow direct connections (0 hops)
    - Check against adaptive max hops
    """
    # Always allow direct connections
    if current_hop == 0:
        return True
    
    # Check against max hops
    if max_hops is None:
        return True  # Unlimited
    
    return current_hop < max_hops


def should_forward_message_baseline(
    current_hop: int,
    max_hops: int
) -> bool:
    """
    Baseline: Simple hop limit check.
    """
    return current_hop < max_hops


def simulate_message_delivery(
    message: Message,
    nodes: Dict[str, NetworkNode],
    max_hops: Optional[int],
    use_avrai: bool = True
) -> Tuple[bool, int, List[str]]:
    """
    Simulate message delivery through mesh network.
    
    Returns: (success, final_hop, path)
    """
    path = [message.origin_node]
    current_hop = 0
    
    # Simple routing: try to reach target through network
    # In reality, would use more sophisticated routing algorithms
    
    visited = {message.origin_node}
    current_node_id = message.origin_node
    
    while current_hop < (max_hops if max_hops else 10):
        current_node = nodes.get(current_node_id)
        
        if current_node is None or not current_node.is_active:
            return False, current_hop, path
        
        # Check if we reached target
        if current_node_id == message.target_node:
            return True, current_hop, path
        
        # Find next hop (simplified: find closest active neighbor to target)
        # In reality, would use proper routing algorithm
        best_next = None
        best_distance = float('inf')
        
        target_node = nodes.get(message.target_node)
        if target_node is None:
            return False, current_hop, path
        
        for node_id, node in nodes.items():
            if node_id in visited or not node.is_active:
                continue
            
            # Calculate distance to target
            distance = np.sqrt(
                (node.position[0] - target_node.position[0]) ** 2 +
                (node.position[1] - target_node.position[1]) ** 2
            )
            
            if distance < best_distance:
                best_distance = distance
                best_next = node_id
        
        if best_next is None:
            return False, current_hop, path
        
        # Check if we should forward
        if use_avrai:
            should_forward = should_forward_message_avrai(current_hop + 1, max_hops, message.priority)
        else:
            should_forward = should_forward_message_baseline(current_hop + 1, max_hops)
        
        if not should_forward:
            return False, current_hop, path
        
        # Forward to next node
        current_node_id = best_next
        path.append(current_node_id)
        visited.add(current_node_id)
        current_hop += 1
    
    return False, current_hop, path


def run_experiment_6():
    """Run Experiment 6: AI2AI Mesh Networking Algorithms Validation."""
    print()
    print("=" * 70)
    print("Experiment 6: AI2AI Mesh Networking Algorithms Validation")
    print("=" * 70)
    print()
    
    # Create network topology
    print("Creating network topology...")
    
    np.random.seed(42)
    
    # Create nodes in a grid-like topology
    nodes = {}
    grid_size = 5
    node_count = 0
    
    for x in range(grid_size):
        for y in range(grid_size):
            node_id = f'node_{node_count}'
            
            # Random battery level and state
            battery_level = float(np.random.uniform(0.2, 1.0))
            is_charging = np.random.random() < 0.2  # 20% charging
            battery_state = BatteryState.CHARGING if is_charging else BatteryState.DISCHARGING
            
            node = NetworkNode(
                node_id=node_id,
                battery_level=battery_level,
                battery_state=battery_state,
                is_charging=is_charging,
                position=(float(x), float(y))
            )
            nodes[node_id] = node
            node_count += 1
    
    print(f"  Created {len(nodes)} nodes in {grid_size}x{grid_size} grid")
    
    # Test 1: Message Delivery Success Rate
    print()
    print("Test 1: Message Delivery Success Rate")
    print("-" * 70)
    
    delivery_results = []
    
    # Generate test messages
    node_ids = list(nodes.keys())
    test_messages = []
    
    for i in range(100):  # 100 test messages
        origin = np.random.choice(node_ids)
        target = np.random.choice([nid for nid in node_ids if nid != origin])
        priority = np.random.choice(list(MessagePriority))
        
        message = Message(
            message_id=f'msg_{i}',
            origin_node=origin,
            target_node=target,
            priority=priority,
            current_hop=0,
            path=[origin]
        )
        test_messages.append(message)
    
    # Calculate network density (average neighbors per node)
    network_density = 4  # Grid topology: each node has ~4 neighbors
    
    for message in test_messages:
        origin_node = nodes[message.origin_node]
        
        # AVRAI: Adaptive max hops
        avrai_max_hops = calculate_max_hops_avrai(
            origin_node.battery_level,
            origin_node.battery_state,
            origin_node.is_charging,
            network_density,
            message.priority
        )
        
        # Baseline: Fixed max hops
        baseline_max_hops = calculate_max_hops_baseline(message.priority)
        
        # Simulate delivery
        avrai_success, avrai_hops, avrai_path = simulate_message_delivery(
            message, nodes, avrai_max_hops, use_avrai=True
        )
        
        baseline_success, baseline_hops, baseline_path = simulate_message_delivery(
            message, nodes, baseline_max_hops, use_avrai=False
        )
        
        delivery_results.append({
            'message_id': message.message_id,
            'origin_node': message.origin_node,
            'target_node': message.target_node,
            'priority': message.priority.value,
            'origin_battery_level': origin_node.battery_level,
            'origin_is_charging': origin_node.is_charging,
            'network_density': network_density,
            'avrai_max_hops': avrai_max_hops,
            'baseline_max_hops': baseline_max_hops,
            'avrai_success': avrai_success,
            'baseline_success': baseline_success,
            'avrai_hops': avrai_hops,
            'baseline_hops': baseline_hops,
            'avrai_path_length': len(avrai_path),
            'baseline_path_length': len(baseline_path),
        })
    
    df_delivery = pd.DataFrame(delivery_results)
    
    # Test 2: Battery-Adaptive Behavior
    print()
    print("Test 2: Battery-Adaptive Behavior")
    print("-" * 70)
    
    battery_results = []
    
    for battery_level in [0.1, 0.3, 0.5, 0.7, 0.9]:
        for is_charging in [False, True]:
            battery_state = BatteryState.CHARGING if is_charging else BatteryState.DISCHARGING
            
            avrai_max_hops = calculate_max_hops_avrai(
                battery_level,
                battery_state,
                is_charging,
                network_density,
                MessagePriority.MEDIUM
            )
            
            baseline_max_hops = calculate_max_hops_baseline(MessagePriority.MEDIUM)
            
            battery_results.append({
                'battery_level': battery_level,
                'is_charging': is_charging,
                'avrai_max_hops': avrai_max_hops,
                'baseline_max_hops': baseline_max_hops,
                'adaptive_advantage': avrai_max_hops - baseline_max_hops,
            })
    
    df_battery = pd.DataFrame(battery_results)
    
    # Test 3: Network Resilience
    print()
    print("Test 3: Network Resilience Under Failures")
    print("-" * 70)
    
    resilience_results = []
    
    for failure_rate in [0.0, 0.1, 0.2, 0.3]:  # 0%, 10%, 20%, 30% node failures
        # Simulate failures
        failed_nodes = set()
        num_failures = int(len(nodes) * failure_rate)
        failed_node_ids = np.random.choice(node_ids, num_failures, replace=False)
        
        for node_id in failed_node_ids:
            nodes[node_id].is_active = False
            failed_nodes.add(node_id)
        
        # Test message delivery
        test_messages_resilience = test_messages[:20]  # Use first 20 messages
        
        avrai_successes = 0
        baseline_successes = 0
        
        for message in test_messages_resilience:
            origin_node = nodes[message.origin_node]
            
            if not origin_node.is_active:
                continue
            
            avrai_max_hops = calculate_max_hops_avrai(
                origin_node.battery_level,
                origin_node.battery_state,
                origin_node.is_charging,
                network_density,
                message.priority
            )
            
            baseline_max_hops = calculate_max_hops_baseline(message.priority)
            
            avrai_success, _, _ = simulate_message_delivery(
                message, nodes, avrai_max_hops, use_avrai=True
            )
            
            baseline_success, _, _ = simulate_message_delivery(
                message, nodes, baseline_max_hops, use_avrai=False
            )
            
            if avrai_success:
                avrai_successes += 1
            if baseline_success:
                baseline_successes += 1
        
        resilience_results.append({
            'failure_rate': failure_rate,
            'failed_nodes': num_failures,
            'avrai_success_rate': avrai_successes / len(test_messages_resilience),
            'baseline_success_rate': baseline_successes / len(test_messages_resilience),
            'improvement': (avrai_successes - baseline_successes) / len(test_messages_resilience),
        })
        
        # Restore nodes for next test
        for node_id in failed_node_ids:
            nodes[node_id].is_active = True
    
    df_resilience = pd.DataFrame(resilience_results)
    
    # Calculate statistics
    print()
    print("Results Summary")
    print("=" * 70)
    
    # Delivery success rates
    avrai_success_rate = df_delivery['avrai_success'].mean()
    baseline_success_rate = df_delivery['baseline_success'].mean()
    success_improvement_pct = ((avrai_success_rate - baseline_success_rate) / baseline_success_rate * 100) if baseline_success_rate > 0 else 0.0
    
    print(f"Message Delivery Success Rate:")
    print(f"  AVRAI: {avrai_success_rate:.4f} ({avrai_success_rate*100:.2f}%)")
    print(f"  Baseline: {baseline_success_rate:.4f} ({baseline_success_rate*100:.2f}%)")
    print(f"  Improvement: {success_improvement_pct:.2f}%")
    
    # Battery-adaptive behavior
    avg_adaptive_advantage = df_battery['adaptive_advantage'].mean()
    print(f"\nBattery-Adaptive Behavior:")
    print(f"  Average adaptive advantage: {avg_adaptive_advantage:.2f} hops")
    print(f"  Charging allows more hops: {(df_battery[df_battery['is_charging']]['adaptive_advantage'] > 0).all()}")
    
    # Network resilience
    if len(df_resilience) > 0:
        avg_avrai_resilience = df_resilience['avrai_success_rate'].mean()
        avg_baseline_resilience = df_resilience['baseline_success_rate'].mean()
        resilience_improvement = avg_avrai_resilience - avg_baseline_resilience
        
        print(f"\nNetwork Resilience:")
        print(f"  AVRAI average success rate: {avg_avrai_resilience:.4f}")
        print(f"  Baseline average success rate: {avg_baseline_resilience:.4f}")
        print(f"  Improvement: {resilience_improvement:.4f}")
    
    # Save results
    print()
    print("Saving results...")
    
    df_delivery.to_csv(RESULTS_DIR / 'experiment_6_delivery_results.csv', index=False)
    df_battery.to_csv(RESULTS_DIR / 'experiment_6_battery_results.csv', index=False)
    df_resilience.to_csv(RESULTS_DIR / 'experiment_6_resilience_results.csv', index=False)
    
    summary = {
        'status': 'complete',
        'total_nodes': len(nodes),
        'total_messages_tested': len(test_messages),
        'message_delivery': {
            'avrai_success_rate': float(avrai_success_rate),
            'baseline_success_rate': float(baseline_success_rate),
            'improvement_pct': float(success_improvement_pct),
        },
        'battery_adaptive': {
            'avg_adaptive_advantage': float(avg_adaptive_advantage),
            'charging_allows_more_hops': bool((df_battery[df_battery['is_charging']]['adaptive_advantage'] > 0).all()),
        },
        'network_resilience': {
            'avg_avrai_success_rate': float(avg_avrai_resilience) if len(df_resilience) > 0 else 0.0,
            'avg_baseline_success_rate': float(avg_baseline_resilience) if len(df_resilience) > 0 else 0.0,
            'improvement': float(resilience_improvement) if len(df_resilience) > 0 else 0.0,
        },
        'success_criteria': {
            'avrai_better_delivery': avrai_success_rate > baseline_success_rate,
            'battery_adaptive_works': avg_adaptive_advantage > 0,
            'resilience_improvement': resilience_improvement > 0 if len(df_resilience) > 0 else False,
        },
    }
    
    with open(RESULTS_DIR / 'experiment_6_mesh_networking.json', 'w') as f:
        json.dump(summary, f, indent=2, default=str)
    
    print(f"  ✅ Results saved to {RESULTS_DIR}")
    print()
    
    # Final verdict
    print("=" * 70)
    if summary['success_criteria']['avrai_better_delivery']:
        print("✅ SUCCESS: AVRAI's adaptive mesh networking is superior to baseline")
    else:
        print("⚠️  WARNING: Results need review")
    print("=" * 70)
    print()
    
    return summary


if __name__ == '__main__':
    run_experiment_6()
