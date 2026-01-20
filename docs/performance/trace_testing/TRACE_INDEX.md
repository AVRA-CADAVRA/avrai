# Trace Index

**Catalog of all captured Instruments traces for performance analysis.**

**Last Updated:** January 16, 2025

---

## Index Format

Each entry includes:
- **Filename:** Trace file name
- **Date:** Capture date
- **Category:** baseline | optimization | feature
- **Purpose:** What was being tested
- **Key Metrics:** Startup time, context switches, etc.
- **Status:** ✅ Analyzed | ⏳ Pending | 📊 In Progress
- **Results:** Link to analysis results

---

## Baseline Traces

### Startup Performance

| Filename | Date | Purpose | Key Metrics | Status | Results |
|----------|------|---------|-------------|--------|---------|
| `startup_baseline_20250116.trace` | 2025-01-16 | Initial baseline before optimizations | TTFF: ~5-8s, Context switches: High | ⏳ Pending | - |

---

## Optimization Traces

### Startup Optimization

| Filename | Date | Optimization | Improvement | Status | Results |
|----------|------|--------------|-------------|--------|---------|
| `startup_deferred_init_20250116.trace` | 2025-01-16 | Deferred non-critical services | Target: 50-70% faster | ⏳ Pending | - |

### Threading Optimization

| Filename | Date | Optimization | Improvement | Status | Results |
|----------|------|--------------|-------------|--------|---------|
| `ble_throttling_20250116.trace` | 2025-01-16 | BLE operation throttling | Target: 30-40% fewer context switches | ⏳ Pending | - |

---

## Feature Traces

| Filename | Date | Feature | Purpose | Status | Results |
|----------|------|---------|---------|--------|---------|
| - | - | - | - | - | - |

---

## Analysis Status Legend

- ✅ **Analyzed** - Analysis complete, results available
- ⏳ **Pending** - Trace captured, analysis not started
- 📊 **In Progress** - Analysis currently in progress
- ❌ **Failed** - Analysis failed, needs review

---

## Adding New Traces

1. Capture trace following [Naming Conventions](NAMING_CONVENTIONS.md)
2. Add entry to this index
3. Extract metrics using `scripts/extract_metrics.py`
4. Update status as analysis progresses
5. Link to results in `results/` folder when complete

---

## Trace Retention

- **Active:** Last 3 months
- **Archive:** 3-6 months (keep metrics, archive trace files)
- **Delete:** Older than 6 months (unless marked for long-term retention)

---

## Notes

- Baseline traces should be captured before major optimizations
- Compare optimization traces against most recent baseline
- Document any special conditions (device, OS version, network state)
