import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:spots_core/spots_core.dart';
import '../../interfaces/realtime_backend.dart';

/// Supabase realtime backend implementation
class SupabaseRealtimeBackend implements RealtimeBackend {
  final SupabaseClient _client;
  bool _isInitialized = false;
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final _connectionStatusController = StreamController<RealtimeConnectionStatus>.broadcast();
  RealtimeConnectionStatus _connectionStatus = RealtimeConnectionStatus.disconnected;
  
  SupabaseRealtimeBackend(this._client);
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _isInitialized = true;
  }
  
  @override
  Future<void> dispose() async {
    await unsubscribeAll();
    await _connectionStatusController.close();
    _isInitialized = false;
  }
  
  // Domain-specific subscriptions
  @override
  Stream<User?> subscribeToUser(String userId) {
    return subscribeToDocument<User>(
      'users',
      userId,
      (json) => User.fromJson(json),
    );
  }
  
  @override
  Stream<Spot?> subscribeToSpot(String spotId) {
    return subscribeToDocument<Spot>(
      'spots',
      spotId,
      (json) => Spot.fromJson(json),
    );
  }
  
  @override
  Stream<SpotList?> subscribeToSpotList(String listId) {
    return subscribeToDocument<SpotList>(
      'spot_lists',
      listId,
      (json) => SpotList.fromJson(json),
    );
  }
  
  @override
  Stream<List<Spot>> subscribeToSpotsInList(String listId) {
    return subscribeToCollection<Spot>(
      'spots',
      (json) => Spot.fromJson(json),
      filters: {'listId': listId},
    );
  }
  
  @override
  Stream<List<Spot>> subscribeToNearbySpots(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    // Note: This would need PostGIS or client-side filtering
    // For now, subscribe to all spots and filter client-side
    return subscribeToCollection<Spot>(
      'spots',
      (json) => Spot.fromJson(json),
    ).map((spots) {
      return spots.where((spot) {
        final distance = spot.distanceFrom(latitude, longitude);
        return distance <= radiusKm;
      }).toList();
    });
  }
  
  @override
  Stream<List<SpotList>> subscribeToUserLists(String userId) {
    return subscribeToCollection<SpotList>(
      'spot_lists',
      (json) => SpotList.fromJson(json),
      filters: {'curatorId': userId},
    );
  }
  
  @override
  Stream<List<Spot>> subscribeToUserRespectedSpots(String userId) {
    // This would need a join or separate query
    // For now, subscribe to all spots and filter client-side
    return subscribeToCollection<Spot>(
      'spots',
      (json) => Spot.fromJson(json),
    ).map((spots) {
      return spots.where((spot) => spot.respectedBy.contains(userId)).toList();
    });
  }
  
  @override
  Stream<List<T>> subscribeToCollection<T>(
    String collection,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? descending,
    int? limit,
  }) {
    final channelName = 'collection:$collection';
    final controller = StreamController<List<T>>.broadcast();
    
    // Get initial data
    _client.from(collection).select().then((data) {
      final items = (data as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
      controller.add(items);
        });
    
    // Subscribe to changes
    final channel = _client.channel(channelName);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: collection,
      callback: (payload) {
        // Refetch data on change
        _client.from(collection).select().then((data) {
          final items = (data as List)
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();
          controller.add(items);
                });
      },
    ).subscribe();
    
    _activeChannels[channelName] = channel;
    
    return controller.stream;
  }
  
  @override
  Stream<T?> subscribeToDocument<T>(
    String collection,
    String documentId,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final channelName = 'document:$collection:$documentId';
    final controller = StreamController<T?>.broadcast();
    
    // Get initial data
    _client.from(collection)
        .select()
        .eq('id', documentId)
        .maybeSingle()
        .then((data) {
      if (data != null) {
        controller.add(fromJson(data));
      } else {
        controller.add(null);
      }
    });
    
    // Subscribe to changes
    final channel = _client.channel(channelName);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: collection,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: documentId,
      ),
      callback: (payload) {
        controller.add(fromJson(payload.newRecord!));
            },
    ).subscribe();
    
    _activeChannels[channelName] = channel;
    
    return controller.stream;
  }
  
  @override
  Stream<List<UserPresence>> subscribeToPresence(String channelId) {
    final channel = _getOrCreateChannel('presence:$channelId');
    final controller = StreamController<List<UserPresence>>.broadcast();
    
    channel.onPresenceSync((payload) {
      final presences = <UserPresence>[];
      
      // Parse presence state from payload
      // Convert presence state to UserPresence list
      // This is a simplified implementation
      try {
        // Supabase presence format may vary
        controller.add(presences);
      } catch (e) {
        // Handle error
      }
        });
    
    // Listen to presence changes via broadcast
    channel.onBroadcast(
      event: 'presence',
      callback: (payload, [ref]) {
        try {
          final presence = UserPresence.fromJson(payload);
          // Get current state and update
          final currentPresences = <UserPresence>[];
          currentPresences.add(presence);
          controller.add(currentPresences);
                } catch (e) {
          // Handle error
        }
      },
    );
    
    return controller.stream;
  }
  
  @override
  Future<void> updatePresence(String channelId, UserPresence presence) async {
    final channel = _getOrCreateChannel('presence:$channelId');
    await channel.track(presence.toJson());
  }
  
  @override
  Future<void> removePresence(String channelId) async {
    final channel = _activeChannels['presence:$channelId'];
    if (channel != null) {
      await channel.untrack();
    }
  }
  
  @override
  Stream<RealtimeMessage> subscribeToMessages(String channelId) {
    final channel = _getOrCreateChannel('messages:$channelId');
    final controller = StreamController<RealtimeMessage>.broadcast();
    
    channel.onBroadcast(
      event: 'message',
      callback: (payload, [ref]) {
        controller.add(RealtimeMessage.fromJson(payload));
      },
    );
    
    return controller.stream;
  }
  
  @override
  Future<void> sendMessage(String channelId, RealtimeMessage message) async {
    final channel = _getOrCreateChannel('messages:$channelId');
    await channel.sendBroadcastMessage(
      event: 'message',
      payload: message.toJson(),
    );
  }
  
  @override
  Stream<List<LiveCursor>> subscribeToLiveCursors(String documentId) {
    final channel = _getOrCreateChannel('cursors:$documentId');
    final controller = StreamController<List<LiveCursor>>.broadcast();
    
    channel.onBroadcast(
      event: 'cursor_update',
      callback: (payload, [ref]) {
        // Collect all cursors from presence or broadcast
        final cursors = <LiveCursor>[];
        // This would need to aggregate cursor data
        controller.add(cursors);
      },
    );
    
    return controller.stream;
  }
  
  @override
  Future<void> updateLiveCursor(String documentId, LiveCursor cursor) async {
    final channel = _getOrCreateChannel('cursors:$documentId');
    await channel.sendBroadcastMessage(
      event: 'cursor_update',
      payload: cursor.toJson(),
    );
  }
  
  @override
  Future<void> unsubscribe(String subscriptionId) async {
    final channel = _activeChannels[subscriptionId];
    if (channel != null) {
      await channel.unsubscribe();
      _activeChannels.remove(subscriptionId);
    }
    
    final subscription = _subscriptions[subscriptionId];
    if (subscription != null) {
      await subscription.cancel();
      _subscriptions.remove(subscriptionId);
    }
  }
  
  @override
  Future<void> unsubscribeAll() async {
    for (final channel in _activeChannels.values) {
      await channel.unsubscribe();
    }
    _activeChannels.clear();
    
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
  
  @override
  Stream<RealtimeConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  
  @override
  Future<void> connect() async {
    _updateConnectionStatus(RealtimeConnectionStatus.connecting);
    // Supabase realtime connects automatically when channels are subscribed
    _updateConnectionStatus(RealtimeConnectionStatus.connected);
  }
  
  @override
  Future<void> disconnect() async {
    _updateConnectionStatus(RealtimeConnectionStatus.disconnecting);
    await unsubscribeAll();
    _updateConnectionStatus(RealtimeConnectionStatus.disconnected);
  }
  
  @override
  Future<void> joinChannel(String channelId) async {
    final channel = _getOrCreateChannel(channelId);
    await channel.subscribe();
  }
  
  @override
  Future<void> leaveChannel(String channelId) async {
    await unsubscribe(channelId);
  }
  
  @override
  Future<void> trackRealtimeEvent(String eventName, Map<String, dynamic> data) async {
    // Track analytics events - could use Supabase analytics or custom table
    try {
      await _client.from('realtime_events').insert({
        'event_name': eventName,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail analytics tracking
    }
  }
  
  // Helper methods
  RealtimeChannel _getOrCreateChannel(String channelName) {
    if (_activeChannels.containsKey(channelName)) {
      return _activeChannels[channelName]!;
    }
    
    final channel = _client.channel(channelName);
    _activeChannels[channelName] = channel;
    return channel;
  }
  
  void _updateConnectionStatus(RealtimeConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }
}
