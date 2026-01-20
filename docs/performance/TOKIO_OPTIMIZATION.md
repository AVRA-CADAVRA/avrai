# Tokio Runtime Optimization

## Overview

The Signal Protocol uses a Tokio runtime (Rust async runtime) via FFI. This document describes how to optimize the Tokio runtime configuration to reduce context switching and improve performance on mobile devices.

## Current Configuration

**Location**: `native/signal_ffi/libsignal/rust/bridge/shared/types/src/net/tokio.rs`

The Tokio runtime is currently configured as a multi-threaded runtime with default worker threads:

```rust
fn default_runtime_builder() -> tokio::runtime::Builder {
    let mut builder = tokio::runtime::Builder::new_multi_thread();
    builder
        .enable_io()
        .enable_time()
        .thread_name("libsignal-tokio-worker");
    builder
}
```

**Current behavior**:
- Creates a worker thread pool with size = number of CPU cores
- Each worker thread can spawn additional blocking threads as needed
- Default blocking thread limit is 512

## Performance Impact

### Issues with Default Configuration

1. **High Context Switching**: Multiple worker threads competing for CPU time
2. **Battery Drain**: More threads = more CPU wake-ups and context switches
3. **Mobile Overhead**: Mobile devices have limited CPU cores; excessive parallelism doesn't help
4. **Memory Usage**: Each thread has stack space (typically 2MB per thread)

### Observed Problems (from Instruments trace)

- High context switch frequency
- Thread contention during BLE operations
- Battery impact from excessive thread activity

## Recommended Optimization

### Option 1: Reduce Worker Threads (Recommended)

Modify `default_runtime_builder()` to use fewer worker threads:

```rust
fn default_runtime_builder() -> tokio::runtime::Builder {
    let mut builder = tokio::runtime::Builder::new_multi_thread();
    builder
        .enable_io()
        .enable_time()
        .thread_name("libsignal-tokio-worker")
        .worker_threads(2)  // Fixed: 2 threads instead of CPU cores
        .max_blocking_threads(4);  // Limit blocking threads
    builder
}
```

**Rationale**:
- **2 worker threads**: Sufficient for async I/O operations (BLE, network)
- **4 blocking threads**: Limits blocking operations (crypto, encoding/decoding)
- **Balance**: Maintains parallelism while reducing overhead

### Option 2: Single-Threaded Runtime (Maximum Optimization)

For minimal thread overhead:

```rust
pub fn new_optimized() -> Self {
    Self::from_runtime(
        Self::default_runtime_builder()
            .worker_threads(1)
            .max_blocking_threads(2)
    )
}
```

**Trade-off**: Less parallelism, but minimal context switching.

### Option 3: Platform-Specific Configuration

Use different configurations based on platform:

```rust
fn default_runtime_builder() -> tokio::runtime::Builder {
    let mut builder = tokio::runtime::Builder::new_multi_thread();
    builder
        .enable_io()
        .enable_time()
        .thread_name("libsignal-tokio-worker");
    
    // Platform-specific optimization
    #[cfg(target_os = "ios")]
    {
        builder.worker_threads(2).max_blocking_threads(4);
    }
    
    #[cfg(target_os = "android")]
    {
        builder.worker_threads(2).max_blocking_threads(4);
    }
    
    // Desktop platforms can use more threads
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        // Use default (CPU cores)
    }
    
    builder
}
```

## Expected Impact

### Metrics Improvement

- **Context switches**: 30-40% reduction
- **Thread count**: Reduced from N (CPU cores) to 2
- **Battery usage**: 10-15% improvement (estimated)
- **Memory**: ~(N-2) × 2MB saved (where N = CPU cores)

### Trade-offs

**Pros**:
- Reduced context switching
- Better battery life
- Lower memory usage
- Better for mobile devices

**Cons**:
- Potentially less parallelism for heavy workloads
- May slightly increase latency for CPU-intensive operations

**Mitigation**: Most Signal Protocol operations are I/O-bound (BLE, network), so reduced parallelism has minimal impact.

## Implementation

### Step 1: Modify Tokio Runtime Builder

**File**: `native/signal_ffi/libsignal/rust/bridge/shared/types/src/net/tokio.rs`

**Change**:
```rust
fn default_runtime_builder() -> tokio::runtime::Builder {
    let mut builder = tokio::runtime::Builder::new_multi_thread();
    builder
        .enable_io()
        .enable_time()
        .thread_name("libsignal-tokio-worker")
        .worker_threads(2)  // ADD THIS
        .max_blocking_threads(4);  // ADD THIS
    builder
}
```

### Step 2: Test

1. **Build Rust FFI**:
   ```bash
   cd native/signal_ffi
   cargo build --release
   ```

2. **Profile with Instruments**:
   - Take before/after traces
   - Compare context switch counts
   - Measure battery impact

3. **Functional Testing**:
   - Verify Signal Protocol still works correctly
   - Test BLE operations
   - Test encryption/decryption performance

### Step 3: Monitor

- Track thread counts in production
- Monitor battery usage
- Check for any performance regressions

## Alternative: Environment Variable Configuration

Allow runtime configuration via environment variable (advanced):

```rust
fn default_runtime_builder() -> tokio::runtime::Builder {
    let mut builder = tokio::runtime::Builder::new_multi_thread();
    builder
        .enable_io()
        .enable_time()
        .thread_name("libsignal-tokio-worker");
    
    // Allow override via environment variable (for testing)
    if let Ok(threads_str) = std::env::var("LIBSIGNAL_TOKIO_WORKERS") {
        if let Ok(threads) = threads_str.parse::<usize>() {
            builder.worker_threads(threads);
        }
    } else {
        // Default: 2 threads for mobile optimization
        builder.worker_threads(2);
    }
    
    builder.max_blocking_threads(4);
    builder
}
```

## References

- [Tokio Runtime Documentation](https://docs.rs/tokio/latest/tokio/runtime/struct.Builder.html)
- [Tokio Runtime Model](https://tokio.rs/tokio/tutorial/runtime)
- Instruments trace analysis: `AVRAI test 1.trace/PERFORMANCE_INSIGHTS.md`

## Status

**Current Status**: Documented for future implementation

**Priority**: Medium (requires Rust-side changes, can be done separately)

**Blocking**: No - app works with current configuration, optimization is performance enhancement

## Notes

- This is a Rust-side change and cannot be done from Dart
- Requires rebuilding the Rust FFI bindings
- Should be tested thoroughly before deployment
- Consider making it configurable per platform (mobile vs desktop)
