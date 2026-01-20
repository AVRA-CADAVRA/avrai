---
name: experiment-testing-standards
description: Enforces experiment testing standards: real implementation testing, no simplified approximations, exact formula matching. Use when creating experiments, testing algorithms, or validating mathematical implementations.
---

# Experiment Testing Standards

## Core Principle

**Experiments must test the REAL implementation, never simplified approximations.**

## Mandatory Requirements

### ✅ REQUIRED
- **Real Implementation Logic** - Use exact same calculations, formulas, and logic as production code
- **Full Feature Testing** - Test complete implementations, not simplified versions
- **Exact Formula Matching** - Quantum state calculations, compatibility formulas must match production exactly
- **Real Data** - Use real Big Five OCEAN data converted to SPOTS dimensions

### ❌ FORBIDDEN
- **Simplified Calculations** - Never use simplified approximations
- **Linear Approximations** - Never use linear approximations of nonlinear operations
- **Mock Implementations** - Never use mock/stub implementations in experiments
- **Partial Testing** - Never test only part of feature with simplified logic

## Example Patterns

### ❌ BAD: Simplified Approximation
```python
# Simplified distance decay (NOT the real implementation)
location_compatibility = exp(-decay_rate * distance_km)
```

### ✅ GOOD: Real Implementation
```python
# Real quantum state inner product (matches production code)
location_state = create_location_quantum_state(
    lat, lon, type, accessibility, vibe
)
compatibility = abs(inner_product(location_state_a, location_state_b)) ** 2
```

## Real Data Requirement

**All experiments MUST use real Big Five OCEAN data:**

```python
from shared_data_model import load_and_convert_big_five_to_spots

# Load and convert Big Five OCEAN to SPOTS 12
spots_profiles = load_and_convert_big_five_to_spots(
    max_profiles=1000,
    data_source='auto',
    project_root=project_root
)
```

**❌ FORBIDDEN:**
- Synthetic data generation
- Hardcoded personality dimensions
- Simplified approximations

## Checklist

- [ ] Experiment uses exact same formulas as production code
- [ ] Quantum state calculations match production implementation
- [ ] No simplified approximations used
- [ ] All mathematical operations match production code
- [ ] Uses real Big Five OCEAN data (not synthetic)
- [ ] Experiment logic documented with references to production code

## Reference

- `.cursorrules` - Experiment Testing Standards section
- `docs/plans/test_refactoring/TEST_WRITING_GUIDE.md`
