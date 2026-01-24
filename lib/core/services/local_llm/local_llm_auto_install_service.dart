import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;
import 'package:get_it/get_it.dart';

import 'package:avrai/core/services/device_capability_service.dart';
import 'package:avrai/core/services/on_device_ai_capability_gate.dart';
import 'package:avrai/core/services/local_llm/model_pack_manager.dart';
import 'package:avrai/core/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_macos_auto_install_service.dart';
import 'package:avrai/core/services/storage_service.dart' show SharedPreferencesCompat;

/// Best-effort auto-downloader for local LLM packs.
///
/// We do NOT bundle 8B weights inside the app binary (too large). Instead:
/// - user opts in (offline LLM enabled)
/// - if eligible and manifest URL is known, download in background
abstract class BatteryFacade {
  Future<BatteryState> getBatteryState();
  Stream<BatteryState> get onBatteryStateChanged;
}

class BatteryPlusFacade implements BatteryFacade {
  BatteryPlusFacade({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;

  @override
  Future<BatteryState> getBatteryState() => _battery.batteryState;

  @override
  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;
}

class LocalLlmAutoInstallService {
  static const String _logName = 'LocalLlmAutoInstallService';

  static const String _prefsKeyOfflineLlmEnabled = 'offline_llm_enabled_v1';
  static const String _prefsKeyLocalLlmManifestUrl = 'local_llm_manifest_url_v1';
  static const String _prefsKeyLastUpdateCheckMs =
      'local_llm_last_update_check_ms_v1';

  static const Duration _minUpdateCheckInterval = Duration(hours: 24);

  static StreamSubscription<List<ConnectivityResult>>? _wifiSubscription;
  static StreamSubscription<BatteryState>? _batterySubscription;
  static Timer? _idleTimer;

  static const int _idleStartHour = 0; // 12am local
  static const int _idleEndHour = 6; // 6am local (exclusive)

  final Connectivity _connectivity;
  final BatteryFacade _battery;
  final LocalLlmModelPackManager _packs;
  final DeviceCapabilityService _caps;
  final OnDeviceAiCapabilityGate _gate;
  final LocalLlmProvisioningStateService _provisioning;
  final SharedPreferencesCompat? _prefsOverride;
  final DateTime Function() _now;

  LocalLlmAutoInstallService({
    Connectivity? connectivity,
    BatteryFacade? battery,
    LocalLlmModelPackManager? packs,
    DeviceCapabilityService? deviceCapabilities,
    OnDeviceAiCapabilityGate? gate,
    LocalLlmProvisioningStateService? provisioning,
    SharedPreferencesCompat? prefs,
    DateTime Function()? now,
  })  : _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? BatteryPlusFacade(),
        _packs = packs ?? LocalLlmModelPackManager(),
        _caps = deviceCapabilities ?? DeviceCapabilityService(),
        _gate = gate ?? OnDeviceAiCapabilityGate(),
        _provisioning = provisioning ?? LocalLlmProvisioningStateService(),
        _prefsOverride = prefs,
        _now = now ?? DateTime.now;

  Future<SharedPreferencesCompat> _prefs() async {
    if (_prefsOverride != null) return _prefsOverride!;
    return await SharedPreferencesCompat.getInstance();
  }

  Future<void> maybeAutoInstall() async {
    if (kIsWeb) return;

    // macOS: Use immediate download service (no gates)
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return LocalLlmMacOSAutoInstallService().maybeAutoInstallMacOS();
    }

    try {
      final prefs = await _prefs();
      // Opt-out behavior:
      // - If device is eligible for offline LLM, default to enabled unless user disabled it.
      final hasUserChoice = prefs.containsKey(_prefsKeyOfflineLlmEnabled);
      bool enabled = prefs.getBool(_prefsKeyOfflineLlmEnabled) ?? false;

      if (!hasUserChoice) {
        final caps = await _caps.getCapabilities();
        final gateResult = _gate.evaluate(caps);
        enabled = gateResult.recommendedTier != OfflineLlmTier.none;
        await prefs.setBool(_prefsKeyOfflineLlmEnabled, enabled);
      }
      if (!enabled) {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.idle);
        return;
      }

      final status = await _packs.getStatus();
      if (status.isInstalled) {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);
        // Best-effort: check for updates only when conditions are safe.
        unawaited(_maybeAutoUpdateInstalled(prefs: prefs));
        return;
      }

      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      if (!isWifi) {
        developer.log('Skipping auto-install: not on Wi-Fi', name: _logName);
        await _provisioning.setPhase(LocalLlmProvisioningPhase.queuedWifi);
        _ensureWifiListenerStarted();
        return;
      }

      final batteryState = await _battery.getBatteryState();
      final isCharging =
          batteryState == BatteryState.charging || batteryState == BatteryState.full;
      if (!isCharging) {
        developer.log('Skipping auto-install: not charging', name: _logName);
        await _provisioning.setPhase(LocalLlmProvisioningPhase.queuedCharging);
        _ensureChargingListenerStarted();
        return;
      }

      final now = _now();
      final isIdle = now.hour >= _idleStartHour && now.hour < _idleEndHour;
      if (!isIdle) {
        developer.log('Skipping auto-install: not in idle window', name: _logName);
        await _provisioning.setPhase(LocalLlmProvisioningPhase.queuedIdle);
        _scheduleIdleRecheck(now);
        return;
      }

      unawaited(_downloadNow(prefs: prefs));
    } catch (e, st) {
      developer.log(
        'Auto-install failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _maybeAutoUpdateInstalled({
    required SharedPreferencesCompat prefs,
  }) async {
    try {
      if (!kReleaseMode) return; // dev builds can manage manually

      final last = prefs.getInt(_prefsKeyLastUpdateCheckMs) ?? 0;
      final now = _now();
      final nowMs = now.millisecondsSinceEpoch;
      if (last > 0 &&
          nowMs - last < _minUpdateCheckInterval.inMilliseconds) {
        return;
      }

      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      if (!isWifi) {
        _ensureWifiListenerStarted();
        return;
      }

      final batteryState = await _battery.getBatteryState();
      final isCharging =
          batteryState == BatteryState.charging || batteryState == BatteryState.full;
      if (!isCharging) {
        _ensureChargingListenerStarted();
        return;
      }

      final isIdle = now.hour >= _idleStartHour && now.hour < _idleEndHour;
      if (!isIdle) {
        _scheduleIdleRecheck(now);
        return;
      }

      // Update check uses the same trusted manifest path.
      final caps = await _caps.getCapabilities();
      final gateResult = _gate.evaluate(caps);
      final tier = switch (gateResult.recommendedTier) {
        OfflineLlmTier.llama8b => 'llama8b',
        OfflineLlmTier.small3b => 'small3b',
        OfflineLlmTier.none => 'none',
      };
      if (tier == 'none') return;

      // Mark check time before downloading to avoid repeated loops if download is
      // slow or interrupted.
      await prefs.setInt(_prefsKeyLastUpdateCheckMs, nowMs);

      await _provisioning.setPhase(LocalLlmProvisioningPhase.downloading);
      void onProgress(int receivedBytes, int totalBytes) {
        unawaited(
          _provisioning.setProgress(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
          ),
        );
      }

      await _packs.downloadAndActivateTrusted(
        tier: tier,
        onProgress: onProgress,
      );

      await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);
    } catch (e, st) {
      await _provisioning.setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
      developer.log(
        'Auto-update failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _ensureWifiListenerStarted() {
    // Avoid multiple listeners across app lifetime.
    if (_wifiSubscription != null) return;

    _wifiSubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
      final isWifi = results.contains(ConnectivityResult.wifi);
      if (!isWifi) return;

      try {
        await _wifiSubscription?.cancel();
      } finally {
        _wifiSubscription = null;
      }

      try {
        await maybeAutoInstall();
      } catch (e, st) {
        developer.log(
          'Wi-Fi listener install attempt failed (non-fatal)',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  void _ensureChargingListenerStarted() {
    if (_batterySubscription != null) return;

    _batterySubscription = _battery.onBatteryStateChanged.listen((state) async {
      final isCharging =
          state == BatteryState.charging || state == BatteryState.full;
      if (!isCharging) return;

      try {
        await _batterySubscription?.cancel();
      } finally {
        _batterySubscription = null;
      }

      try {
        await maybeAutoInstall();
      } catch (e, st) {
        developer.log(
          'Charging listener install attempt failed (non-fatal)',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  void _scheduleIdleRecheck(DateTime now) {
    _idleTimer?.cancel();
    final nextStart = DateTime(now.year, now.month, now.day + 1, _idleStartHour);
    final delay = nextStart.difference(now);
    // If clocks are weird, fall back to a short recheck.
    final safeDelay = delay.isNegative ? const Duration(minutes: 30) : delay;
    _idleTimer = Timer(
      safeDelay,
      () => unawaited(LocalLlmAutoInstallService().maybeAutoInstall()),
    );
  }

  Future<void> _downloadNow({required SharedPreferencesCompat prefs}) async {
    try {
      await _provisioning.setPhase(LocalLlmProvisioningPhase.downloading);
      void onProgress(int receivedBytes, int totalBytes) {
        unawaited(
          _provisioning.setProgress(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
          ),
        );
      }

      // Best-effort background download (don’t crash startup).
      if (kReleaseMode) {
        final caps = await _caps.getCapabilities();
        final gateResult = _gate.evaluate(caps);
        final tier = switch (gateResult.recommendedTier) {
          OfflineLlmTier.llama8b => 'llama8b',
          OfflineLlmTier.small3b => 'small3b',
          OfflineLlmTier.none => 'none',
        };
        if (tier == 'none') return;

        await _packs.downloadAndActivateTrusted(
          tier: tier,
          onProgress: onProgress,
        );
      } else {
        final url = prefs.getString(_prefsKeyLocalLlmManifestUrl);
        if (url == null || url.isEmpty) return;
        await _packs.downloadAndActivate(
          manifestUrl: Uri.parse(url),
          onProgress: onProgress,
        );
      }

      await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);
      // Best-effort: build local “memory” for the current user if we can.
      try {
        final sl = GetIt.instance;
        final bootstrap = sl.isRegistered<LocalLlmPostInstallBootstrapService>()
            ? sl<LocalLlmPostInstallBootstrapService>()
            : LocalLlmPostInstallBootstrapService();
        unawaited(bootstrap.maybeBootstrapCurrentUser());
      } catch (e, st) {
        developer.log(
          'Bootstrap kickoff failed (non-fatal): $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
      developer.log('Auto-install completed', name: _logName);
    } catch (e, st) {
      await _provisioning.setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
      developer.log(
        'Auto-install download failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Test-only helper to avoid leaked static subscriptions across test runs.
  static Future<void> resetWifiListenerForTests() async {
    try {
      await _wifiSubscription?.cancel();
      await _batterySubscription?.cancel();
      _idleTimer?.cancel();
    } finally {
      _wifiSubscription = null;
      _batterySubscription = null;
      _idleTimer = null;
    }
  }
}

