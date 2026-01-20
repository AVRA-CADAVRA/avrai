// AVRA Network Library
// Backend abstraction layer for flexible data persistence

// Core interfaces
export 'interfaces/backend_interface.dart';
export 'interfaces/auth_backend.dart';
export 'interfaces/data_backend.dart';
export 'interfaces/realtime_backend.dart';

// Backend factory
export 'backend_factory.dart';

// HTTP client
export 'clients/api_client.dart';
export 'clients/http_client.dart';

// Error handling
export 'errors/network_errors.dart';
export 'errors/backend_errors.dart';

// Models
export 'models/api_response.dart';
export 'models/connection_config.dart';
export 'models/sync_status.dart';

// Utils
export 'utils/connectivity_manager.dart';
export 'utils/request_builder.dart';
export 'utils/response_parser.dart';

// Network services - Device Discovery
export 'network/ble_connection_pool.dart';
export 'network/ble_foreground_service.dart';
export 'network/ble_inbox.dart';
export 'network/ble_message_sender.dart';
export 'network/ble_peripheral.dart';
export 'network/device_discovery.dart';
export 'network/device_discovery_factory.dart';
// NOTE:
// Platform-specific implementations (io/android/ios/web/stub) are intentionally
// NOT exported from this barrel because:
// - Some implementations are platform-specific and will not compile everywhere.
// - Some implementations define overlapping top-level symbols (e.g. create*()),
//   which can cause duplicate export errors.
//
// Consumers should depend on `DeviceDiscoveryService` + DI, and tests can import
// the platform files directly if needed.

// Network services - Personality Advertising
export 'network/personality_advertising_service.dart';
export 'network/personality_data_codec.dart';

// Network services - Configuration
export 'network/webrtc_signaling_config.dart';

// Network services - AI2AI Protocol
export 'network/ai2ai_protocol.dart';
export 'network/ai2ai_protocol_signal_integration.dart';

// Network services - Rate Limiting (BitChat-inspired, AI2AI-enhanced)
export 'network/rate_limiter.dart';

// Network services - Encryption
export 'network/message_encryption_service.dart';

// Network models
export 'network/models/anonymized_vibe_data.dart';
