import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';

import 'package:avrai/core/services/device_capability_service.dart';
import 'package:avrai/core/services/on_device_ai_capability_gate.dart';
import 'package:avrai/core/services/local_llm/model_pack_manager.dart';
import 'package:avrai/core/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai/core/services/storage_service.dart' show SharedPreferencesCompat;

/// macOS-specific auto-install service for local LLM models.
///
/// Unlike iOS/Android, macOS downloads immediately (no Wi-Fi/charging/idle gates).
/// This is because macOS typically has stable power and network connections.
class LocalLlmMacOSAutoInstallService {
  static const String _logName = 'LocalLlmMacOSAutoInstallService';

  static const String _prefsKeyOfflineLlmEnabled = 'offline_llm_enabled_v1';

  final LocalLlmModelPackManager _packs;
  final DeviceCapabilityService _caps;
  final OnDeviceAiCapabilityGate _gate;
  final LocalLlmProvisioningStateService _provisioning;
  final SharedPreferencesCompat? _prefsOverride;

  LocalLlmMacOSAutoInstallService({
    LocalLlmModelPackManager? packs,
    DeviceCapabilityService? deviceCapabilities,
    OnDeviceAiCapabilityGate? gate,
    LocalLlmProvisioningStateService? provisioning,
    SharedPreferencesCompat? prefs,
  })  : _packs = packs ?? LocalLlmModelPackManager(),
        _caps = deviceCapabilities ?? DeviceCapabilityService(),
        _gate = gate ?? OnDeviceAiCapabilityGate(),
        _provisioning = provisioning ?? LocalLlmProvisioningStateService(),
        _prefsOverride = prefs;

  Future<SharedPreferencesCompat> _prefs() async {
    if (_prefsOverride != null) return _prefsOverride!;
    return await SharedPreferencesCompat.getInstance();
  }

  /// Main entry point: maybe auto-install for macOS.
  ///
  /// Downloads immediately without Wi-Fi/charging/idle gates.
  Future<void> maybeAutoInstallMacOS() async {
    if (kIsWeb) return;

    try {
      final prefs = await _prefs();
      
      // Check if offline LLM is enabled
      final hasUserChoice = prefs.containsKey(_prefsKeyOfflineLlmEnabled);
      bool enabled = prefs.getBool(_prefsKeyOfflineLlmEnabled) ?? false;

      if (!hasUserChoice) {
        // Auto-enable if eligible (opt-out behavior)
        final caps = await _caps.getCapabilities();
        final gateResult = _gate.evaluate(caps);
        enabled = gateResult.recommendedTier != OfflineLlmTier.none;
        await prefs.setBool(_prefsKeyOfflineLlmEnabled, enabled);
      }

      if (!enabled) {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.idle);
        return;
      }

      // Check if already installed
      final status = await _packs.getStatus();
      if (status.isInstalled) {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);
        return;
      }

      // Download immediately (no gates for macOS)
      await _downloadNow();
    } catch (e, st) {
      developer.log(
        'macOS auto-install failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _provisioning.setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
    }
  }

  /// Download and activate model immediately.
  Future<void> _downloadNow() async {
    try {
      await _provisioning.setPhase(LocalLlmProvisioningPhase.downloading);

      // Select optimal tier based on system specs
      final caps = await _caps.getCapabilities();
      final gateResult = _gate.evaluate(caps);
      final tier = switch (gateResult.recommendedTier) {
        OfflineLlmTier.llama8b => 'llama8b',
        OfflineLlmTier.small3b => 'small3b',
        OfflineLlmTier.none => 'none',
      };

      if (tier == 'none') {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.idle);
        developer.log(
          'Device not eligible for local LLM',
          name: _logName,
        );
        return;
      }

      // Progress callback
      void onProgress(int receivedBytes, int totalBytes) {
        _provisioning.setProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        );
      }

      // Download and activate
      await _packs.downloadAndActivateTrusted(
        tier: tier,
        onProgress: onProgress,
      );

      await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);

      // Best-effort: build local "memory" for the current user
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

      developer.log('macOS auto-install completed', name: _logName);
    } catch (e, st) {
      await _provisioning.setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
      developer.log(
        'macOS auto-install download failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      // Fallback to bundled model could be implemented here if available
    }
  }
}
