import 'package:spots/core/network/device_discovery.dart';
import 'device_discovery_stub.dart' show StubDeviceDiscovery;

/// Factory for creating platform-specific device discovery implementations
class DeviceDiscoveryFactory {
  /// Creates the appropriate platform-specific device discovery implementation
  /// 
  /// In test environments (no dart.library.io or dart.library.html), this will
  /// use the stub implementation from device_discovery_stub.dart.
  /// 
  /// On mobile platforms (dart.library.io available), platform-specific
  /// implementations should be instantiated directly or via dependency injection.
  /// 
  /// On web (dart.library.html available), WebDeviceDiscovery should be instantiated
  /// directly or via dependency injection.
  /// 
  /// Note: This factory always returns StubDeviceDiscovery to ensure testability.
  /// Production code should use platform-specific implementations via dependency
  /// injection or direct instantiation where appropriate.
  static DeviceDiscoveryPlatform? createPlatformDiscovery() {
    // Always return stub for testability
    // Platform-specific implementations can be provided via dependency injection
    // or instantiated directly in production code
    return StubDeviceDiscovery();
  }
  
  /// Checks if device discovery is supported on the current platform
  static bool isPlatformSupported() {
    final platform = createPlatformDiscovery();
    return platform != null && platform.isSupported();
  }
}
