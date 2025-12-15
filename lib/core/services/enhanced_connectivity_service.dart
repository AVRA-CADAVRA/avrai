import 'dart:developer' as developer;
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Enhanced connectivity service with HTTP ping for true internet verification
/// 
/// Optional Enhancement: Goes beyond basic WiFi/mobile connectivity
/// to verify actual internet access by pinging a reliable endpoint
class EnhancedConnectivityService {
  static const String _logName = 'EnhancedConnectivityService';
  static const String _pingUrl = 'https://www.google.com';
  static const Duration _pingTimeout = Duration(seconds: 5);
  static const Duration _cacheTimeout = Duration(seconds: 30);
  
  final Connectivity _connectivity;
  final http.Client _httpClient;
  
  // Cache for ping results
  DateTime? _lastPingTime;
  bool? _lastPingResult;
  
  EnhancedConnectivityService({
    Connectivity? connectivity,
    http.Client? httpClient,
  }) : _connectivity = connectivity ?? Connectivity(),
       _httpClient = httpClient ?? http.Client();
  
  /// Check if device has basic connectivity (WiFi/Mobile)
  Future<bool> hasBasicConnectivity() async {
    try {
      // #region agent log
      developer.log('Checking basic connectivity', name: _logName);
      // #endregion
      
      final result = await _connectivity.checkConnectivity();
      final hasConnectivity = !result.contains(ConnectivityResult.none);
      
      // #region agent log
      developer.log('Basic connectivity result: $hasConnectivity, types: ${result.map((r) => r.name).join(", ")}', name: _logName);
      // #endregion
      
      return hasConnectivity;
    } catch (e) {
      // #region agent log
      developer.log('Basic connectivity check failed: $e', name: _logName);
      // #endregion
      return false;
    }
  }
  
  /// Check if device has actual internet access (with HTTP ping)
  /// Uses cached result if recent ping was successful
  Future<bool> hasInternetAccess({bool forceRefresh = false}) async {
    // #region agent log
    developer.log('Checking internet access: forceRefresh=$forceRefresh', name: _logName);
    // #endregion
    
    // Check basic connectivity first (fast check)
    final hasBasic = await hasBasicConnectivity();
    if (!hasBasic) {
      // #region agent log
      developer.log('No basic connectivity, skipping internet check', name: _logName);
      // #endregion
      return false;
    }
    
    // Use cached result if available and not expired
    if (!forceRefresh && _lastPingResult != null && _lastPingTime != null) {
      final age = DateTime.now().difference(_lastPingTime!);
      if (age < _cacheTimeout) {
        // #region agent log
        developer.log('Using cached ping result: $_lastPingResult (age: ${age.inSeconds}s, cacheTimeout: ${_cacheTimeout.inSeconds}s)', name: _logName);
        // #endregion
        return _lastPingResult!;
      } else {
        // #region agent log
        developer.log('Cache expired (age: ${age.inSeconds}s >= ${_cacheTimeout.inSeconds}s), performing new ping', name: _logName);
        // #endregion
      }
    }
    
    // Perform HTTP ping
    final pingResult = await _pingEndpoint();
    _lastPingTime = DateTime.now();
    _lastPingResult = pingResult;
    
    // #region agent log
    developer.log('Internet access check complete: $pingResult, cached for ${_cacheTimeout.inSeconds}s', name: _logName);
    // #endregion
    
    return pingResult;
  }
  
  /// Ping a reliable endpoint to verify internet access
  Future<bool> _pingEndpoint() async {
    try {
      // #region agent log
      developer.log('Pinging $_pingUrl with timeout: ${_pingTimeout.inSeconds}s', name: _logName);
      // #endregion
      
      final startTime = DateTime.now();
      final response = await _httpClient
          .head(Uri.parse(_pingUrl))
          .timeout(_pingTimeout);
      
      final duration = DateTime.now().difference(startTime);
      final success = response.statusCode >= 200 && response.statusCode < 500;
      
      // #region agent log
      developer.log('Ping result: $success (status: ${response.statusCode}, duration: ${duration.inMilliseconds}ms)', name: _logName);
      // #endregion
      
      return success;
    } catch (e) {
      // #region agent log
      developer.log('Ping failed: $e', name: _logName);
      // #endregion
      return false;
    }
  }
  
  /// Stream of connectivity changes (basic connectivity only)
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      final hasConnectivity = !result.contains(ConnectivityResult.none);
      
      // #region agent log
      developer.log('Connectivity changed: $hasConnectivity, types: ${result.map((r) => r.name).join(", ")}', name: _logName);
      // #endregion
      
      return hasConnectivity;
    });
  }
  
  /// Stream of internet access changes (with periodic pings)
  /// Emits true/false as internet access changes
  /// 
  /// [checkInterval] - How often to verify internet access (default: 30s)
  Stream<bool> internetAccessStream({Duration checkInterval = const Duration(seconds: 30)}) async* {
    // #region agent log
    developer.log('Starting internet access stream: checkInterval=${checkInterval.inSeconds}s', name: _logName);
    // #endregion
    
    // Initial check
    final initialResult = await hasInternetAccess();
    // #region agent log
    developer.log('Initial internet access check: $initialResult', name: _logName);
    // #endregion
    yield initialResult;
    
    // Periodic checks
    await for (final _ in Stream.periodic(checkInterval)) {
      final periodicResult = await hasInternetAccess(forceRefresh: true);
      // #region agent log
      developer.log('Periodic internet access check: $periodicResult', name: _logName);
      // #endregion
      yield periodicResult;
    }
  }
  
  /// Get detailed connectivity status
  Future<ConnectivityStatus> getDetailedStatus() async {
    // #region agent log
    developer.log('Getting detailed connectivity status', name: _logName);
    // #endregion
    
    final basic = await hasBasicConnectivity();
    final internet = basic ? await hasInternetAccess() : false;
    
    final result = await _connectivity.checkConnectivity();
    // checkConnectivity() always returns List<ConnectivityResult>
    final connectionType = result.isNotEmpty 
        ? result.first 
        : ConnectivityResult.none;
    
    final status = ConnectivityStatus(
      hasBasicConnectivity: basic,
      hasInternetAccess: internet,
      connectionType: connectionType,
      lastChecked: DateTime.now(),
    );
    
    // #region agent log
    developer.log('Detailed status: ${status.statusString}, type: ${status.connectionTypeString}, fullyOnline: ${status.isFullyOnline}', name: _logName);
    // #endregion
    
    return status;
  }
  
  /// Clear ping cache
  void clearCache() {
    // #region agent log
    developer.log('Clearing ping cache (lastResult: $_lastPingResult, lastTime: $_lastPingTime)', name: _logName);
    // #endregion
    
    _lastPingTime = null;
    _lastPingResult = null;
    
    // #region agent log
    developer.log('Ping cache cleared', name: _logName);
    // #endregion
  }
  
  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Detailed connectivity status
class ConnectivityStatus {
  final bool hasBasicConnectivity;
  final bool hasInternetAccess;
  final ConnectivityResult connectionType;
  final DateTime lastChecked;
  
  ConnectivityStatus({
    required this.hasBasicConnectivity,
    required this.hasInternetAccess,
    required this.connectionType,
    required this.lastChecked,
  });
  
  /// Whether the device is fully online (basic + internet)
  bool get isFullyOnline => hasBasicConnectivity && hasInternetAccess;
  
  /// Whether the device appears online but may not have internet
  bool get isLimitedConnectivity => hasBasicConnectivity && !hasInternetAccess;
  
  /// Whether the device is completely offline
  bool get isOffline => !hasBasicConnectivity;
  
  /// Human-readable status string
  String get statusString {
    if (isFullyOnline) return 'Online';
    if (isLimitedConnectivity) return 'Limited Connectivity';
    return 'Offline';
  }
  
  /// Connection type as string
  String get connectionTypeString {
    switch (connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'None';
    }
  }
  
  @override
  String toString() {
    return 'ConnectivityStatus(status: $statusString, type: $connectionTypeString, checked: $lastChecked)';
  }
}

