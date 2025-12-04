import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_intent.dart';
import 'package:spots/core/models/payment_result.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/geographic_scope.dart';
import 'package:spots/core/models/locality.dart';
import 'package:spots/core/models/large_city.dart';
import 'package:spots/core/models/locality_value.dart';
import 'package:spots/core/models/local_expert_qualification.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import '../fixtures/model_factories.dart';
import 'test_helpers.dart';

/// Integration Test Helpers
/// 
/// Provides utilities for integration testing including:
/// - Event creation helpers
/// - Payment test helpers  
/// - User creation helpers with expertise
/// - Mock services setup
/// 
/// **Usage:**
/// ```dart
/// final event = IntegrationTestHelpers.createTestEvent(
///   host: user,
///   category: 'Coffee',
/// );
/// ```
class IntegrationTestHelpers {
  // ======= Event Creation Helpers =======

  /// Create a test event with default or custom properties
  /// 
  /// **Usage:**
  /// ```dart
  /// final event = IntegrationTestHelpers.createTestEvent(
  ///   host: hostUser,
  ///   title: 'Coffee Tour',
  ///   category: 'Coffee',
  ///   eventType: ExpertiseEventType.tour,
  ///   price: 25.00,
  /// );
  /// ```
  static ExpertiseEvent createTestEvent({
    required UnifiedUser host,
    String? id,
    String? title,
    String? description,
    String? category,
    ExpertiseEventType? eventType,
    DateTime? startTime,
    DateTime? endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    int? maxAttendees,
    double? price,
    bool? isPaid,
    bool? isPublic,
    EventStatus? status,
    List<String>? attendeeIds,
  }) {
    final now = TestHelpers.createTestDateTime();
    final eventStartTime = startTime ?? now.add(const Duration(days: 1));
    final eventEndTime = endTime ?? eventStartTime.add(const Duration(hours: 2));

    return ExpertiseEvent(
      id: id ?? 'test-event-${now.millisecondsSinceEpoch}',
      title: title ?? 'Test Event',
      description: description ?? 'A test event for integration testing',
      category: category ?? 'General',
      eventType: eventType ?? ExpertiseEventType.tour,
      host: host,
      attendeeIds: attendeeIds ?? [],
      attendeeCount: attendeeIds?.length ?? 0,
      maxAttendees: maxAttendees ?? 20,
      startTime: eventStartTime,
      endTime: eventEndTime,
      spots: spots ?? [],
      location: location,
      latitude: latitude,
      longitude: longitude,
      price: price,
      isPaid: isPaid ?? (price != null && price > 0),
      isPublic: isPublic ?? true,
      createdAt: now,
      updatedAt: now,
      status: status ?? EventStatus.upcoming,
    );
  }

  /// Create a paid event
  static ExpertiseEvent createPaidEvent({
    required UnifiedUser host,
    double? price,
    String? category,
  }) {
    return createTestEvent(
      host: host,
      category: category ?? 'Coffee',
      price: price ?? 25.00,
      isPaid: true,
    );
  }

  /// Create a free event
  static ExpertiseEvent createFreeEvent({
    required UnifiedUser host,
    String? category,
  }) {
    return createTestEvent(
      host: host,
      category: category ?? 'Coffee',
      price: 0.0,
      isPaid: false,
    );
  }

  /// Create event with specific expertise category
  static ExpertiseEvent createEventWithCategory({
    required UnifiedUser host,
    required String category,
    ExpertiseEventType? eventType,
  }) {
    // Ensure host has expertise in category
    final hostWithExpertise = host.copyWith(
      expertiseMap: Map<String, String>.from(host.expertiseMap)
        ..[category] = 'city', // City level (can host in all localities in city)
    );

    return createTestEvent(
      host: hostWithExpertise,
      category: category,
      eventType: eventType,
    );
  }

  /// Create event with spots
  static ExpertiseEvent createEventWithSpots({
    required UnifiedUser host,
    List<Spot>? spots,
    String? category,
  }) {
    final eventSpots = spots ?? [
      ModelFactories.createTestSpot(name: 'Spot 1', category: category),
      ModelFactories.createTestSpot(name: 'Spot 2', category: category),
      ModelFactories.createTestSpot(name: 'Spot 3', category: category),
    ];

    return createTestEvent(
      host: host,
      spots: eventSpots,
      category: category ?? 'Coffee',
    );
  }

  /// Create event with attendees
  static ExpertiseEvent createEventWithAttendees({
    required UnifiedUser host,
    List<String>? attendeeIds,
    int? maxAttendees,
  }) {
    final attendees = attendeeIds ?? [
      'attendee-1',
      'attendee-2',
      'attendee-3',
    ];

    return createTestEvent(
      host: host,
      attendeeIds: attendees,
      maxAttendees: maxAttendees ?? 20,
    );
  }

  /// Create full event (at capacity)
  static ExpertiseEvent createFullEvent({
    required UnifiedUser host,
    int? maxAttendees,
  }) {
    final max = maxAttendees ?? 5;
    final attendees = List.generate(max, (index) => 'attendee-$index');

    return createTestEvent(
      host: host,
      attendeeIds: attendees,
      maxAttendees: max,
    );
  }

  // ======= Payment Test Helpers =======

  /// Create a test payment with default or custom properties
  /// 
  /// **Usage:**
  /// ```dart
  /// final payment = IntegrationTestHelpers.createTestPayment(
  ///   eventId: 'event-123',
  ///   userId: 'user-456',
  ///   amount: 25.00,
  ///   status: PaymentStatus.completed,
  /// );
  /// ```
  static Payment createTestPayment({
    required String eventId,
    required String userId,
    String? id,
    double? amount,
    PaymentStatus? status,
    String? stripePaymentIntentId,
    int? quantity,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = TestHelpers.createTestDateTime();
    return Payment(
      id: id ?? 'payment-${now.millisecondsSinceEpoch}',
      eventId: eventId,
      userId: userId,
      amount: amount ?? 25.00,
      status: status ?? PaymentStatus.completed,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      stripePaymentIntentId: stripePaymentIntentId,
      quantity: quantity ?? 1,
      metadata: metadata ?? {},
    );
  }

  /// Create successful payment
  static Payment createSuccessfulPayment({
    required String eventId,
    required String userId,
    double? amount,
  }) {
    return createTestPayment(
      eventId: eventId,
      userId: userId,
      amount: amount,
      status: PaymentStatus.completed,
      stripePaymentIntentId: 'pi_test_success',
    );
  }

  /// Create pending payment
  static Payment createPendingPayment({
    required String eventId,
    required String userId,
    double? amount,
  }) {
    return createTestPayment(
      eventId: eventId,
      userId: userId,
      amount: amount,
      status: PaymentStatus.pending,
    );
  }

  /// Create failed payment
  static Payment createFailedPayment({
    required String eventId,
    required String userId,
    double? amount,
    PaymentStatus? failureStatus,
  }) {
    return createTestPayment(
      eventId: eventId,
      userId: userId,
      amount: amount,
      status: failureStatus ?? PaymentStatus.failed,
    );
  }

  /// Create test payment intent
  static PaymentIntent createTestPaymentIntent({
    String? id,
    String? clientSecret,
    int? amount,
    String? currency,
    PaymentStatus? status,
    String? eventId,
    String? userId,
    DateTime? createdAt,
  }) {
    final now = TestHelpers.createTestDateTime();
    return PaymentIntent(
      id: id ?? 'pi_test_${now.millisecondsSinceEpoch}',
      clientSecret: clientSecret ?? 'pi_test_secret_${now.millisecondsSinceEpoch}',
      amount: amount ?? 2500, // $25.00 in cents
      currency: currency ?? 'usd',
      status: status ?? PaymentStatus.pending,
      createdAt: createdAt ?? now,
      eventId: eventId,
      userId: userId,
    );
  }

  /// Create successful payment result
  static PaymentResult createSuccessfulPaymentResult({
    required Payment payment,
    PaymentIntent? paymentIntent,
    RevenueSplit? revenueSplit,
  }) {
    return PaymentResult.success(
      payment: payment,
      paymentIntent: paymentIntent,
      revenueSplit: revenueSplit,
    );
  }

  /// Create failed payment result
  static PaymentResult createFailedPaymentResult({
    required String errorMessage,
    String? errorCode,
    PaymentIntent? paymentIntent,
  }) {
    return PaymentResult.failure(
      errorMessage: errorMessage,
      errorCode: errorCode,
      paymentIntent: paymentIntent,
    );
  }

  /// Create test revenue split
  /// 
  /// **Default split:**
  /// - Platform Fee: 10% to SPOTS
  /// - Processing Fee: ~3% to Stripe (2.9% + $0.30 per transaction)
  /// - Host Payout: Remaining (~87%)
  /// 
  /// **Usage:**
  /// ```dart
  /// final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
  ///   eventId: 'event-123',
  ///   totalAmount: 100.00,
  ///   ticketsSold: 1,
  /// );
  /// ```
  static RevenueSplit createTestRevenueSplit({
    required String eventId,
    required double totalAmount,
    int ticketsSold = 1,
    DateTime? calculatedAt,
  }) {
    // Use the factory method to calculate correct split
    return RevenueSplit.calculate(
      eventId: eventId,
      totalAmount: totalAmount,
      ticketsSold: ticketsSold,
      calculatedAt: calculatedAt ?? TestHelpers.createTestDateTime(),
    );
  }

  // ======= User Creation Helpers (with Expertise) =======

  /// Create user with City level expertise (can host events in all localities in city)
  static UnifiedUser createUserWithCityExpertise({
    String? id,
    String? category,
    String? location,
  }) {
    final user = ModelFactories.createTestUser(id: id);
    final expertiseMap = Map<String, String>.from(user.expertiseMap);
    expertiseMap[category ?? 'Coffee'] = 'city';

    return user.copyWith(
      expertiseMap: expertiseMap,
      location: location,
    );
  }

  /// Create user with Local level expertise (can host events in locality)
  static UnifiedUser createUserWithLocalExpertise({
    String? id,
    String? category,
    String? location,
  }) {
    final user = ModelFactories.createTestUser(id: id);
    final expertiseMap = Map<String, String>.from(user.expertiseMap);
    expertiseMap[category ?? 'Coffee'] = 'local';

    return user.copyWith(
      expertiseMap: expertiseMap,
      location: location,
    );
  }

  /// Create user with specific expertise level
  static UnifiedUser createUserWithExpertise({
    String? id,
    required String category,
    required ExpertiseLevel level,
    String? location,
  }) {
    final user = ModelFactories.createTestUser(id: id);
    final expertiseMap = Map<String, String>.from(user.expertiseMap);
    expertiseMap[category] = level.name;

    return user.copyWith(
      expertiseMap: expertiseMap,
      location: location,
    );
  }

  /// Create user without event hosting capability (no expertise)
  static UnifiedUser createUserWithoutHosting({
    String? id,
    String? category,
  }) {
    final user = ModelFactories.createTestUser(id: id);
    // Don't add any expertise - user has no expertise, cannot host events
    return user;
  }

  /// Create expert user (City level+) for hosting events (can host in all localities in city)
  static UnifiedUser createExpertUser({
    String? id,
    List<String>? categories,
    String? location,
  }) {
    final user = ModelFactories.createTestUser(id: id);
    final expertiseMap = <String, String>{};
    final cats = categories ?? ['Coffee', 'Restaurants'];

    for (final category in cats) {
      expertiseMap[category] = 'city';
    }

    return user.copyWith(
      expertiseMap: expertiseMap,
      location: location,
    );
  }

  // ======= Test Scenarios =======

  /// Create complete payment scenario (event + payment + result)
  static Map<String, dynamic> createCompletePaymentScenario({
    required UnifiedUser host,
    required UnifiedUser attendee,
    double? ticketPrice,
    String? category,
  }) {
    final event = createPaidEvent(
      host: host,
      price: ticketPrice ?? 25.00,
      category: category ?? 'Coffee',
    );

    final payment = createSuccessfulPayment(
      eventId: event.id,
      userId: attendee.id,
      amount: ticketPrice ?? 25.00,
    );

    final revenueSplit = createTestRevenueSplit(
      eventId: event.id,
      totalAmount: ticketPrice ?? 25.00,
      ticketsSold: 1,
    );

    final result = createSuccessfulPaymentResult(
      payment: payment,
      revenueSplit: revenueSplit,
    );

    return {
      'event': event,
      'payment': payment,
      'result': result,
      'revenueSplit': revenueSplit,
      'host': host,
      'attendee': attendee,
    };
  }

  /// Create event hosting scenario (expert user creates event)
  static Map<String, dynamic> createEventHostingScenario({
    required String category,
    String? eventType,
    List<Spot>? spots,
  }) {
    final host = createExpertUser(
      categories: [category],
    );

    final event = createEventWithCategory(
      host: host,
      category: category,
      eventType: eventType != null
          ? ExpertiseEventType.values.firstWhere(
              (e) => e.name == eventType.toLowerCase(),
              orElse: () => ExpertiseEventType.tour,
            )
          : null,
    );

    final eventWithSpots = spots != null
        ? event.copyWith(spots: spots)
        : createEventWithSpots(
            host: host,
            category: category,
          );

    return {
      'host': host,
      'event': eventWithSpots,
      'category': category,
    };
  }

  /// Create expertise progression scenario (user gaining expertise)
  static Map<String, dynamic> createExpertiseProgressionScenario({
    required String category,
  }) {
    final user = ModelFactories.createTestUser();
    final userLocal = createUserWithExpertise(
      id: user.id,
      category: category,
      level: ExpertiseLevel.local,
    );
    final userCity = createUserWithExpertise(
      id: user.id,
      category: category,
      level: ExpertiseLevel.city,
    );

    return {
      'user': user,
      'localLevel': userLocal,
      'cityLevel': userCity,
      'category': category,
      'canHostEvents': userCity.canHostEvents(),
    };
  }

  // ======= Test Data Collections =======

  /// Create multiple test events
  static List<ExpertiseEvent> createTestEvents({
    required UnifiedUser host,
    int count = 3,
    String? category,
  }) {
    return List.generate(count, (index) {
      return createTestEvent(
        host: host,
        id: 'event-$index',
        title: 'Test Event $index',
        category: category ?? 'Coffee',
        startTime: TestHelpers.createTestDateTime().add(Duration(days: index + 1)),
      );
    });
  }

  /// Create multiple test payments
  static List<Payment> createTestPayments({
    required String eventId,
    required String userId,
    int count = 3,
    double? amount,
  }) {
    return List.generate(count, (index) {
      return createTestPayment(
        eventId: eventId,
        userId: userId,
        id: 'payment-$index',
        amount: amount ?? 25.00,
      );
    });
  }

  // ======= Mock Service Helpers =======

  /// Setup mock payment service responses
  static Map<String, dynamic> setupMockPaymentResponses() {
    return {
      'success': true,
      'failure': false,
      'timeout': false,
      'networkError': false,
    };
  }

  /// Setup mock event service responses
  static Map<String, dynamic> setupMockEventResponses() {
    return {
      'created': true,
      'updated': true,
      'deleted': true,
      'capacityExceeded': false,
    };
  }

  // ======= Partnership Test Helpers =======

  /// Create a test partnership
  static EventPartnership createTestPartnership({
    String? id,
    required String eventId,
    required String userId,
    required String businessId,
    PartnershipStatus? status,
    double? vibeCompatibilityScore,
    bool? userApproved,
    bool? businessApproved,
    String? revenueSplitId,
    PartnershipType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = TestHelpers.createTestDateTime();
    return EventPartnership(
      id: id ?? 'test-partnership-${now.millisecondsSinceEpoch}',
      eventId: eventId,
      userId: userId,
      businessId: businessId,
      status: status ?? PartnershipStatus.pending,
      vibeCompatibilityScore: vibeCompatibilityScore ?? 0.80,
      userApproved: userApproved ?? false,
      businessApproved: businessApproved ?? false,
      revenueSplitId: revenueSplitId,
      type: type ?? PartnershipType.eventBased,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Create an approved partnership
  static EventPartnership createApprovedPartnership({
    required String eventId,
    required String userId,
    required String businessId,
    double? vibeCompatibilityScore,
  }) {
    return createTestPartnership(
      eventId: eventId,
      userId: userId,
      businessId: businessId,
      status: PartnershipStatus.approved,
      vibeCompatibilityScore: vibeCompatibilityScore,
      userApproved: true,
      businessApproved: true,
    );
  }

  /// Create a locked partnership (agreement finalized)
  static EventPartnership createLockedPartnership({
    required String eventId,
    required String userId,
    required String businessId,
    String? revenueSplitId,
  }) {
    return createTestPartnership(
      eventId: eventId,
      userId: userId,
      businessId: businessId,
      status: PartnershipStatus.locked,
      userApproved: true,
      businessApproved: true,
      revenueSplitId: revenueSplitId,
    );
  }

  // ======= Business Account Test Helpers =======

  /// Create a test business account
  static BusinessAccount createTestBusinessAccount({
    String? id,
    String? name,
    String? email,
    String? businessType,
    bool? isVerified,
    String? location,
    List<String>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    final now = TestHelpers.createTestDateTime();
    return BusinessAccount(
      id: id ?? 'test-business-${now.millisecondsSinceEpoch}',
      name: name ?? 'Test Business',
      email: email ?? 'test@business.com',
      businessType: businessType ?? 'Restaurant',
      isVerified: isVerified ?? false,
      location: location,
      categories: categories ?? [],
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      createdBy: createdBy ?? 'test-user',
    );
  }

  /// Create a verified business account
  static BusinessAccount createVerifiedBusinessAccount({
    String? id,
    String? name,
    String? businessType,
  }) {
    return createTestBusinessAccount(
      id: id,
      name: name,
      businessType: businessType,
      isVerified: true,
    );
  }

  // ======= Sponsorship Test Helpers =======

  /// Create a test sponsorship
  static Sponsorship createTestSponsorship({
    String? id,
    required String eventId,
    required String brandId,
    SponsorshipType? type,
    double? contributionAmount,
    double? productValue,
    SponsorshipStatus? status,
  }) {
    final now = TestHelpers.createTestDateTime();
    return Sponsorship(
      id: id ?? 'test-sponsor-${now.millisecondsSinceEpoch}',
      eventId: eventId,
      brandId: brandId,
      type: type ?? SponsorshipType.financial,
      contributionAmount: contributionAmount,
      productValue: productValue,
      status: status ?? SponsorshipStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a test brand account
  static BrandAccount createTestBrandAccount({
    String? id,
    String? name,
    String? brandType,
    BrandVerificationStatus? verificationStatus,
  }) {
    final now = TestHelpers.createTestDateTime();
    return BrandAccount(
      id: id ?? 'test-brand-${now.millisecondsSinceEpoch}',
      name: name ?? 'Test Brand',
      brandType: brandType ?? 'Food & Beverage',
      contactEmail: 'test@brand.com',
      verificationStatus: verificationStatus ?? BrandVerificationStatus.verified,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a test product tracking
  static ProductTracking createTestProductTracking({
    String? id,
    required String sponsorshipId,
    String? productName,
    int? quantityProvided,
    int? quantitySold,
    double? unitPrice,
  }) {
    final now = TestHelpers.createTestDateTime();
    return ProductTracking(
      id: id ?? 'test-product-track-${now.millisecondsSinceEpoch}',
      sponsorshipId: sponsorshipId,
      productName: productName ?? 'Test Product',
      quantityProvided: quantityProvided ?? 20,
      quantitySold: quantitySold ?? 0,
      unitPrice: unitPrice ?? 25.00,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Integration Test Constants
/// 
/// Common constants for integration tests
class IntegrationTestConstants {
  // Test User IDs
  static const String testHostId = 'test-host-123';
  static const String testAttendeeId = 'test-attendee-456';
  static const String testUserId = 'test-user-789';

  // Test Event IDs
  static const String testEventId = 'test-event-123';
  static const String testPaidEventId = 'test-paid-event-456';
  static const String testFreeEventId = 'test-free-event-789';

  // Test Payment IDs
  static const String testPaymentId = 'test-payment-123';
  static const String testPaymentIntentId = 'pi_test_1234567890';

  // Test Amounts
  static const double testTicketPrice = 25.00;
  static const double testEventPrice = 50.00;
  static const int testTicketPriceCents = 2500;

  // Test Locations
  static const String testLocation = 'New York, NY';
  static const double testLatitude = 40.7128;
  static const double testLongitude = -74.0060;

  // Test Categories
  static const String testCategoryCoffee = 'Coffee';
  static const String testCategoryRestaurants = 'Restaurants';
  static const String testCategoryBookstores = 'Bookstores';

  // Test Event Configurations
  static const int testMaxAttendees = 20;
  static const int testSmallMaxAttendees = 5;
  static const int testLargeMaxAttendees = 100;

  // Test Timestamps
  static DateTime get testStartTime => 
      TestHelpers.createTestDateTime().add(const Duration(days: 1));
  static DateTime get testEndTime => 
      testStartTime.add(const Duration(hours: 2));

  // ======= Geographic Scope Helpers =======

  /// Create GeographicScope for local expert (can host in their locality only)
  static GeographicScope createLocalExpertScope({
    required String userId,
    required String locality,
    String? city,
    String? state,
    String? country,
  }) {
    final now = TestHelpers.createTestDateTime();
    return GeographicScope(
      userId: userId,
      level: ExpertiseLevel.local,
      locality: locality,
      city: city,
      state: state,
      country: country,
      allowedLocalities: [locality],
      allowedCities: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create GeographicScope for city expert (can host in all localities in city)
  static GeographicScope createCityExpertScope({
    required String userId,
    required String city,
    required List<String> localities,
    String? state,
    String? country,
  }) {
    final now = TestHelpers.createTestDateTime();
    return GeographicScope(
      userId: userId,
      level: ExpertiseLevel.city,
      city: city,
      state: state,
      country: country,
      allowedLocalities: localities,
      allowedCities: [city],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create GeographicScope for regional+ expert (can host in any locality/city)
  static GeographicScope createRegionalExpertScope({
    required String userId,
    required ExpertiseLevel level,
    String? state,
    String? country,
  }) {
    final now = TestHelpers.createTestDateTime();
    return GeographicScope(
      userId: userId,
      level: level,
      state: state,
      country: country,
      allowedLocalities: [],
      allowedCities: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create Locality for testing
  static Locality createTestLocality({
    String? id,
    String? name,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    bool isNeighborhood = false,
    String? parentCity,
  }) {
    final now = TestHelpers.createTestDateTime();
    return Locality(
      id: id ?? 'locality-${now.millisecondsSinceEpoch}',
      name: name ?? 'Greenpoint',
      city: city,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      isNeighborhood: isNeighborhood,
      parentCity: parentCity,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create LargeCity for testing
  static LargeCity createTestLargeCity({
    String? id,
    String? name,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    int? population,
    double? geographicSizeKm2,
    List<String>? neighborhoods,
    bool isDetected = false,
  }) {
    final now = TestHelpers.createTestDateTime();
    return LargeCity(
      id: id ?? 'city-${now.millisecondsSinceEpoch}',
      name: name ?? 'Brooklyn',
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      population: population,
      geographicSizeKm2: geographicSizeKm2,
      neighborhoods: neighborhoods ?? [],
      isDetected: isDetected,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ======= Locality Value & Qualification Helpers =======

  /// Create LocalityValue for testing
  static LocalityValue createTestLocalityValue({
    String? id,
    String? locality,
    Map<String, double>? activityWeights,
    Map<String, Map<String, double>>? categoryPreferences,
    Map<String, int>? activityCounts,
  }) {
    final now = TestHelpers.createTestDateTime();
    return LocalityValue(
      id: id ?? 'value-${now.millisecondsSinceEpoch}',
      locality: locality ?? 'Greenpoint',
      activityWeights: activityWeights ??
          {
            'events_hosted': 0.20,
            'lists_created': 0.20,
            'reviews_written': 0.20,
            'event_attendance': 0.15,
            'professional_background': 0.15,
            'positive_trends': 0.10,
          },
      categoryPreferences: categoryPreferences ?? {},
      activityCounts: activityCounts ?? {},
      lastAnalyzed: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create LocalityValue with high event hosting weight (coffee-focused locality)
  static LocalityValue createCoffeeFocusedLocalityValue({
    String? locality,
  }) {
    return createTestLocalityValue(
      locality: locality ?? 'Greenpoint',
      activityWeights: {
        'events_hosted': 0.35, // High weight
        'lists_created': 0.25,
        'reviews_written': 0.20,
        'event_attendance': 0.15,
        'professional_background': 0.05,
        'positive_trends': 0.0,
      },
      activityCounts: {
        'events_hosted': 100,
        'lists_created': 50,
        'reviews_written': 200,
      },
    );
  }

  /// Create LocalExpertQualification for testing
  static LocalExpertQualification createTestQualification({
    String? id,
    String? userId,
    String? category,
    String? locality,
    ExpertiseLevel? currentLevel,
    ThresholdValues? baseThresholds,
    ThresholdValues? localityThresholds,
    QualificationProgress? progress,
    QualificationFactors? factors,
    bool isQualified = false,
  }) {
    final now = TestHelpers.createTestDateTime();

    final base = baseThresholds ??
        const ThresholdValues(
          minVisits: 10,
          minRatings: 5,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
          minCommunityEngagement: 3,
          minListCuration: 2,
          minEventHosting: 1,
        );

    final local = localityThresholds ??
        const ThresholdValues(
          minVisits: 7,
          minRatings: 4,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
          minCommunityEngagement: 2,
          minListCuration: 1,
          minEventHosting: 1,
        );

    return LocalExpertQualification(
      id: id ?? 'qual-${now.millisecondsSinceEpoch}',
      userId: userId ?? 'user-123',
      category: category ?? 'Coffee',
      locality: locality ?? 'Greenpoint',
      currentLevel: currentLevel ?? ExpertiseLevel.local,
      baseThresholds: base,
      localityThresholds: local,
      progress: progress ?? const QualificationProgress(),
      factors: factors ?? const QualificationFactors(),
      isQualified: isQualified,
      qualifiedAt: isQualified ? now : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create QualificationProgress for testing
  static QualificationProgress createTestProgress({
    int visits = 0,
    int ratings = 0,
    double avgRating = 0.0,
    int communityEngagement = 0,
    int listCuration = 0,
    int eventHosting = 0,
    int eventAttendance = 0,
  }) {
    return QualificationProgress(
      visits: visits,
      ratings: ratings,
      avgRating: avgRating,
      communityEngagement: communityEngagement,
      listCuration: listCuration,
      eventHosting: eventHosting,
      eventAttendance: eventAttendance,
    );
  }

  /// Create QualificationFactors for testing
  static QualificationFactors createTestFactors({
    int listsWithFollowers = 0,
    int peerReviewedReviews = 0,
    bool hasProfessionalBackground = false,
    bool hasPositiveTrends = false,
    double listRespectRate = 0.0,
    double eventGrowthRate = 0.0,
  }) {
    return QualificationFactors(
      listsWithFollowers: listsWithFollowers,
      peerReviewedReviews: peerReviewedReviews,
      hasProfessionalBackground: hasProfessionalBackground,
      hasPositiveTrends: hasPositiveTrends,
      listRespectRate: listRespectRate,
      eventGrowthRate: eventGrowthRate,
    );
  }
}

