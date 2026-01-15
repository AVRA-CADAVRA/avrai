// Reservation Notification Service
//
// Phase 15: Reservation System Implementation
// Section 15.1.7: Reservation Notification Service
//
// Purpose: Send reminders, confirmations, updates

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:get_it/get_it.dart';

// Optional FCM import (graceful degradation if not available)
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;

/// Notification type
enum ReservationNotificationType {
  /// Reservation confirmation
  confirmation,

  /// 24-hour reminder
  reminder24h,

  /// 1-hour reminder
  reminder1h,

  /// Cancellation notice
  cancellation,

  /// Modification notice
  modification,

  /// Waitlist promotion
  waitlistPromotion,
}

/// Reservation Notification Service
///
/// **Purpose:** Send reminders, confirmations, updates
///
/// **Notification Types:**
/// - Confirmation (when reservation created)
/// - 24-hour reminder
/// - 1-hour reminder
/// - Cancellation notice
/// - Modification notice
/// - Waitlist promotion
class ReservationNotificationService {
  static const String _logName = 'ReservationNotificationService';

  final SupabaseService _supabaseService;
  final StorageService _storageService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  // Optional FCM (Firebase Cloud Messaging) for push notifications
  fcm.FirebaseMessaging? _firebaseMessaging;
  String? _fcmToken;
  bool _fcmInitialized = false;
  bool _userOptedIntoPush = false; // User preference for push notifications

  // Connectivity monitoring for offline-first sync
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  ReservationNotificationService({
    SupabaseService? supabaseService,
    StorageService? storageService,
    bool enableFCM = true, // Allow disabling FCM if needed
  })  : _supabaseService = supabaseService ?? GetIt.instance<SupabaseService>(),
        _storageService = storageService ?? GetIt.instance<StorageService>() {
    _initializeLocalNotifications();
    if (enableFCM) {
      _initializeFCM();
    }
    _initializeConnectivityListener();
  }

  /// Initialize connectivity listener for offline-first sync
  ///
  /// Automatically syncs queued notifications when device comes online
  Future<void> _initializeConnectivityListener() async {
    try {
      // Check initial connectivity
      final initialResult = await _connectivity.checkConnectivity();
      _wasOffline = initialResult.contains(ConnectivityResult.none);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (results) async {
          final isOffline = results.contains(ConnectivityResult.none);
          
          // If device came back online, sync queued notifications
          if (_wasOffline && !isOffline) {
            developer.log(
              'Device came back online, syncing queued notifications...',
              name: _logName,
            );
            await syncQueuedNotifications();
          }
          
          _wasOffline = isOffline;
        },
        onError: (error) {
          developer.log(
            'Connectivity listener error: $error',
            name: _logName,
            error: error,
          );
        },
      );

      developer.log(
        '✅ Connectivity listener initialized',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error initializing connectivity listener (non-critical): $e',
        name: _logName,
        error: e,
      );
      // Non-critical - notifications still work
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize plugin
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          developer.log(
            'Notification tapped: ${response.payload}',
            name: _logName,
          );
        },
      );

      _localNotificationsInitialized = initialized ?? false;

      if (_localNotificationsInitialized) {
        developer.log(
          '✅ Local notifications initialized',
          name: _logName,
        );
      } else {
        developer.log(
          '⚠️ Local notifications initialization failed',
          name: _logName,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing local notifications: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      _localNotificationsInitialized = false;
    }
  }

  /// Initialize Firebase Cloud Messaging (optional enhancement)
  ///
  /// **Offline-First Strategy:**
  /// - FCM is optional and only used when online
  /// - Local notifications are primary and work offline
  /// - FCM provides server-initiated push notifications as enhancement
  Future<void> _initializeFCM() async {
    try {
      // Check if Firebase is available
      _firebaseMessaging = fcm.FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == fcm.AuthorizationStatus.authorized ||
          settings.authorizationStatus == fcm.AuthorizationStatus.provisional) {
        _userOptedIntoPush = true;

        // Get FCM token
        _fcmToken = await _firebaseMessaging!.getToken();
        if (_fcmToken != null) {
          developer.log(
            '✅ FCM token obtained: ${_fcmToken!.substring(0, 20)}...',
            name: _logName,
          );

          // Store FCM token for backend (when online)
          if (_supabaseService.isAvailable) {
            try {
              await _storeFCMToken(_fcmToken!);
            } catch (e) {
              developer.log(
                'Error storing FCM token (non-critical): $e',
                name: _logName,
                error: e,
              );
            }
          } else {
            // Queue token storage for when online
            await _queueFCMTokenStorage(_fcmToken!);
          }

          // Listen for token refresh
          _firebaseMessaging!.onTokenRefresh.listen((newToken) {
            _fcmToken = newToken;
            developer.log(
              'FCM token refreshed: ${newToken.substring(0, 20)}...',
              name: _logName,
            );
            if (_supabaseService.isAvailable) {
              _storeFCMToken(newToken);
            } else {
              _queueFCMTokenStorage(newToken);
            }
          });
        }

        // Register background message handler
        fcm.FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        // Handle foreground messages (optional - local notifications handle this)
        fcm.FirebaseMessaging.onMessage.listen((message) {
          developer.log(
            'FCM foreground message received: ${message.messageId}',
            name: _logName,
          );
          // Local notifications already handle this, but we can process FCM data here
          // Optionally show local notification from FCM data
          if (message.notification != null && _localNotificationsInitialized) {
            _localNotifications.show(
              message.hashCode,
              message.notification?.title ?? 'Reservation Update',
              message.notification?.body ?? '',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'reservations',
                  'Reservation Notifications',
                  channelDescription:
                      'Notifications for reservation confirmations, reminders, and updates',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: message.data['reservationId'] as String?,
            );
          }
        });

        // Handle background message taps (when user taps notification)
        fcm.FirebaseMessaging.onMessageOpenedApp.listen((message) {
          developer.log(
            'FCM message opened from background: ${message.messageId}',
            name: _logName,
          );
          // Handle navigation to reservation detail if needed
          // TODO: Navigate to reservation detail page using message.data['reservationId']
        });

        _fcmInitialized = true;
        developer.log(
          '✅ FCM initialized successfully',
          name: _logName,
        );
      } else {
        developer.log(
          '⚠️ FCM permission denied (local notifications still work)',
          name: _logName,
        );
        _userOptedIntoPush = false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing FCM (non-critical - local notifications still work): $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Graceful degradation - local notifications still work
      _fcmInitialized = false;
    }
  }

  /// Store FCM token in backend (when online)
  Future<void> _storeFCMToken(String token) async {
    if (!_supabaseService.isAvailable) return;

    try {
      final client = _supabaseService.client;
      // Get userId from agentId (if available)
      // TODO: Get userId from agentId lookup
      final agentId = 'current_user_agent_id'; // Placeholder

      await client.from('fcm_tokens').upsert({
        'agent_id': agentId,
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log(
        '✅ FCM token stored in backend',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error storing FCM token: $e',
        name: _logName,
        error: e,
      );
      rethrow;
    }
  }

  /// Queue FCM token storage for when online
  Future<void> _queueFCMTokenStorage(String token) async {
    try {
      final key = 'fcm_token_queue';
      await _storageService.setString(key, token);
      developer.log(
        '✅ FCM token queued for storage when online',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error queueing FCM token (non-critical): $e',
        name: _logName,
        error: e,
      );
    }
  }

  /// Queue FCM notification request for backend (when online)
  ///
  /// **Note:** This queues a request for the backend to send a push notification.
  /// The backend will send the push notification when the device is online.
  /// Local notifications are primary and work offline.
  Future<void> _queueFCMNotificationRequest({
    required String reservationId,
    required ReservationNotificationType type,
    required String title,
    required String body,
  }) async {
    if (!_fcmInitialized || !_userOptedIntoPush || _fcmToken == null) {
      return; // FCM not available or user opted out
    }

    try {
      // Queue notification request for backend
      // Backend will send push notification when device is online
      final key = 'fcm_notification_queue_${DateTime.now().millisecondsSinceEpoch}';
      await _storageService.setString(
        key,
        jsonEncode({
          'reservationId': reservationId,
          'type': type.name,
          'title': title,
          'body': body,
          'fcmToken': _fcmToken,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      developer.log(
        '✅ FCM notification request queued: reservation=$reservationId',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error queueing FCM notification request (non-critical): $e',
        name: _logName,
        error: e,
      );
      // Non-critical - local notification already sent
    }
  }

  /// Send confirmation
  Future<void> sendConfirmation(Reservation reservation) async {
    developer.log(
      'Sending confirmation: reservationId=${reservation.id}',
      name: _logName,
    );

    try {
      await _sendNotification(
        reservation: reservation,
        type: ReservationNotificationType.confirmation,
        title: 'Reservation Confirmed',
        body: _getConfirmationMessage(reservation),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error sending confirmation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - notification failure is non-critical
    }
  }

  /// Send reminder (24h before, 1h before)
  Future<void> sendReminder(
    Reservation reservation,
    Duration beforeTime,
  ) async {
    developer.log(
      'Sending reminder: reservationId=${reservation.id}, beforeTime=$beforeTime',
      name: _logName,
    );

    try {
      final notificationType = beforeTime.inHours >= 24
          ? ReservationNotificationType.reminder24h
          : ReservationNotificationType.reminder1h;

      await _sendNotification(
        reservation: reservation,
        type: notificationType,
        title: 'Reservation Reminder',
        body: _getReminderMessage(reservation, beforeTime),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error sending reminder: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - notification failure is non-critical
    }
  }

  /// Send cancellation notice
  Future<void> sendCancellationNotice(Reservation reservation) async {
    developer.log(
      'Sending cancellation notice: reservationId=${reservation.id}',
      name: _logName,
    );

    try {
      await _sendNotification(
        reservation: reservation,
        type: ReservationNotificationType.cancellation,
        title: 'Reservation Cancelled',
        body: _getCancellationMessage(reservation),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error sending cancellation notice: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - notification failure is non-critical
    }
  }

  /// Schedule reminders
  ///
  /// **Schedules:**
  /// - 24-hour reminder
  /// - 1-hour reminder
  Future<void> scheduleReminders(Reservation reservation) async {
    developer.log(
      'Scheduling reminders: reservationId=${reservation.id}',
      name: _logName,
    );

    try {
      final reservationTime = reservation.reservationTime;
      final now = DateTime.now();

      // Schedule 24-hour reminder
      final reminder24hTime =
          reservationTime.subtract(const Duration(hours: 24));
      if (reminder24hTime.isAfter(now)) {
        await _scheduleNotification(
          reservation: reservation,
          scheduledFor: reminder24hTime,
          type: ReservationNotificationType.reminder24h,
        );
      }

      // Schedule 1-hour reminder
      final reminder1hTime = reservationTime.subtract(const Duration(hours: 1));
      if (reminder1hTime.isAfter(now)) {
        await _scheduleNotification(
          reservation: reservation,
          scheduledFor: reminder1hTime,
          type: ReservationNotificationType.reminder1h,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error scheduling reminders: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - scheduling failure is non-critical
    }
  }

  // Private helper methods

  /// Send notification
  ///
  /// **Offline-First Strategy:**
  /// 1. Local notification (primary) - Works offline ✅
  /// 2. Cloud sync (when online) - Sync to database for cross-device access
  /// 3. Optional FCM (when online) - Server-initiated push as enhancement
  Future<void> _sendNotification({
    required Reservation reservation,
    required ReservationNotificationType type,
    required String title,
    required String body,
  }) async {
    // Step 1: Send local notification (PRIMARY - works offline)
    // This is the main mechanism and works completely offline
    if (_localNotificationsInitialized) {
      try {
        // Android notification details
        final androidDetails = AndroidNotificationDetails(
          'reservations',
          'Reservation Notifications',
          channelDescription:
              'Notifications for reservation confirmations, reminders, and updates',
          importance: Importance.high,
          priority: Priority.high,
        );

        // iOS notification details
        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _localNotifications.show(
          reservation.id.hashCode, // Use reservation ID hash as notification ID
          title,
          body,
          notificationDetails,
          payload: reservation.id, // Pass reservation ID as payload
        );

        developer.log(
          '✅ Local notification sent: reservation=${reservation.id}, type=$type',
          name: _logName,
        );
      } catch (e, stackTrace) {
        developer.log(
          'Error sending local notification: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        // Don't throw - notification failure is non-critical
      }
    }

    // Step 2: Store notification in database (when online - for cross-device access)
    // This enables notification history across devices but is not required for offline functionality
    if (_supabaseService.isAvailable) {
      try {
        final client = _supabaseService.client;
        await client.from('notifications').insert({
          'user_id': reservation
              .agentId, // Note: In production, use userId from agentId lookup
          'type': 'reservation_${type.name}',
          'title': title,
          'body': body,
          'data': {
            'reservationId': reservation.id,
            'type': reservation.type.name,
            'targetId': reservation.targetId,
            'reservationTime': reservation.reservationTime.toIso8601String(),
          },
          'created_at': DateTime.now().toIso8601String(),
        });

        developer.log(
          '✅ Notification synced to cloud: ${reservation.id}, type=$type',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error syncing notification to cloud (non-critical): $e',
          name: _logName,
          error: e,
        );
        // Non-critical - local notification already sent
      }
    } else {
      // Queue notification for sync when online (offline-first pattern)
      try {
        final key = 'notification_queue_${reservation.id}_${type.name}';
        await _storageService.setString(
          key,
          jsonEncode({
            'reservationId': reservation.id,
            'type': type.name,
            'title': title,
            'body': body,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );
        developer.log(
          '✅ Notification queued for sync: ${reservation.id}, type=$type',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error queueing notification (non-critical): $e',
          name: _logName,
          error: e,
        );
        // Non-critical - local notification already sent
      }
    }

    // Step 3: Optional FCM push notification (enhancement when online)
    // Only used for server-initiated notifications (e.g., waitlist promotion)
    // Local notifications are primary and work offline
    // FCM is optional enhancement for real-time server-initiated notifications
    if (_fcmInitialized &&
        _userOptedIntoPush &&
        _fcmToken != null &&
        _supabaseService.isAvailable) {
      try {
        // Queue FCM notification request for backend
        // Backend will send push notification when device is online
        await _queueFCMNotificationRequest(
          reservationId: reservation.id,
          type: type,
          title: title,
          body: body,
        );
      } catch (e) {
        // Non-critical - local notification already sent
        developer.log(
          'FCM notification queued (non-critical): $e',
          name: _logName,
          error: e,
        );
      }
    }
  }

  /// Schedule notification
  Future<void> _scheduleNotification({
    required Reservation reservation,
    required DateTime scheduledFor,
    required ReservationNotificationType type,
  }) async {
    // Store scheduled notification locally
    try {
      final key = 'scheduled_notification_${reservation.id}_${type.name}';
      await _storageService.setString(
        key,
        scheduledFor.toIso8601String(),
      );

      developer.log(
        '✅ Notification scheduled: ${reservation.id}, type=$type, scheduledFor=$scheduledFor',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error scheduling notification: $e',
        name: _logName,
        error: e,
      );
    }

    // Schedule local notification (Phase 5: Notification polish)
    if (_localNotificationsInitialized) {
      try {
        // Android notification details
        final androidDetails = AndroidNotificationDetails(
          'reservations',
          'Reservation Notifications',
          channelDescription:
              'Notifications for reservation confirmations, reminders, and updates',
          importance: Importance.high,
          priority: Priority.high,
        );

        // iOS notification details
        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Calculate notification title and body based on type
        String notificationTitle;
        String notificationBody;
        switch (type) {
          case ReservationNotificationType.reminder24h:
            notificationTitle = 'Reservation Reminder';
            notificationBody =
                _getReminderMessage(reservation, const Duration(hours: 24));
            break;
          case ReservationNotificationType.reminder1h:
            notificationTitle = 'Reservation Reminder';
            notificationBody =
                _getReminderMessage(reservation, const Duration(hours: 1));
            break;
          default:
            notificationTitle = 'Reservation Update';
            notificationBody = _getConfirmationMessage(reservation);
        }

        // Schedule notification
        await _localNotifications.zonedSchedule(
          reservation.id.hashCode +
              type.hashCode, // Unique ID per reservation + type
          notificationTitle,
          notificationBody,
          _convertToTZDateTime(scheduledFor),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: reservation.id,
        );

        developer.log(
          '✅ Local notification scheduled: reservation=${reservation.id}, type=$type, scheduledFor=$scheduledFor',
          name: _logName,
        );
      } catch (e, stackTrace) {
        developer.log(
          'Error scheduling local notification: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Convert DateTime to TZDateTime for scheduling
  ///
  /// **Note:** flutter_local_notifications requires TZDateTime for scheduling
  /// Uses timezone package for proper timezone-aware scheduling
  /// Phase 5: Timezone-aware scheduling - uses device/system timezone
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      // Initialize timezone database if not already initialized
      // Use system timezone (from DateTime) or fallback to UTC
      final timezoneName = dateTime.timeZoneName;

      // Convert common timezone abbreviations to IANA format
      String timezoneId = 'UTC'; // Default fallback
      if (timezoneName.contains('PST') || timezoneName.contains('PDT')) {
        timezoneId = 'America/Los_Angeles';
      } else if (timezoneName.contains('EST') || timezoneName.contains('EDT')) {
        timezoneId = 'America/New_York';
      } else if (timezoneName.contains('CST') || timezoneName.contains('CDT')) {
        timezoneId = 'America/Chicago';
      } else if (timezoneName.contains('MST') || timezoneName.contains('MDT')) {
        timezoneId = 'America/Denver';
      } else if (timezoneName.contains('JST')) {
        timezoneId = 'Asia/Tokyo';
      } else if (timezoneName.contains('UTC') || timezoneName.contains('GMT')) {
        timezoneId = 'UTC';
      } else if (timezoneName.isNotEmpty) {
        // Try to use timezone name directly (may need conversion in production)
        timezoneId = timezoneName;
      }

      // Get timezone location
      final location = tz.getLocation(timezoneId);

      // Convert to TZDateTime in the specified timezone
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      developer.log(
        'Error converting to TZDateTime, using UTC fallback: $e',
        name: _logName,
        error: e,
      );
      // Fallback to UTC if timezone conversion fails
      return tz.TZDateTime.from(dateTime, tz.UTC);
    }
  }

  /// Get confirmation message
  String _getConfirmationMessage(Reservation reservation) {
    return 'Your reservation is confirmed for ${_formatDateTime(reservation.reservationTime)}.';
  }

  /// Get reminder message
  String _getReminderMessage(Reservation reservation, Duration beforeTime) {
    final hours = beforeTime.inHours;
    return 'Reminder: Your reservation is in $hours ${hours == 1 ? 'hour' : 'hours'} (${_formatDateTime(reservation.reservationTime)}).';
  }

  /// Get cancellation message
  String _getCancellationMessage(Reservation reservation) {
    return 'Your reservation for ${_formatDateTime(reservation.reservationTime)} has been cancelled.';
  }

  /// Format date/time for display
  String _formatDateTime(DateTime dateTime) {
    // Simple formatting - can be enhanced with proper date formatting
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Sync queued notifications when device comes online
  ///
  /// **Offline-First Pattern:**
  /// - Called when device comes online
  /// - Syncs queued notifications to cloud
  /// - Syncs queued FCM token storage
  /// - Processes queued FCM notification requests
  Future<void> syncQueuedNotifications() async {
    if (!_supabaseService.isAvailable) {
      developer.log(
        'Device offline, skipping notification sync',
        name: _logName,
      );
      return;
    }

    try {
      developer.log(
        'Syncing queued notifications...',
        name: _logName,
      );

      // Sync queued FCM token if available
      final fcmTokenKey = 'fcm_token_queue';
      final queuedToken = _storageService.getString(fcmTokenKey);
      if (queuedToken != null && queuedToken.isNotEmpty) {
        try {
          await _storeFCMToken(queuedToken);
          await _storageService.remove(fcmTokenKey);
          developer.log(
            '✅ Queued FCM token synced',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            'Error syncing queued FCM token: $e',
            name: _logName,
            error: e,
          );
        }
      }

      // Sync queued notifications
      final allKeys = _storageService.getKeys().toList();
      final notificationQueueKeys = allKeys
          .where((key) => key.startsWith('notification_queue_'))
          .toList();

      int syncedCount = 0;
      for (final key in notificationQueueKeys) {
        try {
          final notificationJson = _storageService.getString(key);
          if (notificationJson == null) continue;

          final notificationData = jsonDecode(notificationJson) as Map<String, dynamic>;
          final client = _supabaseService.client;

          await client.from('notifications').insert({
            'user_id': notificationData['reservationId'], // Placeholder - should use agentId lookup
            'type': 'reservation_${notificationData['type']}',
            'title': notificationData['title'],
            'body': notificationData['body'],
            'data': {
              'reservationId': notificationData['reservationId'],
            },
            'created_at': notificationData['createdAt'],
          });

          await _storageService.remove(key);
          syncedCount++;
        } catch (e) {
          developer.log(
            'Error syncing queued notification $key: $e',
            name: _logName,
            error: e,
          );
          // Continue with next notification
        }
      }

      // Process queued FCM notification requests (send to backend)
      final fcmQueueKeys = allKeys
          .where((key) => key.startsWith('fcm_notification_queue_'))
          .toList();

      for (final key in fcmQueueKeys) {
        try {
          final requestJson = _storageService.getString(key);
          if (requestJson == null) continue;

          final requestData = jsonDecode(requestJson) as Map<String, dynamic>;
          // TODO: Send FCM notification request to backend API
          // Backend will send push notification to device
          // For now, just log and remove from queue
          developer.log(
            'FCM notification request processed: ${requestData['reservationId']}',
            name: _logName,
          );
          await _storageService.remove(key);
        } catch (e) {
          developer.log(
            'Error processing FCM notification request $key: $e',
            name: _logName,
            error: e,
          );
          // Continue with next request
        }
      }

      developer.log(
        '✅ Synced $syncedCount queued notifications',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing queued notifications: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get FCM token (for backend registration)
  ///
  /// Returns FCM token if available, null otherwise
  String? getFCMToken() => _fcmToken;

  /// Check if FCM is initialized and available
  bool get isFCMAvailable => _fcmInitialized && _userOptedIntoPush;
}

// Top-level function for FCM background message handling
// Required for FCM to handle messages when app is in background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(fcm.RemoteMessage message) async {
  developer.log(
    'FCM background message received: ${message.messageId}',
    name: 'ReservationNotificationService',
  );
  
  // Background messages are handled by FCM automatically
  // Local notifications will be shown by the system
  // This handler is required for FCM to work in background
}
