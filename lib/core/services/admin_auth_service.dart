import 'dart:developer' as developer;
import 'dart:convert';
import 'package:spots/core/services/supabase_service.dart';
import 'package:spots/core/services/storage_service.dart';

/// Admin Authentication Service
/// Handles god-mode admin login and session management
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Admin access requires strict authentication
class AdminAuthService {
  static const String _logName = 'AdminAuthService';
  static const String _adminSessionKey = 'admin_session';
  static const String _adminLoginAttemptsKey = 'admin_login_attempts';
  static const String _adminLockoutKey = 'admin_lockout_until';
  
  final SharedPreferencesCompat _prefs;
  
  // Maximum login attempts before lockout
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  AdminAuthService(this._prefs);
  
  /// Authenticate admin with god-mode credentials
  /// Returns true if authentication successful
  Future<AdminAuthResult> authenticate({
    required String username,
    required String password,
    String? twoFactorCode,
  }) async {
    try {
      // Check for lockout
      final lockoutUntil = _prefs.getInt(_adminLockoutKey);
      if (lockoutUntil != null && DateTime.now().millisecondsSinceEpoch < lockoutUntil) {
        final remaining = Duration(milliseconds: lockoutUntil - DateTime.now().millisecondsSinceEpoch);
        return AdminAuthResult.lockedOut(remaining);
      }
      
      // Verify credentials via Supabase Edge Function
      final verifyResult = await _verifyCredentials(username, password, twoFactorCode);
      
      if (!verifyResult.success) {
        // Handle lockout from server
        if (verifyResult.lockedOut && verifyResult.lockoutRemaining != null) {
          final lockoutUntil = DateTime.now().add(verifyResult.lockoutRemaining!).millisecondsSinceEpoch;
          await _prefs.setInt(_adminLockoutKey, lockoutUntil);
          return AdminAuthResult.lockedOut(verifyResult.lockoutRemaining!);
        }
        
        // Handle failed attempts
        if (verifyResult.remainingAttempts != null) {
          return AdminAuthResult.failed(
            error: verifyResult.error,
            remainingAttempts: verifyResult.remainingAttempts,
          );
        }
        
        return AdminAuthResult.failed(error: verifyResult.error);
      }
      
      // Reset failed attempts on success
      await _prefs.remove(_adminLoginAttemptsKey);
      await _prefs.remove(_adminLockoutKey);
      
      // Create admin session
      final session = AdminSession(
        username: username,
        loginTime: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        accessLevel: AdminAccessLevel.godMode,
        permissions: AdminPermissions.all(),
      );
      
      await _saveSession(session);
      
      developer.log('Admin authenticated: $username', name: _logName);
      return AdminAuthResult.success(session);
    } catch (e) {
      developer.log('Error during admin authentication: $e', name: _logName);
      return AdminAuthResult.error(e.toString());
    }
  }
  
  /// Verify admin credentials via Supabase Edge Function
  /// Returns a result object with success status and additional info
  Future<_VerifyResult> _verifyCredentials(String username, String password, String? twoFactorCode) async {
    try {
      final supabaseService = SupabaseService();
      
      // Check if Supabase is available before trying to use it
      if (!supabaseService.isAvailable) {
        developer.log(
          'Supabase not initialized - cannot verify admin credentials',
          name: _logName,
        );
        return _VerifyResult(
          success: false,
          error: 'Backend service unavailable. Please configure Supabase credentials.',
        );
      }
      
      // Get client (we know it's available from the check above)
      final client = supabaseService.client;
      
      // Call the admin-auth edge function
      final response = await client.functions.invoke(
        'admin-auth',
        body: {
          'username': username,
          'password': password,
          if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        },
      );

      // Parse response data - handle both Map and String responses
      Map<String, dynamic>? data;
      if (response.data is Map) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          developer.log('Failed to parse edge function response: $e', name: _logName);
          return _VerifyResult(
            success: false,
            error: 'Invalid response from server',
          );
        }
      }
      
      if (response.status == 200 && data?['success'] == true) {
        developer.log('Admin credentials verified successfully', name: _logName);
        return _VerifyResult(success: true);
      }

      // Handle error responses
      final error = data?['error'] as String? ?? 'Authentication failed';
      final lockedOut = data?['lockedOut'] as bool? ?? false;
      final lockoutRemaining = data?['lockoutRemaining'] as int?;
      final remainingAttempts = data?['remainingAttempts'] as int?;

      developer.log('Admin auth failed: $error (status: ${response.status})', name: _logName);

      return _VerifyResult(
        success: false,
        error: error,
        lockedOut: lockedOut,
        lockoutRemaining: lockoutRemaining != null 
            ? Duration(minutes: lockoutRemaining)
            : null,
        remainingAttempts: remainingAttempts,
      );
    } catch (e) {
      developer.log('Error verifying admin credentials: $e', name: _logName);
      return _VerifyResult(
        success: false,
        error: 'Connection error: $e',
      );
    }
  }
  
  /// Get current admin session
  AdminSession? getCurrentSession() {
    try {
      final sessionJson = _prefs.getString(_adminSessionKey);
      if (sessionJson == null) return null;
      
      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      return AdminSession.fromJson(sessionMap);
    } catch (e) {
      developer.log('Error loading admin session: $e', name: _logName);
      return null;
    }
  }
  
  /// Check if admin is currently authenticated
  bool isAuthenticated() {
    final session = getCurrentSession();
    if (session == null) return false;
    
    // Check if session expired
    if (DateTime.now().isAfter(session.expiresAt)) {
      logout();
      return false;
    }
    
    return true;
  }
  
  /// Check if admin has specific permission
  bool hasPermission(AdminPermission permission) {
    final session = getCurrentSession();
    if (session == null) return false;
    
    return session.permissions.hasPermission(permission);
  }
  
  /// Logout admin
  Future<void> logout() async {
    await _prefs.remove(_adminSessionKey);
    developer.log('Admin logged out', name: _logName);
  }
  
  /// Save admin session
  Future<void> _saveSession(AdminSession session) async {
    final sessionJson = jsonEncode(session.toJson());
    await _prefs.setString(_adminSessionKey, sessionJson);
  }
  
  /// Extend session
  Future<void> extendSession() async {
    final session = getCurrentSession();
    if (session != null) {
      final extendedSession = session.copyWith(
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
      await _saveSession(extendedSession);
    }
  }
}

/// Admin session data
class AdminSession {
  final String username;
  final DateTime loginTime;
  final DateTime expiresAt;
  final AdminAccessLevel accessLevel;
  final AdminPermissions permissions;
  
  AdminSession({
    required this.username,
    required this.loginTime,
    required this.expiresAt,
    required this.accessLevel,
    required this.permissions,
  });
  
  AdminSession copyWith({
    String? username,
    DateTime? loginTime,
    DateTime? expiresAt,
    AdminAccessLevel? accessLevel,
    AdminPermissions? permissions,
  }) {
    return AdminSession(
      username: username ?? this.username,
      loginTime: loginTime ?? this.loginTime,
      expiresAt: expiresAt ?? this.expiresAt,
      accessLevel: accessLevel ?? this.accessLevel,
      permissions: permissions ?? this.permissions,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'loginTime': loginTime.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'accessLevel': accessLevel.name,
      'permissions': permissions.toJson(),
    };
  }
  
  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      username: json['username'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accessLevel: AdminAccessLevel.values.firstWhere(
        (e) => e.name == json['accessLevel'],
        orElse: () => AdminAccessLevel.standard,
      ),
      permissions: AdminPermissions.fromJson(json['permissions'] as Map<String, dynamic>),
    );
  }
}

/// Admin access levels
enum AdminAccessLevel {
  standard,
  elevated,
  godMode,
}

/// Admin permissions
class AdminPermissions {
  final bool viewUserData;
  final bool viewAIData;
  final bool viewCommunications;
  final bool viewUserProgress;
  final bool viewUserPredictions;
  final bool viewBusinessAccounts;
  final bool viewRealTimeData;
  final bool modifyUserData;
  final bool modifyAIData;
  final bool modifyBusinessData;
  final bool accessAuditLogs;
  
  AdminPermissions({
    this.viewUserData = false,
    this.viewAIData = false,
    this.viewCommunications = false,
    this.viewUserProgress = false,
    this.viewUserPredictions = false,
    this.viewBusinessAccounts = false,
    this.viewRealTimeData = false,
    this.modifyUserData = false,
    this.modifyAIData = false,
    this.modifyBusinessData = false,
    this.accessAuditLogs = false,
  });
  
  factory AdminPermissions.all() {
    return AdminPermissions(
      viewUserData: true,
      viewAIData: true,
      viewCommunications: true,
      viewUserProgress: true,
      viewUserPredictions: true,
      viewBusinessAccounts: true,
      viewRealTimeData: true,
      modifyUserData: true,
      modifyAIData: true,
      modifyBusinessData: true,
      accessAuditLogs: true,
    );
  }
  
  bool hasPermission(AdminPermission permission) {
    switch (permission) {
      case AdminPermission.viewUserData:
        return viewUserData;
      case AdminPermission.viewAIData:
        return viewAIData;
      case AdminPermission.viewCommunications:
        return viewCommunications;
      case AdminPermission.viewUserProgress:
        return viewUserProgress;
      case AdminPermission.viewUserPredictions:
        return viewUserPredictions;
      case AdminPermission.viewBusinessAccounts:
        return viewBusinessAccounts;
      case AdminPermission.viewRealTimeData:
        return viewRealTimeData;
      case AdminPermission.modifyUserData:
        return modifyUserData;
      case AdminPermission.modifyAIData:
        return modifyAIData;
      case AdminPermission.modifyBusinessData:
        return modifyBusinessData;
      case AdminPermission.accessAuditLogs:
        return accessAuditLogs;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'viewUserData': viewUserData,
      'viewAIData': viewAIData,
      'viewCommunications': viewCommunications,
      'viewUserProgress': viewUserProgress,
      'viewUserPredictions': viewUserPredictions,
      'viewBusinessAccounts': viewBusinessAccounts,
      'viewRealTimeData': viewRealTimeData,
      'modifyUserData': modifyUserData,
      'modifyAIData': modifyAIData,
      'modifyBusinessData': modifyBusinessData,
      'accessAuditLogs': accessAuditLogs,
    };
  }
  
  factory AdminPermissions.fromJson(Map<String, dynamic> json) {
    return AdminPermissions(
      viewUserData: json['viewUserData'] as bool? ?? false,
      viewAIData: json['viewAIData'] as bool? ?? false,
      viewCommunications: json['viewCommunications'] as bool? ?? false,
      viewUserProgress: json['viewUserProgress'] as bool? ?? false,
      viewUserPredictions: json['viewUserPredictions'] as bool? ?? false,
      viewBusinessAccounts: json['viewBusinessAccounts'] as bool? ?? false,
      viewRealTimeData: json['viewRealTimeData'] as bool? ?? false,
      modifyUserData: json['modifyUserData'] as bool? ?? false,
      modifyAIData: json['modifyAIData'] as bool? ?? false,
      modifyBusinessData: json['modifyBusinessData'] as bool? ?? false,
      accessAuditLogs: json['accessAuditLogs'] as bool? ?? false,
    );
  }
}

/// Admin permission types
enum AdminPermission {
  viewUserData,
  viewAIData,
  viewCommunications,
  viewUserProgress,
  viewUserPredictions,
  viewBusinessAccounts,
  viewRealTimeData,
  modifyUserData,
  modifyAIData,
  modifyBusinessData,
  accessAuditLogs,
}

/// Admin authentication result
class AdminAuthResult {
  final bool success;
  final AdminSession? session;
  final String? error;
  final bool lockedOut;
  final Duration? lockoutRemaining;
  final int? remainingAttempts;
  
  AdminAuthResult({
    required this.success,
    this.session,
    this.error,
    this.lockedOut = false,
    this.lockoutRemaining,
    this.remainingAttempts,
  });
  
  factory AdminAuthResult.success(AdminSession session) {
    return AdminAuthResult(success: true, session: session);
  }
  
  factory AdminAuthResult.failed({String? error, int? remainingAttempts}) {
    return AdminAuthResult(
      success: false,
      error: error ?? 'Invalid credentials',
      remainingAttempts: remainingAttempts,
    );
  }
  
  factory AdminAuthResult.lockedOut(Duration remaining) {
    return AdminAuthResult(
      success: false,
      lockedOut: true,
      lockoutRemaining: remaining,
      error: 'Account locked. Try again in ${remaining.inMinutes} minutes.',
    );
  }
  
  factory AdminAuthResult.error(String error) {
    return AdminAuthResult(success: false, error: error);
  }
}

/// Internal result class for credential verification
class _VerifyResult {
  final bool success;
  final String? error;
  final bool lockedOut;
  final Duration? lockoutRemaining;
  final int? remainingAttempts;

  _VerifyResult({
    required this.success,
    this.error,
    this.lockedOut = false,
    this.lockoutRemaining,
    this.remainingAttempts,
  });
}

