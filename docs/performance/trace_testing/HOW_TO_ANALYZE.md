# How to Analyze Instruments Traces

**Guide for analyzing trace files to extract performance insights and identify optimizations.**

---

## Quick Start

### Using Analysis Scripts

1. **Extract metrics from trace:**
   ```bash
   python3 scripts/extract_metrics.py traces/baseline/startup_baseline_20250116.trace
   ```

2. **Compare two traces:**
   ```bash
   python3 scripts/compare_traces.py \
     traces/baseline/startup_baseline_20250116.trace \
     traces/optimizations/startup_deferred_init_20250116.trace
   ```

3. **Generate report:**
   ```bash
   python3 scripts/generate_report.py \
     --baseline traces/baseline/startup_baseline_20250116.trace \
     --optimized traces/optimizations/startup_deferred_init_20250116.trace \
     --output results/comparisons/startup_comparison_20250116.md
   ```

---

## Using Instruments GUI

### Opening a Trace

1. **Double-click** `.trace` file, or
2. **Instruments → File → Open**
3. Select your trace file

### Key Views

#### Time Profiler View

**What to look for:**
- **Heaviest stack trace** - Functions taking most CPU time
- **Call tree** - Function call hierarchy
- **Sample count** - How often functions are called
- **Self weight** - Time spent in function itself (not children)

**Actions:**
- Sort by "Weight" to find hot functions
- Expand call trees to see callers
- Use search to find specific functions
- Focus on functions with high sample counts

#### System Trace View

**What to look for:**
- **Thread activity** - Thread creation/destruction
- **Context switches** - Thread switching frequency
- **CPU cores** - Core utilization
- **I/O operations** - Disk/network activity

**Actions:**
- Look for excessive thread creation
- Identify threads with many context switches
- Check for I/O bottlenecks

#### Allocations View

**What to look for:**
- **Memory growth** - Steadily increasing memory
- **Large allocations** - Unusually large memory allocations
- **Allocation hotspots** - Where memory is allocated

**Actions:**
- Use "Mark Generation" to track allocations over time
- Sort by size to find large allocations
- Look for memory that never decreases (potential leaks)

---

## Key Metrics to Extract

### Startup Performance

1. **Time to First Frame (TTFF)**
   - Measure from app launch to first UI render
   - Look in Time Profiler timeline

2. **Initialization Time**
   - Time spent in `main()` function
   - Time for service initialization

3. **UI Render Time**
   - Time from first frame to interactive UI

### Threading Performance

1. **Context Switch Count**
   - Number of thread context switches
   - Lower is better

2. **Thread Count**
   - Peak concurrent threads
   - Average thread count

3. **Thread Creation/Destruction**
   - Frequency of thread lifecycle events

### Memory Performance

1. **Peak Memory**
   - Maximum memory usage
   - Compare before/after optimizations

2. **Memory Growth Rate**
   - Rate of memory increase over time
   - Should stabilize after startup

3. **Allocation Rate**
   - Allocations per second
   - Should decrease after initialization

---

## Analysis Workflow

### 1. Baseline Analysis

1. Open baseline trace in Instruments
2. Identify key metrics:
   - Startup time
   - Hot functions (top 10)
   - Thread count/context switches
   - Memory usage
3. Document findings in `results/metrics/baseline_[date].csv`

### 2. Optimization Analysis

1. Open optimized trace
2. Extract same metrics as baseline
3. Compare values:
   - Startup time: % improvement
   - Context switches: % reduction
   - Thread count: absolute change
4. Document in `results/metrics/optimized_[date].csv`

### 3. Comparison Report

1. Use comparison script or manual comparison
2. Calculate improvements:
   - `improvement = (baseline - optimized) / baseline * 100`
3. Generate report in `results/comparisons/`
4. Update [Metrics Tracker](METRICS_TRACKER.md)

---

## Common Patterns to Look For

### Performance Issues

#### High CPU in Main Thread
**Symptom:** Main thread shows high CPU usage during startup
**Solution:** Move work off main thread, defer initialization

#### Excessive Context Switches
**Symptom:** Many thread switches in short time
**Solution:** Reduce concurrent operations, batch async work

#### Memory Leaks
**Symptom:** Memory steadily increases, never decreases
**Solution:** Check for circular references, unclosed resources

#### Long Initialization
**Symptom:** Long time in `main()` or initialization functions
**Solution:** Defer non-critical initialization, lazy load services

### Good Patterns

#### Smooth Threading
- Low context switch rate
- Stable thread count
- Threads used for I/O operations

#### Efficient Startup
- Quick time to first frame
- Deferred heavy operations
- Minimal blocking in main thread

---

## Using Analysis Scripts

### extract_metrics.py

Extract key metrics from a trace:

```bash
python3 scripts/extract_metrics.py \
  traces/baseline/startup_baseline_20250116.trace \
  --output results/metrics/baseline_20250116.json
```

**Output includes:**
- Startup time
- Context switch count
- Thread statistics
- Memory metrics
- Hot functions

### compare_traces.py

Compare two traces:

```bash
python3 scripts/compare_traces.py \
  traces/baseline/startup_baseline_20250116.trace \
  traces/optimizations/startup_deferred_init_20250116.trace \
  --output results/comparisons/startup_improvement_20250116.md
```

**Output includes:**
- Side-by-side metric comparison
- Improvement percentages
- Key differences highlighted

---

## Documenting Findings

### For Each Analysis

1. **Date and trace file**
2. **Key metrics extracted**
3. **Findings and insights**
4. **Recommendations** (if any)
5. **Next steps**

### Template

Use `templates/trace_analysis_template.md`:

```markdown
# Trace Analysis: [Trace Name]

**Date:** [Date]
**Trace File:** [Filename]
**Analyzed By:** [Name]

## Metrics

- Startup Time: [X]ms
- Context Switches: [X]
- Thread Count: [X]
- Peak Memory: [X]MB

## Findings

[Key findings]

## Recommendations

[Actionable recommendations]

## Next Steps

[Follow-up actions]
```

---

## Tips

1. **Always compare:** Compare against baseline, not absolute values
2. **Multiple runs:** Average 3-5 traces for accurate metrics
3. **Document context:** Note device, OS version, network state
4. **Focus on trends:** Look for patterns, not single data points
5. **Use scripts:** Automate metric extraction for consistency

---

## Troubleshooting

### "Cannot open trace file"

**Solution:**
- Ensure Instruments version is compatible
- Try opening in newer Instruments version
- Extract data using scripts instead

### "Missing symbols"

**Solution:**
- Ensure debug symbols are available
- Use script extraction (doesn't require symbols)
- Check dSYM files are in correct location

### Metrics seem incorrect

**Solution:**
- Verify trace was captured correctly
- Check trace duration covers relevant period
- Compare with Instruments GUI view

---

## References

- [Instruments Analysis Guide](https://developer.apple.com/documentation/instruments)
- [Performance Optimization Guide](../TOKIO_OPTIMIZATION.md)
- [Trace Index](TRACE_INDEX.md)
