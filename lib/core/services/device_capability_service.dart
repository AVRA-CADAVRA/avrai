import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

import 'device_capabilities.dart';

/// Reads device capability signals for gating heavy on-device AI features.
///
/// **Security posture:**
/// This is part of “protect the user from above” governance:
/// - prevents pushing unsafe/heavy downloads onto weak devices
/// - ensures on-device training only happens when device can safely handle it
class DeviceCapabilityService {
  static const String _logName = 'DeviceCapabilityService';
  static const MethodChannel _channel =
      MethodChannel('avra/device_capabilities');

  DeviceCapabilities? _cached;
  int _cachedAtMs = 0;

  Future<DeviceCapabilities> getCapabilities({
    bool forceRefresh = false,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!forceRefresh &&
        _cached != null &&
        (nowMs - _cachedAtMs) < const Duration(minutes: 10).inMilliseconds) {
      return _cached!;
    }

    if (kIsWeb) {
      const caps = DeviceCapabilities(
        platform: 'web',
        deviceModel: 'web',
        osVersion: null,
        totalRamMb: null,
        freeDiskMb: null,
        totalDiskMb: null,
        cpuCores: 0,
        isLowPowerMode: false,
      );
      _cached = caps;
      _cachedAtMs = nowMs;
      return caps;
    }

    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCapabilities',
      );
      final map = <String, dynamic>{};
      for (final entry in (raw ?? const <Object?, Object?>{}).entries) {
        final k = entry.key;
        if (k is String) map[k] = entry.value;
      }

      // Ensure platform string is set even if native didn’t provide it.
      map.putIfAbsent(
        'platform',
        () => switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'unknown',
        },
      );

      final caps = DeviceCapabilities.fromJson(map);
      _cached = caps;
      _cachedAtMs = nowMs;
      return caps;
    } catch (e, st) {
      developer.log(
        'Failed to read device capabilities',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      final fallback = DeviceCapabilities(
        platform: switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          TargetPlatform.macOS => 'macos',
          _ => 'unknown',
        },
        deviceModel: '',
        osVersion: null,
        totalRamMb: null,
        freeDiskMb: null,
        totalDiskMb: null,
        cpuCores: 0,
        isLowPowerMode: false,
      );
      _cached = fallback;
      _cachedAtMs = nowMs;
      return fallback;
    }
  }
}

