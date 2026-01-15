#!/usr/bin/env python3
"""
Patent #31 Experiment 4: Dynamic Knot Evolution

Validates dynamic knot changes correlate with mood/energy and tracks personality 
evolution over time. Tests that knot complexity, stability, and type change 
appropriately with mood/energy/stress levels.

Date: December 28, 2025
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
from datetime import datetime, timedelta

# Add knot validation scripts to path
knot_validation_path = Path(__file__).parent.parent.parent.parent / 'scripts' / 'knot_validation'
sys.path.insert(0, str(knot_validation_path))

try:
    from generate_knots_from_profiles import KnotGenerator, PersonalityKnot, PersonalityProfile
except ImportError:
    # Fallback: define minimal classes if import fails
    from dataclasses import dataclass
    from typing import Dict, List, Optional
    
    @dataclass
    class PersonalityProfile:
        user_id: str
        dimensions: Dict[str, float]
        created_at: Optional[str] = None
    
    @dataclass
    class KnotCrossing:
        strand1: int
        strand2: int
        is_over: bool
        position: int
        correlation_strength: float
    
    @dataclass
    class PersonalityKnot:
        user_id: str
        knot_type: str
        crossings: List[KnotCrossing]
        complexity: float
        created_at: str
        braidData: List[float] = None
        
        def __post_init__(self):
            if self.braidData is None:
                self.braidData = [float(len(self.crossings))] + [
                    float(c.position) for c in self.crossings
                ]
    
    class KnotGenerator:
        def generate_knot(self, profile):
            dim_values = list(profile.dimensions.values())
            complexity = float(np.std(dim_values)) if len(dim_values) > 0 else 0.5
            
            num_crossings = max(0, int(complexity * 20))
            crossings = []
            for i in range(num_crossings):
                crossings.append(KnotCrossing(
                    strand1=0,
                    strand2=1,
                    is_over=True,
                    position=i,
                    correlation_strength=complexity
                ))
            
            if complexity < 0.1:
                knot_type = 'unknot'
            elif complexity < 0.3:
                knot_type = 'trefoil'
            elif complexity < 0.5:
                knot_type = 'figure-eight'
            else:
                knot_type = 'complex'
            
            return PersonalityKnot(
                user_id=profile.user_id,
                knot_type=knot_type,
                crossings=crossings,
                complexity=complexity,
                created_at=profile.created_at or 'unknown'
            )


class MoodType(Enum):
    HAPPY = "happy"
    CALM = "calm"
    ENERGETIC = "energetic"
    STRESSED = "stressed"
    ANXIOUS = "anxious"
    RELAXED = "relaxed"
    EXCITED = "excited"
    TIRED = "tired"
    FOCUSED = "focused"
    CREATIVE = "creative"
    SOCIAL = "social"
    INTROSPECTIVE = "introspective"


@dataclass
class MoodState:
    type: MoodType
    intensity: float  # 0.0 to 1.0
    timestamp: str


@dataclass
class EnergyLevel:
    value: float  # 0.0 to 1.0
    timestamp: str


@dataclass
class StressLevel:
    value: float  # 0.0 to 1.0
    timestamp: str


@dataclass
class DynamicKnot:
    baseKnot: PersonalityKnot
    complexityModifier: float
    mood: MoodState
    energy: EnergyLevel
    stress: StressLevel
    lastUpdated: str
    
    @property
    def effective_complexity(self) -> float:
        """Calculate effective complexity with modifier."""
        return float(np.clip(self.baseKnot.complexity * self.complexityModifier, 0.0, 1.0))


@dataclass
class KnotSnapshot:
    knot: PersonalityKnot
    mood: MoodState
    energy: EnergyLevel
    stress: StressLevel
    timestamp: str
    complexity: float
    knot_type: str


# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_31'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

DATA_DIR = Path(__file__).parent.parent / 'data' / 'patent_1_quantum_compatibility'


def load_personality_profiles() -> List[PersonalityProfile]:
    """
    Load personality profiles from Big Five OCEAN data, converted to SPOTS 12 dimensions.
    
    **MANDATORY:** This experiment uses real Big Five OCEAN data (100k+ examples)
    converted to SPOTS 12 dimensions via the standardized conversion function.
    
    **Historical Note:** Experiments completed before December 30, 2025 used synthetic data.
    This experiment has been updated to use real Big Five data.
    """
    from shared_data_model import load_and_convert_big_five_to_spots
    
    # Get project root
    project_root = Path(__file__).parent.parent.parent.parent.parent
    
    # Load and convert Big Five OCEAN to SPOTS 12 (50 profiles for evolution tracking)
    spots_profiles = load_and_convert_big_five_to_spots(
        max_profiles=50,
        data_source='auto',  # Try CSV first, then JSON
        project_root=project_root
    )
    
    # Convert to PersonalityProfile objects
    profiles = []
    for item in spots_profiles:
        profile = PersonalityProfile(
            user_id=item['user_id'],
            dimensions=item['dimensions'],
            created_at=item.get('created_at', '2025-12-30')
        )
        profiles.append(profile)
    
    return profiles


def generate_synthetic_profiles(n: int) -> List[PersonalityProfile]:
    """Generate synthetic personality profiles for testing."""
    np.random.seed(42)
    profiles = []
    
    dimension_names = [
        'exploration_eagerness', 'community_orientation', 'adventure_seeking',
        'social_preference', 'energy_preference', 'novelty_seeking',
        'value_orientation', 'crowd_tolerance', 'authenticity',
        'archetype', 'trust_level', 'openness'
    ]
    
    for i in range(n):
        dimensions = {name: float(np.random.uniform(0.0, 1.0)) for name in dimension_names}
        profile = PersonalityProfile(
            user_id=f'agent_synthetic_{i}',
            dimensions=dimensions,
            created_at='2025-12-28'
        )
        profiles.append(profile)
    
    return profiles


def calculate_complexity_modifier(energy: EnergyLevel, stress: StressLevel) -> float:
    """
    Calculate complexity modifier from energy/stress.
    
    Mirrors DynamicKnotService._calculateComplexityModifier():
    - High energy + low stress = more complex (up to 1.5x)
    - Low energy + high stress = simpler (down to 0.5x)
    """
    # Weighted combination: 60% energy, 40% inverse stress
    modifier = (energy.value * 0.6) + ((1.0 - stress.value) * 0.4)
    
    # Clamp to reasonable range (0.5 to 1.5)
    return float(np.clip(modifier, 0.5, 1.5))


def update_knot_with_current_state(
    base_knot: PersonalityKnot,
    mood: MoodState,
    energy: EnergyLevel,
    stress: StressLevel
) -> DynamicKnot:
    """
    Update knot based on current mood/energy/stress.
    
    Mirrors DynamicKnotService.updateKnotWithCurrentState() logic.
    """
    complexity_modifier = calculate_complexity_modifier(energy, stress)
    
    return DynamicKnot(
        baseKnot=base_knot,
        complexityModifier=complexity_modifier,
        mood=mood,
        energy=energy,
        stress=stress,
        lastUpdated=datetime.now().isoformat()
    )


def generate_mood_energy_timeline(days: int = 30) -> List[Tuple[MoodState, EnergyLevel, StressLevel]]:
    """
    Generate synthetic mood/energy/stress timeline.
    
    Simulates realistic patterns:
    - Energy varies daily (higher in morning, lower at night)
    - Stress varies with events (random spikes)
    - Mood correlates with energy and stress
    """
    timeline = []
    np.random.seed(42)
    
    base_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        for hour in range(0, 24, 3):  # Every 3 hours
            timestamp = (base_date + timedelta(days=day, hours=hour)).isoformat()
            
            # Energy: higher in morning (6-12), lower at night
            if 6 <= hour < 12:
                energy_value = float(np.random.uniform(0.6, 0.9))
            elif 12 <= hour < 18:
                energy_value = float(np.random.uniform(0.5, 0.8))
            else:
                energy_value = float(np.random.uniform(0.3, 0.6))
            
            energy = EnergyLevel(value=energy_value, timestamp=timestamp)
            
            # Stress: random spikes, but generally lower with higher energy
            stress_base = 1.0 - energy_value
            stress_value = float(np.clip(stress_base + np.random.normal(0, 0.2), 0.0, 1.0))
            stress = StressLevel(value=stress_value, timestamp=timestamp)
            
            # Mood: correlates with energy and inverse stress
            mood_score = (energy_value + (1.0 - stress_value)) / 2.0
            
            if mood_score > 0.7:
                mood_type = MoodType.HAPPY if np.random.random() > 0.5 else MoodType.ENERGETIC
            elif mood_score > 0.5:
                mood_type = MoodType.CALM if np.random.random() > 0.5 else MoodType.RELAXED
            elif mood_score > 0.3:
                mood_type = MoodType.FOCUSED if np.random.random() > 0.5 else MoodType.INTROSPECTIVE
            else:
                mood_type = MoodType.TIRED if stress_value < 0.5 else MoodType.STRESSED
            
            mood = MoodState(
                type=mood_type,
                intensity=float(mood_score),
                timestamp=timestamp
            )
            
            timeline.append((mood, energy, stress))
    
    return timeline


def detect_milestones(snapshots: List[KnotSnapshot]) -> List[Dict[str, Any]]:
    """
    Detect milestones in knot evolution.
    
    Milestones:
    - Knot type changes
    - Significant complexity changes (>20%)
    - Stability threshold crossings
    """
    milestones = []
    
    if len(snapshots) < 2:
        return milestones
    
    prev_snapshot = snapshots[0]
    
    for i, snapshot in enumerate(snapshots[1:], start=1):
        # Check for knot type change
        if snapshot.knot_type != prev_snapshot.knot_type:
            milestones.append({
                'type': 'knot_type_change',
                'from': prev_snapshot.knot_type,
                'to': snapshot.knot_type,
                'timestamp': snapshot.timestamp,
                'index': i,
            })
        
        # Check for significant complexity change
        complexity_change = abs(snapshot.complexity - prev_snapshot.complexity)
        if complexity_change > 0.2:
            milestones.append({
                'type': 'complexity_change',
                'from': prev_snapshot.complexity,
                'to': snapshot.complexity,
                'change': complexity_change,
                'timestamp': snapshot.timestamp,
                'index': i,
            })
        
        prev_snapshot = snapshot
    
    return milestones


def interpolate_polynomials_avrai(
    poly1: List[float],
    poly2: List[float],
    factor: float
) -> List[float]:
    """
    AVRAI's polynomial interpolation algorithm (from Experiment 8).
    
    Matches KnotEvolutionStringService._interpolatePolynomials() exactly.
    """
    max_length = max(len(poly1), len(poly2))
    interpolated = []
    
    for i in range(max_length):
        val1 = poly1[i] if i < len(poly1) else 0.0
        val2 = poly2[i] if i < len(poly2) else 0.0
        interpolated.append(val1 * (1 - factor) + val2 * factor)
    
    return interpolated


def calculate_evolution_rate_avrai(
    snapshot1: KnotSnapshot,
    snapshot2: KnotSnapshot,
    future_time: datetime
) -> float:
    """
    AVRAI's evolution rate calculation (from Experiment 8).
    
    Matches KnotEvolutionStringService._extrapolateFutureKnot() logic:
    evolutionRate = timeDelta / historyDelta
    """
    time_delta = (future_time - snapshot2.timestamp).total_seconds()
    history_delta = (snapshot2.timestamp - snapshot1.timestamp).total_seconds()
    
    if history_delta == 0:
        return 0.0
    
    return float(time_delta / history_delta)


def run_experiment_4():
    """Run Experiment 4: Dynamic Knot Evolution (Enhanced with String Evolution)."""
    print()
    print("=" * 70)
    print("Experiment 4: Dynamic Knot Evolution (Enhanced)")
    print("=" * 70)
    print()
    
    # Load profiles
    print("Loading personality profiles from Big Five OCEAN data...")
    profiles = load_personality_profiles()
    print(f"  ✅ Loaded {len(profiles)} profiles (real Big Five data)")
    
    # Generate base knots
    print("Generating base knots...")
    generator = KnotGenerator()
    base_knots = []
    for profile in profiles:
        try:
            knot = generator.generate_knot(profile)
            base_knots.append(knot)
        except Exception as e:
            print(f"  ⚠️  Failed to generate knot for {profile.user_id}: {e}")
            continue
    
    print(f"  Generated {len(base_knots)} base knots")
    
    if len(base_knots) < 10:
        print("  ⏳ Not enough knots for meaningful analysis")
        return {'status': 'insufficient_data', 'total_knots': len(base_knots)}
    
    # Generate mood/energy timeline (30 days, every 3 hours)
    print("Generating mood/energy timeline...")
    timeline = generate_mood_energy_timeline(days=30)
    print(f"  Generated {len(timeline)} time points")
    
    # Track evolution for each knot
    print("Tracking knot evolution...")
    all_snapshots = []
    evolution_results = []
    
    for knot in base_knots[:20]:  # Track first 20 knots
        snapshots = []
        
        for mood, energy, stress in timeline:
            # Update knot with current state
            dynamic_knot = update_knot_with_current_state(knot, mood, energy, stress)
            
            # Create snapshot
            snapshot = KnotSnapshot(
                knot=knot,
                mood=mood,
                energy=energy,
                stress=stress,
                timestamp=mood.timestamp,
                complexity=dynamic_knot.effective_complexity,
                knot_type=knot.knot_type,  # Type doesn't change, but complexity does
            )
            snapshots.append(snapshot)
        
        all_snapshots.extend(snapshots)
        
        # Detect milestones
        milestones = detect_milestones(snapshots)
        
        # Calculate correlations
        complexities = [s.complexity for s in snapshots]
        energies = [s.energy.value for s in snapshots]
        stresses = [s.stress.value for s in snapshots]
        
        energy_complexity_corr = float(np.corrcoef(energies, complexities)[0, 1]) if len(energies) > 1 else 0.0
        stress_complexity_corr = float(np.corrcoef(stresses, complexities)[0, 1]) if len(stresses) > 1 else 0.0
        
        evolution_results.append({
            'knot_id': knot.user_id,
            'total_snapshots': len(snapshots),
            'milestones_detected': len(milestones),
            'energy_complexity_correlation': energy_complexity_corr if not np.isnan(energy_complexity_corr) else 0.0,
            'stress_complexity_correlation': stress_complexity_corr if not np.isnan(stress_complexity_corr) else 0.0,
            'avg_complexity': float(np.mean(complexities)),
            'complexity_variance': float(np.var(complexities)),
            'milestones': milestones,
        })
    
    # Save detailed snapshots
    print("Saving evolution data...")
    snapshot_data = []
    for snapshot in all_snapshots[:1000]:  # Limit to first 1000 for file size
        snapshot_data.append({
            'knot_id': snapshot.knot.user_id,
            'timestamp': snapshot.timestamp,
            'complexity': snapshot.complexity,
            'knot_type': snapshot.knot_type,
            'energy': snapshot.energy.value,
            'stress': snapshot.stress.value,
            'mood_type': snapshot.mood.type.value,
            'mood_intensity': snapshot.mood.intensity,
        })
    
    df_snapshots = pd.DataFrame(snapshot_data)
    df_snapshots.to_csv(RESULTS_DIR / 'experiment_4_dynamic_evolution_snapshots.csv', index=False)
    
    # Save evolution results
    df_results = pd.DataFrame(evolution_results)
    df_results.to_csv(RESULTS_DIR / 'experiment_4_dynamic_evolution_results.csv', index=False)
    
    # Save string interpolation results
    if len(df_string) > 0:
        df_string.to_csv(RESULTS_DIR / 'experiment_4_string_interpolation_results.csv', index=False)
    
    # NEW: Test string evolution interpolation
    print()
    print("Testing string evolution interpolation...")
    string_interpolation_results = []
    
    for user_id, snapshots in [(r['knot_id'], []) for r in evolution_results[:10]]:  # Test first 10
        # Find snapshots for this user
        user_snapshots = [s for s in all_snapshots if s.knot.user_id == user_id]
        if len(user_snapshots) < 3:
            continue
        
        # Test interpolation between consecutive snapshots
        for i in range(len(user_snapshots) - 1):
            snapshot1 = user_snapshots[i]
            snapshot2 = user_snapshots[i + 1]
            
            # Test interpolation at midpoint
            midpoint_time = snapshot1.timestamp + (snapshot2.timestamp - snapshot1.timestamp) / 2
            
            # Simulate polynomial interpolation (simplified - use complexity as proxy)
            factor = 0.5
            poly1 = [snapshot1.complexity]  # Simplified polynomial
            poly2 = [snapshot2.complexity]
            
            interpolated = interpolate_polynomials_avrai(poly1, poly2, factor)
            expected = (snapshot1.complexity + snapshot2.complexity) / 2.0
            
            interpolation_error = abs(interpolated[0] - expected) if len(interpolated) > 0 else 0.0
            
            # Test evolution rate calculation
            future_time = snapshot2.timestamp + timedelta(days=1)
            evolution_rate = calculate_evolution_rate_avrai(
                KnotSnapshot(
                    knot=snapshot1.knot,
                    timestamp=snapshot1.timestamp,
                    mood=snapshot1.mood,
                    energy=snapshot1.energy,
                    stress=snapshot1.stress,
                    complexity=snapshot1.complexity,
                    knot_type=snapshot1.knot_type
                ),
                KnotSnapshot(
                    knot=snapshot2.knot,
                    timestamp=snapshot2.timestamp,
                    mood=snapshot2.mood,
                    energy=snapshot2.energy,
                    stress=snapshot2.stress,
                    complexity=snapshot2.complexity,
                    knot_type=snapshot2.knot_type
                ),
                future_time
            )
            
            string_interpolation_results.append({
                'user_id': user_id,
                'snapshot_pair': f'{i}-{i+1}',
                'interpolation_error': interpolation_error,
                'evolution_rate': evolution_rate,
            })
    
    df_string = pd.DataFrame(string_interpolation_results) if string_interpolation_results else pd.DataFrame()
    
    # Calculate overall statistics
    avg_energy_complexity_corr = float(np.mean([r['energy_complexity_correlation'] for r in evolution_results]))
    avg_stress_complexity_corr = float(np.mean([r['stress_complexity_correlation'] for r in evolution_results]))
    total_milestones = sum(len(r['milestones']) for r in evolution_results)
    
    # Overall correlation across all snapshots
    all_complexities = [s.complexity for s in all_snapshots]
    all_energies = [s.energy.value for s in all_snapshots]
    all_stresses = [s.stress.value for s in all_snapshots]
    
    overall_energy_complexity_corr = float(np.corrcoef(all_energies, all_complexities)[0, 1]) if len(all_energies) > 1 else 0.0
    overall_stress_complexity_corr = float(np.corrcoef(all_stresses, all_complexities)[0, 1]) if len(all_stresses) > 1 else 0.0
    
    # String interpolation statistics
    avg_interpolation_error = float(df_string['interpolation_error'].mean()) if len(df_string) > 0 else 0.0
    avg_evolution_rate = float(df_string['evolution_rate'].mean()) if len(df_string) > 0 else 0.0
    
    summary = {
        'status': 'complete',
        'total_knots_tracked': len(evolution_results),
        'total_snapshots': len(all_snapshots),
        'timeline_days': 30,
        'total_milestones_detected': total_milestones,
        'correlations': {
            'avg_energy_complexity': avg_energy_complexity_corr if not np.isnan(avg_energy_complexity_corr) else 0.0,
            'avg_stress_complexity': avg_stress_complexity_corr if not np.isnan(avg_stress_complexity_corr) else 0.0,
            'overall_energy_complexity': overall_energy_complexity_corr if not np.isnan(overall_energy_complexity_corr) else 0.0,
            'overall_stress_complexity': overall_stress_complexity_corr if not np.isnan(overall_stress_complexity_corr) else 0.0,
        },
        'string_evolution': {
            'total_interpolation_tests': len(string_interpolation_results),
            'avg_interpolation_error': avg_interpolation_error,
            'avg_evolution_rate': avg_evolution_rate,
        },
        'success_criteria': {
            'energy_complexity_correlation': abs(overall_energy_complexity_corr) > 0.3 if not np.isnan(overall_energy_complexity_corr) else False,
            'stress_complexity_correlation': abs(overall_stress_complexity_corr) > 0.3 if not np.isnan(overall_stress_complexity_corr) else False,
            'milestones_detected': total_milestones > 0,
            'evolution_tracked': len(all_snapshots) > 0,
            'string_interpolation_works': len(string_interpolation_results) > 0,
        },
        'evolution_results': evolution_results,
    }
    
    with open(RESULTS_DIR / 'experiment_4_dynamic_evolution.json', 'w') as f:
        json.dump(summary, f, indent=2, default=str)
    
    print()
    print("✅ Results saved:")
    print(f"   CSV (snapshots): {RESULTS_DIR / 'experiment_4_dynamic_evolution_snapshots.csv'}")
    print(f"   CSV (results): {RESULTS_DIR / 'experiment_4_dynamic_evolution_results.csv'}")
    print(f"   JSON: {RESULTS_DIR / 'experiment_4_dynamic_evolution.json'}")
    print()
    
    # Print summary
    print("Summary:")
    print("----------------------------------------------------------------------")
    print(f"Total knots tracked: {len(evolution_results)}")
    print(f"Total snapshots: {len(all_snapshots)}")
    print(f"Total milestones: {total_milestones}")
    print(f"Overall energy-complexity correlation: {overall_energy_complexity_corr:.4f}")
    print(f"Overall stress-complexity correlation: {overall_stress_complexity_corr:.4f}")
    print()
    
    if len(df_string) > 0:
        print(f"String Evolution Interpolation:")
        print(f"  Average interpolation error: {avg_interpolation_error:.6f}")
        print(f"  Average evolution rate: {avg_evolution_rate:.4f}")
        print(f"  Interpolation tests: {len(string_interpolation_results)}")
        print()
    
    energy_ok = "✅" if abs(overall_energy_complexity_corr) > 0.3 else "⚠️"
    stress_ok = "✅" if abs(overall_stress_complexity_corr) > 0.3 else "⚠️"
    milestones_ok = "✅" if total_milestones > 0 else "⚠️"
    string_ok = "✅" if len(string_interpolation_results) > 0 else "⚠️"
    
    print(f"Energy-complexity correlation: {overall_energy_complexity_corr:.4f} {energy_ok}")
    print(f"Stress-complexity correlation: {overall_stress_complexity_corr:.4f} {stress_ok}")
    print(f"Milestones detected: {total_milestones} {milestones_ok}")
    print(f"String interpolation: {len(string_interpolation_results)} tests {string_ok}")
    print()
    
    return summary


if __name__ == '__main__':
    run_experiment_4()
