---
name: kotlin-java-android-patterns
description: Guides Kotlin/Java Android integration patterns: platform channels, method channels, native Android features, BLE implementation. Use when implementing Android-specific features, native platform channels, or Kotlin/Java integration.
---

# Kotlin/Java Android Integration Patterns

## Core Purpose

Kotlin/Java integration enables Flutter apps to use Android-specific features via platform channels.

## Method Channel Pattern

### Kotlin Side
```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.spots.app/methods"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformVersion" -> {
                        result.success("Android ${android.os.Build.VERSION.SDK_INT}")
                    }
                    "performNativeOperation" -> {
                        val params = call.arguments as? Map<*, *>
                        performNativeOperation(params, result)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
    
    private fun performNativeOperation(
        params: Map<*, *>?,
        result: MethodChannel.Result
    ) {
        try {
            // Perform native Android operation
            val resultData = "Operation completed"
            result.success(resultData)
        } catch (e: Exception) {
            result.error("OPERATION_ERROR", e.message, null)
        }
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
}
```

## BLE Implementation (Android)

### Kotlin BLE Service
```kotlin
import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult

class AndroidBLEService(private val context: Context) {
    private val bluetoothAdapter: BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager)
            .adapter
    
    fun startScanning(callback: (ScanResult) -> Unit) {
        val scanner = bluetoothAdapter?.bluetoothLeScanner
        val scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                callback(result)
            }
        }
        
        scanner?.startScan(scanCallback)
    }
    
    fun stopScanning() {
        val scanner = bluetoothAdapter?.bluetoothLeScanner
        scanner?.stopScan(scanCallback)
    }
}
```

## Foreground Service (Android)

```kotlin
import android.app.Notification
import android.app.Service
import android.content.Intent
import android.os.IBinder

class BLEForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Create notification for foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Start BLE operations
        startBLEScanning()
        
        return START_STICKY
    }
    
    private fun createNotification(): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("SPOTS BLE")
            .setContentText("Scanning for nearby devices")
            .setSmallIcon(R.drawable.icon)
            .build()
    }
}
```

## Error Handling

```kotlin
private fun performOperation(result: MethodChannel.Result) {
    try {
        val resultData = performWork()
        result.success(resultData)
    } catch (e: Exception) {
        result.error(
            "OPERATION_ERROR",
            e.message,
            e.stackTraceToString()
        )
    }
}
```

## Reference

- `android/app/src/main/java/` - Android native code
- Flutter Platform Channels documentation
