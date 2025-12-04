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
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
          return result != ConnectivityResult.none;
    } catch (e) {
      developer.log('Basic connectivity check failed: $e', name: _logName);
      return false;
    }
  }
  
  /// Check if device has actual internet access (with HTTP ping)
  /// Uses cached result if recent ping was successful
  Future<bool> hasInternetAccess({bool forceRefresh = false}) async {
    // Check basic connectivity first (fast check)
    final hasBasic = await hasBasicConnectivity();
    if (!hasBasic) {
      developer.log('No basic connectivity', name: _logName);
      return false;
    }
    
    // Use cached result if available and not expired
    if (!forceRefresh && _lastPingResult != null && _lastPingTime != null) {
      final age = DateTime.now().difference(_lastPingTime!);
      if (age < _cacheTimeout) {
        developer.log('Using cached ping result: $_lastPingResult (age: ${age.inSeconds}s)', name: _logName);
        return _lastPingResult!;
      }
    }
    
    // Perform HTTP ping
    final pingResult = await _pingEndpoint();
    _lastPingTime = DateTime.now();
    _lastPingResult = pingResult;
    
    return pingResult;
  }
  
  /// Ping a reliable endpoint to verify internet access
  Future<bool> _pingEndpoint() async {
    try {
      developer.log('Pinging $_pingUrl...', name: _logName);
      
      final response = await _httpClient
          .head(Uri.parse(_pingUrl))
          .timeout(_pingTimeout);
      
      final success = response.statusCode >= 200 && response.statusCode < 500;
      developer.log('Ping result: $success (status: ${response.statusCode})', name: _logName);
      
      return success;
    } catch (e) {
      developer.log('Ping failed: $e', name: _logName);
      return false;
    }
  }
  
  /// Stream of connectivity changes (basic connectivity only)
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return !result.contains(ConnectivityResult.none);
          return result != ConnectivityResult.none;
    });
  }
  
  /// Stream of internet access changes (with periodic pings)
  /// Emits true/false as internet access changes
  /// 
  /// [checkInterval] - How often to verify internet access (default: 30s)
  Stream<bool> internetAccessStream({Duration checkInterval = const Duration(seconds: 30)}) async* {
    // Initial check
    yield await hasInternetAccess();
    
    // Periodic checks
    await for (final _ in Stream.periodic(checkInterval)) {
      yield await hasInternetAccess(forceRefresh: true);
    }
  }
  
  /// Get detailed connectivity status
  Future<ConnectivityStatus> getDetailedStatus() async {
    final basic = await hasBasicConnectivity();
    final internet = basic ? await hasInternetAccess() : false;
    
    final result = await _connectivity.checkConnectivity();
    final connectionType = result is List 
        ? (result.isNotEmpty ? result.first : ConnectivityResult.none)
        : result as ConnectivityResult;
    
    return ConnectivityStatus(
      hasBasicConnectivity: basic,
      hasInternetAccess: internet,
      connectionType: connectionType,
      lastChecked: DateTime.now(),
    );
  }
  
  /// Clear ping cache
  void clearCache() {
    _lastPingTime = null;
    _lastPingResult = null;
    developer.log('Cleared ping cache', name: _logName);
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
      default:
        return 'Unknown';
    }
  }
  
  @override
  String toString() {
    return 'ConnectivityStatus(status: $statusString, type: $connectionTypeString, checked: $lastChecked)';
  }
}

