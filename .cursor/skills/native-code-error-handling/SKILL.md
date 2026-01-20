---
name: native-code-error-handling
description: Guides native code error handling patterns: exception conversion, error propagation to Dart, user-friendly messages. Use when implementing native code error handling, platform channel error handling, or FFI error handling.
---

# Native Code Error Handling

## Core Principle

Native code errors must be converted to Dart-friendly errors with user-friendly messages.

## Platform Channel Error Handling

### Swift/iOS
```swift
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
        let resultData = try performOperation()
        result(resultData)
    } catch let error as SpecificError {
        result(FlutterError(
            code: "SPECIFIC_ERROR",
            message: "User-friendly message: \(error.localizedDescription)",
            details: nil
        ))
    } catch let error {
        result(FlutterError(
            code: "OPERATION_ERROR",
            message: "Operation failed: \(error.localizedDescription)",
            details: nil
        ))
    }
}
```

### Kotlin/Android
```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    .setMethodCallHandler { call, result ->
        try {
            when (call.method) {
                "performOperation" -> {
                    val resultData = performOperation()
                    result.success(resultData)
                }
                else -> result.notImplemented()
            }
        } catch (e: SpecificException) {
            result.error(
                "SPECIFIC_ERROR",
                "User-friendly message: ${e.message}",
                null
            )
        } catch (e: Exception) {
            result.error(
                "OPERATION_ERROR",
                "Operation failed: ${e.message}",
                e.stackTraceToString()
            )
        }
    }
```

## FFI Error Handling

### Rust FFI
```rust
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

### Dart FFI
```dart
int performOperation() {
  final result = rustOperation();
  if (result != 0) {
    throw PlatformException(
      code: 'OPERATION_ERROR',
      message: 'Operation failed with error code: $result',
    );
  }
  return result;
}
```

## Error Code Standards

Use consistent error codes:
- `OPERATION_ERROR` - Generic operation failure
- `PERMISSION_DENIED` - Permission denied
- `NOT_AVAILABLE` - Feature not available
- `INVALID_ARGUMENT` - Invalid input
- `NETWORK_ERROR` - Network failure
- `TIMEOUT` - Operation timeout

## User-Friendly Messages

Convert technical errors to user-friendly messages:

```swift
private func getUserFriendlyMessage(from error: Error) -> String {
    switch error {
    case is PermissionDeniedError:
        return "Please grant required permissions in Settings"
    case is NetworkError:
        return "Connection failed. Please check your internet."
    case is TimeoutError:
        return "Operation timed out. Please try again."
    default:
        return "Something went wrong. Please try again."
    }
}
```

## Reference

- Platform-specific error handling in iOS/Android code
- Flutter Platform Channels error handling documentation
