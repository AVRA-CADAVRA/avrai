/// Cancellation Initiator Enum
/// 
/// Represents who initiated the cancellation.
/// 
/// **Initiators:**
/// - `attendee`: Attendee cancelled their ticket
/// - `host`: Event host cancelled the event
/// - `venue`: Venue cancelled (if applicable)
/// - `weather`: Weather-related cancellation (force majeure)
/// - `platform`: Platform cancelled (safety, policy violation, etc.)
enum CancellationInitiator {
  attendee,
  host,
  venue,
  weather,
  platform;

  /// Get display name for cancellation initiator
  String get displayName {
    switch (this) {
      case CancellationInitiator.attendee:
        return 'Attendee';
      case CancellationInitiator.host:
        return 'Host';
      case CancellationInitiator.venue:
        return 'Venue';
      case CancellationInitiator.weather:
        return 'Weather';
      case CancellationInitiator.platform:
        return 'Platform';
    }
  }

  /// Check if this is a force majeure cancellation
  bool get isForceMajeure =>
      this == CancellationInitiator.weather ||
      this == CancellationInitiator.platform;

  /// Check if this is a host-initiated cancellation
  bool get isHostInitiated => this == CancellationInitiator.host;

  /// Check if this is an attendee-initiated cancellation
  bool get isAttendeeInitiated => this == CancellationInitiator.attendee;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static CancellationInitiator fromJson(String value) {
    return CancellationInitiator.values.firstWhere(
      (initiator) => initiator.name == value,
      orElse: () => CancellationInitiator.attendee,
    );
  }
}

