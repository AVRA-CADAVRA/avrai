// WiFi Fingerprint Service
//
// Phase 10.1: Multi-Layered Check-In System
// WiFi fingerprinting for indoor location validation
//
// Validates indoor location via WiFi SSID/BSSID matching (Android) or current SSID (iOS).

import 'dart:developer' as developer;
import 'dart:io';
import 'package:avrai/core/models/spot.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart' as wifi_iot;
import 'package:permission_handler/permission_handler.dart';

/// WiFi Network
///
/// Represents a WiFi network with SSID and BSSID.
class WiFiNetwork {
  /// Service Set Identifier (network name)
  final String? ssid;

  /// Basic Service Set Identifier (MAC address)
  final String? bssid;

  /// Signal strength in dBm (optional)
  final int? rssi;

  /// Frequency in MHz (optional)
  final int? frequency;

  const WiFiNetwork({
    this.ssid,
    this.bssid,
    this.rssi,
    this.frequency,
  });
}

/// WiFi Fingerprint Configuration
///
/// Expected WiFi fingerprint configuration from spot metadata.
class WiFiFingerprintConfig {
  /// Expected SSIDs (Service Set Identifiers)
  final List<String> ssids;

  /// Expected BSSIDs (Basic Service Set Identifiers - MAC addresses)
  final List<String> bssids;

  const WiFiFingerprintConfig({
    required this.ssids,
    required this.bssids,
  });

  /// Create from JSON (spot metadata)
  factory WiFiFingerprintConfig.fromJson(Map<String, dynamic> json) {
    return WiFiFingerprintConfig(
      ssids: List<String>.from(json['ssids'] ?? []),
      bssids: List<String>.from(json['bssids'] ?? []),
    );
  }
}

/// WiFi Fingerprint Service
///
/// Scans and validates WiFi fingerprints for location verification.
///
/// **Platform Support:**
/// - **Android:** Full WiFi scanning (SSID, BSSID, signal strength) via `wifi_scan`
/// - **iOS:** Current SSID only (privacy limitations) via `wifi_iot`
///
/// **Phase 10.1:** Multi-layered proximity-triggered check-in system
class WiFiFingerprintService {
  static const String _logName = 'WiFiFingerprintService';

  /// Get current WiFi networks (SSID + BSSID)
  ///
  /// **Platform Differences:**
  /// - **Android:** Returns all visible WiFi networks (full scanning)
  /// - **iOS:** Returns current connected SSID only (no general scanning)
  ///
  /// **Parameters:**
  /// None (uses platform-specific implementation)
  ///
  /// **Returns:**
  /// List of WiFi networks (SSID, BSSID, signal strength)
  ///
  /// **Throws:**
  /// - `UnimplementedError` if platform is not supported
  Future<List<WiFiNetwork>> getCurrentWiFiNetworks() async {
    try {
      if (Platform.isAndroid) {
        // Android: Use wifi_scan for full WiFi scanning
        return await _getAndroidWiFiNetworks();
      } else if (Platform.isIOS) {
        // iOS: Use wifi_iot for current SSID only
        return await _getIOSWiFiNetworks();
      } else {
        developer.log(
          'WiFi scanning not supported on platform: ${Platform.operatingSystem}',
          name: _logName,
        );
        return [];
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error getting WiFi networks: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get WiFi networks on Android using wifi_scan package
  ///
  /// **Requirements:**
  /// - Location permission (required for WiFi scanning on Android 10+)
  /// - ACCESS_FINE_LOCATION permission in AndroidManifest.xml
  ///
  /// **API Verified:** wifi_scan 0.4.1+2
  /// - `WiFiScan.instance.canGetScannedResults()` returns `CanGetScannedResults` enum
  /// - `WiFiScan.instance.getScannedResults()` returns `List<WiFiAccessPoint>` directly
  ///
  /// **Real Device Testing Required:**
  /// - See `docs/agents/protocols/RELEASE_GATE_CHECKLIST_CORE_APP_V1.md` Gate 10.J
  /// - Functional testing needed on physical Android device (emulators have limited WiFi scanning)
  Future<List<WiFiNetwork>> _getAndroidWiFiNetworks() async {
    try {
      // Check location permission (required for WiFi scanning on Android 10+)
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        developer.log(
          'Location permission not granted for WiFi scanning',
          name: _logName,
        );
        return [];
      }

      // Check if we can get scanned results
      final canGetResults = await WiFiScan.instance.canGetScannedResults();
      if (canGetResults != CanGetScannedResults.yes) {
        developer.log(
          'Cannot get scanned WiFi results: $canGetResults',
          name: _logName,
        );
        return [];
      }

      // Start WiFi scan
      await WiFiScan.instance.startScan();

      // Get scanned results (API now returns List<WiFiAccessPoint> directly)
      final accessPoints = await WiFiScan.instance.getScannedResults();

      // Convert to WiFiNetwork list
      final networks = accessPoints.map((ap) {
        return WiFiNetwork(
          ssid: ap.ssid,
          bssid: ap.bssid,
          rssi: ap.level,
          frequency: ap.frequency,
        );
      }).toList();

      developer.log(
        'Android WiFi scan complete: ${networks.length} networks found',
        name: _logName,
      );

      return networks;
    } catch (e, stackTrace) {
      developer.log(
        'Error scanning WiFi on Android: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get current WiFi network on iOS using wifi_iot package
  ///
  /// **Limitations:**
  /// - iOS only provides current connected SSID (privacy restrictions)
  /// - Cannot scan for all available networks
  Future<List<WiFiNetwork>> _getIOSWiFiNetworks() async {
    try {
      // Check if WiFi is enabled
      final isEnabled = await wifi_iot.WiFiForIoTPlugin.isEnabled();
      if (!isEnabled) {
        developer.log(
          'WiFi is not enabled on iOS',
          name: _logName,
        );
        return [];
      }

      // Get current SSID and BSSID (iOS limitation: only current network)
      final ssid = await wifi_iot.WiFiForIoTPlugin.getSSID();
      final bssid = await wifi_iot.WiFiForIoTPlugin.getBSSID();

      if (ssid == null || ssid.isEmpty) {
        developer.log(
          'No WiFi network connected on iOS',
          name: _logName,
        );
        return [];
      }

      final network = WiFiNetwork(
        ssid: ssid,
        bssid: bssid,
        // iOS doesn't provide RSSI or frequency for current network via wifi_iot
      );

      developer.log(
        'iOS WiFi network: SSID=$ssid, BSSID=$bssid',
        name: _logName,
      );

      return [network];
    } catch (e, stackTrace) {
      developer.log(
        'Error getting WiFi network on iOS: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Validate WiFi fingerprint against expected configuration
  ///
  /// **Validation Logic:**
  /// 1. Check if expected SSIDs are present in current networks
  /// 2. Check if expected BSSIDs are present (more precise)
  /// 3. Return `true` if at least one SSID or BSSID matches
  ///
  /// **Parameters:**
  /// - `currentNetworks`: Current WiFi networks (from `getCurrentWiFiNetworks()`)
  /// - `expected`: Expected WiFi fingerprint configuration
  ///
  /// **Returns:**
  /// `true` if WiFi fingerprint matches, `false` otherwise
  Future<bool> validateWiFiFingerprint({
    required List<WiFiNetwork> currentNetworks,
    required WiFiFingerprintConfig expected,
  }) async {
    try {
      if (expected.ssids.isEmpty && expected.bssids.isEmpty) {
        // No expected fingerprint → validation passes (optional validation)
        developer.log(
          'No expected WiFi fingerprint → validation passes (optional)',
          name: _logName,
        );
        return true;
      }

      if (currentNetworks.isEmpty) {
        // No current networks → validation fails
        developer.log(
          'No current WiFi networks → validation fails',
          name: _logName,
        );
        return false;
      }

      // Normalize expected SSIDs and BSSIDs (lowercase for comparison)
      final expectedSSIDs = expected.ssids.map((s) => s.toLowerCase()).toSet();
      final expectedBSSIDs =
          expected.bssids.map((b) => b.toLowerCase()).toSet();

      // Check current networks
      final currentSSIDs = currentNetworks
          .map((n) => n.ssid?.toLowerCase() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      final currentBSSIDs = currentNetworks
          .map((n) => n.bssid?.toLowerCase() ?? '')
          .where((b) => b.isNotEmpty)
          .toSet();

      // Check SSID match
      final ssidMatch =
          expectedSSIDs.any((expected) => currentSSIDs.contains(expected));

      // Check BSSID match (more precise)
      final bssidMatch = expectedBSSIDs.isNotEmpty &&
          expectedBSSIDs.any((expected) => currentBSSIDs.contains(expected));

      final isValid = ssidMatch || bssidMatch;

      developer.log(
        'WiFi fingerprint validation: ssidMatch=$ssidMatch, bssidMatch=$bssidMatch, isValid=$isValid',
        name: _logName,
      );

      return isValid;
    } catch (e, stackTrace) {
      developer.log(
        'Error validating WiFi fingerprint: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get WiFi fingerprint configuration from spot metadata
  ///
  /// **Parameters:**
  /// - `spot`: Spot with check-in configuration in metadata
  ///
  /// **Returns:**
  /// WiFi fingerprint configuration, or `null` if not configured
  WiFiFingerprintConfig? getWiFiFingerprintConfig(Spot spot) {
    try {
      final checkInConfig = spot.metadata['check_in_config'];
      if (checkInConfig == null) {
        return null;
      }

      final checkInSpot = checkInConfig['check_in_spot'];
      if (checkInSpot == null) {
        return null;
      }

      final wifiFingerprint = checkInSpot['wifi_fingerprint'];
      if (wifiFingerprint == null) {
        return null;
      }

      return WiFiFingerprintConfig.fromJson(
        wifiFingerprint as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log(
        'Error getting WiFi fingerprint config: $e',
        name: _logName,
      );
      return null;
    }
  }
}
