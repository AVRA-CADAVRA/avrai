/// Stub implementation for device discovery when platform is not supported
/// Used in unit tests and unsupported platforms
import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/core/ai/privacy_protection.dart';

/// Stub device discovery implementation
class StubDeviceDiscovery extends DeviceDiscoveryPlatform {
  @override
  bool isSupported() => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<List<DiscoveredDevice>> scanForDevices() async => [];

  // Note: startAdvertising and stopAdvertising are not part of DeviceDiscoveryPlatform interface
  // They are kept here for potential future use or compatibility, but don't override anything
  Future<void> startAdvertising(AnonymizedVibeData vibeData) async {}

  Future<void> stopAdvertising() async {}

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async => {
    'platform': 'stub',
    'is_supported': false,
  };
}

/// Stub factory functions for unsupported platforms
/// These are used when conditional imports don't match any platform
DeviceDiscoveryPlatform createWebDeviceDiscovery() => StubDeviceDiscovery();
DeviceDiscoveryPlatform createAndroidDeviceDiscovery() => StubDeviceDiscovery();
DeviceDiscoveryPlatform createIOSDeviceDiscovery() => StubDeviceDiscovery();

