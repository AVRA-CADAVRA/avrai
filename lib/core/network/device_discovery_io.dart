import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/core/network/device_discovery_android.dart';
import 'package:spots/core/network/device_discovery_ios.dart';

/// Create Android device discovery implementation
DeviceDiscoveryPlatform createAndroidDeviceDiscovery() {
  return AndroidDeviceDiscovery();
}

/// Create iOS device discovery implementation
DeviceDiscoveryPlatform createIOSDeviceDiscovery() {
  return IOSDeviceDiscovery();
}

