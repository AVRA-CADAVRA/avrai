---
name: battery-adaptive-scheduling
description: Guides battery-adaptive BLE scheduling: adaptive scanning, power optimization, foreground services, background modes. Use when implementing BLE features, background operations, or battery optimization.
---

# Battery-Adaptive Scheduling

## Core Purpose

Optimize BLE operations based on battery level to minimize battery drain while maintaining functionality.

## Adaptive Scanning Pattern

```dart
/// Adaptive BLE Scanner
/// 
/// Adjusts scan frequency based on battery level
class AdaptiveBLEScanner {
  /// Start adaptive scanning
  Future<void> startAdaptiveScanning() async {
    final batteryLevel = await _getBatteryLevel();
    final isCharging = await _isCharging();
    
    // Calculate scan interval based on battery level
    final scanInterval = _calculateScanInterval(
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
    
    // Start scanning with adaptive interval
    await _startScanning(scanInterval: scanInterval);
  }
  
  /// Calculate scan interval based on battery
  Duration _calculateScanInterval({
    required double batteryLevel,
    required bool isCharging,
  }) {
    if (isCharging) {
      // More frequent when charging
      return Duration(seconds: 3);
    } else if (batteryLevel > 50) {
      // High battery: Normal frequency
      return Duration(seconds: 5);
    } else if (batteryLevel > 20) {
      // Medium battery: Reduced frequency
      return Duration(seconds: 10);
    } else {
      // Low battery: Minimal frequency
      return Duration(seconds: 30);
    }
  }
}
```

## Power Optimization Levels

### High Battery (>50%)
- Normal scanning frequency (5 seconds)
- Normal advertising frequency
- Full background operations

### Medium Battery (20-50%)
- Reduced scanning frequency (10 seconds)
- Reduced advertising frequency
- Limited background operations

### Low Battery (<20%)
- Minimal scanning frequency (30 seconds)
- Minimal advertising
- Critical operations only

### Charging
- Maximum frequency (3 seconds)
- Full background operations
- Aggressive scanning

## Background Service Pattern

### Android Foreground Service
```kotlin
class BLEForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Create notification
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Start adaptive BLE operations
        startAdaptiveBLE()
        
        return START_STICKY
    }
    
    private fun startAdaptiveBLE() {
        // Monitor battery level
        // Adjust scanning frequency
    }
}
```

### iOS Background Modes
```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
  <string>bluetooth-peripheral</string>
</array>
```

## Reference

- `docs/ai2ai/06_network_connectivity/BLE_BACKGROUND.md` - Background BLE guide
- `lib/core/ai2ai/battery_adaptive_ble_scheduler.dart` - Adaptive scheduler
