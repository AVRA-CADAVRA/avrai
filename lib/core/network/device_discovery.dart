import 'dart:developer' as developer;
import 'dart:async';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/network/device_discovery_factory.dart';

/// Device Discovery Service for Phase 6: Physical Layer
/// Discovers nearby SPOTS-enabled devices using WiFi/Bluetooth
/// OUR_GUTS.md: "All device interactions must go through Personality AI Layer"
class DeviceDiscoveryService {
  static const String _logName = 'DeviceDiscoveryService';
  
  // Discovery state
  bool _isScanning = false;
  final Map<String, DiscoveredDevice> _discoveredDevices = {};
  final Map<String, DateTime> _deviceLastSeen = {};
  Timer? _scanTimer;
  
  // Discovery callbacks
  final List<Function(List<DiscoveredDevice>)> _onDevicesDiscovered = [];
  
  // Platform-specific discovery implementations
  final DeviceDiscoveryPlatform? _platform;
  
  DeviceDiscoveryService({DeviceDiscoveryPlatform? platform}) 
      : _platform = platform ?? DeviceDiscoveryFactory.createPlatformDiscovery();
  
  /// Start continuous device discovery
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration deviceTimeout = const Duration(minutes: 2),
  }) async {
    if (_isScanning) {
      developer.log('Discovery already running', name: _logName);
      return;
    }
    
    _isScanning = true;
    developer.log('Starting device discovery', name: _logName);
    
    // Perform initial scan
    await _performScan();
    
    // Start periodic scanning
    _scanTimer = Timer.periodic(scanInterval, (_) async {
      await _performScan();
      _cleanupStaleDevices(deviceTimeout);
    });
  }
  
  /// Stop device discovery
  void stopDiscovery() {
    if (!_isScanning) return;
    
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    developer.log('Stopped device discovery', name: _logName);
  }
  
  /// Perform a single discovery scan
  Future<void> _performScan() async {
    try {
      if (_platform == null) {
        developer.log('No platform discovery implementation available', name: _logName);
        return;
      }
      
      // Scan for devices
      final devices = await _platform!.scanForDevices();
      
      // Filter for SPOTS-enabled devices
      final spotsDevices = devices.where((device) => 
        device.isSpotsEnabled
      ).toList();
      
      // Update discovered devices
      final now = DateTime.now();
      for (final device in spotsDevices) {
        _discoveredDevices[device.deviceId] = device;
        _deviceLastSeen[device.deviceId] = now;
      }
      
      // Notify listeners
      if (spotsDevices.isNotEmpty) {
        _notifyDevicesDiscovered(spotsDevices);
      }
      
      developer.log('Discovered ${spotsDevices.length} SPOTS devices', name: _logName);
    } catch (e) {
      developer.log('Error during device scan: $e', name: _logName);
    }
  }
  
  /// Clean up devices that haven't been seen recently
  void _cleanupStaleDevices(Duration timeout) {
    final now = DateTime.now();
    final staleDevices = <String>[];
    
    _deviceLastSeen.forEach((deviceId, lastSeen) {
      if (now.difference(lastSeen) > timeout) {
        staleDevices.add(deviceId);
      }
    });
    
    for (final deviceId in staleDevices) {
      _discoveredDevices.remove(deviceId);
      _deviceLastSeen.remove(deviceId);
    }
    
    if (staleDevices.isNotEmpty) {
      developer.log('Removed ${staleDevices.length} stale devices', name: _logName);
    }
  }
  
  /// Get currently discovered devices
  List<DiscoveredDevice> getDiscoveredDevices() {
    return _discoveredDevices.values.toList();
  }
  
  /// Get a specific device by ID
  DiscoveredDevice? getDevice(String deviceId) {
    return _discoveredDevices[deviceId];
  }
  
  /// Register callback for device discovery events
  void onDevicesDiscovered(Function(List<DiscoveredDevice>) callback) {
    _onDevicesDiscovered.add(callback);
  }
  
  /// Notify listeners of discovered devices
  void _notifyDevicesDiscovered(List<DiscoveredDevice> devices) {
    for (final callback in _onDevicesDiscovered) {
      try {
        callback(devices);
      } catch (e) {
        developer.log('Error in discovery callback: $e', name: _logName);
      }
    }
  }
  
  /// Extract personality data from a discovered device
  /// Returns anonymized personality data for AI2AI matching
  Future<AnonymizedVibeData?> extractPersonalityData(DiscoveredDevice device) async {
    try {
      if (!device.isSpotsEnabled || device.personalityData == null) {
        return null;
      }
      
      // The personality data should already be anonymized
      // This method validates and returns it
      return device.personalityData;
    } catch (e) {
      developer.log('Error extracting personality data: $e', name: _logName);
      return null;
    }
  }
  
  /// Calculate proximity score (0.0-1.0) based on signal strength
  double calculateProximity(DiscoveredDevice device) {
    if (device.signalStrength == null) return 0.5; // Unknown proximity
    
    // Normalize signal strength to 0.0-1.0
    // Stronger signal = closer proximity
    // Typical range: -100 dBm (weak) to -30 dBm (strong)
    final normalized = (device.signalStrength! + 100) / 70;
    return normalized.clamp(0.0, 1.0);
  }
}

/// Represents a discovered nearby device
class DiscoveredDevice {
  final String deviceId;
  final String deviceName;
  final DeviceType type;
  final bool isSpotsEnabled;
  final AnonymizedVibeData? personalityData;
  final int? signalStrength; // Signal strength in dBm (negative value)
  final DateTime discoveredAt;
  final Map<String, dynamic> metadata;
  
  const DiscoveredDevice({
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.isSpotsEnabled,
    this.personalityData,
    this.signalStrength,
    required this.discoveredAt,
    this.metadata = const {},
  });
  
  /// Check if device is still valid (not stale)
  bool isStale(Duration timeout) {
    return DateTime.now().difference(discoveredAt) > timeout;
  }
  
  /// Get proximity estimate based on signal strength
  double get proximityScore {
    if (signalStrength == null) return 0.5;
    final normalized = (signalStrength! + 100) / 70;
    return normalized.clamp(0.0, 1.0);
  }
}

/// Device discovery types
enum DeviceType {
  wifi,
  bluetooth,
  wifiDirect,
  multpeerConnectivity, // iOS Multipeer Connectivity
  webrtc, // Web platform
}

/// Platform-specific device discovery interface
/// Implementations should be provided for each platform
abstract class DeviceDiscoveryPlatform {
  /// Scan for nearby devices
  Future<List<DiscoveredDevice>> scanForDevices();
  
  /// Get platform-specific device info
  Future<Map<String, dynamic>> getDeviceInfo();
  
  /// Check if discovery is supported on this platform
  bool isSupported();
  
  /// Request necessary permissions
  Future<bool> requestPermissions();
}

