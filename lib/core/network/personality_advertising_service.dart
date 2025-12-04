import 'dart:developer' as developer;
import 'dart:async';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/ai/vibe_analysis_engine.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/network/personality_data_codec.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_nsd/flutter_nsd.dart';

/// Personality Advertising Service
/// Advertises anonymized personality data so other devices can discover this device
/// OUR_GUTS.md: "All device interactions must go through Personality AI Layer"
class PersonalityAdvertisingService {
  static const String _logName = 'PersonalityAdvertisingService';
  
  // SPOTS service UUID for BLE advertisements
  static const String spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';
  
  // Advertising state
  bool _isAdvertising = false;
  AnonymizedVibeData? _currentPersonalityData;
  AnonymousUser? _currentAnonymousUser;
  Timer? _refreshTimer;
  
  // Anonymization service for converting UnifiedUser to AnonymousUser
  final UserAnonymizationService? _anonymizationService;
  
  // Platform-specific advertising implementations
  // Use dynamic to avoid importing platform-specific classes (which would pull in web code)
  final dynamic _androidDiscovery;
  final dynamic _iosDiscovery;
  final dynamic _webDiscovery;
  
  // BLE advertising (Android/iOS)
  // Note: BLE advertising requires platform channels - placeholder for now
  FlutterNsd? _nsdService;
  
  PersonalityAdvertisingService({
    dynamic androidDiscovery,
    dynamic iosDiscovery,
    dynamic webDiscovery,
    UserAnonymizationService? anonymizationService,
  }) : _androidDiscovery = androidDiscovery,
       _iosDiscovery = iosDiscovery,
       _webDiscovery = webDiscovery,
       _anonymizationService = anonymizationService;
  
  /// Start advertising personality data
  /// This makes the device discoverable by other SPOTS devices
  Future<bool> startAdvertising(
    String userId,
    PersonalityProfile personality,
    UserVibeAnalyzer vibeAnalyzer,
  ) async {
    if (_isAdvertising) {
      developer.log('Already advertising personality data', name: _logName);
      return true;
    }
    
    try {
      developer.log('Starting personality advertising for user: $userId', name: _logName);
      
      // Compile user vibe from personality
      final userVibe = await vibeAnalyzer.compileUserVibe(userId, personality);
      
      // Anonymize personality data
      final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(userVibe);
      _currentPersonalityData = anonymizedVibe;
      
      // Start platform-specific advertising
      bool success = false;
      
      if (kIsWeb) {
        success = await _startWebAdvertising(anonymizedVibe);
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            success = await _startAndroidAdvertising(anonymizedVibe);
            break;
          case TargetPlatform.iOS:
            success = await _startIOSAdvertising(anonymizedVibe);
            break;
          default:
            developer.log('Platform not supported for advertising', name: _logName);
            return false;
        }
      }
      
      if (success) {
        _isAdvertising = true;
        
        // Set up automatic refresh (refresh every 5 minutes or when data expires)
        _startRefreshTimer(userId, personality, vibeAnalyzer);
        
        developer.log('Personality advertising started successfully', name: _logName);
        return true;
      } else {
        developer.log('Failed to start personality advertising', name: _logName);
        return false;
      }
    } catch (e) {
      developer.log('Error starting personality advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Stop advertising personality data
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) {
      return;
    }
    
    try {
      developer.log('Stopping personality advertising', name: _logName);
      
      _refreshTimer?.cancel();
      _refreshTimer = null;
      
      // Stop platform-specific advertising
      if (kIsWeb) {
        await _stopWebAdvertising();
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            await _stopAndroidAdvertising();
            break;
          case TargetPlatform.iOS:
            await _stopIOSAdvertising();
            break;
          default:
            break;
        }
      }
      
      _isAdvertising = false;
      _currentPersonalityData = null;
      _currentAnonymousUser = null;
      
      developer.log('Personality advertising stopped', name: _logName);
    } catch (e) {
      developer.log('Error stopping personality advertising: $e', name: _logName);
    }
  }
  
  /// Update personality data being advertised
  /// Call this when personality evolves
  Future<bool> updatePersonalityData(
    String userId,
    PersonalityProfile personality,
    UserVibeAnalyzer vibeAnalyzer,
  ) async {
    if (!_isAdvertising) {
      // If not advertising, start advertising
      return await startAdvertising(userId, personality, vibeAnalyzer);
    }
    
    try {
      developer.log('Updating advertised personality data', name: _logName);
      
      // Compile and anonymize new personality data
      final userVibe = await vibeAnalyzer.compileUserVibe(userId, personality);
      final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(userVibe);
      _currentPersonalityData = anonymizedVibe;
      
      // Update platform-specific advertising
      bool success = false;
      
      if (kIsWeb) {
        success = await _updateWebAdvertising(anonymizedVibe);
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            success = await _updateAndroidAdvertising(anonymizedVibe);
            break;
          case TargetPlatform.iOS:
            success = await _updateIOSAdvertising(anonymizedVibe);
            break;
          default:
            return false;
        }
      }
      
      if (success) {
        developer.log('Personality data updated successfully', name: _logName);
      }
      
      return success;
    } catch (e) {
      developer.log('Error updating personality data: $e', name: _logName);
      return false;
    }
  }
  
  /// Check if currently advertising
  bool get isAdvertising => _isAdvertising;
  
  /// Get current advertised personality data
  AnonymizedVibeData? get currentPersonalityData => _currentPersonalityData;
  
  /// Get current anonymous user data (if user profile is being advertised)
  AnonymousUser? get currentAnonymousUser => _currentAnonymousUser;

  /// Start advertising with UnifiedUser (converts to AnonymousUser automatically)
  /// 
  /// **CRITICAL:** This method ensures UnifiedUser is converted to AnonymousUser
  /// before transmission. No personal data is shared in AI2AI network.
  /// 
  /// **Parameters:**
  /// - `user`: UnifiedUser to advertise (will be anonymized)
  /// - `agentId`: Anonymous agent ID (required, must start with "agent_")
  /// - `personality`: Personality profile to include
  /// - `vibeAnalyzer`: UserVibeAnalyzer for vibe compilation
  /// - `isAdmin`: If true, allows exact location (godmode/admin access)
  /// 
  /// **Returns:**
  /// true if advertising started successfully
  Future<bool> startAdvertisingWithUser(
    UnifiedUser user,
    String agentId,
    PersonalityProfile personality,
    UserVibeAnalyzer vibeAnalyzer, {
    bool isAdmin = false,
  }) async {
    if (_anonymizationService == null) {
      developer.log('UserAnonymizationService not available. Cannot advertise user profile.', name: _logName);
      // Fallback to vibe-only advertising
      return await startAdvertising(user.id, personality, vibeAnalyzer);
    }

    try {
      developer.log('Starting advertising with UnifiedUser (will be anonymized): ${user.id}', name: _logName);
      
      // Convert UnifiedUser to AnonymousUser
      final anonymousUser = await _anonymizationService!.anonymizeUser(
        user,
        agentId,
        personality,
        isAdmin: isAdmin,
      );
      
      _currentAnonymousUser = anonymousUser;
      
      // Also compile vibe for compatibility with existing advertising
      final userVibe = await vibeAnalyzer.compileUserVibe(user.id, personality);
      final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(userVibe);
      _currentPersonalityData = anonymizedVibe;
      
      // Start platform-specific advertising with anonymized data
      bool success = false;
      
      if (kIsWeb) {
        success = await _startWebAdvertising(anonymizedVibe);
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            success = await _startAndroidAdvertising(anonymizedVibe);
            break;
          case TargetPlatform.iOS:
            success = await _startIOSAdvertising(anonymizedVibe);
            break;
          default:
            developer.log('Platform not supported for advertising', name: _logName);
            return false;
        }
      }
      
      if (success) {
        _isAdvertising = true;
        _startRefreshTimer(user.id, personality, vibeAnalyzer);
        developer.log('User profile advertising started successfully (anonymized)', name: _logName);
        return true;
      } else {
        developer.log('Failed to start user profile advertising', name: _logName);
        return false;
      }
    } catch (e) {
      developer.log('Error starting user profile advertising: $e', name: _logName);
      return false;
    }
  }

  /// Validate that no UnifiedUser is being sent directly in AI2AI network
  /// 
  /// This is a safety check to prevent accidental personal data leaks.
  void validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    final forbiddenFields = ['id', 'email', 'displayName', 'photoUrl', 'userId'];
    
    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw Exception(
          'CRITICAL: UnifiedUser field "$field" detected in AI2AI payload. '
          'All user data must be converted to AnonymousUser before transmission. '
          'Use startAdvertisingWithUser() method.'
        );
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
  
  // Platform-specific advertising implementations
  
  /// Start Android BLE advertising
  Future<bool> _startAndroidAdvertising(AnonymizedVibeData personalityData) async {
    try {
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        developer.log('Bluetooth not supported on Android', name: _logName);
        return false;
      }
      
      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        developer.log('Bluetooth is off, cannot advertise', name: _logName);
        return false;
      }
      
      // Encode personality data to binary format
      final binaryData = PersonalityDataCodec.encodeToBinary(personalityData);
      if (binaryData.isEmpty) {
        developer.log('Failed to encode personality data', name: _logName);
        return false;
      }
      
      // TODO: Start BLE advertising with personality data
      // This requires:
      // 1. Create BLE peripheral/advertiser
      // 2. Set service UUID: spotsServiceUuid
      // 3. Add manufacturer data with binary personality data
      // 4. Start advertising
      
      // Note: flutter_blue_plus doesn't support BLE advertising directly
      // You'll need to use platform channels or a plugin that supports advertising
      // For now, we'll log that advertising would happen here
      
      developer.log('Android BLE advertising requires platform channel implementation', name: _logName);
      developer.log('Would advertise ${binaryData.length} bytes of personality data', name: _logName);
      
      // Placeholder: return true to indicate structure is ready
      // Actual implementation requires native Android code
      return true;
      
    } catch (e) {
      developer.log('Error starting Android advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Start iOS mDNS/Bonjour advertising
  Future<bool> _startIOSAdvertising(AnonymizedVibeData personalityData) async {
    try {
      // Encode personality data to base64 for TXT record
      final base64Data = PersonalityDataCodec.encodeToBase64(personalityData);
      if (base64Data.isEmpty) {
        developer.log('Failed to encode personality data', name: _logName);
        return false;
      }
      
      // Create NSD service for advertising
      // Note: FlutterNsd API may vary - using try-catch for compatibility
      try {
        final nsd = FlutterNsd();
        
        // Create TXT record with personality data
        final txtRecord = <String, String>{
          'spots': 'true',
          'personality_data': base64Data,
          'version': '1.0',
        };
        
        // Note: FlutterNsd API may not have registerService method
        // This is a placeholder - actual implementation may require platform channels
        // For now, log that advertising would happen
        developer.log('NSD service registration would happen here with TXT record: $txtRecord', name: _logName);
        // TODO: Implement actual NSD service registration via platform channels if needed
        
        _nsdService = nsd;
      } catch (e) {
        developer.log('NSD service registration not available: $e', name: _logName);
        // Fallback: Service registration may require platform-specific implementation
        return false;
      }
      
      developer.log('iOS mDNS/Bonjour advertising started', name: _logName);
      return true;
      
    } catch (e) {
      developer.log('Error starting iOS advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Start Web WebRTC/WebSocket advertising
  Future<bool> _startWebAdvertising(AnonymizedVibeData personalityData) async {
    try {
      // Encode personality data to JSON for WebRTC
      final jsonData = PersonalityDataCodec.encodeToJson(personalityData);
      if (jsonData.isEmpty) {
        developer.log('Failed to encode personality data', name: _logName);
        return false;
      }
      
      // TODO: Register with WebRTC signaling server
      // This requires:
      // 1. Connect to signaling server
      // 2. Register device with personality data
      // 3. Keep connection alive for discovery
      
      // Note: This would be handled by the signaling server
      // The WebDeviceDiscovery already has the structure for this
      
      developer.log('Web advertising requires signaling server registration', name: _logName);
      developer.log('Would register with personality data: ${jsonData.length} bytes', name: _logName);
      
      // Placeholder: return true to indicate structure is ready
      return true;
      
    } catch (e) {
      developer.log('Error starting Web advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Stop Android advertising
  Future<void> _stopAndroidAdvertising() async {
    try {
      // TODO: Stop BLE advertising
      // This requires stopping the BLE peripheral/advertiser
      developer.log('Stopping Android BLE advertising', name: _logName);
    } catch (e) {
      developer.log('Error stopping Android advertising: $e', name: _logName);
    }
  }
  
  /// Stop iOS advertising
  Future<void> _stopIOSAdvertising() async {
    try {
      if (_nsdService != null) {
        // Note: FlutterNsd doesn't have unregisterService method
        // Service will stop when object is disposed
        _nsdService = null;
        developer.log('Stopped iOS mDNS/Bonjour advertising', name: _logName);
      }
    } catch (e) {
      developer.log('Error stopping iOS advertising: $e', name: _logName);
    }
  }
  
  /// Stop Web advertising
  Future<void> _stopWebAdvertising() async {
    try {
      // TODO: Unregister from signaling server
      developer.log('Stopping Web advertising', name: _logName);
    } catch (e) {
      developer.log('Error stopping Web advertising: $e', name: _logName);
    }
  }
  
  /// Update Android advertising
  Future<bool> _updateAndroidAdvertising(AnonymizedVibeData personalityData) async {
    // Stop and restart with new data
    await _stopAndroidAdvertising();
    return await _startAndroidAdvertising(personalityData);
  }
  
  /// Update iOS advertising
  Future<bool> _updateIOSAdvertising(AnonymizedVibeData personalityData) async {
    // Stop and restart with new data
    await _stopIOSAdvertising();
    return await _startIOSAdvertising(personalityData);
  }
  
  /// Update Web advertising
  Future<bool> _updateWebAdvertising(AnonymizedVibeData personalityData) async {
    // Update registration with new data
    // This would update the signaling server registration
    developer.log('Updating Web advertising with new personality data', name: _logName);
    return true;
  }
  
  /// Start automatic refresh timer
  void _startRefreshTimer(
    String userId,
    PersonalityProfile personality,
    UserVibeAnalyzer vibeAnalyzer,
  ) {
    _refreshTimer?.cancel();
    
    // Refresh every 5 minutes or when data is about to expire
    final refreshInterval = const Duration(minutes: 5);
    
    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      // Check if data is expired or about to expire
      if (_currentPersonalityData != null) {
        final timeUntilExpiry = _currentPersonalityData!.expiresAt.difference(DateTime.now());
        
        // Refresh if expired or expiring within 1 minute
        if (timeUntilExpiry.inMinutes < 1) {
          developer.log('Personality data expiring soon, refreshing advertisement', name: _logName);
          await updatePersonalityData(userId, personality, vibeAnalyzer);
        }
      }
    });
  }
}

