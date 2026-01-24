import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';

// ignore: uri_does_not_exist
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/local_llm_bootstrap_state.dart';
import 'package:avrai/core/services/agent_happiness_service.dart';
import 'package:avrai/core/services/device_capability_service.dart';
import 'package:avrai/core/services/device_capabilities.dart';
import 'package:avrai/core/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai/core/services/local_llm/local_llm_import_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai/core/services/model_safety_supervisor.dart';
import 'package:avrai/core/services/on_device_ai_capability_gate.dart';
import 'package:avrai/core/services/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/ml/model_version_registry.dart';
import 'package:avrai/core/services/local_llm/model_pack_manager.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnDeviceAiSettingsPage extends StatefulWidget {
  const OnDeviceAiSettingsPage({super.key});

  @override
  State<OnDeviceAiSettingsPage> createState() => _OnDeviceAiSettingsPageState();
}

class _OnDeviceAiSettingsPageState extends State<OnDeviceAiSettingsPage> {
  static const String _logName = 'OnDeviceAiSettingsPage';
  static const String _prefsKeyOfflineLlmEnabled = 'offline_llm_enabled_v1';
  static const String _prefsKeyOfflineLoraEnabled = 'offline_lora_enabled_v1';
  static const String _prefsKeyLocalLlmManifestUrl =
      'local_llm_manifest_url_v1';

  bool _loading = true;
  String? _error;

  bool _offlineLlmEnabled = false;
  bool _offlineLoraEnabled = false;

  late SharedPreferencesCompat _prefs;
  final _capService = DeviceCapabilityService();
  final _gate = OnDeviceAiCapabilityGate();

  DeviceCapabilities? _caps;
  OnDeviceAiGateResult? _gateResult;
  AgentHappinessSnapshot? _happiness;
  List<Map<String, dynamic>> _rollbackEvents = const [];
  LocalLlmModelPackStatus? _packStatus;
  LocalLlmBootstrapState? _bootstrap;
  List<LocalLlmRefinementPrompt> _pendingRefinementPrompts = const [];

  ProofRunServiceV0? _tryResolveProofRun() {
    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<ProofRunServiceV0>()) return null;
      return sl<ProofRunServiceV0>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordProofRunMilestoneIfActive(
    String eventType, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    if (!kDebugMode) return;
    final proof = _tryResolveProofRun();
    final runId = proof?.getActiveRunId();
    if (proof == null || runId == null || runId.isEmpty) return;
    try {
      await proof.recordMilestone(
        runId: runId,
        eventType: eventType,
        payload: payload,
      );
    } catch (e, st) {
      developer.log('Proof run milestone failed (non-fatal): $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _prefs = await SharedPreferencesCompat.getInstance();
      final caps = await _capService.getCapabilities();
      final gate = _gate.evaluate(caps);
      final happiness = AgentHappinessService(prefs: _prefs).getSnapshot();
      final rollbacks =
          ModelSafetySupervisor(prefs: _prefs).getRollbackEvents();
      final packStatus = await LocalLlmModelPackManager().getStatus();

      // Opt-out behavior: default enabled for eligible devices.
      final hasUserChoice = _prefs.containsKey(_prefsKeyOfflineLlmEnabled);
      _offlineLlmEnabled = _prefs.getBool(_prefsKeyOfflineLlmEnabled) ?? false;
      if (!hasUserChoice) {
        final eligibleByGate = gate.recommendedTier != OfflineLlmTier.none;
        _offlineLlmEnabled = eligibleByGate;
        await _prefs.setBool(_prefsKeyOfflineLlmEnabled, _offlineLlmEnabled);
      }
      _offlineLoraEnabled =
          _prefs.getBool(_prefsKeyOfflineLoraEnabled) ?? false;

      LocalLlmBootstrapState? bootstrap;
      List<LocalLlmRefinementPrompt> pendingPrompts = const [];
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null && userId.isNotEmpty) {
          final svc = GetIt.instance.isRegistered<LocalLlmPostInstallBootstrapService>()
              ? GetIt.instance<LocalLlmPostInstallBootstrapService>()
              : LocalLlmPostInstallBootstrapService();
          bootstrap = await svc.getBootstrapStateForUser(userId);
          if (bootstrap != null && bootstrap.pendingRefinementPromptIds.isNotEmpty) {
            pendingPrompts = await svc.getPendingRefinementPromptsForUser(userId);
          }
        }
      } catch (e, st) {
        developer.log('Failed to load offline AI refinement prompts (non-fatal): $e',
            name: _logName, error: e, stackTrace: st);
      }

      setState(() {
        _caps = caps;
        _gateResult = gate;
        _happiness = happiness;
        _rollbackEvents = rollbacks;
        _packStatus = packStatus;
        _bootstrap = bootstrap;
        _pendingRefinementPrompts = pendingPrompts;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load on-device AI settings',
          name: _logName, error: e, stackTrace: st);
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('On-Device AI'),
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  _buildInfoCard(
                    title: 'Error',
                    body: _error!,
                    icon: Icons.error_outline,
                    iconColor: AppColors.error,
                  ),
                _buildHappinessCard(),
                const SizedBox(height: 12),
                _buildCapabilityCard(),
                const SizedBox(height: 12),
                _buildModelSafetyCard(),
                const SizedBox(height: 12),
                _buildTogglesCard(),
                const SizedBox(height: 12),
                _buildNotesCard(),
              ],
            ),
    );
  }

  Widget _buildHappinessCard() {
    final h = _happiness ??
        const AgentHappinessSnapshot(score: 0.5, count: 0, p50: 50, p95: 50);
    final percent = (h.score * 100).round();
    final color = percent >= 70
        ? AppColors.success
        : percent >= 50
            ? AppColors.warning
            : AppColors.error;

    return _buildInfoCard(
      title: 'Agent happiness',
      body: '$percent/100 (n=${h.count}, p50=${h.p50}, p95=${h.p95}).\n\n'
          'This score helps schedule training safely (and blocks “from above” changes that make your agent worse).',
      icon: Icons.favorite_outline,
      iconColor: color,
    );
  }

  Widget _buildCapabilityCard() {
    final caps = _caps;
    final gate = _gateResult;
    if (caps == null || gate == null) {
      return _buildInfoCard(
        title: 'Device capability',
        body: 'Unavailable.',
        icon: Icons.memory,
        iconColor: AppColors.textSecondary,
      );
    }

    final tier = switch (gate.recommendedTier) {
      OfflineLlmTier.none => 'Not eligible',
      OfflineLlmTier.small3b => 'Eligible (small ~3B class)',
      OfflineLlmTier.llama8b => 'Eligible (Llama 3.1 8B class)',
    };

    // macOS-specific: Show architecture info
    final architectureInfo = defaultTargetPlatform == TargetPlatform.macOS
        ? (caps.deviceModel.isNotEmpty ? 'Architecture: ${caps.deviceModel}\n' : '')
        : '';
    
    return _buildInfoCard(
      title: 'Device capability gate',
      body: [
        architectureInfo,
        'Tier: $tier',
        if (caps.totalRamMb != null) 'RAM: ${caps.totalRamMb}MB',
        if (caps.freeDiskMb != null) 'Free storage: ${caps.freeDiskMb}MB',
        if (defaultTargetPlatform != TargetPlatform.macOS)
          'Low power mode: ${caps.isLowPowerMode ? "on" : "off"}',
        if (gate.reasons.isNotEmpty) '',
        ...gate.reasons.map((r) => '- $r'),
      ].join('\n'),
      icon: Icons.shield_outlined,
      iconColor: gate.eligible ? AppColors.electricGreen : AppColors.grey600,
    );
  }

  Widget _buildTogglesCard() {
    final gate = _gateResult;
    final eligible = gate?.eligible ?? false;
    final allowLora = gate?.allowOnDeviceLoraTraining ?? false;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildLocalModelPackRow(eligible: eligible),
            if ((_packStatus?.isInstalled ?? false) &&
                _pendingRefinementPrompts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRefinementPicksCard(),
              ),
            SwitchListTile(
              value: _offlineLlmEnabled,
              onChanged: eligible
                  ? (v) async {
                      setState(() => _offlineLlmEnabled = v);
                      await _setBool(_prefsKeyOfflineLlmEnabled, v);
                    }
                  : null,
              title: const Text('Enable offline LLM (download)'),
              subtitle: Text(eligible
                  ? (defaultTargetPlatform == TargetPlatform.macOS
                      ? 'Downloads a local model immediately and runs chat offline.'
                      : 'Downloads a local model when on Wi-Fi and charging, then runs chat offline.')
                  : 'Disabled: device not eligible (or low power mode on).'),
            ),
            SwitchListTile(
              value: _offlineLoraEnabled,
              onChanged: (eligible && allowLora)
                  ? (v) async {
                      setState(() => _offlineLoraEnabled = v);
                      await _setBool(_prefsKeyOfflineLoraEnabled, v);
                    }
                  : null,
              title: const Text('Enable scheduled LoRA training'),
              subtitle: Text((eligible && allowLora)
                  ? (defaultTargetPlatform == TargetPlatform.macOS
                      ? 'Trains adapters only during idle periods.'
                      : 'Trains adapters only during charging + idle.')
                  : 'Disabled: requires higher-tier device capability.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefinementPicksCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refine offline AI (30 seconds)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'These quick picks make local suggestions sharper.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pendingRefinementPrompts
                .take(3)
                .map((p) => Chip(
                      label: Text(p.title),
                      backgroundColor:
                          AppColors.electricGreen.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: AppColors.electricGreen.withValues(alpha: 0.35),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showRefinementFlow,
              child: const Text('Refine now'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefinementFlow() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    if (_pendingRefinementPrompts.isEmpty) return;

    final prompts = _pendingRefinementPrompts;
    final existingSelections =
        _bootstrap?.refinementSelections ?? const <String, List<String>>{};
    final selections = <String, Set<String>>{
      for (final p in prompts) p.id: {...(existingSelections[p.id] ?? const [])},
    };

    int idx = 0;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final prompt = prompts[idx];
          final selected = selections[prompt.id] ?? <String>{};

          return AlertDialog(
            title: Text(prompt.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: prompt.options
                      .map((o) => FilterChip(
                            label: Text(o.label),
                            selected: selected.contains(o.id),
                            onSelected: (v) {
                              setLocalState(() {
                                if (v) {
                                  selected.add(o.id);
                                } else {
                                  selected.remove(o.id);
                                }
                                selections[prompt.id] = selected;
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
            actions: [
              if (idx > 0)
                TextButton(
                  onPressed: () => setLocalState(() => idx--),
                  child: const Text('Back'),
                ),
              TextButton(
                onPressed: () {
                  setLocalState(() {
                    selections[prompt.id] = <String>{};
                    if (idx < prompts.length - 1) {
                      idx++;
                    } else {
                      Navigator.pop(context, true);
                    }
                  });
                },
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (idx < prompts.length - 1) {
                    setLocalState(() => idx++);
                  } else {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(idx < prompts.length - 1 ? 'Next' : 'Done'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final svc = GetIt.instance.isRegistered<LocalLlmPostInstallBootstrapService>()
          ? GetIt.instance<LocalLlmPostInstallBootstrapService>()
          : LocalLlmPostInstallBootstrapService();
      for (final p in prompts) {
        await svc.applyRefinementSelection(
          userId: userId,
          promptId: p.id,
          selectedOptionIds: (selections[p.id] ?? const <String>{}).toList(),
        );
      }

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline AI refined'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, st) {
      developer.log('Failed to apply refinement picks: $e',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refinement failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildLocalModelPackRow({required bool eligible}) {
    final status = _packStatus;
    final installed = status?.isInstalled == true;
    final subtitle = installed
        ? 'Installed: ${status?.activePackId ?? 'unknown'}'
        : 'Not installed';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        installed ? Icons.download_done : Icons.download_outlined,
        color: installed ? AppColors.success : AppColors.textSecondary,
      ),
      title: const Text('Local model pack'),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 8,
        children: [
          if (kDebugMode && !kIsWeb)
            OutlinedButton(
              onPressed: eligible ? _importLocalGgufDev : null,
              child: const Text('Import (dev)'),
            ),
          ElevatedButton(
            onPressed: eligible
                ? (kReleaseMode
                    ? _downloadTrustedModelPack
                    : _promptAndDownloadModelPack)
                : null,
            child: const Text(kReleaseMode ? 'Install' : 'Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTrustedModelPack() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final provisioning = LocalLlmProvisioningStateService();
      await provisioning.setPhase(LocalLlmProvisioningPhase.downloading);
      final tier =
          switch (_gateResult?.recommendedTier ?? OfflineLlmTier.none) {
        OfflineLlmTier.llama8b => 'llama8b',
        OfflineLlmTier.small3b => 'small3b',
        OfflineLlmTier.none => 'none',
      };
      if (tier == 'none') {
        throw Exception('Device not eligible for offline model');
      }

      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_started',
        payload: <String, Object?>{
          'path': 'trusted',
          'tier': tier,
        },
      );

      await LocalLlmModelPackManager().downloadAndActivateTrusted(
        tier: tier,
        onProgress: (r, t) {
          unawaited(provisioning.setProgress(receivedBytes: r, totalBytes: t));
        },
      );
      await provisioning.setPhase(LocalLlmProvisioningPhase.installed);

      final installedPackId = (await LocalLlmModelPackManager().getStatus()).activePackId;
      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_installed',
        payload: <String, Object?>{
          'path': 'trusted',
          'tier': tier,
          if (installedPackId != null) 'pack_id': installedPackId,
        },
      );

      try {
        final sl = GetIt.instance;
        final bootstrap = sl.isRegistered<LocalLlmPostInstallBootstrapService>()
            ? sl<LocalLlmPostInstallBootstrapService>()
            : LocalLlmPostInstallBootstrapService();
        await bootstrap.maybeBootstrapCurrentUser();
      } catch (e, st) {
        developer.log('Bootstrap kickoff failed (non-fatal): $e',
            name: _logName, error: e, stackTrace: st);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline model downloaded and activated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_failed',
        payload: <String, Object?>{
          'path': 'trusted',
          'error': e.toString(),
        },
      );
      await LocalLlmProvisioningStateService().setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Install failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _importLocalGgufDev() async {
    try {
      // Some CI analyzers in this repo don’t always pick up freshly added pub
      // deps; this code is still valid (verified via `flutter analyze`).
      // ignore: undefined_identifier
      final result = await FilePicker.platform.pickFiles(
        // ignore: undefined_identifier
        type: FileType.custom,
        allowedExtensions: const ['gguf'],
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;

      if (!mounted) return;
      setState(() => _loading = true);

      await LocalLlmProvisioningStateService()
          .setPhase(LocalLlmProvisioningPhase.downloading);

      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_started',
        payload: const <String, Object?>{
          'path': 'import_dev',
          'format': 'gguf',
        },
      );

      await LocalLlmImportService().importAndActivateAndroidGguf(
        ggufFile: File(path),
      );
      await LocalLlmProvisioningStateService()
          .setPhase(LocalLlmProvisioningPhase.installed);

      final installedPackId = (await LocalLlmModelPackManager().getStatus()).activePackId;
      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_installed',
        payload: <String, Object?>{
          'path': 'import_dev',
          'format': 'gguf',
          if (installedPackId != null) 'pack_id': installedPackId,
        },
      );
      try {
        final sl = GetIt.instance;
        final bootstrap = sl.isRegistered<LocalLlmPostInstallBootstrapService>()
            ? sl<LocalLlmPostInstallBootstrapService>()
            : LocalLlmPostInstallBootstrapService();
        await bootstrap.maybeBootstrapCurrentUser();
      } catch (e, st) {
        developer.log('Bootstrap kickoff failed (non-fatal): $e',
            name: _logName, error: e, stackTrace: st);
      }

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GGUF imported and activated (dev)'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_failed',
        payload: <String, Object?>{
          'path': 'import_dev',
          'format': 'gguf',
          'error': e.toString(),
        },
      );
      await LocalLlmProvisioningStateService().setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _promptAndDownloadModelPack() async {
    final initial = _prefs.getString(_prefsKeyLocalLlmManifestUrl) ?? '';
    final controller = TextEditingController(text: initial);

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download offline model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the model pack manifest URL (JSON).',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Manifest URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (url == null || url.isEmpty) return;

    try {
      await _prefs.setString(_prefsKeyLocalLlmManifestUrl, url);
    } catch (_) {
      // Ignore.
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final provisioning = LocalLlmProvisioningStateService();
      await provisioning.setPhase(LocalLlmProvisioningPhase.downloading);

      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_started',
        payload: <String, Object?>{
          'path': 'manifest_url',
          'manifest_url': url,
        },
      );

      await LocalLlmModelPackManager().downloadAndActivate(
        manifestUrl: Uri.parse(url),
        onProgress: (r, t) {
          unawaited(provisioning.setProgress(receivedBytes: r, totalBytes: t));
        },
      );
      await provisioning.setPhase(LocalLlmProvisioningPhase.installed);

      final installedPackId = (await LocalLlmModelPackManager().getStatus()).activePackId;
      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_installed',
        payload: <String, Object?>{
          'path': 'manifest_url',
          if (installedPackId != null) 'pack_id': installedPackId,
        },
      );

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline model downloaded and activated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      await _recordProofRunMilestoneIfActive(
        'proof_offline_ai_provisioning_failed',
        payload: <String, Object?>{
          'path': 'manifest_url',
          'error': e.toString(),
        },
      );
      await LocalLlmProvisioningStateService().setPhase(
        LocalLlmProvisioningPhase.error,
        lastError: e.toString(),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildModelSafetyCard() {
    final currentCalling = ModelVersionRegistry.activeCallingScoreVersion;
    final currentOutcome = ModelVersionRegistry.activeOutcomeVersion;
    final last = _rollbackEvents.isNotEmpty ? _rollbackEvents.first : null;

    final lines = <String>[
      'Calling score model: $currentCalling',
      'Outcome model: $currentOutcome',
      '',
      'Auto-rollback is enabled using agent happiness signals.',
    ];
    if (last != null) {
      lines.add('');
      lines.add('Last rollback:');
      lines.add('- when: ${last['ts'] ?? 'unknown'}');
      lines.add('- model: ${last['model_type'] ?? 'unknown'}');
      lines.add(
          '- ${last['to_version'] ?? '?'} → ${last['from_version'] ?? '?'}');
    }

    return _buildInfoCard(
      title: 'Model safety',
      body: lines.join('\n'),
      icon: Icons.health_and_safety_outlined,
      iconColor: AppColors.electricGreen,
    );
  }

  Widget _buildNotesCard() {
    return _buildInfoCard(
      title: 'Why this exists (protection from above)',
      body: 'Off-device governance is a protective firewall:\n'
          '- It limits what leaves your device.\n'
          '- It validates what comes back (signed, versioned, safe).\n'
          '- It schedules training when it won’t hurt battery/heat.\n'
          '\n'
          'Your local agent stays in control of your personalization.',
      icon: Icons.lock_outline,
      iconColor: AppColors.textSecondary,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String body,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            )
          ],
        ),
      ),
    );
  }
}
