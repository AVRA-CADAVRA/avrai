# How to Capture Instruments Traces

**Guide for capturing Instruments trace files for performance analysis.**

---

## Prerequisites

- macOS with Xcode installed
- Instruments application (part of Xcode)
- Flutter/Dart app built for profiling
- Device or simulator for testing

---

## Method 1: Using Instruments GUI (Recommended)

### Step 1: Build App for Profiling

```bash
# Build release/profile mode (required for accurate profiling)
flutter build ios --release
# or
flutter build macos --release
```

### Step 2: Open Instruments

1. Open Xcode
2. **Xcode → Open Developer Tool → Instruments**
3. Or run from terminal:
   ```bash
   open -a Instruments
   ```

### Step 3: Select Template

Choose appropriate profiling template:
- **Time Profiler** - CPU usage, hot functions (most common)
- **System Trace** - Comprehensive system activity
- **Leaks** - Memory leak detection
- **Allocations** - Memory allocation patterns
- **Activity Monitor** - System resource usage

For startup performance, use **Time Profiler** or **System Trace**.

### Step 4: Configure Recording

1. Select your app target from the device dropdown
2. Configure recording options:
   - **Recording Time:** Set duration (e.g., 30 seconds for startup)
   - **Options:** Enable "High-frequency sampling" if available
3. Click **Record** (red button)

### Step 5: Perform Actions

- Launch the app (for startup traces)
- Perform the actions you want to profile
- Wait for trace to complete

### Step 6: Save Trace

1. Stop recording (red button again)
2. **File → Save**
3. Save to: `docs/performance/trace_testing/traces/[category]/`
4. Follow [Naming Conventions](NAMING_CONVENTIONS.md)

---

## Method 2: Command Line (Automated)

### Basic Capture

```bash
instruments -t "Time Profiler" \
  -D docs/performance/trace_testing/traces/startup_baseline_20250116.trace \
  /path/to/your/app.app
```

### With Time Limit

```bash
instruments -t "Time Profiler" \
  -D docs/performance/trace_testing/traces/startup_baseline_20250116.trace \
  -l 30000 \  # 30 seconds
  /path/to/your/app.app
```

### Multiple Templates

```bash
instruments -t "Time Profiler" -t "System Trace" \
  -D docs/performance/trace_testing/traces/comprehensive_20250116.trace \
  /path/to/your/app.app
```

---

## Method 3: Flutter-Specific

### Using Flutter DevTools

1. Run app in profile mode:
   ```bash
   flutter run --profile
   ```

2. Open DevTools:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

3. Connect to app and use Performance tab

**Note:** DevTools doesn't create `.trace` files directly, but provides similar analysis.

### Using Xcode Instruments with Flutter

1. Build iOS app:
   ```bash
   flutter build ios --release
   ```

2. Open in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. In Xcode: **Product → Profile** (⌘I)
4. Select Instruments template
5. Record and save trace

---

## Best Practices

### For Startup Traces

1. **Clean state:** Close app completely before each trace
2. **Cold start:** Ensure it's a true cold start (not warm launch)
3. **Duration:** Capture 10-30 seconds (covers full startup)
4. **Multiple runs:** Capture 3-5 traces, use average
5. **Consistent conditions:** Same device, same network state

### For Feature Traces

1. **Focused capture:** Only capture the feature being tested
2. **Baseline first:** Capture baseline before testing feature
3. **Reproducible:** Use consistent test scenarios
4. **Context:** Document what actions were performed

### For Memory Traces

1. **Extended duration:** Run for longer (2-5 minutes)
2. **Repetitive actions:** Perform same actions multiple times
3. **Watch for leaks:** Look for memory that doesn't decrease

---

## Common Issues

### "Cannot attach to process"

**Solution:** 
- Ensure app is built in Release or Profile mode
- Check code signing
- Try running Instruments as administrator

### "No symbols available"

**Solution:**
- Build with debug symbols: `flutter build ios --release --split-debug-info=debug_info`
- Ensure dSYM files are available

### Trace file too large

**Solution:**
- Reduce capture duration
- Use specific templates instead of System Trace
- Disable unnecessary data collection options

---

## Post-Capture Steps

1. **Document in [Trace Index](TRACE_INDEX.md)**
2. **Extract metrics:** Use `scripts/extract_metrics.py`
3. **Add notes:** Document any special conditions or observations

---

## Automation Script

Create `scripts/capture_trace.sh`:

```bash
#!/bin/bash
# Usage: ./scripts/capture_trace.sh category optimization_name

CATEGORY=$1
OPTIMIZATION=$2
DATE=$(date +%Y%m%d)
FILENAME="${CATEGORY}_${OPTIMIZATION}_${DATE}.trace"

instruments -t "Time Profiler" \
  -D "docs/performance/trace_testing/traces/${CATEGORY}/${FILENAME}" \
  -l 30000 \
  /path/to/your/app.app

echo "Trace saved: ${FILENAME}"
```

---

## References

- [Instruments User Guide](https://developer.apple.com/documentation/instruments)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Xcode Profiling Guide](https://developer.apple.com/documentation/xcode/analyzing-performance)
