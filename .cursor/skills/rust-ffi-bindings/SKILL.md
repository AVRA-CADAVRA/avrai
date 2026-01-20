---
name: rust-ffi-bindings
description: Guides Rust FFI bindings implementation: FFI bindings, type conversion, memory management, error handling, Flutter Rust Bridge. Use when implementing Rust FFI bindings, native code integration, or FFI callbacks.
---

# Rust FFI Bindings

## Core Purpose

Rust FFI bindings bridge Rust code with Dart/Flutter using C-compatible FFI.

## Architecture Pattern

```
Dart Code
    ↓ (C FFI)
Rust Wrapper
    ↓ (creates function pointers)
C Library / Dart Callbacks
```

## FFI Function Pattern

```rust
// Rust FFI function (C-compatible)
#[no_mangle]
pub extern "C" fn rust_function_name(
    param1: *const c_char,
    param2: c_int,
) -> c_int {
    // Implementation
    // Convert C types to Rust types
    // Call Rust code
    // Convert Rust result to C type
    // Return C-compatible result
}
```

## Callback Registration Pattern

```rust
// Callback registry for Dart callbacks
type CallbackId = u64;

#[repr(C)]
pub struct CallbackArgs {
    pub callback_id: u64,
    pub arg1: *mut c_void,
    pub arg2: *mut c_void,
}

// Global callback registry (thread-safe)
static CALLBACK_REGISTRY: Mutex<CallbackRegistry> = Mutex::new(CallbackRegistry {
    dispatch: None,
});

// Register Dart callback
#[no_mangle]
pub extern "C" fn register_dart_callback(callback: DispatchCallback) {
    let mut registry = CALLBACK_REGISTRY.lock().unwrap();
    registry.dispatch = Some(callback);
}
```

## Dart FFI Integration

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Load Rust library
final DynamicLibrary rustLib = DynamicLibrary.open('libsignal_ffi_wrapper.so');

// Define function signature
typedef RegisterCallbackNative = Void Function(Pointer<Void>);
typedef RegisterCallback = void Function(Pointer<Void>);

// Get function
final registerCallback = rustLib.lookupFunction<
    RegisterCallbackNative,
    RegisterCallback>('register_dart_callback');

// Register Dart callback
final dispatchCallback = Pointer.fromFunction<DispatchFunctionNative, int>(
  dispatchFunction, // Dart function
);

registerCallback(dispatchCallback);
```

## Memory Management

```rust
// Rust manages memory for FFI
pub extern "C" fn allocate_buffer(size: usize) -> *mut u8 {
    let buffer = vec![0u8; size];
    Box::into_raw(buffer.into_boxed_slice()) as *mut u8
}

pub extern "C" fn free_buffer(ptr: *mut u8, size: usize) {
    if !ptr.is_null() {
        unsafe {
            let _ = Box::from_raw(std::slice::from_raw_parts_mut(ptr, size));
        }
    }
}
```

## Error Handling

```rust
// Return error codes from FFI functions
#[no_mangle]
pub extern "C" fn rust_operation() -> c_int {
    match perform_operation() {
        Ok(_) => 0, // Success
        Err(e) => {
            // Log error
            eprintln!("Error: {}", e);
            -1 // Error code
        }
    }
}
```

## Flutter Rust Bridge

For complex integration, use Flutter Rust Bridge:

```rust
// flutter_rust_bridge macro
use flutter_rust_bridge::frb;

#[frb(sync)]
pub fn calculate_compatibility(
    profile_a: Vec<f64>,
    profile_b: Vec<f64>,
) -> Result<f64, String> {
    // Implementation
    Ok(compatibility_score)
}
```

## Reference

- `native/signal_ffi/wrapper_rust/src/lib.rs` - Rust FFI wrapper example
- `native/knot_math/src/api.rs` - FFI API example
- `native/signal_ffi/wrapper_rust/README.md` - FFI setup guide
