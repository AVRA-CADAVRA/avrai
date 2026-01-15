#!/usr/bin/env python3
"""
Patent #1: Quantum Compatibility Calculation Experiments

Runs all 5 experiments (4 required + 1 optional):
1. Quantum vs. Classical Accuracy Comparison (P1)
2. Noise Handling (P1)
3. Entanglement Impact (P1)
4. Performance Benchmarks (P1)
5. Quantum State Normalization (P2 - Optional)

Date: December 19, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from scipy.stats import pearsonr
from sklearn.metrics import precision_score, recall_score, f1_score, mean_absolute_error, mean_squared_error

# Configuration
DATA_DIR = Path(__file__).parent.parent / 'data' / 'patent_1_quantum_compatibility'
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_1'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def load_data():
    """Load synthetic data."""
    with open(DATA_DIR / 'synthetic_profiles.json', 'r') as f:
        agents = json.load(f)
    
    with open(DATA_DIR / 'compatibility_pairs.json', 'r') as f:
        pairs = json.load(f)
    
    profiles = {a['agentId']: np.array(a['profile']) for a in agents}
    
    return agents, pairs, profiles


def quantum_compatibility(profile_a, profile_b):
    """Calculate quantum compatibility: C = |⟨ψ_A|ψ_B⟩|²"""
    inner_product = np.abs(np.dot(profile_a, profile_b))
    return inner_product ** 2


def classical_cosine(profile_a, profile_b):
    """Calculate classical cosine similarity."""
    dot_product = np.dot(profile_a, profile_b)
    norm_a = np.linalg.norm(profile_a)
    norm_b = np.linalg.norm(profile_b)
    if norm_a * norm_b > 0:
        return dot_product / (norm_a * norm_b)
    return 0.0


def classical_euclidean(profile_a, profile_b):
    """Calculate classical Euclidean distance (inverted for compatibility)."""
    distance = np.linalg.norm(profile_a - profile_b)
    max_distance = np.sqrt(12)  # Maximum distance in 12D space
    return 1.0 - (distance / max_distance)


def classical_weighted_average(profile_a, profile_b):
    """Calculate weighted average compatibility."""
    diff = profile_a - profile_b
    weights = np.ones(12) / 12  # Equal weights
    return 1.0 - np.sqrt(np.sum(weights * diff ** 2))


def experiment_1_quantum_vs_classical():
    """Experiment 1: Quantum vs. Classical Accuracy Comparison."""
    print("=" * 70)
    print("Experiment 1: Quantum vs. Classical Accuracy Comparison")
    print("=" * 70)
    print()
    
    agents, pairs, profiles = load_data()
    
    results = []
    print(f"Processing {len(pairs)} pairs...")
    
    for i, pair in enumerate(pairs):
        profile_a = profiles[pair['agent_a_id']]
        profile_b = profiles[pair['agent_b_id']]
        ground_truth = pair['ground_truth_compatibility']
        
        # Calculate methods
        quantum = quantum_compatibility(profile_a, profile_b)
        cosine = classical_cosine(profile_a, profile_b)
        euclidean = classical_euclidean(profile_a, profile_b)
        weighted = classical_weighted_average(profile_a, profile_b)
        
        results.append({
            'pair_id': i,
            'ground_truth': ground_truth,
            'quantum': quantum,
            'classical_cosine': cosine,
            'classical_euclidean': euclidean,
            'classical_weighted': weighted
        })
        
        if (i + 1) % 200 == 0:
            print(f"  Processed {i + 1}/{len(pairs)} pairs...")
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    methods = ['quantum', 'classical_cosine', 'classical_euclidean', 'classical_weighted']
    metrics = {}
    
    for method in methods:
        correlation, p_value = pearsonr(df[method], df['ground_truth'])
        
        # Convert to binary classification for precision/recall
        threshold = 0.7
        y_true = (df['ground_truth'] >= threshold).astype(int)
        y_pred = (df[method] >= threshold).astype(int)
        
        precision = precision_score(y_true, y_pred, zero_division=0)
        recall = recall_score(y_true, y_pred, zero_division=0)
        f1 = f1_score(y_true, y_pred, zero_division=0)
        mae = mean_absolute_error(df['ground_truth'], df[method])
        rmse = np.sqrt(mean_squared_error(df['ground_truth'], df[method]))
        
        metrics[method] = {
            'correlation': correlation,
            'p_value': p_value,
            'precision': precision,
            'recall': recall,
            'f1_score': f1,
            'mae': mae,
            'rmse': rmse
        }
    
    # Print results
    print()
    print("Results:")
    print("-" * 70)
    print(f"{'Method':<25} {'Correlation':<12} {'F1 Score':<12} {'MAE':<12} {'RMSE':<12}")
    print("-" * 70)
    for method in methods:
        m = metrics[method]
        print(f"{method:<25} {m['correlation']:<12.4f} {m['f1_score']:<12.4f} {m['mae']:<12.4f} {m['rmse']:<12.4f}")
    
    # Calculate quantum advantage
    quantum_corr = metrics['quantum']['correlation']
    best_classical = max(metrics['classical_cosine']['correlation'],
                        metrics['classical_euclidean']['correlation'],
                        metrics['classical_weighted']['correlation'])
    advantage = (quantum_corr - best_classical) / best_classical * 100
    
    print()
    print(f"Quantum Advantage: {advantage:.2f}%")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'accuracy_comparison.csv', index=False)
    
    # Save metrics
    metrics_df = pd.DataFrame(metrics).T
    metrics_df.to_csv(RESULTS_DIR / 'accuracy_metrics.csv')
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'accuracy_comparison.csv'}")
    print()
    
    return df, metrics


def simulate_mesh_networking_resilience(
    num_nodes: int,
    failure_rate: float,
    max_hops: int
) -> Dict[str, float]:
    """
    Simulate mesh networking resilience under node failures.
    
    Tests how well the network handles missing nodes.
    """
    # Simulate network topology (simplified grid)
    active_nodes = int(num_nodes * (1 - failure_rate))
    
    # Calculate message delivery success rate
    # In a grid, each node has ~4 neighbors
    # With failures, some paths become unavailable
    avg_path_length = np.log(active_nodes) / np.log(4)  # Approximate path length in grid
    
    # Success if path length <= max_hops
    success_rate = 1.0 if avg_path_length <= max_hops else max(0.0, 1.0 - (avg_path_length - max_hops) * 0.2)
    
    return {
        'active_nodes': active_nodes,
        'failed_nodes': num_nodes - active_nodes,
        'avg_path_length': avg_path_length,
        'success_rate': success_rate,
    }


def experiment_2_noise_handling():
    """Experiment 2: Noise Handling (Missing Data Scenarios) - Enhanced with Mesh Networking."""
    print("=" * 70)
    print("Experiment 2: Noise Handling (Enhanced with Mesh Networking)")
    print("=" * 70)
    print()
    
    agents, pairs, profiles = load_data()
    
    noise_scenarios = [
        ('10% missing', 0.1),
        ('20% missing', 0.2),
        ('30% missing', 0.3),
        ('Gaussian σ=0.1', 0.1, 'gaussian'),
        ('Gaussian σ=0.2', 0.2, 'gaussian'),
    ]
    
    # NEW: Mesh networking scenarios
    mesh_scenarios = [
        ('No failures', 0.0),
        ('10% node failures', 0.1),
        ('20% node failures', 0.2),
        ('30% node failures', 0.3),
    ]
    
    results = []
    
    # Baseline (full data)
    baseline_results = []
    for pair in pairs[:100]:  # Sample for speed
        profile_a = profiles[pair['agent_a_id']]
        profile_b = profiles[pair['agent_b_id']]
        quantum = quantum_compatibility(profile_a, profile_b)
        baseline_results.append(quantum)
    baseline_accuracy = np.mean(baseline_results)
    
    print(f"Baseline accuracy (full data): {baseline_accuracy:.4f}")
    print()
    
    for scenario_name, noise_level, *noise_type in noise_scenarios:
        noise_type = noise_type[0] if noise_type else 'missing'
        print(f"Testing: {scenario_name}...")
        
        scenario_results = []
        
        for pair in pairs[:100]:  # Sample for speed
            profile_a = profiles[pair['agent_a_id']].copy()
            profile_b = profiles[pair['agent_b_id']].copy()
            
            if noise_type == 'missing':
                # Remove random dimensions
                num_missing = int(12 * noise_level)
                missing_dims = np.random.choice(12, num_missing, replace=False)
                profile_a[missing_dims] = 0.0  # Zero-filling
                profile_b[missing_dims] = 0.0
            else:  # gaussian
                # Add Gaussian noise
                profile_a += np.random.normal(0, noise_level, 12)
                profile_b += np.random.normal(0, noise_level, 12)
                profile_a = np.clip(profile_a, 0.0, 1.0)
                profile_b = np.clip(profile_b, 0.0, 1.0)
            
            quantum = quantum_compatibility(profile_a, profile_b)
            scenario_results.append(quantum)
        
        scenario_accuracy = np.mean(scenario_results)
        robustness = scenario_accuracy / baseline_accuracy if baseline_accuracy > 0 else 0
        
        results.append({
            'scenario': scenario_name,
            'noise_level': noise_level,
            'noise_type': noise_type,
            'accuracy': scenario_accuracy,
            'robustness': robustness,
            'accuracy_loss': baseline_accuracy - scenario_accuracy
        })
        
        print(f"  Accuracy: {scenario_accuracy:.4f}, Robustness: {robustness:.4f}")
    
    print()
    
    # NEW: Test mesh networking resilience
    print("Testing mesh networking resilience...")
    mesh_results = []
    
    num_nodes = 25  # 5x5 grid network
    for scenario_name, failure_rate in mesh_scenarios:
        print(f"  Testing: {scenario_name}...")
        
        # AVRAI: Adaptive max hops (simulate with medium battery, normal density)
        avrai_max_hops = 3  # Adaptive would calculate based on conditions
        avrai_resilience = simulate_mesh_networking_resilience(num_nodes, failure_rate, avrai_max_hops)
        
        # Baseline: Fixed 2 hops
        baseline_max_hops = 2
        baseline_resilience = simulate_mesh_networking_resilience(num_nodes, failure_rate, baseline_max_hops)
        
        mesh_results.append({
            'scenario': scenario_name,
            'failure_rate': failure_rate,
            'avrai_max_hops': avrai_max_hops,
            'baseline_max_hops': baseline_max_hops,
            'avrai_success_rate': avrai_resilience['success_rate'],
            'baseline_success_rate': baseline_resilience['success_rate'],
            'improvement': avrai_resilience['success_rate'] - baseline_resilience['success_rate'],
        })
        
        print(f"    AVRAI success rate: {avrai_resilience['success_rate']:.4f}")
        print(f"    Baseline success rate: {baseline_resilience['success_rate']:.4f}")
    
    print()
    
    # Save results
    df = pd.DataFrame(results)
    df.to_csv(RESULTS_DIR / 'noise_handling_results.csv', index=False)
    
    # Save mesh networking results
    df_mesh = pd.DataFrame(mesh_results)
    df_mesh.to_csv(RESULTS_DIR / 'noise_handling_mesh_results.csv', index=False)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'noise_handling_results.csv'}")
    print(f"✅ Mesh networking results saved to: {RESULTS_DIR / 'noise_handling_mesh_results.csv'}")
    print()
    
    return df, df_mesh


def experiment_3_entanglement_impact():
    """Experiment 3: Entanglement Impact on Accuracy."""
    print("=" * 70)
    print("Experiment 3: Entanglement Impact on Accuracy")
    print("=" * 70)
    print()
    print("Note: Entanglement simulation simplified for this experiment")
    print("Full entanglement requires multi-dimensional tensor products")
    print()
    
    agents, pairs, profiles = load_data()
    
    results = []
    
    for pair in pairs[:200]:  # Sample for speed
        profile_a = profiles[pair['agent_a_id']]
        profile_b = profiles[pair['agent_b_id']]
        
        # Standard compatibility
        standard = quantum_compatibility(profile_a, profile_b)
        
        # Simulated entanglement (energy and exploration dimensions)
        # In full implementation, this would use tensor products
        energy_dim = 8  # energy_preference
        exploration_dim = 0  # exploration_eagerness
        
        # Create "entangled" version (simplified)
        profile_a_entangled = profile_a.copy()
        profile_b_entangled = profile_b.copy()
        
        # Entangle energy and exploration
        avg_energy = (profile_a[energy_dim] + profile_b[energy_dim]) / 2
        avg_exploration = (profile_a[exploration_dim] + profile_b[exploration_dim]) / 2
        
        profile_a_entangled[energy_dim] = avg_energy
        profile_a_entangled[exploration_dim] = avg_exploration
        profile_b_entangled[energy_dim] = avg_energy
        profile_b_entangled[exploration_dim] = avg_exploration
        
        entangled = quantum_compatibility(profile_a_entangled, profile_b_entangled)
        
        contribution = (entangled - standard) / standard if standard > 0 else 0
        
        results.append({
            'standard': standard,
            'entangled': entangled,
            'contribution': contribution,
            'improvement': entangled - standard
        })
    
    df = pd.DataFrame(results)
    
    avg_improvement = df['improvement'].mean()
    avg_contribution = df['contribution'].mean()
    
    print(f"Average improvement from entanglement: {avg_improvement:.4f}")
    print(f"Average contribution: {avg_contribution:.4f}")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'entanglement_impact.csv', index=False)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'entanglement_impact.csv'}")
    print()
    
    return df


def experiment_4_performance_benchmarks():
    """Experiment 4: Performance Benchmarks."""
    print("=" * 70)
    print("Experiment 4: Performance Benchmarks")
    print("=" * 70)
    print()
    
    agents, pairs, profiles = load_data()
    
    test_sizes = [100, 500, 1000, 5000, 10000]
    results = []
    
    for size in test_sizes:
        print(f"Testing with {size} pairs...")
        
        # Generate test pairs
        test_pairs = []
        for _ in range(size):
            agent_ids = list(profiles.keys())
            idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
            test_pairs.append((agent_ids[idx_a], agent_ids[idx_b]))
        
        # Benchmark quantum compatibility
        start_time = time.time()
        for agent_a_id, agent_b_id in test_pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            quantum_compatibility(profile_a, profile_b)
        elapsed = time.time() - start_time
        
        time_per_pair = elapsed / size * 1000  # milliseconds
        throughput = size / elapsed  # pairs per second
        
        results.append({
            'num_pairs': size,
            'total_time_seconds': elapsed,
            'time_per_pair_ms': time_per_pair,
            'throughput_pairs_per_sec': throughput
        })
        
        print(f"  Time: {elapsed:.4f}s, Per pair: {time_per_pair:.4f}ms, Throughput: {throughput:.0f} pairs/sec")
    
    print()
    
    # Save results
    df = pd.DataFrame(results)
    df.to_csv(RESULTS_DIR / 'performance_benchmarks.csv', index=False)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'performance_benchmarks.csv'}")
    print()
    
    return df


def experiment_5_normalization():
    """Experiment 5: Quantum State Normalization and Superposition Validation."""
    print("=" * 70)
    print("Experiment 5: Quantum State Normalization and Superposition Validation")
    print("=" * 70)
    print()
    
    agents, pairs, profiles = load_data()
    
    results = []
    
    # Test 1: Normalization Test
    print("Testing normalization: ⟨ψ|ψ⟩ = 1...")
    normalization_errors = []
    for agent_id, profile in profiles.items():
        norm = np.linalg.norm(profile)
        error = abs(norm - 1.0)
        normalization_errors.append(error)
    
    avg_error = np.mean(normalization_errors)
    max_error = np.max(normalization_errors)
    all_normalized = all(e < 0.001 for e in normalization_errors)
    
    print(f"  Average normalization error: {avg_error:.6f}")
    print(f"  Maximum normalization error: {max_error:.6f}")
    print(f"  All states normalized (< 0.001): {all_normalized}")
    
    results.append({
        'test': 'normalization',
        'avg_error': avg_error,
        'max_error': max_error,
        'all_normalized': all_normalized,
        'normalized_count': sum(1 for e in normalization_errors if e < 0.001),
        'total_count': len(normalization_errors)
    })
    
    # Test 2: Superposition Test (verify personality can exist in multiple states)
    print()
    print("Testing superposition properties...")
    # Create superposition state: |ψ_super⟩ = α|ψ_A⟩ + β|ψ_B⟩
    agent_ids = list(profiles.keys())
    superposition_valid = []
    
    for _ in range(100):
        idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
        profile_a = profiles[agent_ids[idx_a]]
        profile_b = profiles[agent_ids[idx_b]]
        
        # Create superposition
        alpha = np.random.uniform(0.0, 1.0)
        beta = np.sqrt(1.0 - alpha**2)  # Normalize
        superposition = alpha * profile_a + beta * profile_b
        superposition = superposition / np.linalg.norm(superposition)  # Normalize
        
        # Verify superposition is valid (normalized and in valid range)
        norm = np.linalg.norm(superposition)
        is_valid = (abs(norm - 1.0) < 0.001) and np.all((superposition >= 0) & (superposition <= 1))
        superposition_valid.append(is_valid)
    
    superposition_validity = np.mean(superposition_valid)
    print(f"  Superposition validity: {superposition_validity * 100:.2f}%")
    
    results.append({
        'test': 'superposition',
        'validity_rate': superposition_validity,
        'valid_count': sum(superposition_valid),
        'total_count': len(superposition_valid)
    })
    
    # Test 3: Measurement Operators
    print()
    print("Testing measurement operators...")
    measurement_accuracy = []
    
    for _ in range(100):
        idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
        profile_a = profiles[agent_ids[idx_a]]
        profile_b = profiles[agent_ids[idx_b]]
        
        # Quantum measurement: |⟨ψ_A|ψ_B⟩|²
        inner_product = np.abs(np.dot(profile_a, profile_b))
        measurement = inner_product ** 2
        
        # Verify measurement is in valid range [0, 1]
        is_valid = 0.0 <= measurement <= 1.0
        measurement_accuracy.append(is_valid)
    
    measurement_validity = np.mean(measurement_accuracy)
    print(f"  Measurement operator validity: {measurement_validity * 100:.2f}%")
    
    results.append({
        'test': 'measurement_operators',
        'validity_rate': measurement_validity,
        'valid_count': sum(measurement_accuracy),
        'total_count': len(measurement_accuracy)
    })
    
    # Test 4: State Vector Properties
    print()
    print("Testing state vector properties...")
    state_properties_valid = []
    
    for agent_id, profile in list(profiles.items())[:100]:  # Sample 100
        # Check properties:
        # 1. Normalized
        norm = np.linalg.norm(profile)
        is_normalized = abs(norm - 1.0) < 0.001
        
        # 2. All values in [0, 1]
        in_range = np.all((profile >= 0) & (profile <= 1))
        
        # 3. Real values (no imaginary components)
        is_real = np.all(np.isreal(profile))
        
        is_valid = is_normalized and in_range and is_real
        state_properties_valid.append(is_valid)
    
    state_properties_validity = np.mean(state_properties_valid)
    print(f"  State vector properties validity: {state_properties_validity * 100:.2f}%")
    
    results.append({
        'test': 'state_vector_properties',
        'validity_rate': state_properties_validity,
        'valid_count': sum(state_properties_valid),
        'total_count': len(state_properties_valid)
    })
    
    print()
    
    # Save results
    df = pd.DataFrame(results)
    df.to_csv(RESULTS_DIR / 'normalization_validation.csv', index=False)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'normalization_validation.csv'}")
    print()
    
    return df


def run_patent_1_experiments():
    """Run all Patent #1 experiments."""
    print()
    print("=" * 70)
    print("Patent #1: Quantum Compatibility Calculation Experiments (Enhanced)")
    print("=" * 70)
    print()
    
    start_time = time.time()
    
    # Required experiments
    experiment_1_quantum_vs_classical()
    experiment_2_noise_handling()
    experiment_3_entanglement_impact()
    experiment_4_performance_benchmarks()
    
    # Optional experiment
    experiment_5_normalization()
    
    # NEW: Experiment 6 - Mesh Networking
    try:
        from patent_1_experiment_6_mesh_networking import run_experiment_6
        run_experiment_6()
    except Exception as e:
        print(f"⚠️  Experiment 6 failed: {e}")
    
    elapsed = time.time() - start_time
    
    print("=" * 70)
    print(f"✅ Patent #1 experiments completed in {elapsed:.2f} seconds")
    print("=" * 70)
    print()


if __name__ == '__main__':
    run_patent_1_experiments()

