import 'package:spots/core/models/expertise_event.dart';

/// Event Waiver Class
/// 
/// Generates event-specific liability waivers for attendees.
/// Used for legal protection and risk management.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to safe event participation
/// - Enables legal protection for all parties
/// - Supports responsible event hosting
/// 
/// **Usage:**
/// ```dart
/// final waiver = EventWaiver.generateWaiver(event);
/// // Display waiver to user before event registration
/// ```
class EventWaiver {
  /// Generate waiver text for an event
  static String generateWaiver(ExpertiseEvent event) {
    final eventTitle = event.title;
    final eventDate = event.startTime.toString();
    final eventLocation = event.location ?? 'Location TBD';
    final eventType = event.getEventTypeDisplayName();

    return '''
EVENT PARTICIPATION WAIVER AND RELEASE OF LIABILITY

Event: $eventTitle
Event Type: $eventType
Date: $eventDate
Location: $eventLocation

I understand that participation in this event involves inherent risks, including but not limited to:
- Physical injury or harm
- Property damage or loss
- Acts of nature or weather
- Actions of other participants
- Transportation risks

I AGREE TO:
1. Assume all risks of participation in this event
2. Release SPOTS, event organizers, hosts, and partners from all liability
3. Not hold SPOTS responsible for any injuries, damages, or losses
4. Follow all safety guidelines and instructions provided
5. Leave the event if asked by organizers or hosts
6. Be responsible for my own safety and well-being

I UNDERSTAND:
- SPOTS is a platform connecting hosts and attendees only
- This event is organized by independent hosts, not SPOTS
- SPOTS does not control event quality, safety, or execution
- Emergency services: Call 911 if needed
- Photo/video consent: I may be photographed or recorded during the event

ACKNOWLEDGMENT:
By clicking "I Agree" or participating in this event, I confirm that:
- I have read and understand this waiver
- I voluntarily assume all risks associated with participation
- I release SPOTS and all parties from liability
- I am of legal age to enter into this agreement (or have guardian consent)

This waiver is binding and applies to me, my heirs, and assigns.

[I Agree Button]
''';
  }

  /// Generate simplified waiver for low-risk events
  static String generateSimplifiedWaiver(ExpertiseEvent event) {
    final eventTitle = event.title;
    final eventDate = event.startTime.toString();

    return '''
PARTICIPATION ACKNOWLEDGMENT

Event: $eventTitle
Date: $eventDate

By participating in this event, I acknowledge that:
- I participate at my own risk
- SPOTS is a platform only and not responsible for event quality or safety
- I will follow all safety guidelines

[I Agree Button]
''';
  }

  /// Check if event requires full waiver (vs. simplified)
  static bool requiresFullWaiver(ExpertiseEvent event) {
    // High-risk event types require full waiver
    // This can be enhanced based on event type, location, activity level
    return event.eventType == ExpertiseEventType.tour ||
        event.eventType == ExpertiseEventType.walk ||
        event.maxAttendees > 50; // Large events
  }

  /// Get waiver type for event
  static String getWaiverType(ExpertiseEvent event) {
    return requiresFullWaiver(event) ? 'full' : 'simplified';
  }
}

