---
name: swift-integration-patterns
description: Guides Swift integration patterns: platform channels, method channels, async callbacks, native iOS features. Use when implementing iOS-specific features, native platform channels, or Swift code integration.
---

# Swift Integration Patterns

## Core Purpose

Swift integration enables Flutter apps to use iOS-specific features via platform channels.

## Method Channel Pattern

### Swift Side
```swift
import Flutter
import UIKit

public class SwiftMethodChannelHandler: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.spots.app/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftMethodChannelHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "performNativeOperation":
            performNativeOperation(arguments: call.arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func performNativeOperation(arguments: Any?, result: @escaping FlutterResult) {
        // Perform native iOS operation
        // Call result handler when complete
        result("Operation completed")
    }
}
```

### Dart Side
```dart
import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.spots.app/methods');
  
  Future<String> getPlatformVersion() async {
    try {
      final String version = await _channel.invokeMethod('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      developer.log('Platform version error: ${e.message}');
      return 'Unknown';
    }
  }
  
  Future<String> performNativeOperation(Map<String, dynamic> params) async {
    try {
      final String result = await _channel.invokeMethod(
        'performNativeOperation',
        params,
      );
      return result;
    } on PlatformException catch (e) {
      developer.log('Operation error: ${e.message}');
      rethrow;
    }
  }
}
```

## Event Channel Pattern

### Swift Side
```swift
public class SwiftEventChannelHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(
            name: "com.spots.app/events",
            binaryMessenger: registrar.messenger()
        )
        let handler = SwiftEventChannelHandler()
        channel.setStreamHandler(handler)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        startListening()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopListening()
        return nil
    }
    
    private func startListening() {
        // Start native iOS listener
        // Send events via eventSink
        eventSink?("Event data")
    }
}
```

### Dart Side
```dart
import 'package:flutter/services.dart';

class EventChannelService {
  static const EventChannel _channel = EventChannel('com.spots.app/events');
  
  Stream<String> get events {
    return _channel.receiveBroadcastStream().cast<String>();
  }
}
```

## Async Operations

```swift
// Handle async operations
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "asyncOperation":
        performAsyncOperation(result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
}

private func performAsyncOperation(result: @escaping FlutterResult) {
    DispatchQueue.global().async {
        // Perform async work
        let resultData = performWork()
        
        DispatchQueue.main.async {
            // Return result on main thread
            result(resultData)
        }
    }
}
```

## Error Handling

```swift
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
        let resultData = try performOperation()
        result(resultData)
    } catch let error {
        result(FlutterError(
            code: "OPERATION_ERROR",
            message: error.localizedDescription,
            details: nil
        ))
    }
}
```

## Reference

- `ios/Runner/AppDelegate.swift` - iOS app delegate
- Flutter Platform Channels documentation
