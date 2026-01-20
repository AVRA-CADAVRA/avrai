import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:crypto/crypto.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/ai_agent_fingerprint_service.dart';
import 'package:avrai/core/models/user_vibe.dart';
import 'package:avrai/core/services/agent_happiness_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/connection_metrics.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai/core/services/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/ai2ai/battery_adaptive_ble_scheduler.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_hop_policy.dart' as mesh_policy;
import 'package:avrai/core/ai2ai/embedding_delta_collector.dart';
import 'package:avrai/core/ai2ai/federated_learning_codec.dart';
import 'package:avrai/core/ai2ai/room_coherence_engine.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/anonymous_user.dart';
import 'package:avrai/core/services/user_anonymization_service.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_mesh_cache.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';
import 'package:uuid/uuid.dart';
import 'package:avrai/core/models/business_expert_message.dart' as chat_models;
import 'package:avrai/core/models/business_business_message.dart'
    as chat_models;
import 'package:avrai/data/datasources/local/sembast_database.dart';
import 'package:sembast/sembast.dart';

class _HotLatencySummary {
  final int count;
  final int p50;
  final int p95;

  const _HotLatencySummary({
    required this.count,
    required this.p50,
    required this.p95,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'count': count,
        'p50_ms': p50,
        'p95_ms': p95,
      };
}

/// Minimal ring-buffer latency collector.
///
/// Keeps the last N samples and computes p50/p95 on demand.
class _HotLatencyWindow {
  final int maxSamples;
  final List<int> _samples = <int>[];
  int _cursor = 0;

  _HotLatencyWindow({required this.maxSamples});

  void add(int ms) {
    if (ms < 0) return;
    if (_samples.length < maxSamples) {
      _samples.add(ms);
      return;
    }
    _samples[_cursor] = ms;
    _cursor = (_cursor + 1) % maxSamples;
  }

  _HotLatencySummary summary() {
    if (_samples.isEmpty) {
      return const _HotLatencySummary(count: 0, p50: 0, p95: 0);
    }
    final sorted = List<int>.from(_samples)..sort();
    int pick(double q) {
      final idx = ((sorted.length - 1) * q).round().clamp(0, sorted.length - 1);
      return sorted[idx];
    }

    return _HotLatencySummary(
      count: sorted.length,
      p50: pick(0.50),
      p95: pick(0.95),
    );
  }
}

class _EventModeCandidate {
  final DiscoveredDevice device;
  final String nodeTagKey;
  final bool remoteConnectOk;

  const _EventModeCandidate({
    required this.device,
    required this.nodeTagKey,
    required this.remoteConnectOk,
  });
}

class _EventModeBufferedLearningInsight {
  final String source; // "passive" | "inbox"
  final String? insightId;
  final String senderDeviceId;
  final DateTime receivedAt;
  final double learningQuality;
  final Map<String, double> deltas;

  const _EventModeBufferedLearningInsight({
    required this.source,
    required this.insightId,
    required this.senderDeviceId,
    required this.receivedAt,
    required this.learningQuality,
    required this.deltas,
  });
}

/// OUR_GUTS.md: "AI2AI vibe-based connections that enable cross-personality learning while preserving privacy"
/// Comprehensive connection orchestrator that manages AI2AI personality matching and learning
/// Enhanced with Supabase Realtime for live AI2AI communication
class VibeConnectionOrchestrator {
  static const String _logName = 'VibeConnectionOrchestrator';
  static const bool _allowBleSideEffectsInTests = bool.fromEnvironment(
    'SPOTS_ALLOW_BLE_SIDE_EFFECTS_IN_TESTS',
    defaultValue: false,
  );
  static const bool _allowBleSideEffectsOnIos = bool.fromEnvironment(
    'SPOTS_ALLOW_IOS_BLE_SIDE_EFFECTS',
    defaultValue: false,
  );

  bool get _isTestBinding {
    // Avoid importing flutter_test into production code; detect by binding type name.
    try {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      return bindingType.contains('TestWidgetsFlutterBinding') ||
          bindingType.contains('AutomatedTestWidgetsFlutterBinding') ||
          bindingType.contains('IntegrationTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  bool get _allowBleSideEffects {
    // BLE side-effects (MethodChannels, Timer.periodic loops, BLE connects) can
    // make tests flaky/hang. Default: OFF in tests unless explicitly enabled.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !_allowBleSideEffectsOnIos) {
      // iOS simulator (and many dev runs) cannot safely support BLE peripheral
      // advertising. The CoreBluetooth stack can hard-crash if restoration is
      // configured without the right delegate hooks. Default: disable BLE
      // side-effects on iOS unless explicitly enabled.
      return false;
    }
    return !_isTestBinding || _allowBleSideEffectsInTests;
  }

  final UserVibeAnalyzer _vibeAnalyzer;
  final Connectivity _connectivity;
  AI2AIBroadcastService? _realtimeService;
  final DiscoveryManager _discoveryManager;
  final ConnectionManager _connectionManager;
  final RealtimeCoordinator? _realtimeCoordinator;
  final DeviceDiscoveryService? _deviceDiscovery;
  final AI2AIProtocol? _protocol;
  final PersonalityAdvertisingService? _advertisingService;
  final UserAnonymizationService? _anonymizationService;
  final SignalKeyManager? _signalKeyManager;
  final SharedPreferencesCompat _prefs;
  final AppLogger _logger =
      const AppLogger(defaultTag: 'AI2AI', minimumLevel: LogLevel.debug);

  // Phase 2: Knot Weaving Integration
  final KnotWeavingService? _knotWeavingService;
  final KnotStorageService? _knotStorageService;

  // Connection state management
  final Map<String, ConnectionMetrics> _activeConnections = {};
  final Map<String, DateTime> _connectionCooldowns = {};
  final List<PendingConnection> _pendingConnections = [];

  // Connection discovery and matching
  final Map<String, UserVibe> _nearbyVibes = {};
  final Map<String, AIPersonalityNode> _discoveredNodes = {};

  // Connection orchestration state
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isInitialized = false;
  Timer? _discoveryTimer;
  Timer? _connectionMaintenanceTimer;
  Timer? _bleInboxPoller;
  BatteryAdaptiveBleScheduler? _batteryScheduler;
  AdaptiveMeshNetworkingService? _adaptiveMeshService;

  // Quality-based key rotation tracking (AI2AI-specific)
  /// Previous quality scores per agent ID (for detecting quality changes)
  final Map<String, double> _previousQualityScores = {};

  /// Quality change threshold for triggering key rotation (AI2AI-specific)
  static const double _qualityChangeThreshold = 0.3; // 30% quality change

  Timer? _federatedCloudSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _federatedCloudConnectivitySub;
  int _lastFederatedCloudSyncAttemptMs = 0;

  // Bloom filters for loop prevention (BitChat-inspired, AI2AI-enhanced)
  // Per-scope Bloom filters (complements AdaptiveMeshNetworkingService)
  final Map<String, OptimizedBloomFilter> _bloomFilters = {};

  // Stable node id used for offline BLE addressing + Signal session keys.
  // Rotates periodically (privacy), stable within a window (correctness).
  late String _localBleNodeId;

  // Map discovered deviceId -> peer node id (from BLE stream-1 prekey payload).
  final Map<String, String> _peerNodeIdByDeviceId = {};

  // Replay protection (best-effort): sha256(packet) -> expiresAtMs
  final Map<String, int> _seenBleMessageHashes = {};
  int _lastSeenHashesPersistMs = 0;

  // AI2AI learning throttling to avoid rapid drift from nearby noise.
  final Map<String, DateTime> _lastAi2AiLearningAtByPeerId = {};

  // ========================================================================
  // Event Mode (broadcast-first) state
  // ========================================================================
  static const String _prefsKeyEventModeEnabled = 'event_mode_enabled';
  static const int _eventEpochMs = 5 * 60 * 1000;
  static const int _eventCheckInWindowMs = 30 * 1000;
  static const int _eventInitiatorEligibilityPct = 20;
  static const int _eventMaxDeepSyncPerEvent = 8;
  static const int _eventPerNodeDeepSyncCooldownMs = 60 * 60 * 1000; // 60 min

  final RoomCoherenceEngine _roomCoherenceEngine = RoomCoherenceEngine();
  int _eventModeLastEpochAttempted = -1;
  bool _eventModeCheckInRunning = false;
  int _eventModeDeepSyncCount = 0;
  final Map<String, int> _eventModeLastDeepSyncAtMsByNodeTag = <String, int>{};
  final Map<String, int> _eventModeFamiliarityByNodeTag = <String, int>{};
  final List<_EventModeBufferedLearningInsight> _eventModeLearningBuffer =
      <_EventModeBufferedLearningInsight>[];
  bool _lastAdvertisedEventModeEnabled = false;
  bool _lastAdvertisedConnectOk = false;
  bool _lastAdvertisedBrownout = false;

  late String _localNodeTagKey;

  // Track current authenticated user for background learning application.
  String? _currentUserId;
  PersonalityProfile? _currentPersonality;

  // ========================================================================
  // Walk-by hot path (continuous scan)
  // ========================================================================
  static const int _hotRssiThresholdDbm = -75; // ~3m-ish in typical indoor BLE
  static const Duration _hotDeviceCooldown = Duration(seconds: 20);
  static const Duration _hotScanWindow = Duration(seconds: 4);
  static const Duration _hotDeviceTimeout = Duration(seconds: 30);

  final List<DiscoveredDevice> _hotQueue = <DiscoveredDevice>[];
  final Set<String> _hotQueuedDeviceIds = <String>{};
  bool _hotWorkerRunning = false;
  final Map<String, int> _lastHotProcessedAtMsByDeviceId = <String, int>{};
  final Map<String, int> _hotEnqueuedAtMsByDeviceId = <String, int>{};

  // Hot-path latency metrics (lightweight, in-memory ring buffers).
  static const int _hotMetricsWindowSize = 120;
  static const Duration _hotMetricsLogInterval = Duration(seconds: 30);
  final _HotLatencyWindow _hotQueueWaitMs =
      _HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final _HotLatencyWindow _hotTotalMs =
      _HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final _HotLatencyWindow _hotSessionOpenMs =
      _HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final _HotLatencyWindow _hotVibeReadMs =
      _HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  final _HotLatencyWindow _hotCompatMs =
      _HotLatencyWindow(maxSamples: _hotMetricsWindowSize);
  int _lastHotMetricsLogAtMs = 0;

  // ------------------------------------------------------------------------
  // Testing hooks (no real BLE required)
  // ------------------------------------------------------------------------

  /// Snapshot of currently known nearby AI nodes (for tests/debug tooling).
  @visibleForTesting
  List<AIPersonalityNode> debugDiscoveredNodesSnapshot() {
    return _discoveredNodes.values.toList();
  }

  /// Deterministic, no-BLE simulation of the walk-by hot path.
  ///
  /// This bypasses platform BLE and uses `device.personalityData` only.
  /// Intended for unit tests / CI validation when hardware isn’t available.
  @visibleForTesting
  Future<void> debugSimulateWalkByHotPath({
    required String userId,
    required PersonalityProfile personality,
    required List<DiscoveredDevice> devices,
  }) async {
    _currentUserId = userId;
    _currentPersonality = personality;

    final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    final localVibe = _buildDeterministicUserVibeForTesting(
      userId: userId,
      personality: personality,
    );

    for (final device in devices) {
      if (device.type != DeviceType.bluetooth) continue;
      final rssi = device.signalStrength;
      if (rssi == null || rssi < _hotRssiThresholdDbm) continue;
      final personalityData = device.personalityData;
      if (personalityData == null) continue;

      final vibe = _createVibeFromAnonymizedData(personalityData);
      final trustScore = device.proximityScore * 0.7 + 0.3;

      final node = AIPersonalityNode(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        trustScore: trustScore,
        learningHistory: {},
      );

      final compatibility =
          await _vibeAnalyzer.analyzeVibeCompatibility(localVibe, node.vibe);
      if (!_isConnectionWorthy(compatibility)) continue;

      _updateDiscoveredNodes(<AIPersonalityNode>[node]);
    }
  }

  UserVibe _buildDeterministicUserVibeForTesting({
    required String userId,
    required PersonalityProfile personality,
  }) {
    // Use the personality dimensions directly, with missing dimensions defaulted.
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] =
          (personality.dimensions[d] ?? VibeConstants.defaultDimensionValue)
              .clamp(0.0, 1.0);
    }

    final energy = ((dims['exploration_eagerness'] ?? 0.5) +
            (dims['temporal_flexibility'] ?? 0.5) +
            (dims['location_adventurousness'] ?? 0.5)) /
        3.0;
    final social = ((dims['community_orientation'] ?? 0.5) +
            (dims['social_discovery_style'] ?? 0.5) +
            (dims['trust_network_reliance'] ?? 0.5)) /
        3.0;
    final exploration = ((dims['exploration_eagerness'] ?? 0.5) +
            (dims['location_adventurousness'] ?? 0.5) +
            (1.0 - (dims['authenticity_preference'] ?? 0.5))) /
        3.0;

    final now = DateTime.now();
    return UserVibe(
      hashedSignature: 'test_sig_$userId',
      anonymizedDimensions: dims,
      overallEnergy: energy.clamp(0.0, 1.0),
      socialPreference: social.clamp(0.0, 1.0),
      explorationTendency: exploration.clamp(0.0, 1.0),
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      privacyLevel: 1.0,
      temporalContext: 'test',
    );
  }

  // Dedupe learning insights: insightId -> expiresAtMs
  final Map<String, int> _seenLearningInsightIds = {};
  int _lastSeenInsightsPersistMs = 0;

  static const _prefsKeyBleNodeId = 'ble_node_id_v1';
  static const _prefsKeyBleNodeIdExpiresAtMs = 'ble_node_id_expires_at_ms_v1';
  static const _prefsKeySeenBleHashes = 'ble_seen_hashes_v1';
  static const _prefsKeyAi2AiLearningEnabled = 'ai2ai_learning_enabled';
  static const _prefsKeySeenLearningInsightIds =
      'ai2ai_seen_learning_insights_v1';
  static const _prefsKeyFederatedLearningParticipation =
      'federated_learning_participation';
  static const _prefsKeyFederatedCloudQueue = 'ai2ai_federated_cloud_queue_v1';

  // Realtime event streams (managed by RealtimeCoordinator)
  // Note: Subscriptions are created and managed by _realtimeCoordinator.setup()
  // These fields are reserved for future direct stream access if needed
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _personalityDiscoverySubscription;
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _vibeLearningSubscription;
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _anonymousCommunicationSubscription;

  VibeConnectionOrchestrator({
    required UserVibeAnalyzer vibeAnalyzer,
    required Connectivity connectivity,
    AI2AIBroadcastService? realtimeService,
    DeviceDiscoveryService? deviceDiscovery,
    AI2AIProtocol? protocol,
    PersonalityAdvertisingService? advertisingService,
    UserAnonymizationService? anonymizationService,
    SignalKeyManager? signalKeyManager,
    required SharedPreferencesCompat prefs,
    PersonalityLearning? personalityLearning, // NEW: For offline AI2AI learning
    // Phase 2: Knot Weaving Integration
    KnotWeavingService? knotWeavingService,
    KnotStorageService? knotStorageService,
  })  : _vibeAnalyzer = vibeAnalyzer,
        _connectivity = connectivity,
        _realtimeService = realtimeService,
        _deviceDiscovery = deviceDiscovery,
        _protocol = protocol,
        _advertisingService = advertisingService,
        _anonymizationService = anonymizationService,
        _signalKeyManager = signalKeyManager,
        _prefs = prefs,
        _knotWeavingService = knotWeavingService,
        _knotStorageService = knotStorageService,
        _discoveryManager = DiscoveryManager(
            connectivity: connectivity, vibeAnalyzer: vibeAnalyzer),
        _connectionManager = ConnectionManager(
          vibeAnalyzer: vibeAnalyzer,
          personalityLearning:
              personalityLearning, // NEW: Pass to ConnectionManager
          ai2aiProtocol: protocol, // NEW: Pass to ConnectionManager
        ),
        _realtimeCoordinator = realtimeService != null
            ? RealtimeCoordinator(realtimeService)
            : null;

  /// Inject or update the realtime service after construction to avoid DI cycles
  void setRealtimeService(AI2AIBroadcastService service) {
    _realtimeService = service;
  }

  /// Update personality advertising when personality evolves
  /// Call this after personality profile is updated
  /// This method is automatically called via PersonalityLearning callback
  Future<void> updatePersonalityAdvertising(
    String userId,
    PersonalityProfile updatedPersonality,
  ) async {
    if (_advertisingService == null) {
      return;
    }

    // Respect the user-controlled discovery switch.
    final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    // Keep a current reference for fast-path compatibility checks.
    _currentPersonality = updatedPersonality;

    try {
      _logger.info(
          'Updating personality advertising after evolution (generation ${updatedPersonality.evolutionGeneration})',
          tag: _logName);

      final eventModeEnabled = _isEventModeEnabled();
      final vibe =
          await _vibeAnalyzer.compileUserVibe(userId, updatedPersonality);
      final anonymized = await PrivacyProtection.anonymizeUserVibe(vibe);

      final success = await _advertisingService!.updatePersonalityData(
        personalityData: anonymized,
        nodeId: _localBleNodeId,
        eventModeEnabled: eventModeEnabled,
        connectOk: _lastAdvertisedConnectOk,
        brownout: _lastAdvertisedBrownout,
      );

      if (success) {
        _logger.info('Personality advertising updated successfully',
            tag: _logName);
      } else {
        _logger.warn('Failed to update personality advertising', tag: _logName);
      }
    } catch (e) {
      _logger.error('Error updating personality advertising',
          error: e, tag: _logName);
    }
  }

  /// Set up automatic personality advertising updates
  /// Call this to enable automatic updates when personality evolves
  void setupAutomaticAdvertisingUpdates() {
    // This will be called from injection container after PersonalityLearning is created
    // The callback will be set up there to avoid circular dependencies
  }

  /// Initialize the AI2AI connection orchestration system
  Future<void> initializeOrchestration(
      String userId, PersonalityProfile personality) async {
    if (_isInitialized) {
      _logger.debug(
          'Orchestration already initialized; skipping reinitialization',
          tag: _logName);
      return;
    }
    try {
      _logger.info('Initializing orchestration for user: $userId',
          tag: _logName);

      // Respect the user-controlled discovery switch.
      // If disabled, do not start advertising, scanning, or background timers.
      final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
      if (!discoveryEnabled) {
        _logger.info(
          'AI2AI discovery is disabled by user setting; skipping orchestration init',
          tag: _logName,
        );
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.deviceCapability,
            eventType: 'ai2ai_orchestration_init_skipped',
            occurredAt: DateTime.now(),
            entityType: 'user',
            entityId: userId,
            payload: <String, Object?>{
              'reason': 'discovery_disabled',
            },
          ));
        }
        return;
      }

      _currentUserId = userId;
      _currentPersonality = personality;

      // Ensure stable (rotating) offline BLE node id + load replay protection state.
      await _ensureLocalBleNodeId();
      _loadSeenBleHashes();
      _loadSeenLearningInsightIds();
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_orchestration_init_started',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'allow_ble_side_effects': _allowBleSideEffects,
            'is_test_binding': _isTestBinding,
            'is_web': kIsWeb,
            'platform': defaultTargetPlatform.name,
            'ble_node_id': _localBleNodeId,
          },
        ));
      }

      // Android-only: keep BLE work alive in the background.
      // Note: Android requires a foreground service notification; cannot be truly "silent".
      if (_allowBleSideEffects &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        final started = await BleForegroundService.startService();
        if (started) {
          _logger.info('Android BLE foreground service started', tag: _logName);
          if (LedgerAuditV0.isEnabled) {
            unawaited(LedgerAuditV0.tryAppend(
              domain: LedgerDomainV0.deviceCapability,
              eventType: 'ai2ai_ble_foreground_service_started',
              occurredAt: DateTime.now(),
              payload: const <String, Object?>{
                'platform': 'android',
              },
            ));
          }
        } else {
          _logger.warn('Android BLE foreground service failed to start',
              tag: _logName);
          if (LedgerAuditV0.isEnabled) {
            unawaited(LedgerAuditV0.tryAppend(
              domain: LedgerDomainV0.deviceCapability,
              eventType: 'ai2ai_ble_foreground_service_failed',
              occurredAt: DateTime.now(),
              payload: const <String, Object?>{
                'platform': 'android',
              },
            ));
          }
        }
      }

      // Publish Signal prekey payload for offline bootstrap (Mode 2).
      // This is best-effort: if Signal isn't initialized yet, advertising can still proceed.
      if (_allowBleSideEffects) {
        await _publishSignalPreKeyPayloadIfAvailable();
      }

      // Initialize realtime service if available
      if (_realtimeService != null) {
        final realtimeInitialized = await _realtimeService!.initialize();
        if (realtimeInitialized) {
          _logger.info('Realtime Service initialized', tag: _logName);
          await _setupRealtimeListeners();
        } else {
          _logger.warn('Realtime Service failed to initialize', tag: _logName);
        }
      }

      // Start personality advertising (make this device discoverable).
      // BLE side-effects are disabled by default on iOS (simulator safety).
      if (_allowBleSideEffects && _advertisingService != null) {
        final eventModeEnabled = _isEventModeEnabled();
        final vibe = await _vibeAnalyzer.compileUserVibe(userId, personality);
        final anonymized = await PrivacyProtection.anonymizeUserVibe(vibe);

        final advertisingStarted = await _advertisingService!.startAdvertising(
          personalityData: anonymized,
          nodeId: _localBleNodeId,
          eventModeEnabled: eventModeEnabled,
          connectOk: false,
          brownout: false,
        );
        if (advertisingStarted) {
          _logger.info('Personality advertising started', tag: _logName);
        } else {
          _logger.warn('Personality advertising failed to start',
              tag: _logName);
        }
      }

      // Start device discovery (find other devices).
      // Performance optimization: Add throttling delays between BLE operations
      // to reduce context switching and improve battery life.
      if (_allowBleSideEffects && _deviceDiscovery != null) {
        // Continuous scanning: back-to-back scan windows (walk-by capture).
        _deviceDiscovery!.onDevicesDiscovered(_onDevicesDiscoveredHotPath);
        await _deviceDiscovery!.startDiscovery(
          scanInterval: Duration.zero,
          scanWindow: _hotScanWindow,
          deviceTimeout: _hotDeviceTimeout,
        );
        _logger.info('Device discovery started', tag: _logName);

        // Throttle: Add delay before starting battery scheduler to reduce context switching
        await Future.delayed(const Duration(milliseconds: 300));

        // Battery-adaptive scan scheduling (best-effort).
        _batteryScheduler?.stop();
        _batteryScheduler = BatteryAdaptiveBleScheduler(
          discovery: _deviceDiscovery!,
          prefs: _prefs,
        );
        await _batteryScheduler!.start();

        // Throttle: Add delay before starting adaptive mesh service
        await Future.delayed(const Duration(milliseconds: 200));

        // Initialize adaptive mesh networking service
        _adaptiveMeshService?.stop();
        _adaptiveMeshService = AdaptiveMeshNetworkingService(
          batteryScheduler: _batteryScheduler!,
          discovery: _deviceDiscovery!,
        );
        await _adaptiveMeshService!.start();
      }

      // Throttle: Add delay before starting AI2AI discovery to batch BLE operations
      if (_allowBleSideEffects) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _startAI2AIDiscovery(userId, personality);
      } else {
        _logger.info(
          'BLE side-effects disabled; skipping AI2AI discovery timers',
          tag: _logName,
        );
      }

      // Start processing incoming BLE inbox messages (silent background).
      // This is non-blocking, so no delay needed here.
      if (_allowBleSideEffects) {
        _startBleInboxProcessing();
      }

      // Start federated (hybrid) sync:
      // - Pattern 1: BLE gossip happens opportunistically via learningInsight messages
      // - Pattern 2: Optional cloud aggregation when online (edge function)
      // This is non-blocking, so no delay needed here.
      _startFederatedCloudSync();

      // Throttle: Add delay before connection maintenance to allow BLE operations to stabilize
      await Future.delayed(const Duration(milliseconds: 100));

      // Begin connection maintenance
      await _startConnectionMaintenance();

      _isInitialized = true;
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_orchestration_init_completed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: const <String, Object?>{
            'ok': true,
          },
        ));
      }
      _logger.info('Orchestration initialized successfully', tag: _logName);
    } catch (e) {
      _logger.error('Error initializing AI2AI orchestration',
          error: e, tag: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_orchestration_init_failed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'error': e.toString(),
          },
        ));
      }
      throw AI2AIConnectionException('Failed to initialize orchestration: $e');
    }
  }

  void _onDevicesDiscoveredHotPath(List<DiscoveredDevice> devices) {
    if (!_allowBleSideEffects) return;

    // Respect the user-controlled discovery switch.
    final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    final eventModeEnabled = _isEventModeEnabled();

    // If Event Mode was disabled, clear advertised flags once (best-effort).
    if (!eventModeEnabled && _lastAdvertisedEventModeEnabled) {
      unawaited(_maybeUpdateEventModeBroadcastFlags(
        eventModeEnabled: false,
        connectOk: false,
        brownout: false,
      ));
    }

    // Event Mode: broadcast-first (no hot-path connections except check-ins).
    if (eventModeEnabled) {
      unawaited(_handleEventModeScanWindow(devices));
      return;
    }

    // Hot path is BLE-only (walk-by capture). Other transports can be handled by
    // the slower, general discovery pipeline.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    var sawHotCandidate = false;
    for (final device in devices) {
      if (device.type != DeviceType.bluetooth) continue;

      final rssi = device.signalStrength;
      if (rssi == null || rssi < _hotRssiThresholdDbm) continue;
      sawHotCandidate = true;

      final lastMs = _lastHotProcessedAtMsByDeviceId[device.deviceId];
      if (lastMs != null &&
          nowMs - lastMs < _hotDeviceCooldown.inMilliseconds) {
        continue;
      }

      if (_hotQueuedDeviceIds.add(device.deviceId)) {
        _hotQueue.add(device);
        _hotEnqueuedAtMsByDeviceId[device.deviceId] = nowMs;
      }
    }

    // If we’re seeing strong RSSI results, temporarily boost scan cadence.
    if (sawHotCandidate) {
      _batteryScheduler?.notifyHotOpportunity();
    }
    _batteryScheduler?.notifyDiscoverySample(
      discoveredCount: devices.length,
      sawHotCandidate: sawHotCandidate,
    );

    if (_hotWorkerRunning || _hotQueue.isEmpty) return;
    _hotWorkerRunning = true;
    unawaited(_runHotWorker());
  }

  bool _isEventModeEnabled() =>
      (_prefs.getBool(_prefsKeyEventModeEnabled) ?? false) == true;

  Future<void> _handleEventModeScanWindow(
      List<DiscoveredDevice> devices) async {
    if (!_allowBleSideEffects) return;

    final userId = _currentUserId;
    final personality = _currentPersonality;
    if (userId == null || personality == null) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // If Event Mode was just turned on, reset per-event budgets.
    if (!_lastAdvertisedEventModeEnabled) {
      _eventModeDeepSyncCount = 0;
      _eventModeLastDeepSyncAtMsByNodeTag.clear();
      _eventModeLastEpochAttempted = -1;
      _eventModeCheckInRunning = false;
    }

    final frames = <RoomCoherenceFrame>[];
    final candidates = <_EventModeCandidate>[];

    var sawHotCandidate = false;
    for (final device in devices) {
      if (device.type != DeviceType.bluetooth) continue;

      final rssi = device.signalStrength;
      if (rssi != null && rssi >= _hotRssiThresholdDbm) {
        sawHotCandidate = true;
      }

      final frameMeta = device.metadata['spots_frame_v1'];
      if (frameMeta is! Map) continue;

      final nodeTagRaw = frameMeta['node_tag'];
      final dimsQRaw = frameMeta['dims_q'];
      if (nodeTagRaw is! List || dimsQRaw is! List) continue;

      final nodeTag = nodeTagRaw.map((e) => (e as num).toInt()).toList();
      final dimsQ = dimsQRaw.map((e) => (e as num).toInt()).toList();
      if (nodeTag.length != 4 || dimsQ.length != 12) continue;

      final nodeTagKey = _nodeTagKeyFromBytes(nodeTag);
      final remoteConnectOk = frameMeta['connect_ok'] == true;

      frames.add(RoomCoherenceFrame(nodeTag: nodeTag, dimsQ: dimsQ));
      candidates.add(_EventModeCandidate(
        device: device,
        nodeTagKey: nodeTagKey,
        remoteConnectOk: remoteConnectOk,
      ));

      final prev = _eventModeFamiliarityByNodeTag[nodeTagKey] ?? 0;
      _eventModeFamiliarityByNodeTag[nodeTagKey] = (prev + 1).clamp(0, 10000);
    }

    _batteryScheduler?.notifyDiscoverySample(
      discoveredCount: devices.length,
      sawHotCandidate: sawHotCandidate,
    );
    if (sawHotCandidate) {
      _batteryScheduler?.notifyHotOpportunity();
    }

    final room = _roomCoherenceEngine.observeWindowFrames(
      observedAt: now,
      frames: frames,
    );

    // Ambient dense behaves like brownout (no arming).
    final brownout = room.densityClass == RoomDensityClass.ambientDense;

    final inCheckInWindow = (nowMs % _eventEpochMs) < _eventCheckInWindowMs;
    final connectOk = inCheckInWindow &&
        room.linger &&
        !brownout &&
        _eventModeDeepSyncCount < _eventMaxDeepSyncPerEvent;

    await _maybeUpdateEventModeBroadcastFlags(
      eventModeEnabled: true,
      connectOk: connectOk,
      brownout: brownout,
    );

    if (!connectOk) return;
    if (brownout) return;

    // Only attempt one deep sync per epoch.
    final epoch = nowMs ~/ _eventEpochMs;
    if (_eventModeLastEpochAttempted == epoch) return;
    if (_eventModeCheckInRunning) return;

    // Deterministic initiator: only a small fraction may initiate in a window.
    if (!_eventModeMayInitiate(epoch: epoch)) return;

    final target = _pickEventModeTarget(
      candidates: candidates,
      nowMs: nowMs,
      epoch: epoch,
    );
    if (target == null) return;

    _eventModeLastEpochAttempted = epoch;
    _eventModeCheckInRunning = true;
    try {
      final jitterMs = _eventModeJitterMs(epoch: epoch);
      if (jitterMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: jitterMs));
      }

      // Ensure we still have time left in the window after jitter.
      final postJitterMs = DateTime.now().millisecondsSinceEpoch;
      if ((postJitterMs % _eventEpochMs) >= _eventCheckInWindowMs) {
        return;
      }

      await _processHotDevice(target.device);
      _eventModeDeepSyncCount += 1;
      _eventModeLastDeepSyncAtMsByNodeTag[target.nodeTagKey] = postJitterMs;
    } finally {
      _eventModeCheckInRunning = false;
    }
  }

  Future<void> _maybeUpdateEventModeBroadcastFlags({
    required bool eventModeEnabled,
    required bool connectOk,
    required bool brownout,
  }) async {
    final userId = _currentUserId;
    final personality = _currentPersonality;
    final advertising = _advertisingService;
    if (userId == null || personality == null || advertising == null) return;

    if (_lastAdvertisedEventModeEnabled == eventModeEnabled &&
        _lastAdvertisedConnectOk == connectOk &&
        _lastAdvertisedBrownout == brownout) {
      return;
    }

    _lastAdvertisedEventModeEnabled = eventModeEnabled;
    _lastAdvertisedConnectOk = connectOk;
    _lastAdvertisedBrownout = brownout;

    await advertising.updateServiceDataFrameV1Flags(
      nodeId: _localBleNodeId,
      eventModeEnabled: eventModeEnabled,
      connectOk: connectOk,
      brownout: brownout,
    );
  }

  bool _eventModeMayInitiate({required int epoch}) {
    // eligibility = hash(node_id + epoch) % 100
    final v = _hashMod(
      '$_localBleNodeId:$epoch',
      mod: 100,
    );
    return v < _eventInitiatorEligibilityPct;
  }

  int _eventModeJitterMs({required int epoch}) {
    // jitter_ms = hash(node_id + epoch) % 1500
    return _hashMod('$_localBleNodeId:$epoch', mod: 1500);
  }

  int _hashU32(String input) {
    final bytes = sha256.convert(utf8.encode(input)).bytes;
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  int _hashMod(String input, {required int mod}) {
    final v = _hashU32(input) & 0x7FFFFFFF;
    return v % mod;
  }

  _EventModeCandidate? _pickEventModeTarget({
    required List<_EventModeCandidate> candidates,
    required int nowMs,
    required int epoch,
  }) {
    // Must be two-sided opt-in.
    final eligible = candidates
        .where((c) => c.remoteConnectOk)
        .where((c) => _eventModeIsTieBreakInitiator(
              remoteNodeTagKey: c.nodeTagKey,
              epoch: epoch,
            ))
        .where((c) {
      final last = _eventModeLastDeepSyncAtMsByNodeTag[c.nodeTagKey];
      if (last == null) return true;
      return (nowMs - last) >= _eventPerNodeDeepSyncCooldownMs;
    }).toList();
    if (eligible.isEmpty) return null;

    eligible.sort((a, b) {
      final fa = _eventModeFamiliarityByNodeTag[a.nodeTagKey] ?? 0;
      final fb = _eventModeFamiliarityByNodeTag[b.nodeTagKey] ?? 0;
      return fb.compareTo(fa);
    });

    return eligible.first;
  }

  bool _eventModeIsTieBreakInitiator({
    required String remoteNodeTagKey,
    required int epoch,
  }) {
    // Symmetric tie-break: each side compares
    // hash(local + remote + epoch) vs hash(remote + local + epoch).
    final localFirst = _hashU32('$_localNodeTagKey:$remoteNodeTagKey:$epoch');
    final remoteFirst = _hashU32('$remoteNodeTagKey:$_localNodeTagKey:$epoch');
    return localFirst < remoteFirst;
  }

  void _bufferEventLearningInsight(_EventModeBufferedLearningInsight insight) {
    // In-memory buffer only (v1). This prevents event-time personality writes,
    // while still preserving observations for post-event consolidation.
    const maxItems = 500;
    if (_eventModeLearningBuffer.length >= maxItems) {
      _eventModeLearningBuffer.removeAt(0);
    }
    _eventModeLearningBuffer.add(insight);
  }

  Future<void> _runHotWorker() async {
    try {
      while (_hotQueue.isNotEmpty) {
        // Stop immediately if the switch is turned off mid-loop.
        final discoveryEnabled = _prefs.getBool('discovery_enabled') ?? false;
        if (!discoveryEnabled) return;

        final device = _hotQueue.removeAt(0);
        _hotQueuedDeviceIds.remove(device.deviceId);
        _lastHotProcessedAtMsByDeviceId[device.deviceId] =
            DateTime.now().millisecondsSinceEpoch;

        final enqMs = _hotEnqueuedAtMsByDeviceId.remove(device.deviceId);
        if (enqMs != null) {
          final waitMs = DateTime.now().millisecondsSinceEpoch - enqMs;
          _hotQueueWaitMs.add(waitMs);
        }

        await _processHotDevice(device);
      }
    } finally {
      _hotWorkerRunning = false;
    }
  }

  Future<void> _processHotDevice(DiscoveredDevice device) async {
    final userId = _currentUserId;
    final personality = _currentPersonality;
    if (userId == null || personality == null) return;

    final totalSw = Stopwatch()..start();
    try {
      final localVibe =
          await _vibeAnalyzer.compileUserVibe(userId, personality);

      AnonymizedVibeData? personalityData = device.personalityData;

      BleGattSession? session;
      if (_allowBleSideEffects && device.type == DeviceType.bluetooth) {
        try {
          final openSw = Stopwatch()..start();
          session =
              await BleConnectionPool.instance.openSession(device: device);
          openSw.stop();
          _hotSessionOpenMs.add(openSw.elapsedMilliseconds);

          if (personalityData == null) {
            final vibeReadSw = Stopwatch()..start();
            final vibeBytes = await session.readStreamPayload(streamId: 0);
            vibeReadSw.stop();
            _hotVibeReadMs.add(vibeReadSw.elapsedMilliseconds);
            if (vibeBytes != null && vibeBytes.isNotEmpty) {
              final jsonString = utf8.decode(vibeBytes);
              personalityData = PersonalityDataCodec.decodeFromJson(jsonString);
            }
          }

          // Prime prekeys + send silent bootstrap under the same lease.
          await _primeOfflineSignalPreKeyBundleInSession(
            device: device,
            session: session,
          );
        } catch (e) {
          _logger.debug(
              'Hot-path BLE session failed for ${device.deviceId}: $e',
              tag: _logName);
        } finally {
          try {
            await session?.close();
          } catch (_) {
            // Ignore.
          }
        }
      }

      // If we still don't have vibe, do a best-effort follow-up read.
      // (May connect again; keep this best-effort and bounded by cooldown.)
      personalityData ??=
          await _deviceDiscovery?.extractPersonalityData(device);
      if (personalityData == null) return;

      final vibe = _createVibeFromAnonymizedData(personalityData);

      final proximityScore =
          _deviceDiscovery?.calculateProximity(device) ?? 0.5;
      final trustScore = proximityScore * 0.7 + 0.3;

      final node = AIPersonalityNode(
        nodeId: device.deviceId,
        vibe: vibe,
        lastSeen: device.discoveredAt,
        trustScore: trustScore,
        learningHistory: {},
      );

      final compatSw = Stopwatch()..start();
      final compatibility =
          await _vibeAnalyzer.analyzeVibeCompatibility(localVibe, node.vibe);
      compatSw.stop();
      _hotCompatMs.add(compatSw.elapsedMilliseconds);
      if (!_isConnectionWorthy(compatibility)) return;

      _updateDiscoveredNodes(<AIPersonalityNode>[node]);

      unawaited(_maybeApplyPassiveAi2AiLearning(
        userId: userId,
        localPersonality: personality,
        nodes: <AIPersonalityNode>[node],
        compatibilityByNodeId: <String, VibeCompatibilityResult>{
          node.nodeId: compatibility,
        },
      ));
    } catch (e) {
      _logger.debug('Hot-path processing failed for ${device.deviceId}: $e',
          tag: _logName);
    } finally {
      totalSw.stop();
      _hotTotalMs.add(totalSw.elapsedMilliseconds);
      _maybeLogHotMetrics();
    }
  }

  void _maybeLogHotMetrics() {
    // Throttle logs so they’re useful, not noisy.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastHotMetricsLogAtMs <
        _hotMetricsLogInterval.inMilliseconds) {
      return;
    }
    _lastHotMetricsLogAtMs = nowMs;

    final total = _hotTotalMs.summary();
    if (total.count == 0) return;

    final q = _hotQueueWaitMs.summary();
    final open = _hotSessionOpenMs.summary();
    final vibe = _hotVibeReadMs.summary();
    final compat = _hotCompatMs.summary();

    _logger.debug(
      'HotPath latency ms '
      '(n=${total.count}) '
      'queue(p50=${q.p50},p95=${q.p95}) '
      'open(p50=${open.p50},p95=${open.p95}) '
      'vibe(p50=${vibe.p50},p95=${vibe.p95}) '
      'compat(p50=${compat.p50},p95=${compat.p95}) '
      'total(p50=${total.p50},p95=${total.p95})',
      tag: _logName,
    );
    if (LedgerAuditV0.isEnabled) {
      unawaited(LedgerAuditV0.tryAppend(
        domain: LedgerDomainV0.deviceCapability,
        eventType: 'ai2ai_hotpath_latency_summary',
        occurredAt: DateTime.now(),
        payload: debugHotPathLatencySummary().cast<String, Object?>(),
      ));
    }
  }

  @visibleForTesting
  Map<String, dynamic> debugHotPathLatencySummary() {
    final total = _hotTotalMs.summary();
    final q = _hotQueueWaitMs.summary();
    final open = _hotSessionOpenMs.summary();
    final vibe = _hotVibeReadMs.summary();
    final compat = _hotCompatMs.summary();

    return <String, dynamic>{
      'count': total.count,
      'queue': q.toJson(),
      'open': open.toJson(),
      'vibe': vibe.toJson(),
      'compat': compat.toJson(),
      'total': total.toJson(),
    };
  }

  Future<void> _ensureLocalBleNodeId() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final storedId = _prefs.getString(_prefsKeyBleNodeId);
    final expiresAtMs = _prefs.getInt(_prefsKeyBleNodeIdExpiresAtMs) ?? 0;

    if (storedId != null && storedId.isNotEmpty && expiresAtMs > nowMs) {
      _localBleNodeId = storedId;
      _refreshLocalNodeTag();
      return;
    }

    _localBleNodeId = const Uuid().v4();
    final newExpiresAtMs =
        DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
    await _prefs.setString(_prefsKeyBleNodeId, _localBleNodeId);
    await _prefs.setInt(_prefsKeyBleNodeIdExpiresAtMs, newExpiresAtMs);
    _refreshLocalNodeTag();
  }

  void _refreshLocalNodeTag() {
    _localNodeTagKey =
        _nodeTagKeyFromBytes(_computeNodeTagBytes(_localBleNodeId));
  }

  static List<int> _computeNodeTagBytes(String nodeId) {
    final digest = sha256.convert(utf8.encode(nodeId));
    return digest.bytes.sublist(0, 4);
  }

  static String _nodeTagKeyFromBytes(List<int> bytes4) {
    if (bytes4.length < 4) return bytes4.join(',');
    return '${bytes4[0]}-${bytes4[1]}-${bytes4[2]}-${bytes4[3]}';
  }

  void _loadSeenBleHashes() {
    if (_seenBleMessageHashes.isNotEmpty) return;
    final list = _prefs.getStringList(_prefsKeySeenBleHashes) ?? const [];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final item in list) {
      final parts = item.split(':');
      if (parts.length != 2) continue;
      final hash = parts[0];
      final expiresAt = int.tryParse(parts[1]) ?? 0;
      if (hash.isEmpty || expiresAt <= nowMs) continue;
      _seenBleMessageHashes[hash] = expiresAt;
    }
  }

  Future<void> _persistSeenBleHashesIfNeeded() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastSeenHashesPersistMs < 15 * 1000) return;
    _lastSeenHashesPersistMs = nowMs;

    _seenBleMessageHashes.removeWhere((_, exp) => exp <= nowMs);
    final entries = _seenBleMessageHashes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final capped = entries.take(200).toList();

    final list = capped.map((e) => '${e.key}:${e.value}').toList();
    await _prefs.setStringList(_prefsKeySeenBleHashes, list);
  }

  Future<void> _maybeApplyPassiveAi2AiLearning({
    required String userId,
    required PersonalityProfile localPersonality,
    required List<AIPersonalityNode> nodes,
    required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
  }) async {
    // Gate behind explicit user preference (default: enabled).
    final learningEnabled =
        _prefs.getBool(_prefsKeyAi2AiLearningEnabled) ?? true;
    if (!learningEnabled) return;

    final personalityLearning = _connectionManager.personalityLearning;
    if (personalityLearning == null) return;

    final eventModeEnabled = _isEventModeEnabled();

    final now = DateTime.now();
    const minIntervalPerPeer = Duration(minutes: 20);

    for (final node in nodes) {
      final last = _lastAi2AiLearningAtByPeerId[node.nodeId];
      if (last != null && now.difference(last) < minIntervalPerPeer) {
        continue;
      }

      final remoteDims = node.vibe.anonymizedDimensions;
      final localDims = localPersonality.dimensions;
      final deltas = <String, double>{};

      // Conservative: only learn from strong, repeated signals (anonymized data is noisy).
      for (final dimension in VibeConstants.coreDimensions) {
        final localValue =
            localDims[dimension] ?? VibeConstants.defaultDimensionValue;
        final remoteValue = remoteDims[dimension];
        if (remoteValue == null) continue;

        final diff = remoteValue - localValue;
        if (diff.abs() < 0.22) continue;
        deltas[dimension] = diff;
      }

      if (deltas.isEmpty) continue;

      final compat = compatibilityByNodeId[node.nodeId];
      final learningQuality = compat != null
          ? (compat.basicCompatibility * 0.6 + compat.aiPleasurePotential * 0.4)
              .clamp(0.0, 1.0)
          : 0.5;

      // If the match itself isn't strong, skip learning to prevent drift.
      if (learningQuality < 0.65) continue;

      final insight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: deltas,
        learningQuality: learningQuality,
        timestamp: now,
      );

      try {
        if (eventModeEnabled) {
          _bufferEventLearningInsight(_EventModeBufferedLearningInsight(
            source: 'passive',
            insightId: null,
            senderDeviceId: node.nodeId,
            receivedAt: now,
            learningQuality: learningQuality,
            deltas: deltas,
          ));
          _lastAi2AiLearningAtByPeerId[node.nodeId] = now;
          continue;
        }

        await personalityLearning.evolveFromAI2AILearning(
          userId,
          insight,
        );
        _lastAi2AiLearningAtByPeerId[node.nodeId] = now;

        // Phase 11 Enhancement: Integrate with ContinuousLearningSystem
        // KEEP existing personalityLearning call above - this is ADDITIONAL integration
        if (GetIt.instance.isRegistered<ContinuousLearningSystem>()) {
          try {
            final continuousLearningSystem =
                GetIt.instance<ContinuousLearningSystem>();
            unawaited(continuousLearningSystem.processAI2AILearningInsight(
              userId: userId,
              insight: insight,
              peerId: node.nodeId,
            ));
          } catch (e) {
            _logger.debug(
              'Failed to process AI2AI learning insight in ContinuousLearningSystem: $e',
              tag: _logName,
            );
            // Non-blocking - don't break existing flow
          }
        }

        // V1 "real" AI2AI learning exchange:
        // send the insight to the peer over the encrypted, ACK-confirmed BLE channel.
        await _sendLearningInsightToPeer(
          peerId: node.nodeId,
          insight: insight,
          learningQuality: learningQuality,
        );
      } catch (e) {
        _logger.debug('AI2AI passive learning skipped for ${node.nodeId}: $e',
            tag: _logName);
      }
    }
  }

  Future<void> _sendLearningInsightToPeer({
    required String peerId,
    required AI2AILearningInsight insight,
    required double learningQuality,
  }) async {
    if (!_allowBleSideEffects) return;
    if (_isEventModeEnabled()) return;
    final protocol = _protocol;
    if (protocol == null) return;

    final device = _deviceDiscovery?.getDevice(peerId);
    if (device == null) return;

    // Only implemented over physical BLE transport in v1.
    if (device.type != DeviceType.bluetooth) return;

    // Respect user setting.
    final learningEnabled =
        _prefs.getBool(_prefsKeyAi2AiLearningEnabled) ?? true;
    if (!learningEnabled) return;

    final recipientId =
        _peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
    final insightId = const Uuid().v4();
    const ttlMs = 60 * 60 * 1000; // 1 hour

    // Payload schema v1 (kept intentionally small and bounded).
    final payload = <String, dynamic>{
      'schema_version': 1,
      'insight_id': insightId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'ttl_ms': ttlMs,
      'learning_quality': learningQuality,
      'insight_type': insight.type.name,
      // Gossip fields (optional; ignored by older builds).
      'origin_id': _localBleNodeId,
      'hop': 0,
      'dimension_insights': insight.dimensionInsights.map(
        (k, v) => MapEntry(k, v.clamp(-0.35, 0.35)),
      ),
    };

    try {
      // Pattern 2: queue for optional cloud aggregation.
      await _enqueueFederatedDeltaForCloudFromInsightPayload(payload);

      final packetBytes = await protocol.encodePacketBytes(
        type: MessageType.learningInsight,
        payload: payload,
        senderNodeId: _localBleNodeId,
        recipientNodeId: recipientId,
      );

      // Best-effort, acked send (batch API uses ACK stream).
      final results = await sendBlePacketsBatch(
        device: device,
        senderId: _localBleNodeId,
        packetBytesList: <Uint8List>[packetBytes],
      );
      final ok = results.isNotEmpty && results.first;
      if (ok) {
        _logger.debug('Sent learning insight to $peerId', tag: _logName);
      }
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_learning_insight_sent',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'ok': ok,
            'peer_id': peerId,
            'recipient_id': recipientId,
            'insight_id': insightId,
            'schema_version': 1,
            'learning_quality': learningQuality,
            'delta_dimensions_count': insight.dimensionInsights.length,
          },
        ));
      }
    } catch (e) {
      _logger.debug('Failed to send learning insight to $peerId: $e',
          tag: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_learning_insight_send_failed',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'peer_id': peerId,
            'recipient_id': recipientId,
            'insight_id': insightId,
            'error': e.toString(),
          },
        ));
      }
    }
  }

  Future<void> _publishSignalPreKeyPayloadIfAvailable() async {
    // Avoid relying on field promotion (some packages still compile with
    // language versions where it isn't available).
    final signalKeyManager = _signalKeyManager;
    if (signalKeyManager == null) return;
    try {
      final bundle = await signalKeyManager.generatePreKeyBundle();
      final payloadJson = <String, dynamic>{
        'version': 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'node_id': _localBleNodeId,
        'prekey_bundle': _signalPreKeyBundleToJson(bundle),
      };
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadJson)));
      final ok = await BlePeripheral.updatePreKeyPayload(payload: bytes);
      if (ok) {
        _logger.info('Published Signal prekey payload over BLE', tag: _logName);
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.deviceCapability,
            eventType: 'ai2ai_ble_prekey_payload_published',
            occurredAt: DateTime.now(),
            payload: <String, Object?>{
              'ok': true,
              'bytes_len': bytes.length,
              'schema_version': 1,
            },
          ));
        }
      } else {
        _logger.warn('Failed to publish Signal prekey payload over BLE',
            tag: _logName);
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.deviceCapability,
            eventType: 'ai2ai_ble_prekey_payload_publish_failed',
            occurredAt: DateTime.now(),
            payload: <String, Object?>{
              'ok': false,
              'bytes_len': bytes.length,
              'schema_version': 1,
            },
          ));
        }
      }
    } catch (e) {
      _logger.warn('Error publishing Signal prekey payload over BLE: $e',
          tag: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_ble_prekey_payload_publish_error',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'error': e.toString(),
          },
        ));
      }
    }
  }

  Map<String, dynamic> _signalPreKeyBundleToJson(SignalPreKeyBundle bundle) {
    // Ensure JSON-encodable output (Uint8List -> List<int>).
    return <String, dynamic>{
      'preKeyId': bundle.preKeyId,
      'signedPreKey': bundle.signedPreKey.toList(),
      'signedPreKeyId': bundle.signedPreKeyId,
      'signature': bundle.signature.toList(),
      'identityKey': bundle.identityKey.toList(),
      'oneTimePreKey': bundle.oneTimePreKey?.toList(),
      'oneTimePreKeyId': bundle.oneTimePreKeyId,
      'registrationId': bundle.registrationId,
      'deviceId': bundle.deviceId,
      'kyberPreKeyId': bundle.kyberPreKeyId,
      'kyberPreKey': bundle.kyberPreKey?.toList(),
      'kyberPreKeySignature': bundle.kyberPreKeySignature?.toList(),
    };
  }

  /// Discover nearby AI personalities for potential connections
  Future<List<AIPersonalityNode>> discoverNearbyAIPersonalities(
      String userId, PersonalityProfile personality,
      {bool throwOnError = false}) async {
    if (_isDiscovering) {
      _logger.debug('Discovery already in progress, returning cached results',
          tag: _logName);
      return _discoveredNodes.values.toList();
    }

    // Connectivity should NOT block offline-first physical discovery.
    // It only affects whether realtime/cloud discovery is viable.
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (!_isConnected(connectivityResults)) {
        // #region agent log
        _logger.info(
            'No connectivity available, proceeding with offline discovery',
            tag: _logName);
        // #endregion
      }
    } catch (e) {
      // #region agent log
      _logger.warn('Error checking connectivity: $e, proceeding with discovery',
          tag: _logName);
      // #endregion
    }

    _isDiscovering = true;

    try {
      // #region agent log
      _logger.info('Discovering nearby AI personalities', tag: _logName);
      // #endregion

      final nodes = await _discoveryManager.discover(
          userId, personality, _performAI2AIDiscovery);

      // DiscoveryManager already handles compatibility analysis and prioritization
      // Additional filtering: ensure all nodes are connection-worthy
      if (nodes.isNotEmpty) {
        final localVibe =
            await _vibeAnalyzer.compileUserVibe(userId, personality);
        final compatibilityResults =
            await _analyzeNodeCompatibility(localVibe, nodes);

        // Filter to only connection-worthy nodes (DiscoveryManager already prioritized)
        final worthyNodes = nodes.where((node) {
          final compatibility = compatibilityResults[node.nodeId];
          return compatibility != null && _isConnectionWorthy(compatibility);
        }).toList();

        // #region agent log
        _logger.info(
            'Discovered ${nodes.length} nodes, ${worthyNodes.length} connection-worthy after filtering',
            tag: _logName);
        // #endregion

        _updateDiscoveredNodes(worthyNodes);

        // Passive, on-device AI2AI learning from nearby compatible peers.
        // Fire-and-forget: discovery should not block on learning updates.
        Future<void>(() async {
          await _maybeApplyPassiveAi2AiLearning(
            userId: userId,
            localPersonality: personality,
            nodes: worthyNodes,
            compatibilityByNodeId: compatibilityResults,
          );
        });

        return worthyNodes;
      }

      _updateDiscoveredNodes(nodes);
      // #region agent log
      _logger.info('Discovered ${nodes.length} compatible AI personalities',
          tag: _logName);
      // #endregion
      return nodes;
    } catch (e) {
      // #region agent log
      _logger.error('Error discovering AI personalities',
          error: e, tag: _logName);
      // #endregion
      if (throwOnError) {
        throw AI2AIConnectionException('Discovery failed: $e');
      }
      return [];
    } finally {
      _isDiscovering = false;
    }
  }

  /// Establish AI2AI connection based on vibe compatibility
  Future<ConnectionMetrics?> establishAI2AIConnection(
    String localUserId,
    PersonalityProfile localPersonality,
    AIPersonalityNode remoteNode,
  ) async {
    if (_isConnecting) {
      _logger.debug('Connection establishment already in progress',
          tag: _logName);
      return null;
    }

    // Check connection cooldown
    if (_isInCooldown(remoteNode.nodeId)) {
      _logger.debug('Connection to ${remoteNode.nodeId} is in cooldown period',
          tag: _logName);
      return null;
    }

    // Check active connection limits
    if (_activeConnections.length >= VibeConstants.maxSimultaneousConnections) {
      _logger.warn('Maximum simultaneous connections reached', tag: _logName);
      return null;
    }

    // Verify connection is worthy before attempting
    try {
      final localVibe =
          await _vibeAnalyzer.compileUserVibe(localUserId, localPersonality);
      final compatibility = await _vibeAnalyzer.analyzeVibeCompatibility(
        localVibe,
        remoteNode.vibe,
      );

      if (!_isConnectionWorthy(compatibility)) {
        // #region agent log
        _logger.debug(
            'Connection to ${remoteNode.nodeId} not worthy (compatibility: ${(compatibility.basicCompatibility * 100).round()}%, pleasure: ${(compatibility.aiPleasurePotential * 100).round()}%)',
            tag: _logName);
        // #endregion
        _setCooldown(remoteNode.nodeId);
        return null;
      }
    } catch (e) {
      // #region agent log
      _logger.warn(
          'Error checking connection worthiness: $e, proceeding anyway',
          tag: _logName);
      // #endregion
    }

    _isConnecting = true;

    try {
      // #region agent log
      _logger.info('Establishing connection with node: ${remoteNode.nodeId}',
          tag: _logName);
      // #endregion

      final establishedConnection = await _connectionManager.establish(
        localUserId,
        localPersonality,
        remoteNode,
        (localVibe, remote, comp, metrics) => _performConnectionEstablishment(
          localVibe,
          remote,
          comp,
          metrics,
          localPersonality.agentId,
          remoteNode.nodeId,
        ),
      );

      if (establishedConnection != null) {
        // Store active connection
        _activeConnections[establishedConnection.connectionId] =
            establishedConnection;

        // Schedule connection management
        _scheduleConnectionManagement(establishedConnection);

        // #region agent log
        _logger.info(
            'Connection established (ID: ${establishedConnection.connectionId})',
            tag: _logName);
        // #endregion
        return establishedConnection;
      } else {
        _logger.warn('Failed to establish connection', tag: _logName);
        _setCooldown(remoteNode.nodeId);
        return null;
      }
    } catch (e) {
      // #region agent log
      _logger.error('Error establishing connection', error: e, tag: _logName);
      // #endregion
      _setCooldown(remoteNode.nodeId);
      return null;
    } finally {
      _isConnecting = false;
    }
  }

  /// Manage active AI2AI connections for learning and quality
  Future<void> manageActiveConnections() async {
    if (_activeConnections.isEmpty) return;

    _logger.debug('Managing ${_activeConnections.length} active connections',
        tag: _logName);

    final completedConnections = <String>[];

    for (final connection in _activeConnections.values) {
      try {
        // Check if connection should continue
        if (!connection.shouldContinue || connection.hasReachedMaxDuration) {
          // Complete the connection
          final completedConnection = await _completeConnection(connection);
          if (completedConnection != null) {
            completedConnections.add(completedConnection.connectionId);
          }
          continue;
        }

        // Update connection with new learning interactions
        await _updateConnectionLearning(connection);

        // Monitor connection health
        await _monitorConnectionHealth(connection);
      } catch (e) {
        _logger.error('Error managing connection ${connection.connectionId}',
            error: e, tag: _logName);
        completedConnections.add(connection.connectionId);
      }
    }

    // Remove completed connections
    for (final connectionId in completedConnections) {
      _activeConnections.remove(connectionId);
    }

    _logger.debug(
        'Connection management completed. Active: ${_activeConnections.length}',
        tag: _logName);
  }

  /// Get count of active connections
  int getActiveConnectionCount() {
    return _activeConnections.length;
  }

  /// Calculate AI pleasure score for connection quality
  Future<double> calculateAIPleasureScore(ConnectionMetrics connection) async {
    try {
      _logger.debug(
          'Calculating AI pleasure score for ${connection.connectionId}',
          tag: _logName);

      // Base pleasure from compatibility
      var pleasureScore = connection.currentCompatibility * 0.4;

      // Add pleasure from learning effectiveness
      pleasureScore += connection.learningEffectiveness * 0.3;

      // Add pleasure from successful interactions
      final successfulExchanges =
          connection.learningOutcomes['successful_exchanges'] as int? ?? 0;
      final totalExchanges = connection.interactionHistory.length;
      final successRate =
          totalExchanges > 0 ? successfulExchanges / totalExchanges : 0.0;
      pleasureScore += successRate * 0.2;

      // Add pleasure from dimension evolution
      final dimensionEvolutionCount = connection.dimensionEvolution.keys.length;
      final evolutionBonus =
          (dimensionEvolutionCount / VibeConstants.coreDimensions.length) * 0.1;
      pleasureScore += evolutionBonus;

      final finalScore = pleasureScore.clamp(0.0, 1.0);

      _logger.debug('AI pleasure score: ${(finalScore * 100).round()}%',
          tag: _logName);

      // Feed agent happiness (used to prioritize on-device training and guard
      // against upstream regressions).
      try {
        final happiness = AgentHappinessService(prefs: _prefs);
        await happiness.recordSignal(
          source: 'ai2ai_pleasure',
          score: finalScore,
          metadata: <String, dynamic>{
            'connection_id': connection.connectionId,
          },
        );
      } catch (_) {
        // Ignore.
      }
      return finalScore;
    } catch (e) {
      _logger.error('Error calculating AI pleasure score',
          error: e, tag: _logName);
      return 0.5; // Neutral pleasure on error
    }
  }

  /// Get active connection summaries for monitoring
  List<ConnectionSummary> getActiveConnectionSummaries() {
    return _activeConnections.values.map((connection) {
      return ConnectionSummary(
        connectionId: connection.connectionId,
        duration: connection.connectionDuration,
        compatibility: connection.currentCompatibility,
        learningEffectiveness: connection.learningEffectiveness,
        aiPleasureScore: connection.aiPleasureScore,
        qualityRating: connection.qualityRating,
        status: connection.status,
        interactionCount: connection.interactionHistory.length,
        dimensionsEvolved: connection.dimensionEvolution.keys.length,
      );
    }).toList();
  }

  /// Get active connections for UI display
  /// Returns list of ConnectionMetrics for active connections
  List<ConnectionMetrics> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  /// Cleanup and shutdown orchestration
  Future<void> shutdown() async {
    _logger.info('Shutting down orchestration', tag: _logName);
    _isInitialized = false;

    // Cancel timers
    _discoveryTimer?.cancel();
    _connectionMaintenanceTimer?.cancel();
    _bleInboxPoller?.cancel();
    _federatedCloudSyncTimer?.cancel();
    await _federatedCloudConnectivitySub?.cancel();
    _federatedCloudConnectivitySub = null;
    await _batteryScheduler?.stop();
    _batteryScheduler = null;
    await _adaptiveMeshService?.stop();
    _adaptiveMeshService = null;

    // Stop discovery + advertising (best-effort).
    try {
      _deviceDiscovery?.stopDiscovery();
    } catch (e) {
      _logger.debug('Error stopping device discovery: $e', tag: _logName);
    }
    try {
      await _advertisingService?.stopAdvertising();
    } catch (e) {
      _logger.debug('Error stopping personality advertising: $e',
          tag: _logName);
    }

    // Android-only: stop BLE foreground runtime if we started it.
    if (_allowBleSideEffects &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        await BleForegroundService.stopService();
      } catch (e) {
        _logger.debug('Error stopping Android BLE foreground service: $e',
            tag: _logName);
      }
    }

    // Complete all active connections
    final activeConnectionIds = _activeConnections.keys.toList();
    for (final connectionId in activeConnectionIds) {
      final connection = _activeConnections[connectionId];
      if (connection != null) {
        await _completeConnection(connection, reason: 'system_shutdown');
      }
    }

    // Clear all state
    _activeConnections.clear();
    _connectionCooldowns.clear();
    _pendingConnections.clear();
    _nearbyVibes.clear();
    _discoveredNodes.clear();
    // Update adaptive mesh service with network density
    _adaptiveMeshService?.updateNetworkDensity(0);
    _currentUserId = null;

    _logger.info('Shutdown completed', tag: _logName);
  }

  void _startBleInboxProcessing() {
    if (!_allowBleSideEffects) return;
    _bleInboxPoller?.cancel();
    _bleInboxPoller = Timer.periodic(const Duration(seconds: 2), (_) async {
      final protocol = _protocol;
      if (protocol == null) return;

      try {
        final messages = await BleInbox.pollMessages(maxMessages: 50);
        if (messages.isEmpty) return;

        for (final msg in messages) {
          // Replay protection: drop duplicates within a short window.
          final hash = sha256.convert(msg.data).toString();
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final existingExpiry = _seenBleMessageHashes[hash];
          if (existingExpiry != null && existingExpiry > nowMs) {
            continue;
          }
          _seenBleMessageHashes[hash] =
              nowMs + const Duration(minutes: 10).inMilliseconds;

          // Decoding triggers Signal decrypt + session creation for PreKey messages.
          final decoded = await protocol.decodeMessage(msg.data, msg.senderId);
          if (decoded == null) continue;

          // Route messages based on type (routing happens before payload decryption)
          if (decoded.type == MessageType.learningInsight) {
            // Check if this is a locality agent update or learning insight
            final payload = decoded.payload;
            final type = payload['type'] as String?;
            if (type == 'locality_agent_update') {
              await _handleIncomingLocalityAgentUpdate(decoded);
            } else {
              await _handleIncomingLearningInsight(decoded);
            }
          } else if (decoded.type == MessageType.userChat) {
            // Route user-to-user chat messages to UI layer
            await _handleIncomingUserChat(decoded);
          }
        }

        await _persistSeenBleHashesIfNeeded();
        await _persistSeenLearningInsightIdsIfNeeded();
      } catch (e) {
        _logger.warn('BLE inbox processing error: $e', tag: _logName);
      }
    });
  }

  bool _isFederatedLearningParticipationEnabled() {
    return _prefs.getBool(_prefsKeyFederatedLearningParticipation) ?? true;
  }

  void _startFederatedCloudSync() {
    // Unit/widget tests shouldn't spin background timers/subscriptions; they
    // create pending timers and flaky hangs in CI.
    if (_isTestBinding) {
      _logger.debug(
        'Test binding detected; skipping federated cloud sync timers',
        tag: _logName,
      );
      return;
    }

    // Best-effort: no-op if not configured; safe to call multiple times.
    _federatedCloudSyncTimer?.cancel();
    unawaited(_federatedCloudConnectivitySub?.cancel());
    _federatedCloudConnectivitySub = null;

    _federatedCloudConnectivitySub =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) return;
      unawaited(_syncFederatedCloudQueue());
    });

    // Periodic retry, even if connectivity stream is noisy on some platforms.
    _federatedCloudSyncTimer =
        Timer.periodic(const Duration(minutes: 10), (_) async {
      unawaited(_syncFederatedCloudQueue());
    });
  }

  Future<void> _enqueueFederatedDeltaForCloudFromInsightPayload(
    Map<String, dynamic> payload,
  ) async {
    if (!_isFederatedLearningParticipationEnabled()) return;

    try {
      final entry =
          buildCloudDeltaEntryFromLearningInsightPayload(payload: payload);
      if (entry == null) return;
      final insightId = entry['id'] as String?;
      if (insightId == null || insightId.isEmpty) return;

      final existing =
          _prefs.getStringList(_prefsKeyFederatedCloudQueue) ?? const [];
      final next = <String>[];
      var seenId = false;
      for (final s in existing) {
        // Basic dedupe by `id` without needing to decode everything.
        if (cloudDeltaEntryContainsId(jsonString: s, id: insightId)) {
          seenId = true;
        }
        next.add(s);
      }
      if (!seenId) {
        next.add(jsonEncode(entry));
      }

      // Cap queue size (FIFO) to keep storage bounded.
      final capped =
          next.length <= 200 ? next : next.sublist(next.length - 200);
      await _prefs.setStringList(_prefsKeyFederatedCloudQueue, capped);
    } catch (e) {
      _logger.debug('Failed to enqueue federated delta for cloud: $e',
          tag: _logName);
    }
  }

  Future<void> _syncFederatedCloudQueue() async {
    if (!_isFederatedLearningParticipationEnabled()) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Avoid spamming edge function if multiple triggers happen at once.
    if (nowMs - _lastFederatedCloudSyncAttemptMs < 30 * 1000) return;
    _lastFederatedCloudSyncAttemptMs = nowMs;

    final supabase = SupabaseService();
    if (!supabase.isAvailable) return;
    final user = supabase.currentUser;
    if (user == null) return;

    final list = _prefs.getStringList(_prefsKeyFederatedCloudQueue) ?? const [];
    if (list.isEmpty) return;

    final batch = <Map<String, dynamic>>[];
    final remaining = <String>[];

    // Upload up to 50 entries at a time.
    for (final s in list) {
      if (batch.length >= 50) {
        remaining.add(s);
        continue;
      }
      try {
        final decoded = jsonDecode(s) as Map<String, dynamic>;
        batch.add(decoded);
      } catch (_) {
        // Drop unparseable entries.
      }
    }

    if (batch.isEmpty) {
      await _prefs.setStringList(_prefsKeyFederatedCloudQueue, remaining);
      return;
    }

    try {
      final res = await supabase.client.functions.invoke(
        'federated-sync',
        body: <String, dynamic>{
          'schema_version': 1,
          'source': 'ai2ai_ble',
          'deltas': batch,
        },
      );

      final status = res.status;
      if (status != 200) {
        _logger.debug('Federated sync failed: HTTP $status', tag: _logName);
        return;
      }

      // Optional: apply returned global average deltas as a lightweight "prior"
      // to on-device scoring. This makes the cloud aggregation path real without
      // requiring full model weight updates.
      try {
        final decoded =
            res.data is String ? jsonDecode(res.data as String) : res.data;
        if (decoded is Map) {
          final global = decoded['global_average_deltas'];
          if (global is Map) {
            final priors = <EmbeddingDelta>[];
            for (final entry in global.entries) {
              final category = entry.key?.toString() ?? 'general';
              final value = entry.value;
              if (value is! List) continue;
              final vec = value
                  .whereType<num>()
                  .map((n) => n.toDouble().clamp(-0.35, 0.35))
                  .toList();
              if (vec.isEmpty) continue;
              priors.add(EmbeddingDelta(
                delta: vec,
                timestamp: DateTime.now(),
                category: category,
              ));
            }
            if (priors.isNotEmpty) {
              await OnnxDimensionScorer().updateWithDeltas(priors);
            }
          }
        }
      } catch (e) {
        _logger.debug('Federated priors apply failed (non-blocking): $e',
            tag: _logName);
      }

      // Success: remove the uploaded batch from the queue.
      await _prefs.setStringList(_prefsKeyFederatedCloudQueue, remaining);
    } catch (e) {
      _logger.debug('Federated sync exception: $e', tag: _logName);
    }
  }

  void _loadSeenLearningInsightIds() {
    if (_seenLearningInsightIds.isNotEmpty) return;
    final list =
        _prefs.getStringList(_prefsKeySeenLearningInsightIds) ?? const [];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final item in list) {
      final parts = item.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final expiresAt = int.tryParse(parts[1]) ?? 0;
      if (id.isEmpty || expiresAt <= nowMs) continue;
      _seenLearningInsightIds[id] = expiresAt;
    }
  }

  Future<void> _persistSeenLearningInsightIdsIfNeeded() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastSeenInsightsPersistMs < 15 * 1000) return;
    _lastSeenInsightsPersistMs = nowMs;

    _seenLearningInsightIds.removeWhere((_, exp) => exp <= nowMs);
    final entries = _seenLearningInsightIds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final capped = entries.take(200).toList();
    final list = capped.map((e) => '${e.key}:${e.value}').toList();
    await _prefs.setStringList(_prefsKeySeenLearningInsightIds, list);
  }

  Future<void> _handleIncomingLearningInsight(ProtocolMessage message) async {
    // Respect user setting.
    final learningEnabled =
        _prefs.getBool(_prefsKeyAi2AiLearningEnabled) ?? true;
    if (!learningEnabled) return;

    final userId = _currentUserId;
    final personalityLearning = _connectionManager.personalityLearning;
    if (userId == null || personalityLearning == null) return;

    try {
      final payload = message.payload;
      final schemaVersion = payload['schema_version'] as int?;
      if (schemaVersion != 1) return;

      final insightId = payload['insight_id'] as String?;
      if (insightId == null || insightId.isEmpty) return;

      final createdAtStr = payload['created_at'] as String?;
      final ttlMs = (payload['ttl_ms'] as num?)?.toInt() ?? 0;
      if (createdAtStr == null || ttlMs <= 0 || ttlMs > 6 * 60 * 60 * 1000) {
        // Cap TTL to 6h.
        return;
      }

      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return;
      final expiresAtMs = createdAt.millisecondsSinceEpoch + ttlMs;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (expiresAtMs <= nowMs) return;

      // Dedupe.
      final seenExpiry = _seenLearningInsightIds[insightId];
      if (seenExpiry != null && seenExpiry > nowMs) return;
      _seenLearningInsightIds[insightId] = expiresAtMs;

      final learningQuality =
          (payload['learning_quality'] as num?)?.toDouble() ?? 0.0;
      if (learningQuality < 0.65) return;

      final originId = payload['origin_id'] as String? ?? message.senderId;
      final hop = (payload['hop'] as num?)?.toInt() ?? 0;
      // Validate hop count
      if (hop < 0) return; // Negative hops are invalid

      // Use adaptive mesh service to check hop limit
      if (_adaptiveMeshService != null) {
        if (!_adaptiveMeshService!.shouldForwardMessage(
          currentHop: hop,
          priority: mesh_policy.MessagePriority.medium,
          messageType: mesh_policy.MessageType.learningInsight,
        )) {
          // Adaptive policy says this hop is beyond limit
          return;
        }
      } else {
        // Fallback: limit to 2 hops if adaptive service not available
        if (hop > 2) return;
      }

      final insightsRaw = payload['dimension_insights'];
      if (insightsRaw is! Map) return;
      final deltas = <String, double>{};
      for (final entry in insightsRaw.entries) {
        final k = entry.key;
        final v = entry.value;
        if (k is! String) continue;
        if (!VibeConstants.coreDimensions.contains(k)) continue;
        if (v is! num) continue;
        final dv = v.toDouble();
        if (dv.abs() > 0.35) continue; // hard cap
        deltas[k] = dv;
      }
      if (deltas.isEmpty) return;

      // Throttle per sender.
      final now = DateTime.now();
      final sender = message.senderId;
      final last = _lastAi2AiLearningAtByPeerId[sender];
      if (last != null && now.difference(last) < const Duration(minutes: 20)) {
        return;
      }

      final insight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: deltas,
        learningQuality: learningQuality,
        timestamp: now,
      );

      if (_isEventModeEnabled()) {
        _bufferEventLearningInsight(_EventModeBufferedLearningInsight(
          source: 'inbox',
          insightId: insightId,
          senderDeviceId: sender,
          receivedAt: now,
          learningQuality: learningQuality,
          deltas: deltas,
        ));
        _lastAi2AiLearningAtByPeerId[sender] = now;
        return;
      }

      await personalityLearning.evolveFromAI2AILearning(userId, insight);
      _lastAi2AiLearningAtByPeerId[sender] = now;

      // Phase 11 Enhancement: Integrate with ContinuousLearningSystem
      // KEEP existing personalityLearning call above - this is ADDITIONAL integration
      if (GetIt.instance.isRegistered<ContinuousLearningSystem>()) {
        try {
          final continuousLearningSystem =
              GetIt.instance<ContinuousLearningSystem>();
          unawaited(continuousLearningSystem.processAI2AILearningInsight(
            userId: userId,
            insight: insight,
            peerId: sender,
          ));
        } catch (e) {
          _logger.debug(
            'Failed to process AI2AI learning insight in ContinuousLearningSystem: $e',
            tag: _logName,
          );
          // Non-blocking - don't break existing flow
        }
      }

      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_learning_insight_received',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'insight_id': insightId,
            'sender_device_id': sender,
            'origin_id': originId,
            'hop': hop,
            'schema_version': 1,
            'learning_quality': learningQuality,
            'delta_dimensions_count': deltas.length,
          },
        ));
      }

      // Pattern 1: BLE gossip forwarding (limited-hop) to improve offline propagation.
      unawaited(_maybeForwardLearningInsightGossip(
        payload: payload,
        originId: originId,
        hop: hop,
        receivedFromDeviceId: sender,
      ));
    } catch (e) {
      _logger.debug('Failed to apply incoming learning insight: $e',
          tag: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_learning_insight_receive_failed',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'sender_device_id': message.senderId,
            'error': e.toString(),
          },
        ));
      }
    }
  }

  /// Handle incoming user-to-user chat message routed through AI2AI mesh
  ///
  /// Routes user chat messages (business-expert or business-business) to the
  /// appropriate chat service for storage and UI display. The message type is
  /// determined from the unencrypted binary packet header (MessageType.userChat),
  /// allowing routing before decryption.
  Future<void> _handleIncomingUserChat(ProtocolMessage message) async {
    try {
      final payload = message.payload;

      // Optional: Validate message_category in payload (post-decryption validation/clarity)
      final messageCategory = payload['message_category'] as String?;
      if (messageCategory != null && messageCategory != 'user_chat') {
        _logger.warn(
          'Received userChat message with mismatched category: $messageCategory',
          tag: _logName,
        );
        // Continue anyway - category is optional
      }

      // Determine chat type from payload structure
      // Business-expert chats have: sender_type, business_id, expert_id
      // Business-business chats have: sender_business_id, recipient_business_id
      final hasBusinessExpertFields = payload.containsKey('sender_type') &&
          (payload.containsKey('business_id') ||
              payload.containsKey('expert_id'));
      final hasBusinessBusinessFields =
          payload.containsKey('sender_business_id') &&
              payload.containsKey('recipient_business_id');

      if (hasBusinessExpertFields) {
        await _handleIncomingBusinessExpertChat(message, payload);
      } else if (hasBusinessBusinessFields) {
        await _handleIncomingBusinessBusinessChat(message, payload);
      } else {
        _logger.warn(
          'Received userChat message with unrecognized payload structure: ${payload.keys}',
          tag: _logName,
        );
      }
    } catch (e, st) {
      _logger.error(
        'Error handling incoming user chat message: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Handle incoming business-expert chat message
  Future<void> _handleIncomingBusinessExpertChat(
    ProtocolMessage message,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Extract required fields
      final messageId = payload['message_id'] as String?;
      final conversationId = payload['conversation_id'] as String?;
      final senderTypeStr = payload['sender_type'] as String?;
      final senderId = payload['sender_id'] as String?;
      final recipientTypeStr = payload['recipient_type'] as String?;
      final recipientId = payload['recipient_id'] as String?;
      final content = payload['content'] as String?;
      final encryptedContentStr = payload['encrypted_content'] as String?;
      final encryptionTypeStr = payload['encryption_type'] as String?;
      final messageTypeStr = payload['message_type'] as String?;
      final createdAtStr = payload['created_at'] as String?;

      // Validate required fields
      if (messageId == null ||
          conversationId == null ||
          senderTypeStr == null ||
          senderId == null ||
          recipientTypeStr == null ||
          recipientId == null ||
          content == null ||
          createdAtStr == null) {
        _logger.warn(
          'Received incomplete business-expert chat message: missing required fields',
          tag: _logName,
        );
        return;
      }

      // Parse enums
      final senderType = chat_models.MessageSenderType.values.firstWhere(
        (e) => e.name == senderTypeStr,
        orElse: () => chat_models.MessageSenderType.business,
      );
      final recipientType = chat_models.MessageRecipientType.values.firstWhere(
        (e) => e.name == recipientTypeStr,
        orElse: () => chat_models.MessageRecipientType.expert,
      );
      final encryptionType = EncryptionType.values.firstWhere(
        (e) => e.name == encryptionTypeStr,
        orElse: () => EncryptionType.aes256gcm,
      );
      final messageType = chat_models.MessageType.values.firstWhere(
        (e) => e.name == messageTypeStr,
        orElse: () => chat_models.MessageType.text,
      );

      // Parse encrypted content if present
      Uint8List? encryptedContent;
      if (encryptedContentStr != null && encryptedContentStr.isNotEmpty) {
        try {
          encryptedContent = base64Decode(encryptedContentStr);
        } catch (e) {
          _logger.warn(
            'Failed to decode encrypted content: $e',
            tag: _logName,
          );
        }
      }

      // Parse timestamp
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) {
        _logger.warn(
          'Failed to parse created_at timestamp: $createdAtStr',
          tag: _logName,
        );
        return;
      }

      // Create message object
      final chatMessage = chat_models.BusinessExpertMessage(
        id: messageId,
        conversationId: conversationId,
        senderType: senderType,
        senderId: senderId,
        recipientType: recipientType,
        recipientId: recipientId,
        content: content,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        isRead: false,
        readAt: null,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to Sembast (same store as BusinessExpertChatServiceAI2AI uses)
      final db = await SembastDatabase.database;
      final messagesStore =
          stringMapStoreFactory.store('business_expert_messages');
      await messagesStore.record(messageId).put(db, chatMessage.toJson());

      _logger.debug(
        'Saved incoming business-expert chat message: $messageId',
        tag: _logName,
      );
    } catch (e, st) {
      _logger.error(
        'Error handling incoming business-expert chat: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Handle incoming business-business chat message
  Future<void> _handleIncomingBusinessBusinessChat(
    ProtocolMessage message,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Extract required fields
      final messageId = payload['message_id'] as String?;
      final conversationId = payload['conversation_id'] as String?;
      final senderBusinessId = payload['sender_business_id'] as String?;
      final recipientBusinessId = payload['recipient_business_id'] as String?;
      final content = payload['content'] as String?;
      final encryptedContentStr = payload['encrypted_content'] as String?;
      final encryptionTypeStr = payload['encryption_type'] as String?;
      final messageTypeStr = payload['message_type'] as String?;
      final createdAtStr = payload['created_at'] as String?;

      // Validate required fields
      if (messageId == null ||
          conversationId == null ||
          senderBusinessId == null ||
          recipientBusinessId == null ||
          content == null ||
          createdAtStr == null) {
        _logger.warn(
          'Received incomplete business-business chat message: missing required fields',
          tag: _logName,
        );
        return;
      }

      // Parse enums
      final encryptionType = EncryptionType.values.firstWhere(
        (e) => e.name == encryptionTypeStr,
        orElse: () => EncryptionType.aes256gcm,
      );
      final messageType =
          chat_models.BusinessBusinessMessageType.values.firstWhere(
        (e) => e.name == messageTypeStr,
        orElse: () => chat_models.BusinessBusinessMessageType.text,
      );

      // Parse encrypted content if present
      Uint8List? encryptedContent;
      if (encryptedContentStr != null && encryptedContentStr.isNotEmpty) {
        try {
          encryptedContent = base64Decode(encryptedContentStr);
        } catch (e) {
          _logger.warn(
            'Failed to decode encrypted content: $e',
            tag: _logName,
          );
        }
      }

      // Parse timestamp
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) {
        _logger.warn(
          'Failed to parse created_at timestamp: $createdAtStr',
          tag: _logName,
        );
        return;
      }

      // Create message object
      final chatMessage = chat_models.BusinessBusinessMessage(
        id: messageId,
        conversationId: conversationId,
        senderBusinessId: senderBusinessId,
        recipientBusinessId: recipientBusinessId,
        content: content,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        isRead: false,
        readAt: null,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to Sembast (same store as BusinessBusinessChatServiceAI2AI uses)
      final db = await SembastDatabase.database;
      final messagesStore =
          stringMapStoreFactory.store('business_business_messages');
      await messagesStore.record(messageId).put(db, chatMessage.toJson());

      _logger.debug(
        'Saved incoming business-business chat message: $messageId',
        tag: _logName,
      );
    } catch (e, st) {
      _logger.error(
        'Error handling incoming business-business chat: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _maybeForwardLearningInsightGossip({
    required Map<String, dynamic> payload,
    required String originId,
    required int hop,
    required String receivedFromDeviceId,
  }) async {
    // Forwarding is *optional* federated behavior (distinct from direct AI2AI learning).
    if (!_allowBleSideEffects) return;
    if (!_isFederatedLearningParticipationEnabled()) return;

    // Bloom filter check (BEFORE adaptive hop limits) - AI2AI-specific
    final messageHash =
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    final scope =
        payload['scope'] as String? ?? 'locality'; // Default to locality
    final bloomFilter = _getOrCreateBloomFilter(scope);

    // Check if message might already be in filter (loop prevention)
    if (bloomFilter.mightContain(messageHash)) {
      _logger.debug(
        'Bloom filter: message might be duplicate, skipping forward (scope: $scope)',
        tag: _logName,
      );
      return; // Might be a loop, don't forward
    }

    // Add message to filter
    if (!bloomFilter.add(messageHash)) {
      _logger.debug(
        'Bloom filter full, clearing and retrying (scope: $scope)',
        tag: _logName,
      );
      bloomFilter.clear();
      bloomFilter.add(messageHash);
    }

    // Use adaptive hop limit instead of hardcoded 1-hop limit
    if (_adaptiveMeshService != null) {
      if (!_adaptiveMeshService!.shouldForwardMessage(
        currentHop: hop,
        priority: mesh_policy.MessagePriority.medium,
        messageType: mesh_policy.MessageType.learningInsight,
        geographicScope: scope,
      )) {
        return; // Adaptive policy says don't forward
      }
    } else {
      // Fallback to old behavior if adaptive service not available
      if (hop >= 1) return;
    }

    // Never forward our own-origin updates (it would just amplify duplicates).
    if (originId == _localBleNodeId) return;

    final protocol = _protocol;
    if (protocol == null) return;

    final discovery = _deviceDiscovery;
    if (discovery == null) return;

    // Choose up to 2 nearby devices to forward to (best-effort).
    final candidates = _discoveredNodes.values
        .map((n) => n.nodeId)
        .where((id) => id != receivedFromDeviceId && id != originId)
        .take(2)
        .toList();

    if (candidates.isEmpty) return;

    try {
      final forwardedPayload = Map<String, dynamic>.from(payload);
      forwardedPayload['hop'] = hop + 1;
      forwardedPayload['origin_id'] = originId;

      for (final peerId in candidates) {
        final device = discovery.getDevice(peerId);
        if (device == null) continue;
        if (device.type != DeviceType.bluetooth) continue;

        final recipientId =
            _peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
        final packetBytes = await protocol.encodePacketBytes(
          type: MessageType.learningInsight,
          payload: forwardedPayload,
          senderNodeId: _localBleNodeId,
          recipientNodeId: recipientId,
        );

        // Best-effort ACK-confirmed send.
        await sendBlePacketsBatch(
          device: device,
          senderId: _localBleNodeId,
          packetBytesList: <Uint8List>[packetBytes],
        );
      }
    } catch (e) {
      _logger.debug('Learning insight gossip forward failed: $e',
          tag: _logName);
    }
  }

  // Private helper methods
  Future<void> _startAI2AIDiscovery(
      String userId, PersonalityProfile personality) async {
    _logger.info('Starting AI2AI discovery process', tag: _logName);

    // Start periodic discovery
    _discoveryTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        await discoverNearbyAIPersonalities(userId, personality);
      } catch (e) {
        _logger.error('Error in periodic discovery', error: e, tag: _logName);
      }
    });

    // Perform initial discovery
    await discoverNearbyAIPersonalities(userId, personality,
        throwOnError: true);
  }

  Future<void> _startConnectionMaintenance() async {
    _logger.info('Starting connection maintenance process', tag: _logName);

    _connectionMaintenanceTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await manageActiveConnections();
        // NEW: Manage Signal Protocol session lifecycle (AI2AI-specific)
        await _manageSessionLifecycle();
        // NEW: Manage prekey bundle rotation and refresh (Enhanced BLE distribution)
        await _managePreKeyBundleRotation();
      } catch (e) {
        _logger.error('Error in connection maintenance',
            error: e, tag: _logName);
      }
    });
  }

  /// Manage Signal Protocol session lifecycle for AI2AI connections
  ///
  /// Implements AI2AI-specific session lifecycle management:
  /// - Session expiration based on connection quality
  /// - Automatic cleanup for inactive AI agents
  /// - Session renewal for frequent/active connections
  Future<void> _manageSessionLifecycle() async {
    try {
      // Check if Signal Protocol services are available
      final sl = GetIt.instance;
      if (!sl.isRegistered<SignalSessionManager>()) {
        return; // Signal Protocol not available
      }

      final sessionManager = sl<SignalSessionManager>();

      _logger.debug('Managing Signal Protocol session lifecycle',
          tag: _logName);

      // 1. Check for expired sessions based on connection quality
      await _expireSessionsBasedOnQuality(sessionManager);

      // 2. Clean up inactive sessions (no activity for extended period)
      await _cleanupInactiveSessions(sessionManager);

      // 3. Renew sessions for frequent/active connections
      await _renewActiveSessions(sessionManager);

      // 4. Rotate keys based on connection quality changes (AI2AI-specific)
      await _rotateKeysBasedOnQualityChanges(sessionManager);
    } catch (e, st) {
      _logger.error(
        'Error managing session lifecycle: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Manage prekey bundle rotation and refresh (Enhanced BLE distribution)
  ///
  /// Implements automatic prekey bundle management:
  /// - Cleanup expired prekey bundles
  /// - Proactive refresh of bundles expiring soon
  /// - Distribution of fresh bundles via BLE to active connections
  Future<void> _managePreKeyBundleRotation() async {
    try {
      final signalKeyManager = _signalKeyManager;
      if (signalKeyManager == null) {
        return; // Signal Protocol not available
      }

      // Cleanup expired prekey bundles
      await signalKeyManager.cleanupExpiredPreKeyBundles();

      // Get recipients needing refresh (expiring soon)
      final recipientsNeedingRefresh =
          signalKeyManager.getRecipientsNeedingRefresh();

      // Proactively refresh bundles for active connections
      for (final recipientId in recipientsNeedingRefresh) {
        // Check if recipient has an active connection
        final hasActiveConnection = _activeConnections.values.any(
          (connection) =>
              connection.remoteAISignature == recipientId &&
              (connection.status == ConnectionStatus.active ||
                  connection.status == ConnectionStatus.learning),
        );

        if (hasActiveConnection) {
          _logger.debug(
            'Proactively refreshing prekey bundle for active connection: $recipientId',
            tag: _logName,
          );

          // Background refresh (non-blocking)
          unawaited(
            signalKeyManager.fetchPreKeyBundle(recipientId).then((bundle) {
              _logger.debug(
                'Successfully refreshed prekey bundle for recipient: $recipientId',
                tag: _logName,
              );
              return bundle;
            }).catchError((e) {
              _logger.warn(
                'Failed to refresh prekey bundle for $recipientId: $e',
                tag: _logName,
              );
              // Return a dummy bundle to satisfy type checker (won't be used)
              return SignalPreKeyBundle(
                preKeyId: 'error',
                signedPreKey: Uint8List(0),
                signedPreKeyId: 0,
                signature: Uint8List(0),
                identityKey: Uint8List(0),
                kyberPreKeyId: 0,
                kyberPreKey: Uint8List(0),
                kyberPreKeySignature: Uint8List(0),
              );
            }),
          );
        }
      }

      // Note: Prekey bundle distribution via BLE is handled by PersonalityAdvertisingService
      // (advertising side serves bundles on stream 1). We just manage refresh/rotation here.
    } catch (e, st) {
      _logger.error(
        'Error managing prekey bundle rotation: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Expire sessions based on connection quality (AI2AI-specific)
  ///
  /// Uses SignalSessionManager's quality-based methods to expire sessions
  /// for connections with poor quality.
  Future<void> _expireSessionsBasedOnQuality(
      SignalSessionManager sessionManager) async {
    try {
      // Build map of agent ID to ConnectionMetrics for active connections
      final metricsByAgentId = <String, ConnectionMetrics>{};
      for (final connection in _activeConnections.values) {
        // Skip if connection is not active
        if (connection.status != ConnectionStatus.active &&
            connection.status != ConnectionStatus.learning) {
          continue;
        }

        metricsByAgentId[connection.remoteAISignature] = connection;
      }

      // Get sessions to close using SignalSessionManager's quality-based method
      final sessionsToClose =
          sessionManager.getSessionsToClose(metricsByAgentId);

      // Close sessions and complete connections
      for (final agentId in sessionsToClose) {
        final connection = _activeConnections.values.firstWhere(
          (c) => c.remoteAISignature == agentId,
          orElse: () => throw StateError('Connection not found for agent'),
        );

        _logger.info(
          'Expiring session for agent $agentId due to poor connection quality',
          tag: _logName,
        );

        // Delete the session
        await sessionManager.deleteSession(agentId);

        // Mark connection for completion
        _activeConnections.remove(connection.connectionId);
        await _completeConnection(
          connection,
          reason: 'poor_connection_quality',
        );
      }
    } catch (e, st) {
      _logger.error(
        'Error expiring sessions based on quality: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Clean up inactive sessions (no activity for extended period)
  ///
  /// Sessions are cleaned up if they haven't been used for a certain period
  /// and don't have an active connection. High-quality connections are maintained
  /// even if temporarily inactive.
  Future<void> _cleanupInactiveSessions(
      SignalSessionManager sessionManager) async {
    try {
      const inactivityThreshold = Duration(hours: 24); // 24 hours of inactivity
      final now = DateTime.now();

      // Build map of agent ID to ConnectionMetrics for active connections
      final metricsByAgentId = <String, ConnectionMetrics>{};
      for (final connection in _activeConnections.values) {
        if (connection.status == ConnectionStatus.active ||
            connection.status == ConnectionStatus.learning) {
          metricsByAgentId[connection.remoteAISignature] = connection;
        }
      }

      // Get sessions that should be maintained (high-quality connections)
      final sessionsToMaintain =
          sessionManager.getSessionsToMaintain(metricsByAgentId);
      final maintainedSet = sessionsToMaintain.toSet();

      // Get all sessions from SignalSessionManager
      // Note: SignalSessionManager doesn't have a method to list all sessions,
      // so we track sessions through active connections and discovered nodes

      // Check sessions for active connections
      final activeAgentIds =
          _activeConnections.values.map((c) => c.remoteAISignature).toSet();

      // Also check discovered nodes (may have sessions)
      final discoveredAgentIds = _discoveredNodes.values
          .map((n) => n.nodeId)
          .where((id) => id.isNotEmpty)
          .toSet();

      // Combine all potential agent IDs that might have sessions
      final allAgentIds = {...activeAgentIds, ...discoveredAgentIds};

      // Check each potential session
      for (final agentId in allAgentIds) {
        // Skip if this agent has an active connection
        final hasActiveConnection = _activeConnections.values.any(
          (c) =>
              c.remoteAISignature == agentId &&
              (c.status == ConnectionStatus.active ||
                  c.status == ConnectionStatus.learning),
        );

        if (hasActiveConnection) {
          continue; // Active connection, don't clean up
        }

        // Skip if session should be maintained (high-quality)
        if (maintainedSet.contains(agentId)) {
          _logger.debug(
            'Skipping cleanup for maintained session (high-quality): $agentId',
            tag: _logName,
          );
          continue; // High-quality session, maintain it
        }

        final session = await sessionManager.getSession(agentId);
        if (session == null) {
          continue; // No session to clean up
        }

        // Check last activity time
        final lastActivity = session.lastUsedAt ?? session.createdAt;
        final timeSinceActivity = now.difference(lastActivity);

        if (timeSinceActivity >= inactivityThreshold) {
          _logger.info(
            'Cleaning up inactive session for agent $agentId: inactive for ${timeSinceActivity.inHours}h',
            tag: _logName,
          );

          // Delete the inactive session
          await sessionManager.deleteSession(agentId);
        }
      }
    } catch (e, st) {
      _logger.error(
        'Error cleaning up inactive sessions: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Renew sessions for frequent/active connections
  ///
  /// Uses SignalSessionManager's quality-based methods to renew sessions
  /// for high-quality, active connections.
  Future<void> _renewActiveSessions(SignalSessionManager sessionManager) async {
    try {
      // Build map of agent ID to ConnectionMetrics for active connections
      final metricsByAgentId = <String, ConnectionMetrics>{};
      for (final connection in _activeConnections.values) {
        // Skip if connection is not active
        if (connection.status != ConnectionStatus.active &&
            connection.status != ConnectionStatus.learning) {
          continue;
        }

        metricsByAgentId[connection.remoteAISignature] = connection;
      }

      // Get sessions to renew using SignalSessionManager's quality-based method
      final sessionsToRenew =
          await sessionManager.getSessionsToRenew(metricsByAgentId);

      // Renew sessions
      for (final agentId in sessionsToRenew) {
        _logger.info(
          'Renewing session for agent $agentId based on connection quality',
          tag: _logName,
        );

        // Trigger re-keying by checking needsRekeying and marking as rekeyed
        // The actual re-keying will happen on next message send/receive
        if (await sessionManager.needsRekeying(agentId)) {
          // Mark as rekeyed (will trigger actual re-keying on next use)
          await sessionManager.markRekeyed(agentId);

          _logger.debug(
            'Session renewal triggered for agent $agentId',
            tag: _logName,
          );
        }
      }
    } catch (e, st) {
      _logger.error(
        'Error renewing active sessions: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Rotate keys based on connection quality changes (AI2AI-specific)
  ///
  /// Implements automatic key rotation triggered by significant connection quality changes.
  /// Rotates keys when quality improves significantly (fresh keys for high-value connections)
  /// or degrades significantly (security rotation for compromised connections).
  ///
  /// **AI2AI-Specific:**
  /// - Rotation triggered by quality change threshold (30%)
  /// - Integrates with Signal Protocol re-keying
  /// - Prevents excessive rotation (cooldown period)
  Future<void> _rotateKeysBasedOnQualityChanges(
    SignalSessionManager sessionManager,
  ) async {
    try {
      final sl = GetIt.instance;
      final signalProtocolService = sl.isRegistered<SignalProtocolService>()
          ? sl<SignalProtocolService>()
          : null;

      if (signalProtocolService == null) {
        return; // Signal Protocol not available
      }

      // Track quality changes for active connections
      for (final connection in _activeConnections.values) {
        if (connection.status != ConnectionStatus.active &&
            connection.status != ConnectionStatus.learning) {
          continue; // Skip inactive connections
        }

        final agentId = connection.remoteAISignature;
        final currentQuality = connection.qualityScore;
        final previousQuality = _previousQualityScores[agentId];

        // Initialize previous quality if not tracked
        if (previousQuality == null) {
          _previousQualityScores[agentId] = currentQuality;
          continue; // First time tracking, no change to detect
        }

        // Calculate quality change
        final qualityChange = (currentQuality - previousQuality).abs();

        // Check if quality change exceeds threshold
        if (qualityChange >= _qualityChangeThreshold) {
          _logger.info(
            'Significant quality change detected for agent $agentId: '
            '${previousQuality.toStringAsFixed(2)} → ${currentQuality.toStringAsFixed(2)} '
            '(change: ${(qualityChange * 100).toStringAsFixed(1)}%)',
            tag: _logName,
          );

          // Check if session exists
          final session = await sessionManager.getSession(agentId);
          if (session != null) {
            // Trigger key rotation by marking session as needing re-keying
            // This will cause re-keying on next message send/receive
            _logger.info(
              'Triggering key rotation for agent $agentId due to quality change',
              tag: _logName,
            );

            // Force re-keying by resetting re-keying timestamp
            // This ensures re-keying happens on next message
            await sessionManager.markRekeyed(agentId);

            // Also trigger immediate re-keying by checking needsRekeying
            // and performing re-keying if needed
            if (await sessionManager.needsRekeying(agentId)) {
              // Perform re-keying immediately (for quality-based rotation)
              // Re-keying will happen automatically on next encryptMessage/decryptMessage
              // We've already marked it as needing re-keying above
              _logger.debug(
                'Key rotation triggered for agent $agentId (quality change: ${(qualityChange * 100).toStringAsFixed(1)}%)',
                tag: _logName,
              );
            }
          }

          // Update previous quality score
          _previousQualityScores[agentId] = currentQuality;
        }
      }

      // Clean up quality scores for inactive connections
      final activeAgentIds = _activeConnections.values
          .where((c) =>
              c.status == ConnectionStatus.active ||
              c.status == ConnectionStatus.learning)
          .map((c) => c.remoteAISignature)
          .toSet();

      _previousQualityScores.removeWhere(
        (agentId, _) => !activeAgentIds.contains(agentId),
      );
    } catch (e, st) {
      _logger.error(
        'Error rotating keys based on quality changes: $e',
        tag: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Check if device has active connectivity
  bool _isConnected(List<ConnectivityResult> result) {
    return result
        .any((connectivity) => connectivity != ConnectivityResult.none);
  }

  Future<List<AIPersonalityNode>> _performAI2AIDiscovery(
      AnonymizedVibeData localVibe) async {
    // Phase 6: Use physical layer device discovery if available
    if (_deviceDiscovery != null) {
      try {
        _logger.info('Using physical layer device discovery', tag: _logName);

        // Get discovered devices from physical layer
        final devices = _deviceDiscovery!.getDiscoveredDevices();

        // Convert discovered devices to AI personality nodes
        final nodes = <AIPersonalityNode>[];
        for (final device in devices) {
          // Prefer a single BLE "lease" per device (no interleaving) so we can:
          // read vibe (stream 0), read prekey (stream 1), and send bootstrap in one session.
          AnonymizedVibeData? personalityData = device.personalityData;
          BleGattSession? session;
          if (_allowBleSideEffects && device.type == DeviceType.bluetooth) {
            try {
              session = await BleConnectionPool.instance.openSession(
                device: device,
              );

              if (personalityData == null) {
                final vibeBytes =
                    await session.readStreamPayload(streamId: 0); // vibe stream
                if (vibeBytes != null && vibeBytes.isNotEmpty) {
                  final jsonString = utf8.decode(vibeBytes);
                  personalityData =
                      PersonalityDataCodec.decodeFromJson(jsonString);
                }
              }

              // Prime Signal prekeys + send silent bootstrap under the same lease.
              await _primeOfflineSignalPreKeyBundleInSession(
                device: device,
                session: session,
              );
            } catch (e) {
              // If session acquisition fails, fall back to legacy per-call behavior.
              _logger.warn('BLE session failed for ${device.deviceId}: $e',
                  tag: _logName);
            } finally {
              try {
                await session?.close();
              } catch (_) {
                // Ignore.
              }
            }
          }

          // Fallback: original extraction path (may do its own BLE read).
          personalityData ??=
              await _deviceDiscovery!.extractPersonalityData(device);
          if (personalityData == null) {
            // Even if we couldn't build a node, we may still have primed prekeys above.
            continue;
          }

          // Create vibe from anonymized data
          final vibe = _createVibeFromAnonymizedData(personalityData);

          // Calculate trust score based on proximity and signal strength
          final proximityScore = _deviceDiscovery!.calculateProximity(device);
          final trustScore =
              proximityScore * 0.7 + 0.3; // Base trust + proximity

          final node = AIPersonalityNode(
            nodeId: device.deviceId,
            vibe: vibe,
            lastSeen: device.discoveredAt,
            trustScore: trustScore,
            learningHistory: {},
          );

          nodes.add(node);
        }

        if (nodes.isNotEmpty) {
          _logger.info(
              'Discovered ${nodes.length} AI personalities via physical layer',
              tag: _logName);
          return nodes;
        }
      } catch (e) {
        _logger.error('Error in physical layer discovery: $e', tag: _logName);
        // Fall through to realtime discovery
      }
    }

    // Fallback to realtime discovery (Supabase Realtime)
    // This is the existing implementation
    if (_realtimeService != null) {
      try {
        _logger.info('Using realtime discovery', tag: _logName);
        // Realtime discovery would happen here
        // For now, return empty list if physical layer fails
        return [];
      } catch (e) {
        _logger.error('Error in realtime discovery: $e', tag: _logName);
      }
    }

    // Final fallback: return empty list
    _logger.warn('No discovery method available, returning empty list',
        tag: _logName);
    return [];
  }

  Future<void> _primeOfflineSignalPreKeyBundleInSession({
    required DiscoveredDevice device,
    required BleGattSession session,
  }) async {
    if (!_allowBleSideEffects) return;
    final signalKeyManager = _signalKeyManager;
    final protocol = _protocol;
    if (signalKeyManager == null || protocol == null) return;

    try {
      // Stream 1 = Signal prekey payload.
      final bytes = await session.readStreamPayload(streamId: 1);
      if (bytes == null || bytes.isEmpty) return;

      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final peerNodeId = decoded['node_id'] as String?;
      final bundleJson = decoded['prekey_bundle'] as Map<String, dynamic>?;
      if (bundleJson == null) return;

      final bundle = SignalPreKeyBundle.fromJson(bundleJson);
      final recipientId = (peerNodeId != null && peerNodeId.isNotEmpty)
          ? peerNodeId
          : device.deviceId;
      if (peerNodeId != null && peerNodeId.isNotEmpty) {
        _peerNodeIdByDeviceId[device.deviceId] = peerNodeId;
      }

      // Phase 3.2: Enhanced offline-first prekey bundle exchange
      // Check if bundle needs refresh (automatic refresh logic)
      final needsRefresh = signalKeyManager.getRecipientsNeedingRefresh().contains(recipientId);
      
      if (needsRefresh) {
        _logger.debug(
          'Prekey bundle for $recipientId needs refresh - attempting background refresh',
          tag: _logName,
        );
        
        // Background refresh (non-blocking) - try to fetch fresh bundle from Supabase
        unawaited(
          signalKeyManager.fetchPreKeyBundle(recipientId).then((freshBundle) {
            _logger.debug(
              'Successfully refreshed prekey bundle for recipient: $recipientId',
              tag: _logName,
            );
            // Fresh bundle is automatically cached by fetchPreKeyBundle
          }).catchError((e) {
            _logger.debug(
              'Background refresh failed for $recipientId, using BLE bundle: $e',
              tag: _logName,
            );
            // Continue with BLE bundle if refresh fails
          }),
        );
      }

      // Validate and cache prekey bundle (with automatic validation)
      // This validates PQXDH requirements, signatures, expiration, etc.
      await signalKeyManager.cacheRemotePreKeyBundle(
        recipientId: recipientId,
        preKeyBundle: bundle,
      );

      _logger.debug(
        'Cached and validated prekey bundle for recipient: $recipientId (PQXDH enabled)',
        tag: _logName,
      );

      // Phase 3.2: Mesh forwarding integration
      // Forward prekey bundle through mesh network if mesh service is available
      if (_adaptiveMeshService != null && _isFederatedLearningParticipationEnabled()) {
        await _forwardPreKeyBundleThroughMesh(
          bundle: bundle,
          recipientId: recipientId,
          device: device,
        );
      }

      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_signal_prekey_cached_from_peer',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'device_id': device.deviceId,
            'peer_node_id': peerNodeId ?? '',
            'recipient_id': recipientId,
            'stream_id': 1,
            'bytes_len': bytes.length,
          },
        ));
      }

      // Send a tiny encrypted message to force the receiver to establish
      // a Signal session by decrypting a PreKey message (Mode 2).
      final packetBytes = await protocol.encodePacketBytes(
        type: MessageType.heartbeat,
        payload: <String, dynamic>{
          't': DateTime.now().toUtc().toIso8601String(),
          'kind': 'silent_signal_bootstrap',
        },
        senderNodeId: _localBleNodeId,
        recipientNodeId: recipientId,
      );

      final results = await session.sendPacketsBatch(
        senderId: _localBleNodeId,
        packetBytesList: <Uint8List>[packetBytes],
      );
      final ok = results.isNotEmpty && results.first;
      if (ok) {
        _logger.debug(
          'Sent silent Signal bootstrap packet (session) to ${device.deviceId}',
          tag: _logName,
        );
      }
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_silent_bootstrap_sent',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'ok': ok,
            'device_id': device.deviceId,
            'recipient_id': recipientId,
            'message_type': 'heartbeat',
            'kind': 'silent_signal_bootstrap',
          },
        ));
      }
    } catch (e) {
      _logger.warn('Failed to prime offline Signal in session: $e',
          tag: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.deviceCapability,
          eventType: 'ai2ai_offline_signal_prime_failed',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'device_id': device.deviceId,
            'error': e.toString(),
          },
        ));
      }
    }
  }

  /// Forward prekey bundle through mesh network (Phase 3.2: Mesh forwarding integration)
  ///
  /// Forwards prekey bundle to nearby devices for multi-hop key exchange.
  /// This enables key exchange even without direct connection.
  Future<void> _forwardPreKeyBundleThroughMesh({
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required DiscoveredDevice device,
  }) async {
    if (!_allowBleSideEffects || _deviceDiscovery == null || _protocol == null) {
      return;
    }

    try {
      // Only forward if mesh service says we should
      if (_adaptiveMeshService == null) {
        return;
      }

      // Check if mesh forwarding is allowed (1-hop limit for prekey bundles)
      if (!_adaptiveMeshService!.shouldForwardMessage(
        currentHop: 0,
        priority: mesh_policy.MessagePriority.high,
        messageType: mesh_policy.MessageType.learningInsight, // Reuse type
        geographicScope: 'locality', // Prekey bundles are locality-scoped
      )) {
        return;
      }

      // Choose up to 2 nearby devices to forward to (best-effort)
      final candidates = _discoveredNodes.values
          .map((n) => n.nodeId)
          .where((id) => id != recipientId && id != _localBleNodeId)
          .take(2)
          .toList();

      if (candidates.isEmpty) {
        return;
      }

      // Create prekey bundle message for forwarding
      final bundleJson = bundle.toJson();
      final forwardPayload = <String, dynamic>{
        'kind': 'prekey_bundle_forward',
        'recipient_id': recipientId,
        'prekey_bundle': bundleJson,
        'hop': 1, // Starting at hop 1 (we received it at hop 0)
        'origin_id': recipientId,
        'scope': 'locality', // Prekey bundles are locality-scoped
      };

      // Forward to candidates
      for (final peerId in candidates) {
        final peerDevice = _deviceDiscovery!.getDevice(peerId);
        if (peerDevice == null || peerDevice.type != DeviceType.bluetooth) {
          continue;
        }

        final peerRecipientId = _peerNodeIdByDeviceId[peerDevice.deviceId] ?? peerDevice.deviceId;

        try {
          final packetBytes = await _protocol!.encodePacketBytes(
            type: MessageType.learningInsight, // Reuse learning insight type for prekey forwarding
            payload: forwardPayload,
            senderNodeId: _localBleNodeId,
            recipientNodeId: peerRecipientId,
            geographicScope: 'locality',
          );

          // Best-effort send (don't block)
          unawaited(
            sendBlePacketsBatch(
              device: peerDevice,
              senderId: _localBleNodeId,
              packetBytesList: <Uint8List>[packetBytes],
            ),
          );

          _logger.debug(
            'Forwarded prekey bundle through mesh: $recipientId → $peerRecipientId',
            tag: _logName,
          );
        } catch (e) {
          _logger.debug(
            'Failed to forward prekey bundle to $peerRecipientId: $e',
            tag: _logName,
          );
        }
      }
    } catch (e) {
      _logger.debug(
        'Error forwarding prekey bundle through mesh: $e',
        tag: _logName,
      );
    }
  }

  /// Create UserVibe from AnonymizedVibeData
  UserVibe _createVibeFromAnonymizedData(AnonymizedVibeData anonymizedData) {
    // Extract metrics from anonymized data
    final metrics = anonymizedData.anonymizedMetrics;

    // Create UserVibe using anonymized dimensions and metrics
    return UserVibe(
      hashedSignature: anonymizedData.vibeSignature,
      anonymizedDimensions: anonymizedData.noisyDimensions,
      overallEnergy: metrics.energy,
      socialPreference: metrics.social,
      explorationTendency: metrics.exploration,
      createdAt: anonymizedData.createdAt,
      expiresAt: anonymizedData.expiresAt,
      privacyLevel: anonymizedData.anonymizationQuality,
      temporalContext: anonymizedData.temporalContextHash,
    );
  }

  void _updateDiscoveredNodes(List<AIPersonalityNode> nodes) {
    for (final node in nodes) {
      _discoveredNodes[node.nodeId] = node;
      // Update adaptive mesh service with network density
      _adaptiveMeshService?.updateNetworkDensity(_discoveredNodes.length);
      _nearbyVibes[node.nodeId] = node.vibe;
    }

    // Clean up old discovered nodes (older than 10 minutes)
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    final expiredNodes = _discoveredNodes.entries
        .where((entry) => entry.value.lastSeen.isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();

    for (final nodeId in expiredNodes) {
      _discoveredNodes.remove(nodeId);
      // Update adaptive mesh service with network density
      _adaptiveMeshService?.updateNetworkDensity(_discoveredNodes.length);
      _nearbyVibes.remove(nodeId);
    }
  }

  /// Analyze compatibility for all discovered nodes
  Future<Map<String, VibeCompatibilityResult>> _analyzeNodeCompatibility(
    UserVibe localVibe,
    List<AIPersonalityNode> nodes,
  ) async {
    final compatibilityResults = <String, VibeCompatibilityResult>{};

    for (final node in nodes) {
      final compatibility = await _vibeAnalyzer.analyzeVibeCompatibility(
        localVibe,
        node.vibe,
      );
      compatibilityResults[node.nodeId] = compatibility;
    }

    // #region agent log
    _logger.debug('Analyzed compatibility for ${nodes.length} nodes',
        tag: _logName);
    // #endregion

    return compatibilityResults;
  }

  /// Prioritize discovered nodes based on compatibility and trust
  /// Note: DiscoveryManager already handles prioritization, this is reserved for future use
  // ignore: unused_element
  Future<List<AIPersonalityNode>> _prioritizeConnections(
    List<AIPersonalityNode> nodes,
    Map<String, VibeCompatibilityResult> compatibilityResults,
  ) async {
    // Sort nodes by connection priority
    nodes.sort((a, b) {
      final aResult = compatibilityResults[a.nodeId];
      final bResult = compatibilityResults[b.nodeId];

      if (aResult == null || bResult == null) return 0;

      final aPriority = _calculateConnectionPriority(aResult, a.trustScore);
      final bPriority = _calculateConnectionPriority(bResult, b.trustScore);

      return bPriority.compareTo(aPriority); // Descending order
    });

    final prioritized =
        nodes.take(5).toList(); // Return top 5 prioritized nodes

    // #region agent log
    _logger.debug(
        'Prioritized ${nodes.length} nodes to top ${prioritized.length} connections',
        tag: _logName);
    // #endregion

    return prioritized;
  }

  double _calculateConnectionPriority(
      VibeCompatibilityResult compatibility, double trustScore) {
    return (compatibility.basicCompatibility * 0.4) +
        (compatibility.aiPleasurePotential * 0.3) +
        (compatibility.learningOpportunities.length / 8.0 * 0.2) +
        (trustScore * 0.1);
  }

  bool _isInCooldown(String nodeId) {
    final cooldownEnd = _connectionCooldowns[nodeId];
    if (cooldownEnd == null) return false;

    return DateTime.now().isBefore(cooldownEnd);
  }

  void _setCooldown(String nodeId) {
    _connectionCooldowns[nodeId] = DateTime.now()
        .add(const Duration(seconds: VibeConstants.connectionCooldownSeconds));
  }

  /// Determine if a connection is worthy based on compatibility thresholds
  bool _isConnectionWorthy(VibeCompatibilityResult compatibility) {
    final isWorthy = compatibility.basicCompatibility >=
            VibeConstants.minimumCompatibilityThreshold &&
        compatibility.aiPleasurePotential >= VibeConstants.minAIPleasureScore &&
        compatibility.learningOpportunities.isNotEmpty;

    // #region agent log
    if (!isWorthy) {
      _logger.debug(
          'Connection not worthy: compat=${(compatibility.basicCompatibility * 100).round()}% (min=${(VibeConstants.minimumCompatibilityThreshold * 100).round()}%), pleasure=${(compatibility.aiPleasurePotential * 100).round()}% (min=${(VibeConstants.minAIPleasureScore * 100).round()}%), opportunities=${compatibility.learningOpportunities.length}',
          tag: _logName);
    }
    // #endregion

    return isWorthy;
  }

  Future<ConnectionMetrics?> _performConnectionEstablishment(
    UserVibe localVibe,
    AIPersonalityNode remoteNode,
    VibeCompatibilityResult compatibility,
    ConnectionMetrics initialMetrics,
    String localAgentId,
    String remoteAgentId,
  ) async {
    try {
      // Use protocol to encode initial connection message if available
      if (_protocol != null) {
        try {
          // Encode connection establishment message via protocol
          final connectionMessage = await _protocol!.encodeMessage(
            type: MessageType.connectionRequest,
            payload: {
              'local_vibe_archetype': localVibe.getVibeArchetype(),
              'remote_vibe_archetype': remoteNode.vibe.getVibeArchetype(),
              'initial_compatibility': compatibility.basicCompatibility,
              'connection_id': initialMetrics.connectionId,
            },
            senderNodeId: initialMetrics.localAISignature,
            recipientNodeId: remoteNode.nodeId,
          );
          // #region agent log
          _logger.debug(
              'Encoded connection message via protocol: type=${connectionMessage.type.name}, sender=${connectionMessage.senderId}',
              tag: _logName);
          // #endregion
        } catch (e) {
          // #region agent log
          _logger.warn(
              'Error encoding protocol message: $e, continuing without protocol',
              tag: _logName);
          // #endregion
        }
      }

      // Simulate connection establishment process
      await Future.delayed(const Duration(milliseconds: 200));

      // Create initial interaction event
      final initialInteraction = InteractionEvent.success(
        type: InteractionType.vibeExchange,
        data: {
          'local_vibe_archetype': localVibe.getVibeArchetype(),
          'remote_vibe_archetype': remoteNode.vibe.getVibeArchetype(),
          'initial_compatibility': compatibility.basicCompatibility,
        },
      );

      // Phase 2: Create braided knot for connection
      BraidedKnot? braidedKnot;
      if (_knotWeavingService != null && _knotStorageService != null) {
        try {
          // Get personality knots for both agents
          final localKnot = await _knotStorageService!.loadKnot(localAgentId);
          final remoteKnot = await _knotStorageService!.loadKnot(remoteAgentId);

          if (localKnot != null && remoteKnot != null) {
            // Create braided knot (default to friendship relationship type)
            braidedKnot = await _knotWeavingService!.weaveKnots(
              knotA: localKnot,
              knotB: remoteKnot,
              relationshipType: RelationshipType.friendship,
            );

            // Store braided knot
            await _knotStorageService!.saveBraidedKnot(
              connectionId: initialMetrics.connectionId,
              braidedKnot: braidedKnot,
            );

            // #region agent log
            _logger.info(
              'Braided knot created for connection: ${initialMetrics.connectionId}',
              tag: _logName,
            );
            // #endregion
          } else {
            // #region agent log
            _logger.debug(
              'Knots not available for braiding (local: ${localKnot != null}, remote: ${remoteKnot != null})',
              tag: _logName,
            );
            // #endregion
          }
        } catch (e) {
          // #region agent log
          _logger.warn(
            'Error creating braided knot: $e, continuing without braided knot',
            tag: _logName,
          );
          // #endregion
          // Continue without braided knot - connection can still be established
        }
      }

      // Extract handshake hash for channel binding (if Signal Protocol session exists)
      Uint8List? handshakeHash;
      String? localAgentFingerprint;
      String? remoteAgentFingerprint;

      try {
        final sl = GetIt.instance;
        final signalKeyManager = _signalKeyManager;

        // Generate local agent fingerprint (from our identity key)
        if (signalKeyManager != null) {
          try {
            final localIdentityKeyPair =
                await signalKeyManager.getOrGenerateIdentityKeyPair();
            final localFingerprint =
                AIAgentFingerprintService.generateFingerprintFromKeyPair(
                    localIdentityKeyPair);
            localAgentFingerprint = localFingerprint.hexString;

            _logger.debug(
              'Generated local AI agent fingerprint: ${localFingerprint.displayFormat.substring(0, 20)}...',
              tag: _logName,
            );
          } catch (e) {
            _logger.debug(
              'Failed to generate local fingerprint: $e',
              tag: _logName,
            );
          }

          // Generate remote agent fingerprint (from remote prekey bundle)
          try {
            final remotePreKeyBundle =
                await signalKeyManager.fetchPreKeyBundle(remoteAgentId);
            final remoteFingerprint =
                AIAgentFingerprintService.generateFingerprintFromBundle(
                    remotePreKeyBundle);
            remoteAgentFingerprint = remoteFingerprint.hexString;

            _logger.debug(
              'Generated remote AI agent fingerprint: ${remoteFingerprint.displayFormat.substring(0, 20)}...',
              tag: _logName,
            );
          } catch (e) {
            _logger.debug(
              'Failed to generate remote fingerprint: $e (will be set on first message)',
              tag: _logName,
            );
          }
        }

        // Extract channel binding hash
        if (sl.isRegistered<SignalSessionManager>()) {
          final sessionManager = sl<SignalSessionManager>();
          handshakeHash =
              await sessionManager.getChannelBindingHash(remoteAgentId);

          if (handshakeHash != null) {
            _logger.debug(
              'Channel binding hash extracted for connection: ${initialMetrics.connectionId}',
              tag: _logName,
            );
          }
        }
      } catch (e) {
        // Non-fatal: continue without fingerprints/hash
        _logger.debug(
          'Failed to extract fingerprints/channel binding hash: $e (will be set on first message)',
          tag: _logName,
        );
      }

      // Update connection with initial interaction, fingerprints, and channel binding hash
      final updatedMetrics = initialMetrics.updateDuringInteraction(
        newInteraction: initialInteraction,
        additionalOutcomes: {
          'successful_exchanges': 1,
          if (braidedKnot != null) 'braided_knot_id': braidedKnot.id,
        },
        handshakeHash: handshakeHash,
        localAgentFingerprint: localAgentFingerprint,
        remoteAgentFingerprint: remoteAgentFingerprint,
      );

      return updatedMetrics;
    } catch (e) {
      // #region agent log
      _logger.error('Error in connection establishment',
          error: e, tag: _logName);
      // #endregion
      return null;
    }
  }

  /// Get current battery level (for rate limiting integration)
  ///
  /// Returns battery level (0-100) or null if battery scheduler not available.
  Future<int?> getBatteryLevel() async {
    if (_batteryScheduler != null) {
      try {
        return await _batteryScheduler!.getBatteryLevel();
      } catch (e) {
        _logger.debug(
          'Failed to get battery level: $e',
          tag: _logName,
        );
        return null;
      }
    }
    return null;
  }

  /// Get current network density (for rate limiting integration)
  ///
  /// Returns network density or null if adaptive mesh service not available.
  int? getNetworkDensity() {
    return _adaptiveMeshService?.networkDensity;
  }

  void _scheduleConnectionManagement(ConnectionMetrics connection) {
    // Connection-specific management would be handled by the main maintenance timer
    _logger.debug(
        'Scheduled management for connection: ${connection.connectionId}',
        tag: _logName);
  }

  Future<ConnectionMetrics?> _completeConnection(ConnectionMetrics connection,
      {String? reason}) async {
    try {
      _logger.info('Completing AI2AI connection: ${connection.connectionId}',
          tag: _logName);

      final completedConnection = connection.complete(
        finalStatus: ConnectionStatus.completed,
        completionReason: reason ?? 'natural_completion',
      );

      // Log connection summary
      final summary = completedConnection.getSummary();
      _logger.info('Connection completed: $summary', tag: _logName);

      return completedConnection;
    } catch (e) {
      _logger.error('Error completing connection', error: e, tag: _logName);
      return null;
    }
  }

  Future<void> _updateConnectionLearning(ConnectionMetrics connection) async {
    // Simulate learning interactions
    if (connection.interactionHistory.length < 10) {
      final learningInteraction = InteractionEvent.success(
        type: InteractionType.learningInsight,
        data: {
          'insight_type': 'dimension_evolution',
          'learning_quality': 0.8,
        },
      );

      _activeConnections[connection.connectionId] =
          connection.updateDuringInteraction(
        newInteraction: learningInteraction,
        learningEffectiveness: 0.7,
        additionalOutcomes: {
          'successful_exchanges': 1,
          'insights_gained': 1,
        },
      );
    }
  }

  Future<void> _monitorConnectionHealth(ConnectionMetrics connection) async {
    // Monitor connection health and update AI pleasure score
    final currentPleasure = await calculateAIPleasureScore(connection);

    _activeConnections[connection.connectionId] =
        connection.updateDuringInteraction(
      aiPleasureScore: currentPleasure,
    );
  }

  /// Get current user vibe for AI2AI matching (stub; can be wired to cache)
  UserVibe? getCurrentVibe() {
    return null;
  }

  /// Convert UnifiedUser to AnonymousUser for AI2AI transmission
  ///
  /// **CRITICAL:** This method ensures no personal data is transmitted in AI2AI network.
  /// All user data must be converted to AnonymousUser before transmission.
  ///
  /// **Throws:**
  /// - Exception if anonymizationService is not available
  /// - Exception if conversion fails
  Future<AnonymousUser> anonymizeUserForTransmission(
    UnifiedUser user,
    String agentId,
    PersonalityProfile? personalityProfile, {
    bool isAdmin = false,
  }) async {
    if (_anonymizationService == null) {
      throw Exception(
          'UserAnonymizationService not available. Cannot anonymize user for transmission.');
    }

    _logger.info(
        'Anonymizing user for AI2AI transmission: ${user.id} -> $agentId',
        tag: _logName);

    try {
      final anonymousUser = await _anonymizationService!.anonymizeUser(
        user,
        agentId,
        personalityProfile,
        isAdmin: isAdmin,
      );

      _logger.info('User anonymized successfully for transmission',
          tag: _logName);
      return anonymousUser;
    } catch (e) {
      _logger.error('Failed to anonymize user for transmission',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Validate that no UnifiedUser is being sent directly in AI2AI network
  ///
  /// This is a safety check to prevent accidental personal data leaks.
  /// All user data must be converted to AnonymousUser before transmission.
  void validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    // Check for common UnifiedUser fields that should never appear in AI2AI payloads
    final forbiddenFields = [
      'id',
      'email',
      'displayName',
      'photoUrl',
      'userId'
    ];

    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw Exception(
            'CRITICAL: UnifiedUser field "$field" detected in AI2AI payload. '
            'All user data must be converted to AnonymousUser before transmission. '
            'Use anonymizeUserForTransmission() method.');
      }
    }

    // Recursively check nested objects
    for (final value in payload.values) {
      if (value is Map<String, dynamic>) {
        validateNoUnifiedUserInPayload(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            validateNoUnifiedUserInPayload(item);
          }
        }
      }
    }
  }

  /// Set up realtime listeners for AI2AI communication (safe no-op if unavailable)
  Future<void> _setupRealtimeListeners() async {
    final coordinator = _realtimeCoordinator;
    if (coordinator == null) return;
    try {
      coordinator.setup(
        onPersonality: (message) {
          // #region agent log
          _logger.debug(
              'Received personality discovery message: ${message.type}, nodeId: ${message.metadata['node_id']}',
              tag: _logName);
          // #endregion
          // Handle personality discovery messages - update discovered nodes cache
          // In production, would process message and update _discoveredNodes
          if (message.metadata.containsKey('node_id')) {
            // Would create AIPersonalityNode from message metadata
            // _updateDiscoveredNodes([nodeFromMessage]);
          }
        },
        onLearning: (message) {
          // #region agent log
          _logger.debug(
              'Received vibe learning message: ${message.type}, dimensions: ${message.metadata['dimension_updates']?.keys.length ?? 0}',
              tag: _logName);
          // #endregion
          // Handle vibe learning messages - update active connections with learning insights
          // In production, would process learning insights and update connection metrics
          if (message.metadata.containsKey('dimension_updates')) {
            // Would update active connections with new learning data
          }
        },
        onAnonymous: (message) {
          // #region agent log
          _logger.debug(
              'Received anonymous communication message: ${message.type}, payload_size: ${message.metadata.length}',
              tag: _logName);
          // #endregion
          // Handle anonymous communication messages - process AI2AI network messages
          // In production, would process anonymous messages and route to appropriate handlers
          // Would validate payload doesn't contain UnifiedUser data
          validateNoUnifiedUserInPayload(message.metadata);
        },
      );
      // #region agent log
      _logger.debug('Realtime listeners setup with active subscriptions',
          tag: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      _logger.warn('Failed to setup realtime listeners: $e', tag: _logName);
      // #endregion
    }
  }

  /// NEW: Forward locality agent update through mesh network
  Future<void> forwardLocalityAgentUpdate(Map<String, dynamic> message) async {
    if (!_allowBleSideEffects) return;
    if (!_isFederatedLearningParticipationEnabled()) return;

    final protocol = _protocol;
    if (protocol == null) return;

    final discovery = _deviceDiscovery;
    if (discovery == null) return;

    final hop = (message['hop'] as num?)?.toInt() ?? 0;
    final originId =
        message['origin_id'] as String? ?? message['agent_id'] as String?;

    // Bloom filter check (BEFORE adaptive hop limits) - AI2AI-specific
    final messageHash =
        sha256.convert(utf8.encode(jsonEncode(message))).toString();
    final scope =
        message['scope'] as String? ?? 'locality'; // Default to locality
    final bloomFilter = _getOrCreateBloomFilter(scope);

    // Check if message might already be in filter (loop prevention)
    if (bloomFilter.mightContain(messageHash)) {
      _logger.debug(
        'Bloom filter: locality agent update might be duplicate, skipping forward (scope: $scope)',
        tag: _logName,
      );
      return; // Might be a loop, don't forward
    }

    // Add message to filter
    if (!bloomFilter.add(messageHash)) {
      _logger.debug(
        'Bloom filter full, clearing and retrying (scope: $scope)',
        tag: _logName,
      );
      bloomFilter.clear();
      bloomFilter.add(messageHash);
    }

    // Use adaptive mesh service to check hop limit (AFTER Bloom filter check)
    if (_adaptiveMeshService != null) {
      if (!_adaptiveMeshService!.shouldForwardMessage(
        currentHop: hop,
        priority: mesh_policy.MessagePriority.high,
        messageType: mesh_policy.MessageType.localityAgentUpdate,
        geographicScope: scope,
      )) {
        return; // Adaptive policy says don't forward
      }
    }

    // Never forward our own-origin updates
    if (originId == _localBleNodeId) return;

    // Choose up to 2 nearby devices to forward to (best-effort)
    final candidates = _discoveredNodes.values
        .map((n) => n.nodeId)
        .where((id) => id != originId)
        .take(2)
        .toList();

    if (candidates.isEmpty) return;

    try {
      final forwardedMessage = Map<String, dynamic>.from(message);
      forwardedMessage['hop'] = hop + 1;
      forwardedMessage['origin_id'] = originId;

      for (final peerId in candidates) {
        final device = discovery.getDevice(peerId);
        if (device == null) continue;
        if (device.type != DeviceType.bluetooth) continue;

        final recipientId =
            _peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
        final packetBytes = await protocol.encodePacketBytes(
          type: MessageType
              .learningInsight, // Reuse learning insight type for now
          payload: forwardedMessage,
          senderNodeId: _localBleNodeId,
          recipientNodeId: recipientId,
        );

        // Best-effort ACK-confirmed send
        await sendBlePacketsBatch(
          device: device,
          senderId: _localBleNodeId,
          packetBytesList: <Uint8List>[packetBytes],
        );
      }

      _logger.debug('Forwarded locality agent update through mesh',
          tag: _logName);
    } catch (e) {
      _logger.debug('Locality agent update forward failed: $e', tag: _logName);
    }
  }

  /// NEW: Handle incoming locality agent update from mesh
  Future<void> _handleIncomingLocalityAgentUpdate(
      ProtocolMessage message) async {
    try {
      final payload = message.payload;
      final type = payload['type'] as String?;
      if (type != 'locality_agent_update') return;

      final keyStr = payload['key'] as String?;
      final geohashPrefix = payload['geohash_prefix'] as String?;
      final precision = (payload['precision'] as num?)?.toInt() ?? 7;
      final cityCode = payload['city_code'] as String?;
      final delta12Raw = payload['delta12'] as List?;
      final hop = (payload['hop'] as num?)?.toInt() ?? 0;

      if (keyStr == null || geohashPrefix == null || delta12Raw == null) return;

      // Validate hop count
      if (hop < 0) return;

      // Use adaptive mesh service to check hop limit
      final scope = payload['scope'] as String?;
      if (_adaptiveMeshService != null) {
        if (!_adaptiveMeshService!.shouldForwardMessage(
          currentHop: hop,
          priority: mesh_policy.MessagePriority.high,
          messageType: mesh_policy.MessageType.localityAgentUpdate,
          geographicScope: scope,
        )) {
          return; // Adaptive policy says this hop is beyond limit
        }
      }

      // Parse delta12
      final delta12 = delta12Raw
          .map((e) => (e as num).toDouble())
          .where((v) => v.abs() <= 0.35) // Hard cap like learning insights
          .toList();

      if (delta12.length != 12) return;

      // Create locality agent key
      final key = LocalityAgentKeyV1(
        geohashPrefix: geohashPrefix,
        precision: precision,
        cityCode: cityCode,
      );

      // Store mesh update in cache for neighbor smoothing
      final sl = GetIt.instance;
      if (sl.isRegistered<LocalityAgentMeshCache>()) {
        try {
          final meshCache = sl<LocalityAgentMeshCache>();
          final ttlMs = (payload['ttl_ms'] as num?)?.toInt() ??
              (6 * 60 * 60 * 1000); // Default 6 hours
          await meshCache.storeMeshUpdate(
            key: key,
            delta12: delta12,
            receivedAt: DateTime.now(),
            ttl: Duration(milliseconds: ttlMs),
          );
          _logger.debug(
            'Stored locality agent mesh update: ${key.stableKey} (hop=$hop)',
            tag: _logName,
          );
        } catch (e) {
          _logger.debug(
            'Failed to store mesh update in cache: $e',
            tag: _logName,
          );
        }
      }

      _logger.debug(
        'Received locality agent update: ${key.stableKey} (hop=$hop)',
        tag: _logName,
      );

      // Forward through mesh if within limits
      await _maybeForwardLocalityAgentUpdateGossip(
        payload: payload,
        originId: payload['origin_id'] as String? ?? message.senderId,
        hop: hop,
        receivedFromDeviceId: message.senderId,
      );
    } catch (e, st) {
      _logger.error(
        'Failed to handle incoming locality agent update: $e',
        error: e,
        stackTrace: st,
        tag: _logName,
      );
    }
  }

  /// NEW: Forward locality agent update gossip (similar to learning insight gossip)
  Future<void> _maybeForwardLocalityAgentUpdateGossip({
    required Map<String, dynamic> payload,
    required String originId,
    required int hop,
    required String receivedFromDeviceId,
  }) async {
    // Forwarding is *optional* federated behavior
    if (!_allowBleSideEffects) return;
    if (!_isFederatedLearningParticipationEnabled()) return;

    // Bloom filter check (BEFORE adaptive hop limits) - AI2AI-specific
    final messageHash =
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    final scope =
        payload['scope'] as String? ?? 'locality'; // Default to locality
    final bloomFilter = _getOrCreateBloomFilter(scope);

    // Check if message might already be in filter (loop prevention)
    if (bloomFilter.mightContain(messageHash)) {
      _logger.debug(
        'Bloom filter: locality agent update might be duplicate, skipping forward (scope: $scope)',
        tag: _logName,
      );
      return; // Might be a loop, don't forward
    }

    // Add message to filter
    if (!bloomFilter.add(messageHash)) {
      _logger.debug(
        'Bloom filter full, clearing and retrying (scope: $scope)',
        tag: _logName,
      );
      bloomFilter.clear();
      bloomFilter.add(messageHash);
    }

    // Use adaptive hop limit
    if (_adaptiveMeshService != null) {
      if (!_adaptiveMeshService!.shouldForwardMessage(
        currentHop: hop,
        priority: mesh_policy.MessagePriority.high,
        messageType: mesh_policy.MessageType.localityAgentUpdate,
        geographicScope: scope,
      )) {
        return; // Adaptive policy says don't forward
      }
    } else {
      // Fallback: limit to 2 hops if adaptive service not available
      if (hop >= 2) return;
    }

    // Never forward our own-origin updates
    if (originId == _localBleNodeId) return;

    final protocol = _protocol;
    if (protocol == null) return;

    final discovery = _deviceDiscovery;
    if (discovery == null) return;

    // Choose up to 2 nearby devices to forward to (best-effort)
    final candidates = _discoveredNodes.values
        .map((n) => n.nodeId)
        .where((id) => id != receivedFromDeviceId && id != originId)
        .take(2)
        .toList();

    if (candidates.isEmpty) return;

    try {
      final forwardedPayload = Map<String, dynamic>.from(payload);
      forwardedPayload['hop'] = hop + 1;
      forwardedPayload['origin_id'] = originId;

      for (final peerId in candidates) {
        final device = discovery.getDevice(peerId);
        if (device == null) continue;
        if (device.type != DeviceType.bluetooth) continue;

        final recipientId =
            _peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
        final packetBytes = await protocol.encodePacketBytes(
          type: MessageType.learningInsight, // Reuse learning insight type
          payload: forwardedPayload,
          senderNodeId: _localBleNodeId,
          recipientNodeId: recipientId,
        );

        // Best-effort ACK-confirmed send
        await sendBlePacketsBatch(
          device: device,
          senderId: _localBleNodeId,
          packetBytesList: <Uint8List>[packetBytes],
        );
      }
    } catch (e) {
      _logger.debug('Locality agent update gossip forward failed: $e',
          tag: _logName);
    }
  }

  /// Get or create Bloom filter for geographic scope (AI2AI-specific)
  OptimizedBloomFilter _getOrCreateBloomFilter(String scope) {
    return _bloomFilters.putIfAbsent(
      scope,
      () => OptimizedBloomFilter(geographicScope: scope),
    );
  }
}

// Supporting classes for AI2AI connection orchestration
// moved to core/ai2ai/aipersonality_node.dart

class PendingConnection {
  final String localUserId;
  final AIPersonalityNode remoteNode;
  final VibeCompatibilityResult compatibility;
  final DateTime requestedAt;

  PendingConnection({
    required this.localUserId,
    required this.remoteNode,
    required this.compatibility,
    required this.requestedAt,
  });

  bool get isExpired => DateTime.now().difference(requestedAt).inMinutes > 2;
}

class ConnectionSummary {
  final String connectionId;
  final Duration duration;
  final double compatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;
  final String qualityRating;
  final ConnectionStatus status;
  final int interactionCount;
  final int dimensionsEvolved;

  ConnectionSummary({
    required this.connectionId,
    required this.duration,
    required this.compatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
    required this.qualityRating,
    required this.status,
    required this.interactionCount,
    required this.dimensionsEvolved,
  });

  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionId.substring(0, 8),
      'duration_seconds': duration.inSeconds,
      'compatibility': (compatibility * 100).round(),
      'learning_effectiveness': (learningEffectiveness * 100).round(),
      'ai_pleasure_score': (aiPleasureScore * 100).round(),
      'quality_rating': qualityRating,
      'status': status.toString().split('.').last,
      'interaction_count': interactionCount,
      'dimensions_evolved': dimensionsEvolved,
    };
  }
}

class AI2AIConnectionException implements Exception {
  final String message;

  AI2AIConnectionException(this.message);

  @override
  String toString() => 'AI2AIConnectionException: $message';
}
