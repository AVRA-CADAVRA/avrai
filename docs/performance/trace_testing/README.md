# Trace Testing Documentation

**Purpose:** Track and analyze Instruments trace files to measure performance improvements and identify optimization opportunities.

**Last Updated:** January 16, 2025

---

## Quick Start

1. **Capture a trace:**
   ```bash
   # See HOW_TO_CAPTURE.md for detailed instructions
   instruments -t "Time Profiler" -D traces/baseline/startup_baseline_20250116.trace your_app.app
   ```

2. **Extract data from trace:**
   ```bash
   python3 scripts/extract_trace_data.py traces/baseline/startup_baseline_20250116.trace
   ```

3. **Compare traces:**
   ```bash
   python3 scripts/compare_traces.py traces/baseline/startup_baseline_20250116.trace traces/optimizations/startup_optimized_20250116.trace
   ```

---

## Documentation

- **[Trace Index](TRACE_INDEX.md)** - Catalog of all captured traces
- **[Naming Conventions](NAMING_CONVENTIONS.md)** - How to name trace files consistently
- **[How to Capture](HOW_TO_CAPTURE.md)** - Step-by-step trace capture instructions
- **[How to Analyze](HOW_TO_ANALYZE.md)** - Guide for analyzing traces and extracting insights
- **[Metrics Tracker](METRICS_TRACKER.md)** - Performance metrics over time

---

## Folder Structure

```
trace_testing/
├── traces/              # Actual trace files (.trace - gitignored)
│   ├── baseline/        # Baseline traces before optimizations
│   ├── optimizations/   # Traces after specific optimizations
│   └── features/        # Feature-specific traces
├── scripts/             # Analysis scripts
├── results/             # Analysis results and reports
│   ├── comparisons/     # Before/after comparison reports
│   ├── metrics/         # Extracted metrics (CSV/JSON)
│   └── reports/         # Comprehensive analysis reports
└── templates/           # Documentation templates
```

---

## Workflow

### Before Optimization
1. Capture baseline trace → `traces/baseline/`
2. Extract baseline metrics → `results/metrics/`
3. Document in [Trace Index](TRACE_INDEX.md)

### After Optimization
1. Capture optimized trace → `traces/optimizations/`
2. Compare with baseline → `scripts/compare_traces.py`
3. Generate report → `results/comparisons/`
4. Update [Metrics Tracker](METRICS_TRACKER.md)

### Regular Reviews
- Monthly: Review [Metrics Tracker](METRICS_TRACKER.md) for trends
- Quarterly: Generate comprehensive performance report
- After major releases: Capture new baseline traces

---

## Key Metrics Tracked

- **Startup Time** (Time to First Frame - TTFF)
- **Context Switches** (Thread switching overhead)
- **Memory Usage** (Peak and average)
- **CPU Usage** (Hot functions, call stacks)
- **Thread Count** (Concurrent thread activity)
- **Battery Impact** (Estimated from thread/CPU activity)

---

## Common Use Cases

### Testing Startup Performance
1. Capture baseline: `startup_baseline_[date].trace`
2. Apply optimizations (e.g., deferred initialization)
3. Capture optimized: `startup_[optimization]_[date].trace`
4. Compare and measure improvement

### Testing Feature Performance
1. Capture feature trace: `feature_[name]_[date].trace`
2. Analyze hot functions and bottlenecks
3. Document findings in results folder

### Debugging Performance Issues
1. Capture trace during issue reproduction
2. Analyze with Instruments UI
3. Extract relevant metrics
4. Document issue and solution

---

## Related Documentation

- [Performance Optimization Guide](../TOKIO_OPTIMIZATION.md)
- [Performance Insights](../../../AVRAI%20test%201.trace/PERFORMANCE_INSIGHTS.md)

---

## Notes

- **Trace files are large** - keep them locally, add `traces/**/*.trace` to `.gitignore`
- **Version control** - Commit scripts and documentation, not trace files
- **Retention policy** - Keep traces for 6 months, archive older ones
- **Storage** - Each trace can be 10-100MB, plan storage accordingly
