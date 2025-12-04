import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import '../helpers/integration_test_helpers.dart';
import 'model_factories.dart';

/// Integration Test Fixtures
/// 
/// Pre-configured test data for common integration test scenarios.
/// Provides ready-to-use test objects for end-to-end testing.
/// 
/// **Usage:**
/// ```dart
/// final scenario = IntegrationTestFixtures.paymentFlowScenario();
/// final event = scenario['event'] as ExpertiseEvent;
/// final host = scenario['host'] as UnifiedUser;
/// ```
class IntegrationTestFixtures {
  // ======= Event Fixtures =======

  /// Complete event hosting scenario
  /// 
  /// Returns a map with:
  /// - `host`: Expert user with City level expertise (can host in all localities in city)
  /// - `event`: Paid event ready for hosting
  /// - `category`: Event category
  static Map<String, dynamic> eventHostingScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
      categories: [IntegrationTestConstants.testCategoryCoffee],
      location: IntegrationTestConstants.testLocation,
    );

    final event = IntegrationTestHelpers.createPaidEvent(
      host: host,
      price: IntegrationTestConstants.testTicketPrice,
      category: IntegrationTestConstants.testCategoryCoffee,
    );

    return {
      'host': host,
      'event': event,
      'category': IntegrationTestConstants.testCategoryCoffee,
    };
  }

  /// Free event hosting scenario
  static Map<String, dynamic> freeEventHostingScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
      categories: [IntegrationTestConstants.testCategoryRestaurants],
    );

    final event = IntegrationTestHelpers.createFreeEvent(
      host: host,
      category: IntegrationTestConstants.testCategoryRestaurants,
    );

    return {
      'host': host,
      'event': event,
      'category': IntegrationTestConstants.testCategoryRestaurants,
    };
  }

  /// Event with multiple spots
  static Map<String, dynamic> eventWithSpotsScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      categories: [IntegrationTestConstants.testCategoryCoffee],
    );

    final spots = [
      ModelFactories.createTestSpot(
        name: 'Coffee Shop A',
        category: IntegrationTestConstants.testCategoryCoffee,
      ),
      ModelFactories.createTestSpot(
        name: 'Coffee Shop B',
        category: IntegrationTestConstants.testCategoryCoffee,
      ),
      ModelFactories.createTestSpot(
        name: 'Coffee Shop C',
        category: IntegrationTestConstants.testCategoryCoffee,
      ),
    ];

    final event = IntegrationTestHelpers.createEventWithSpots(
      host: host,
      spots: spots,
      category: IntegrationTestConstants.testCategoryCoffee,
    );

    return {
      'host': host,
      'event': event,
      'spots': spots,
    };
  }

  /// Event at capacity (full)
  static Map<String, dynamic> fullEventScenario() {
    final host = IntegrationTestHelpers.createExpertUser();
    final event = IntegrationTestHelpers.createFullEvent(
      host: host,
      maxAttendees: IntegrationTestConstants.testSmallMaxAttendees,
    );

    return {
      'host': host,
      'event': event,
      'isFull': true,
    };
  }

  // ======= Payment Flow Fixtures =======

  /// Complete payment flow scenario
  /// 
  /// Returns a map with:
  /// - `event`: Paid event
  /// - `host`: Event host
  /// - `attendee`: User purchasing ticket
  /// - `payment`: Successful payment
  /// - `paymentIntent`: Payment intent
  /// - `result`: Payment result
  /// - `revenueSplit`: Revenue split calculation
  static Map<String, dynamic> paymentFlowScenario() {
    return IntegrationTestHelpers.createCompletePaymentScenario(
      host: IntegrationTestHelpers.createExpertUser(
        id: IntegrationTestConstants.testHostId,
        categories: [IntegrationTestConstants.testCategoryCoffee],
      ),
      attendee: ModelFactories.createTestUser(
        id: IntegrationTestConstants.testAttendeeId,
      ),
      ticketPrice: IntegrationTestConstants.testTicketPrice,
      category: IntegrationTestConstants.testCategoryCoffee,
    );
  }

  /// Payment failure scenario
  static Map<String, dynamic> paymentFailureScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
    );
    final attendee = ModelFactories.createTestUser(
      id: IntegrationTestConstants.testAttendeeId,
    );

    final event = IntegrationTestHelpers.createPaidEvent(
      host: host,
      price: IntegrationTestConstants.testTicketPrice,
    );

    final payment = IntegrationTestHelpers.createFailedPayment(
      eventId: event.id,
      userId: attendee.id,
      amount: IntegrationTestConstants.testTicketPrice,
    );

    final result = IntegrationTestHelpers.createFailedPaymentResult(
      errorMessage: 'Card declined',
      errorCode: 'card_declined',
    );

    return {
      'event': event,
      'host': host,
      'attendee': attendee,
      'payment': payment,
      'result': result,
      'isFailure': true,
    };
  }

  /// Pending payment scenario
  static Map<String, dynamic> pendingPaymentScenario() {
    final host = IntegrationTestHelpers.createExpertUser();
    final attendee = ModelFactories.createTestUser();

    final event = IntegrationTestHelpers.createPaidEvent(
      host: host,
      price: IntegrationTestConstants.testTicketPrice,
    );

    final payment = IntegrationTestHelpers.createPendingPayment(
      eventId: event.id,
      userId: attendee.id,
      amount: IntegrationTestConstants.testTicketPrice,
    );

    final paymentIntent = IntegrationTestHelpers.createTestPaymentIntent(
      eventId: event.id,
      userId: attendee.id,
      amount: IntegrationTestConstants.testTicketPriceCents,
      status: PaymentStatus.pending,
    );

    return {
      'event': event,
      'host': host,
      'attendee': attendee,
      'payment': payment,
      'paymentIntent': paymentIntent,
      'isPending': true,
    };
  }

  // ======= Expertise Progression Fixtures =======

  /// Expertise progression scenario
  /// 
  /// Shows user progression from no expertise to Local level (unlocking event hosting in locality)
  static Map<String, dynamic> expertiseProgressionScenario() {
    return IntegrationTestHelpers.createExpertiseProgressionScenario(
      category: IntegrationTestConstants.testCategoryCoffee,
    );
  }

  /// User without hosting capability
  static Map<String, dynamic> userWithoutHostingScenario() {
    final user = IntegrationTestHelpers.createUserWithoutHosting(
      category: IntegrationTestConstants.testCategoryCoffee,
    );

    return {
      'user': user,
      'canHostEvents': false,
      'category': IntegrationTestConstants.testCategoryCoffee,
    };
  }

  /// Expert user with hosting capability
  static Map<String, dynamic> expertUserScenario() {
    final user = IntegrationTestHelpers.createExpertUser(
      categories: [
        IntegrationTestConstants.testCategoryCoffee,
        IntegrationTestConstants.testCategoryRestaurants,
      ],
    );

    return {
      'user': user,
      'canHostEvents': true,
      'categories': [
        IntegrationTestConstants.testCategoryCoffee,
        IntegrationTestConstants.testCategoryRestaurants,
      ],
    };
  }

  // ======= Event Discovery Fixtures =======

  /// Multiple events for discovery testing
  static Map<String, dynamic> eventDiscoveryScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
      categories: [
        IntegrationTestConstants.testCategoryCoffee,
        IntegrationTestConstants.testCategoryRestaurants,
      ],
    );

    final events = [
      IntegrationTestHelpers.createTestEvent(
        host: host,
        title: 'Downtown Coffee Tour',
        category: IntegrationTestConstants.testCategoryCoffee,
        eventType: ExpertiseEventType.tour,
        price: 25.00,
        startTime: IntegrationTestConstants.testStartTime,
      ),
      IntegrationTestHelpers.createTestEvent(
        host: host,
        title: 'Brunch Spots Workshop',
        category: IntegrationTestConstants.testCategoryRestaurants,
        eventType: ExpertiseEventType.workshop,
        price: 30.00,
        startTime: IntegrationTestConstants.testStartTime.add(const Duration(days: 1)),
      ),
      IntegrationTestHelpers.createTestEvent(
        host: host,
        title: 'Bookstore Meetup',
        category: IntegrationTestConstants.testCategoryBookstores,
        eventType: ExpertiseEventType.meetup,
        price: 0.00, // Free
        startTime: IntegrationTestConstants.testStartTime.add(const Duration(days: 2)),
      ),
    ];

    return {
      'host': host,
      'events': events,
      'paidEvents': events.where((e) => e.isPaid).toList(),
      'freeEvents': events.where((e) => !e.isPaid).toList(),
    };
  }

  // ======= Complete User Journey Fixtures =======

  /// Complete user journey scenario
  /// 
  /// Scenario covering:
  /// 1. User discovers event
  /// 2. User registers for event (with payment)
  /// 3. User gains expertise
  /// 4. User hosts own event
  static Map<String, dynamic> completeUserJourneyScenario() {
    // Initial user (no expertise, can't host)
    final user = ModelFactories.createTestUser(
      id: IntegrationTestConstants.testUserId,
    );

    // Expert host with existing event
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
      categories: [IntegrationTestConstants.testCategoryCoffee],
    );

    final discoverableEvent = IntegrationTestHelpers.createPaidEvent(
      host: host,
      price: IntegrationTestConstants.testTicketPrice,
      category: IntegrationTestConstants.testCategoryCoffee,
    );

    // User purchases ticket (gains expertise)
    final payment = IntegrationTestHelpers.createSuccessfulPayment(
      eventId: discoverableEvent.id,
      userId: user.id,
      amount: IntegrationTestConstants.testTicketPrice,
    );

    // User progresses to Local level (can now host events in locality)
    final expertUser = IntegrationTestHelpers.createUserWithLocalExpertise(
      id: user.id,
      category: IntegrationTestConstants.testCategoryCoffee,
    );

    // User hosts own event
    final userHostedEvent = IntegrationTestHelpers.createTestEvent(
      host: expertUser,
      category: IntegrationTestConstants.testCategoryCoffee,
    );

    return {
      'user': user,
      'discoverableEvent': discoverableEvent,
      'payment': payment,
      'expertUser': expertUser,
      'userHostedEvent': userHostedEvent,
      'host': host,
    };
  }

  // ======= Partnership Flow Fixtures =======

  /// Complete partnership flow scenario
  /// 
  /// Returns a map with:
  /// - `event`: Event for partnership
  /// - `host`: Event host
  /// - `business`: Business partner
  /// - `partnership`: Created partnership
  static Map<String, dynamic> partnershipFlowScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
      categories: [IntegrationTestConstants.testCategoryCoffee],
    );
    final business = IntegrationTestHelpers.createVerifiedBusinessAccount(
      id: 'business-123',
      name: 'Test Restaurant',
    );
    final event = IntegrationTestHelpers.createPaidEvent(
      host: host,
      price: IntegrationTestConstants.testTicketPrice,
      category: IntegrationTestConstants.testCategoryCoffee,
    );
    final partnership = IntegrationTestHelpers.createTestPartnership(
      eventId: event.id,
      userId: host.id,
      businessId: business.id,
      vibeCompatibilityScore: 0.85,
    );

    return {
      'event': event,
      'host': host,
      'business': business,
      'partnership': partnership,
    };
  }

  /// Approved partnership scenario
  static Map<String, dynamic> approvedPartnershipScenario() {
    final scenario = partnershipFlowScenario();
    final partnership = scenario['partnership'] as EventPartnership;
    final approved = IntegrationTestHelpers.createApprovedPartnership(
      eventId: partnership.eventId,
      userId: partnership.userId,
      businessId: partnership.businessId,
      vibeCompatibilityScore: partnership.vibeCompatibilityScore,
    );

    return {
      ...scenario,
      'partnership': approved,
      'isApproved': true,
    };
  }

  /// Locked partnership scenario (pre-event)
  static Map<String, dynamic> lockedPartnershipScenario() {
    final scenario = approvedPartnershipScenario();
    final partnership = scenario['partnership'] as EventPartnership;
    final locked = IntegrationTestHelpers.createLockedPartnership(
      eventId: partnership.eventId,
      userId: partnership.userId,
      businessId: partnership.businessId,
    );

    return {
      ...scenario,
      'partnership': locked,
      'isLocked': true,
    };
  }

  /// Multi-party partnership scenario
  static Map<String, dynamic> multiPartyPartnershipScenario() {
    final host = IntegrationTestHelpers.createExpertUser(
      id: IntegrationTestConstants.testHostId,
      categories: [IntegrationTestConstants.testCategoryCoffee],
    );
    final business1 = IntegrationTestHelpers.createVerifiedBusinessAccount(
      id: 'business-1',
      name: 'Restaurant A',
    );
    final business2 = IntegrationTestHelpers.createVerifiedBusinessAccount(
      id: 'business-2',
      name: 'Restaurant B',
    );
    final event = IntegrationTestHelpers.createPaidEvent(
      host: host,
      price: IntegrationTestConstants.testTicketPrice,
      category: IntegrationTestConstants.testCategoryCoffee,
    );
    final partnership1 = IntegrationTestHelpers.createTestPartnership(
      eventId: event.id,
      userId: host.id,
      businessId: business1.id,
      vibeCompatibilityScore: 0.85,
    );
    final partnership2 = IntegrationTestHelpers.createTestPartnership(
      eventId: event.id,
      userId: host.id,
      businessId: business2.id,
      vibeCompatibilityScore: 0.80,
    );

    return {
      'event': event,
      'host': host,
      'business1': business1,
      'business2': business2,
      'partnership1': partnership1,
      'partnership2': partnership2,
      'partnerships': [partnership1, partnership2],
    };
  }

  // ======= Payment Partnership Fixtures =======

  /// Payment with partnership scenario
  /// 
  /// Returns a map with:
  /// - `event`: Event with partnership
  /// - `host`: Event host
  /// - `business`: Business partner
  /// - `partnership`: Approved partnership
  /// - `payment`: Payment for event
  /// - `revenueSplit`: Revenue split calculation
  static Map<String, dynamic> paymentPartnershipScenario() {
    final scenario = approvedPartnershipScenario();
    final event = scenario['event'] as ExpertiseEvent;
    final attendee = ModelFactories.createTestUser(
      id: IntegrationTestConstants.testAttendeeId,
    );
    final payment = IntegrationTestHelpers.createSuccessfulPayment(
      eventId: event.id,
      userId: attendee.id,
      amount: IntegrationTestConstants.testTicketPrice,
    );
    final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
      eventId: event.id,
      totalAmount: IntegrationTestConstants.testTicketPrice,
      ticketsSold: 1,
    );

    return {
      ...scenario,
      'attendee': attendee,
      'payment': payment,
      'revenueSplit': revenueSplit,
    };
  }

  /// Complete partnership payment workflow scenario
  static Map<String, dynamic> partnershipPaymentWorkflowScenario() {
    final scenario = lockedPartnershipScenario();
    final event = scenario['event'] as ExpertiseEvent;
    final partnership = scenario['partnership'] as EventPartnership;
    final attendee = ModelFactories.createTestUser(
      id: IntegrationTestConstants.testAttendeeId,
    );
    final payment = IntegrationTestHelpers.createSuccessfulPayment(
      eventId: event.id,
      userId: attendee.id,
      amount: IntegrationTestConstants.testTicketPrice,
    );
    final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
      eventId: event.id,
      totalAmount: IntegrationTestConstants.testTicketPrice,
      ticketsSold: 1,
    );
    final partnershipWithSplit = partnership.copyWith(
      revenueSplitId: revenueSplit.id,
    );

    return {
      ...scenario,
      'partnership': partnershipWithSplit,
      'attendee': attendee,
      'payment': payment,
      'revenueSplit': revenueSplit,
    };
  }

  // ======= Business Flow Fixtures =======

  /// Business account creation scenario
  static Map<String, dynamic> businessAccountScenario() {
    final creator = ModelFactories.createTestUser(
      id: IntegrationTestConstants.testUserId,
    );
    final business = IntegrationTestHelpers.createTestBusinessAccount(
      id: 'business-123',
      name: 'Test Restaurant',
      email: 'test@restaurant.com',
      businessType: 'Restaurant',
      createdBy: creator.id,
    );

    return {
      'creator': creator,
      'business': business,
    };
  }

  /// Verified business account scenario
  static Map<String, dynamic> verifiedBusinessScenario() {
    final business = IntegrationTestHelpers.createVerifiedBusinessAccount(
      id: 'business-123',
      name: 'Verified Restaurant',
      businessType: 'Restaurant',
    );

    return {
      'business': business,
      'isVerified': true,
    };
  }

  // ======= Geographic Scope Fixtures =======

  /// Local expert scope fixture (Greenpoint locality)
  static Map<String, dynamic> localExpertScopeFixture() {
    final scope = IntegrationTestHelpers.createLocalExpertScope(
      userId: IntegrationTestConstants.testHostId,
      locality: 'Greenpoint',
      city: 'Brooklyn',
      state: 'New York',
      country: 'USA',
    );

    return {
      'scope': scope,
      'locality': 'Greenpoint',
      'city': 'Brooklyn',
      'canHostInLocality': scope.canHostInLocality('Greenpoint'),
      'cannotHostInOtherLocality': !scope.canHostInLocality('DUMBO'),
    };
  }

  /// City expert scope fixture (Brooklyn with multiple localities)
  static Map<String, dynamic> cityExpertScopeFixture() {
    final scope = IntegrationTestHelpers.createCityExpertScope(
      userId: IntegrationTestConstants.testHostId,
      city: 'Brooklyn',
      localities: ['Greenpoint', 'DUMBO', 'Sunset Park', 'Bath Beach'],
      state: 'New York',
      country: 'USA',
    );

    return {
      'scope': scope,
      'city': 'Brooklyn',
      'localities': ['Greenpoint', 'DUMBO', 'Sunset Park', 'Bath Beach'],
      'canHostInLocality': scope.canHostInLocality('Greenpoint'),
      'canHostInCity': scope.canHostInCity('Brooklyn'),
    };
  }

  /// Regional expert scope fixture (can host anywhere in region)
  static Map<String, dynamic> regionalExpertScopeFixture() {
    final scope = IntegrationTestHelpers.createRegionalExpertScope(
      userId: IntegrationTestConstants.testHostId,
      level: ExpertiseLevel.regional,
      state: 'New York',
      country: 'USA',
    );

    return {
      'scope': scope,
      'level': ExpertiseLevel.regional,
      'canHostAnywhere': true,
    };
  }

  /// Locality fixture (Greenpoint neighborhood in Brooklyn)
  static Map<String, dynamic> localityFixture() {
    final locality = IntegrationTestHelpers.createTestLocality(
      id: 'locality-greenpoint',
      name: 'Greenpoint',
      city: 'Brooklyn',
      state: 'New York',
      country: 'USA',
      latitude: 40.7295,
      longitude: -73.9545,
      isNeighborhood: true,
      parentCity: 'Brooklyn',
    );

    return {
      'locality': locality,
      'name': 'Greenpoint',
      'isNeighborhood': true,
      'parentCity': 'Brooklyn',
    };
  }

  /// Large city fixture (Brooklyn with neighborhoods)
  static Map<String, dynamic> largeCityFixture() {
    final city = IntegrationTestHelpers.createTestLargeCity(
      id: 'city-brooklyn',
      name: 'Brooklyn',
      state: 'New York',
      country: 'USA',
      latitude: 40.6782,
      longitude: -73.9442,
      population: 2736074,
      geographicSizeKm2: 251.0,
      neighborhoods: [
        'locality-greenpoint',
        'locality-dumbo',
        'locality-sunset-park',
        'locality-bath-beach',
      ],
      isDetected: true,
    );

    return {
      'city': city,
      'name': 'Brooklyn',
      'hasNeighborhoods': true,
      'neighborhoodCount': 4,
    };
  }

  // ======= Locality Value & Qualification Fixtures =======

  /// Locality value fixture (Greenpoint with coffee focus)
  static Map<String, dynamic> localityValueFixture() {
    final value = IntegrationTestHelpers.createCoffeeFocusedLocalityValue(
      locality: 'Greenpoint',
    );

    return {
      'value': value,
      'locality': 'Greenpoint',
      'valuesEventsHighly': value.valuesActivityHighly('events_hosted'),
      'activityWeights': value.activityWeights,
    };
  }

  /// Local expert qualification fixture (in progress)
  static Map<String, dynamic> localExpertQualificationFixture() {
    final qualification = IntegrationTestHelpers.createTestQualification(
      userId: IntegrationTestConstants.testHostId,
      category: IntegrationTestConstants.testCategoryCoffee,
      locality: 'Greenpoint',
      progress: IntegrationTestHelpers.createTestProgress(
        visits: 5,
        ratings: 3,
        avgRating: 4.5,
        communityEngagement: 1,
        listCuration: 1,
        eventHosting: 0,
      ),
      factors: IntegrationTestHelpers.createTestFactors(
        listsWithFollowers: 2,
        hasPositiveTrends: true,
      ),
    );

    return {
      'qualification': qualification,
      'category': 'Coffee',
      'locality': 'Greenpoint',
      'progressPercentage': qualification.progressPercentage,
      'remainingRequirements': qualification.remainingRequirements,
      'isQualified': qualification.isQualified,
    };
  }

  /// Local expert qualification fixture (qualified)
  static Map<String, dynamic> qualifiedLocalExpertFixture() {
    final qualification = IntegrationTestHelpers.createTestQualification(
      userId: IntegrationTestConstants.testHostId,
      category: IntegrationTestConstants.testCategoryCoffee,
      locality: 'Greenpoint',
      progress: IntegrationTestHelpers.createTestProgress(
        visits: 7,
        ratings: 4,
        avgRating: 4.5,
        communityEngagement: 2,
        listCuration: 1,
        eventHosting: 1,
      ),
      factors: IntegrationTestHelpers.createTestFactors(
        listsWithFollowers: 3,
        peerReviewedReviews: 5,
        hasProfessionalBackground: true,
        hasPositiveTrends: true,
      ),
      isQualified: true,
    );

    return {
      'qualification': qualification,
      'category': 'Coffee',
      'locality': 'Greenpoint',
      'isQualified': true,
      'qualifiedAt': qualification.qualifiedAt,
    };
  }

  /// Threshold values fixture (base and locality-adjusted)
  static Map<String, dynamic> thresholdValuesFixture() {
    const baseThresholds = ThresholdValues(
      minVisits: 10,
      minRatings: 5,
      minAvgRating: 4.0,
      minTimeInCategory: Duration(days: 30),
      minCommunityEngagement: 3,
      minListCuration: 2,
      minEventHosting: 1,
    );

    const localityThresholds = ThresholdValues(
      minVisits: 7, // 30% lower (locality values events highly)
      minRatings: 4, // 20% lower
      minAvgRating: 4.0, // Same
      minTimeInCategory: Duration(days: 30), // Same
      minCommunityEngagement: 2, // 33% lower
      minListCuration: 1, // 50% lower
      minEventHosting: 1, // Same
    );

    return {
      'baseThresholds': baseThresholds,
      'localityThresholds': localityThresholds,
      'adjustment': {
        'visits': 0.7, // 30% reduction
        'ratings': 0.8, // 20% reduction
        'communityEngagement': 0.67, // 33% reduction
        'listCuration': 0.5, // 50% reduction
      },
    };
  }
}

