# Trace Naming Conventions

**Purpose:** Ensure consistent, searchable trace file names for easy organization and identification.

---

## Format

```
{category}_{optimization_or_feature}_{date}.trace
```

### Components

- **category:** `startup` | `ble` | `memory` | `cpu` | `feature` | `baseline`
- **optimization_or_feature:** Specific optimization name or feature (kebab-case)
- **date:** `YYYYMMDD` format

---

## Examples

### Baseline Traces
```
startup_baseline_20250116.trace
ble_baseline_20250116.trace
memory_baseline_20250116.trace
```

### Optimization Traces
```
startup_deferred_init_20250116.trace
ble_throttling_optimized_20250116.trace
startup_lazy_loading_20250116.trace
memory_cache_optimization_20250116.trace
```

### Feature Traces
```
feature_quantum_matching_20250116.trace
feature_signal_protocol_20250116.trace
feature_ai2ai_discovery_20250116.trace
```

### Comparison Traces
```
startup_before_after_20250116.trace  # Single trace with both scenarios
startup_optimization_comparison_20250116.trace
```

---

## Categories

### `startup`
App startup performance, initialization sequence

### `ble`
Bluetooth Low Energy operations, device discovery

### `memory`
Memory usage patterns, leaks, allocation performance

### `cpu`
CPU usage, hot functions, processing bottlenecks

### `feature`
Specific feature performance (quantum matching, AI2AI, etc.)

### `baseline`
Initial state before optimizations (always use `baseline` suffix)

---

## Special Suffixes

- `_baseline` - Initial state before changes
- `_optimized` - After optimization applied
- `_before` - Before specific change
- `_after` - After specific change
- `_comparison` - Side-by-side comparison trace

---

## Best Practices

1. **Be specific:** Include the exact optimization/feature name
2. **Use kebab-case:** All lowercase, words separated by hyphens
3. **Include date:** Always use YYYYMMDD format
4. **Be descriptive:** Name should indicate what was tested
5. **Avoid spaces:** No spaces in filenames

---

## Examples of Good Names

✅ `startup_deferred_initialization_20250116.trace`
✅ `ble_throttling_optimization_20250116.trace`
✅ `feature_quantum_matching_20250116.trace`
✅ `memory_leak_investigation_20250116.trace`

---

## Examples of Bad Names

❌ `trace1.trace` (not descriptive)
❌ `startup test.trace` (has space)
❌ `startup_test_jan16.trace` (ambiguous date)
❌ `Startup_Baseline_2025-01-16.trace` (mixed case, wrong date format)

---

## Folder Organization

Traces are organized by category in subfolders:
- `traces/baseline/` - Baseline traces
- `traces/optimizations/` - Optimization traces
- `traces/features/` - Feature-specific traces

File name should still include category prefix for portability and searchability.
