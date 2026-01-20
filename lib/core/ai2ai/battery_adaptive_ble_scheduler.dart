import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:avrai/core/services/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_network/avra_network.dart';

/// Battery-adaptive scheduler for BLE discovery scanning.
///
/// Goal: keep the “walk-by” experience strong when power is plentiful, and
/// reduce BLE duty-cycle when power is low.
///
/// This does **not** stop discovery; it updates the scan loop configuration
/// in-place via `DeviceDiscoveryService.updateScanConfig`.
class BatteryAdaptiveBleScheduler with WidgetsBindingObserver {
  static const String _logName = 'BatteryAdaptiveBleScheduler';

  // Preferences (opt-out kill switch if needed later).
  static const String _prefsKeyBatteryAdaptiveEnabled =
      'ai2ai_battery_adaptive_enabled';

  final DeviceDiscoveryService discovery;
  final SharedPreferencesCompat prefs;

  final Battery _battery;
  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _pollTimer;
  BatteryScanPolicy? _lastApplied;
  int _burstUntilMs = 0;
  int _activeUntilMs = 0;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  BatteryAdaptiveBleScheduler({
    required this.discovery,
    required this.prefs,
    Battery? battery,
  }) : _battery = battery ?? Battery();
  
  /// Get current battery level (0-100)
  /// Used for battery-aware rate limiting integration
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      developer.log(
        'Error getting battery level: $e',
        name: _logName,
      );
      return 100; // Default to full battery on error
    }
  }

  bool get _enabled =>
      (prefs.getBool(_prefsKeyBatteryAdaptiveEnabled) ?? true) == true;

  bool get _isScreenOnProxy => _lifecycleState == AppLifecycleState.resumed;

  /// Provide a lightweight “user is active / moving” proxy from discovery samples.
  ///
  /// We treat “seeing nearby SPOTS devices” as “active context” (e.g., moving
  /// through a crowd / venue), which makes it rational to briefly boost scan
  /// aggressiveness to capture walk-bys.
  void notifyDiscoverySample({
    required int discoveredCount,
    required bool sawHotCandidate,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    Duration extendBy = Duration.zero;
    if (sawHotCandidate) {
      extendBy = const Duration(minutes: 2);
    } else if (discoveredCount >= 3) {
      extendBy = const Duration(minutes: 1);
    }

    if (extendBy == Duration.zero) return;
    final proposed = nowMs + extendBy.inMilliseconds;
    if (proposed > _activeUntilMs) _activeUntilMs = proposed;
  }

  /// Temporarily boost scanning aggressiveness to improve walk-by capture.
  ///
  /// Intended to be called when we observe strong RSSI scan results.
  void notifyHotOpportunity({
    Duration boostFor = const Duration(seconds: 90),
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _burstUntilMs = _burstUntilMs > (nowMs + boostFor.inMilliseconds)
        ? _burstUntilMs
        : (nowMs + boostFor.inMilliseconds);
    unawaited(_applyOnce(reason: 'hot_opportunity'));
  }

  Future<void> start() async {
    if (kIsWeb) return;
    if (!_enabled) return;

    // Best-effort lifecycle tracking (screen-on proxy).
    try {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleState =
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    } catch (_) {
      _lifecycleState = AppLifecycleState.resumed;
    }

    // Apply once on start.
    await _applyOnce(reason: 'start');

    // Re-apply on battery state changes (charging/discharging/full).
    _batteryStateSub?.cancel();
    _batteryStateSub = _battery.onBatteryStateChanged.listen((_) async {
      await _applyOnce(reason: 'battery_state_changed');
    });

    // Periodic refresh (battery level changes without state changes).
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _applyOnce(reason: 'poll');
    });
  }

  Future<void> stop() async {
    await _batteryStateSub?.cancel();
    _batteryStateSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastApplied = null;
    _burstUntilMs = 0;
    _activeUntilMs = 0;

    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {
      // Ignore.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    unawaited(_applyOnce(reason: 'lifecycle'));
  }

  Future<void> _applyOnce({required String reason}) async {
    if (!_enabled) return;

    try {
      final discoveryEnabled = prefs.getBool('discovery_enabled') ?? false;
      if (!discoveryEnabled) return;

      final levelRaw = await _battery.batteryLevel; // 0..100
      final state = await _battery.batteryState;
      final level = (levelRaw ~/ 5) * 5; // bucket to reduce policy flapping

      bool isInBatterySaveMode = false;
      try {
        isInBatterySaveMode = await _battery.isInBatterySaveMode;
      } catch (_) {
        // Best-effort: some platforms/versions may not support power saver query.
        isInBatterySaveMode = false;
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final burstRequested = nowMs < _burstUntilMs;
      final allowBurst = _isScreenOnProxy || nowMs < _activeUntilMs;

      final policy = BatteryScanPolicy.decide(
        batteryLevel: level,
        state: state,
        isInBatterySaveMode: isInBatterySaveMode,
        burstMode: burstRequested && allowBurst,
      );

      final last = _lastApplied;
      if (last != null && last == policy) {
        return;
      }
      _lastApplied = policy;

      discovery.updateScanConfig(
        scanInterval: policy.scanInterval,
        scanWindow: policy.scanWindow,
        deviceTimeout: policy.deviceTimeout,
      );

      // Optional: inform Android foreground runtime about the intended cadence.
      // This is a placeholder until native scanning is fully implemented.
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Best-effort; ignore failures.
        unawaited(BleForegroundService.updateScanInterval(policy.scanInterval));
      }

      developer.log(
        'Applied battery policy ($reason): '
        'level=$level state=$state saveMode=$isInBatterySaveMode '
        'screenOn=$_isScreenOnProxy active=${nowMs < _activeUntilMs} '
        'burst=${burstRequested && allowBurst} '
        'interval=${policy.scanInterval.inSeconds}s window=${policy.scanWindow.inSeconds}s '
        'timeout=${policy.deviceTimeout.inSeconds}s',
        name: _logName,
      );
    } catch (e, st) {
      developer.log('Failed to apply battery adaptive policy',
          name: _logName, error: e, stackTrace: st);
    }
  }
}

class _BatteryScanPolicy {
  final Duration scanInterval;
  final Duration scanWindow;
  final Duration deviceTimeout;

  const _BatteryScanPolicy({
    required this.scanInterval,
    required this.scanWindow,
    required this.deviceTimeout,
  });

  static _BatteryScanPolicy decide({
    required int batteryLevel,
    required BatteryState state,
    required bool isInBatterySaveMode,
    required bool burstMode,
  }) {
    // If OS power saver is on, honor it first.
    if (isInBatterySaveMode) {
      // Still do *some* scanning so “walk-by” can happen occasionally, but with a
      // clear duty-cycle reduction. Keep scanWindow >= 2s for a meaningful batch.
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 28),
        scanWindow: Duration(seconds: 2),
        deviceTimeout: Duration(seconds: 75),
      );
    }

    // If charging/full, be aggressive.
    if (state == BatteryState.charging || state == BatteryState.full) {
      return const _BatteryScanPolicy(
        scanInterval: Duration.zero,
        scanWindow: Duration(seconds: 4),
        deviceTimeout: Duration(seconds: 30),
      );
    }

    // Burst mode: short, aggressive window to maximize walk-by capture.
    // (Disabled automatically at very low battery below.)
    if (burstMode && batteryLevel >= 20) {
      return const _BatteryScanPolicy(
        scanInterval: Duration.zero,
        scanWindow: Duration(seconds: 4),
        deviceTimeout: Duration(seconds: 30),
      );
    }

    // Battery-tiered duty cycle, tuned so that when not in OS power-saver:
    // - we keep cadence <= ~5s for battery >= 30% (walk-by budget)
    // - we avoid truly continuous scanning while discharging (battery sanity),
    //   reserving scanInterval=0 for charging or “burst”.
    if (batteryLevel >= 80) {
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 1),
        scanWindow: Duration(seconds: 4),
        deviceTimeout: Duration(seconds: 30),
      );
    }
    if (batteryLevel >= 60) {
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 2),
        scanWindow: Duration(seconds: 3),
        deviceTimeout: Duration(seconds: 35),
      );
    }
    if (batteryLevel >= 45) {
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 3),
        scanWindow: Duration(seconds: 2),
        deviceTimeout: Duration(seconds: 45),
      );
    }
    if (batteryLevel >= 30) {
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 3),
        scanWindow: Duration(seconds: 2),
        deviceTimeout: Duration(seconds: 60),
      );
    }
    if (batteryLevel >= 20) {
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 6),
        scanWindow: Duration(seconds: 2),
        deviceTimeout: Duration(seconds: 90),
      );
    }
    if (batteryLevel >= 10) {
      return const _BatteryScanPolicy(
        scanInterval: Duration(seconds: 12),
        scanWindow: Duration(seconds: 2),
        deviceTimeout: Duration(seconds: 120),
      );
    }

    // Severe: keep a heartbeat scan to allow rare discovery.
    return const _BatteryScanPolicy(
      scanInterval: Duration(seconds: 20),
      scanWindow: Duration(seconds: 2),
      deviceTimeout: Duration(seconds: 120),
    );
  }
}

/// Pure battery→scan configuration policy.
///
/// Exposed as public so we can test the decision table in CI without requiring
/// real device power APIs.
class BatteryScanPolicy {
  final Duration scanInterval;
  final Duration scanWindow;
  final Duration deviceTimeout;

  const BatteryScanPolicy({
    required this.scanInterval,
    required this.scanWindow,
    required this.deviceTimeout,
  });

  static BatteryScanPolicy decide({
    required int batteryLevel,
    required BatteryState state,
    bool isInBatterySaveMode = false,
    bool burstMode = false,
  }) {
    final p = _BatteryScanPolicy.decide(
      batteryLevel: batteryLevel,
      state: state,
      isInBatterySaveMode: isInBatterySaveMode,
      burstMode: burstMode,
    );
    return BatteryScanPolicy(
      scanInterval: p.scanInterval,
      scanWindow: p.scanWindow,
      deviceTimeout: p.deviceTimeout,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BatteryScanPolicy &&
        other.scanInterval == scanInterval &&
        other.scanWindow == scanWindow &&
        other.deviceTimeout == deviceTimeout;
  }

  @override
  int get hashCode => Object.hash(scanInterval, scanWindow, deviceTimeout);
}
