import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// This file is only imported when dart.library.html is available (web platform)
// Conditional import ensures this code is never analyzed on mobile platforms
// Note: dart:html is deprecated but still needed for WebSocket and window APIs
// TODO: Migrate to package:web and dart:js_interop when stable
import 'dart:html' as html show window, WebSocket;
// Note: flutter_nsd may not be fully supported on web
// Using conditional imports would be ideal, but for now we'll use dynamic typing
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/network/webrtc_signaling_config.dart';
import 'package:spots/core/network/personality_data_codec.dart';

/// Web-specific device discovery implementation
/// Uses WebRTC peer discovery and WebSocket fallback for device discovery
class WebDeviceDiscovery extends DeviceDiscoveryPlatform {
  static const String _logName = 'WebDeviceDiscovery';
  
  // WebRTC signaling server configuration
  final WebRTCSignalingConfig _signalingConfig;
  
  WebDeviceDiscovery({WebRTCSignalingConfig? signalingConfig}) 
      : _signalingConfig = signalingConfig ?? WebRTCSignalingConfig();
  
  @override
  bool isSupported() {
    return kIsWeb;
  }
  
  @override
  Future<bool> requestPermissions() async {
    try {
      developer.log('Requesting Web device discovery permissions', name: _logName);
      
      // Web doesn't require explicit permissions for WebRTC/WebSocket
      // However, HTTPS is required for WebRTC to work
      
      // Check if we're on HTTPS
      final isSecure = _isSecureContext();
      
      if (!isSecure) {
        developer.log('WebRTC requires HTTPS context', name: _logName);
        return false;
      }
      
      developer.log('Web permissions OK (HTTPS context)', name: _logName);
      return true;
    } catch (e) {
      developer.log('Error checking Web permissions: $e', name: _logName);
      return false;
    }
  }
  
  @override
  Future<List<DiscoveredDevice>> scanForDevices() async {
    if (!isSupported()) {
      developer.log('Web discovery not supported on this platform', name: _logName);
      return [];
    }
    
    try {
      developer.log('Scanning for devices on Web', name: _logName);
      
      final devices = <DiscoveredDevice>[];
      
      // Scan using Network Service Discovery (mDNS) if available
      try {
        final nsdDevices = await _scanNetworkServiceDiscovery();
        devices.addAll(nsdDevices);
        developer.log('Found ${nsdDevices.length} NSD devices', name: _logName);
      } catch (e) {
        developer.log('Error scanning NSD: $e', name: _logName);
      }
      
      // Scan using WebRTC peer discovery (if signaling server configured)
      if (_signalingConfig.isConfigured()) {
        try {
          final webrtcDevices = await _scanWebRTC();
          devices.addAll(webrtcDevices);
          developer.log('Found ${webrtcDevices.length} WebRTC devices', name: _logName);
        } catch (e) {
          developer.log('Error scanning WebRTC: $e', name: _logName);
        }
      }
      
      // Scan using WebSocket fallback (if signaling server configured)
      if (_signalingConfig.isConfigured()) {
        try {
          final websocketDevices = await _scanWebSocket();
          devices.addAll(websocketDevices);
          developer.log('Found ${websocketDevices.length} WebSocket devices', name: _logName);
        } catch (e) {
          developer.log('Error scanning WebSocket: $e', name: _logName);
        }
      }
      
      developer.log('Total devices discovered: ${devices.length}', name: _logName);
      return devices;
    } catch (e) {
      developer.log('Error scanning for Web devices: $e', name: _logName);
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      // Get Web browser information
      // This could include:
      // - User agent
      // - Browser capabilities
      // - WebRTC support
      // - WebSocket support
      
      return {
        'platform': 'web',
        'supported': isSupported(),
        'is_secure_context': _isSecureContext(),
        'user_agent': _getUserAgent(),
        'note': 'Device info collection requires browser API access',
      };
    } catch (e) {
      developer.log('Error getting Web device info: $e', name: _logName);
      return {'platform': 'web', 'error': e.toString()};
    }
  }
  
  /// Check if we're in a secure context (HTTPS)
  bool _isSecureContext() {
    try {
      // Check if we're in a secure context (HTTPS)
      return html.window.isSecureContext ?? false;
    } catch (e) {
      developer.log('Error checking secure context: $e', name: _logName);
      // Fallback: check if URL is HTTPS
      try {
        return html.window.location.protocol == 'https:';
      } catch (_) {
        return false;
      }
    }
  }
  
  /// Get user agent string
  String _getUserAgent() {
    try {
      // userAgent is non-nullable in dart:html, but wrap in try-catch for safety
      return html.window.navigator.userAgent;
    } catch (e) {
      developer.log('Error getting user agent: $e', name: _logName);
      return 'Unknown Browser';
    }
  }
  
  /// Scan using Network Service Discovery (mDNS) on Web
  Future<List<DiscoveredDevice>> _scanNetworkServiceDiscovery() async {
    final devices = <DiscoveredDevice>[];
    
    try {
      // Note: mDNS/Bonjour on Web is limited
      // Most browsers don't support mDNS directly
      // This would require a browser extension or server-side proxy
      // For now, skip mDNS discovery on Web and rely on WebRTC/WebSocket
      developer.log('mDNS discovery not available on Web platform - using WebRTC/WebSocket instead', name: _logName);
      // Return empty list - WebRTC/WebSocket discovery will be used instead
      return devices;
    } catch (e) {
      developer.log('Error in NSD scan: $e', name: _logName);
      return devices;
    }
  }
  
  /// Scan using WebRTC peer discovery
  Future<List<DiscoveredDevice>> _scanWebRTC() async {
    final devices = <DiscoveredDevice>[];
    
    final signalingUrl = _signalingConfig.getSignalingServerUrl();
    if (signalingUrl.isEmpty) {
      developer.log('No signaling server URL configured', name: _logName);
      return [];
    }
    
    try {
      // Connect to signaling server via WebSocket
      final ws = html.WebSocket(signalingUrl);
      
      // Wait for connection
      await ws.onOpen.first;
      
      // Register this device and request peer list
      ws.sendString(html.window.btoa(
        '{"type": "discover", "device_id": "${_generateDeviceId()}"}',
      ));
      
      // Listen for peer list response
      final completer = Completer<List<DiscoveredDevice>>();
      final timer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(devices);
        }
      });
      
      ws.onMessage.listen((event) {
        try {
          final data = html.window.atob(event.data as String);
          final json = jsonDecode(data) as Map<String, dynamic>;
          
          if (json['type'] == 'peers') {
            final peers = json['peers'] as List;
            for (final peer in peers) {
              final peerData = peer as Map<String, dynamic>;
              
              if (peerData['spots_enabled'] == true) {
                final personalityData = _extractPersonalityFromPeer(peerData);
                
                devices.add(DiscoveredDevice(
                  deviceId: peerData['device_id'] as String,
                  deviceName: peerData['device_name'] as String? ?? 'SPOTS Device',
                  type: DeviceType.webrtc,
                  isSpotsEnabled: true,
                  personalityData: personalityData,
                  discoveredAt: DateTime.now(),
                  metadata: {
                    'peer_connection_id': peerData['peer_id'] as String?,
                    'signaling_server': signalingUrl,
                  },
                ));
              }
            }
            
            if (!completer.isCompleted) {
              timer.cancel();
              completer.complete(devices);
            }
          }
        } catch (e) {
          developer.log('Error parsing WebRTC message: $e', name: _logName);
        }
      });
      
      ws.onError.listen((error) {
        developer.log('WebSocket error: $error', name: _logName);
        if (!completer.isCompleted) {
          timer.cancel();
          completer.complete(devices);
        }
      });
      
      await completer.future;
      ws.close();
      
    } catch (e) {
      developer.log('Error in WebRTC scan: $e', name: _logName);
    }
    
    return devices;
  }
  
  /// Scan using WebSocket fallback
  Future<List<DiscoveredDevice>> _scanWebSocket() async {
    final devices = <DiscoveredDevice>[];
    
    final signalingUrl = _signalingConfig.getSignalingServerUrl();
    if (signalingUrl.isEmpty) {
      return [];
    }
    
    try {
      // Use same signaling server but simpler protocol
      final ws = html.WebSocket(signalingUrl);
      await ws.onOpen.first;
      
      // Request device list
      ws.sendString(html.window.btoa('{"action": "discover"}'));
      
      final completer = Completer<List<DiscoveredDevice>>();
      final timer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete(devices);
        }
      });
      
      ws.onMessage.listen((event) {
        try {
          final data = html.window.atob(event.data as String);
          final json = jsonDecode(data) as Map<String, dynamic>;
          
          if (json['action'] == 'devices') {
            final deviceList = json['devices'] as List;
            for (final deviceData in deviceList) {
              final d = deviceData as Map<String, dynamic>;
              
              devices.add(DiscoveredDevice(
                deviceId: d['id'] as String,
                deviceName: d['name'] as String? ?? 'SPOTS Device',
                type: DeviceType.webrtc,
                isSpotsEnabled: d['spots_enabled'] == true,
                discoveredAt: DateTime.now(),
                metadata: d,
              ));
            }
            
            if (!completer.isCompleted) {
              timer.cancel();
              completer.complete(devices);
            }
          }
        } catch (e) {
          developer.log('Error parsing WebSocket message: $e', name: _logName);
        }
      });
      
      await completer.future;
      ws.close();
      
    } catch (e) {
      developer.log('Error in WebSocket scan: $e', name: _logName);
    }
    
    return devices;
  }
  
  /// Generate a unique device ID for Web
  String _generateDeviceId() {
    // Use browser fingerprinting or generate UUID
    // For now, use a simple hash of user agent
    return _getUserAgent().hashCode.toString();
  }
  
  /// Check if a network service is a SPOTS service
  /// Reserved for future mDNS/NSD implementation on Web
  // ignore: unused_element
  bool _isSpotsService(dynamic service) {
    if (service.name.toLowerCase().contains('spots')) {
      return true;
    }
    
    final txtRecord = service.txtRecord;
    if (txtRecord != null && txtRecord.containsKey('spots')) {
      return true;
    }
    
    return false;
  }
  
  /// Extract personality data from network service
  /// Reserved for future mDNS/NSD implementation on Web
  // ignore: unused_element
  AnonymizedVibeData? _extractPersonalityFromService(dynamic service) {
    try {
      final txtRecord = service.txtRecord;
      if (txtRecord == null) return null;
      
      // Try base64 encoded personality data
      final personalityDataStr = txtRecord['personality_data'] as String?;
      if (personalityDataStr != null && personalityDataStr.isNotEmpty) {
        return PersonalityDataCodec.decodeFromBase64(personalityDataStr);
      }
      
      // Try JSON encoded personality data
      final personalityDataJson = txtRecord['personality_data_json'] as String?;
      if (personalityDataJson != null && personalityDataJson.isNotEmpty) {
        return PersonalityDataCodec.decodeFromJson(personalityDataJson);
      }
      
      return null;
    } catch (e) {
      developer.log('Error extracting personality from service: $e', name: _logName);
      return null;
    }
  }
  
  /// Extract personality data from WebRTC peer data
  AnonymizedVibeData? _extractPersonalityFromPeer(Map<String, dynamic> peerData) {
    try {
      // Try base64 encoded personality data
      final personalityDataBase64 = peerData['personality_data'] as String?;
      if (personalityDataBase64 != null && personalityDataBase64.isNotEmpty) {
        return PersonalityDataCodec.decodeFromBase64(personalityDataBase64);
      }
      
      // Try JSON encoded personality data
      final personalityDataJson = peerData['personality_data_json'];
      if (personalityDataJson != null) {
        if (personalityDataJson is String) {
          return PersonalityDataCodec.decodeFromJson(personalityDataJson);
        } else if (personalityDataJson is Map) {
          // Already decoded JSON, convert directly
          return PersonalityDataCodec.decodeFromJson(
            jsonEncode(personalityDataJson),
          );
        }
      }
      
      return null;
    } catch (e) {
      developer.log('Error extracting personality from peer: $e', name: _logName);
      return null;
    }
  }
  
  /// Set signaling server URL for WebRTC discovery
  Future<bool> setSignalingServerUrl(String url) async {
    return await _signalingConfig.setSignalingServerUrl(url);
  }
}

/// Create Web device discovery implementation
/// This function is called from device_discovery_factory.dart via conditional import
DeviceDiscoveryPlatform createWebDeviceDiscovery() {
  try {
    final getIt = GetIt.instance;
    final prefs = getIt.get<SharedPreferences>();
    final signalingConfig = WebRTCSignalingConfig(prefs: prefs);
    return WebDeviceDiscovery(signalingConfig: signalingConfig);
  } catch (e) {
    // Fallback if SharedPreferences not available
    return WebDeviceDiscovery();
  }
}

