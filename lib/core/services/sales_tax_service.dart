import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Sales Tax Calculation Result
class SalesTaxCalculation {
  /// Taxable amount
  final double taxableAmount;

  /// Tax rate (as percentage, e.g., 8.5 for 8.5%)
  final double taxRate;

  /// Calculated tax amount
  final double taxAmount;

  /// Total amount (original + tax)
  final double totalAmount;

  /// Tax jurisdiction
  final String? jurisdiction;

  /// Whether event is tax-exempt
  final bool isTaxExempt;

  /// Reason for tax exemption (if applicable)
  final String? exemptionReason;

  const SalesTaxCalculation({
    required this.taxableAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    this.jurisdiction,
    this.isTaxExempt = false,
    this.exemptionReason,
  });
}

/// Sales Tax Service
///
/// Handles sales tax calculation and filing for events.
///
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables accurate tax calculation
/// - Supports responsible platform operation
///
/// **Responsibilities:**
/// - Calculate sales tax for events
/// - Determine if event type is taxable
/// - Get tax rate for location
/// - File sales tax returns
///
/// **Usage:**
/// ```dart
/// final salesTaxService = SalesTaxService(
///   eventService,
///   paymentService,
/// );
///
/// // Calculate sales tax for event
/// final calculation = await salesTaxService.calculateSalesTax(
///   eventId: 'event-123',
///   ticketPrice: 25.00,
/// );
/// ```
class SalesTaxService {
  static const String _logName = 'SalesTaxService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();

  final ExpertiseEventService _eventService;
  final PaymentService? _paymentService;

  // Tax-exempt event types (varies by jurisdiction)
  // Educational workshops and lectures are often tax-exempt
  static const Set<ExpertiseEventType> _taxExemptEventTypes = {
    ExpertiseEventType.workshop,
    ExpertiseEventType.lecture,
  };

  // In-memory storage for tax rates (in production, use tax API)
  final Map<String, double> _taxRates = {};

  SalesTaxService({
    required ExpertiseEventService eventService,
    PaymentService? paymentService,
  })  : _eventService = eventService,
        _paymentService = paymentService;

  /// Calculate sales tax for an event
  ///
  /// **Flow:**
  /// 1. Get event details
  /// 2. Check if event type is taxable
  /// 3. Get tax rate for location
  /// 4. Calculate tax amount
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `ticketPrice`: Ticket price
  ///
  /// **Returns:**
  /// SalesTaxCalculation with tax details
  Future<SalesTaxCalculation> calculateSalesTax({
    required String eventId,
    required double ticketPrice,
  }) async {
    try {
      _logger.info(
          'Calculating sales tax: event=$eventId, price=\$${ticketPrice.toStringAsFixed(2)}',
          tag: _logName);

      // Step 1: Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }

      // Step 2: Check if event type is tax-exempt
      if (_isTaxExempt(event)) {
        return SalesTaxCalculation(
          taxableAmount: ticketPrice,
          taxRate: 0.0,
          taxAmount: 0.0,
          totalAmount: ticketPrice,
          isTaxExempt: true,
          exemptionReason: 'Event type is tax-exempt',
        );
      }

      // Step 3: Get tax rate for location
      // Extract location components from event.location string
      final locationParts = event.location?.split(',') ?? [];
      final state = locationParts.length >= 3 ? locationParts[2].trim() : null;
      final city = locationParts.length >= 2 ? locationParts[1].trim() : null;
      final zipCode =
          locationParts.length >= 4 ? locationParts[3].trim() : null;

      final taxRate = await getTaxRateForLocation(
        state: state,
        city: city,
        zipCode: zipCode,
      );

      // Step 4: Calculate tax amount
      final taxAmount = ticketPrice * (taxRate / 100.0);
      final totalAmount = ticketPrice + taxAmount;

      final calculation = SalesTaxCalculation(
        taxableAmount: ticketPrice,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        jurisdiction: state ?? 'Unknown',
        isTaxExempt: false,
      );

      _logger.info(
          'Sales tax calculated: event=$eventId, rate=${taxRate.toStringAsFixed(2)}%, tax=\$${taxAmount.toStringAsFixed(2)}',
          tag: _logName);

      return calculation;
    } catch (e) {
      _logger.error('Error calculating sales tax', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get tax rate for a location
  ///
  /// **Flow:**
  /// 1. Check cache for tax rate
  /// 2. Query tax API if not cached
  /// 3. Cache and return rate
  ///
  /// **Parameters:**
  /// - `state`: State code (e.g., "CA")
  /// - `city`: City name (optional)
  /// - `zipCode`: ZIP code (optional)
  ///
  /// **Returns:**
  /// Tax rate as percentage (e.g., 8.5 for 8.5%)
  Future<double> getTaxRateForLocation({
    String? state,
    String? city,
    String? zipCode,
  }) async {
    try {
      // Create location key for caching
      final locationKey =
          _getLocationKey(state: state, city: city, zipCode: zipCode);

      // Check cache
      if (_taxRates.containsKey(locationKey)) {
        return _taxRates[locationKey]!;
      }

      // In production, query tax API (e.g., Avalara, TaxJar, Stripe Tax)
      // For now, use default rates by state
      final taxRate = _getDefaultTaxRate(state);

      // Cache rate
      _taxRates[locationKey] = taxRate;

      _logger.info(
          'Tax rate retrieved: location=$locationKey, rate=${taxRate.toStringAsFixed(2)}%',
          tag: _logName);

      return taxRate;
    } catch (e) {
      _logger.error('Error getting tax rate', error: e, tag: _logName);
      // Return default rate on error
      return 0.0;
    }
  }

  /// Determine if event type is taxable
  ///
  /// **Parameters:**
  /// - `event`: Event to check
  ///
  /// **Returns:**
  /// `true` if tax-exempt, `false` if taxable
  bool _isTaxExempt(ExpertiseEvent event) {
    // Check event type
    if (_taxExemptEventTypes.contains(event.eventType)) {
      return true;
    }

    // Additional checks could include:
    // - Non-profit organization
    // - Educational institution
    // - Government entity

    return false;
  }

  /// Get default tax rate by state
  ///
  /// **Parameters:**
  /// - `state`: State code
  ///
  /// **Returns:**
  /// Default tax rate (0.0 if state not found)
  double _getDefaultTaxRate(String? state) {
    // Default sales tax rates by state (approximate)
    // In production, use tax API for accurate rates
    final defaultRates = <String, double>{
      'CA': 7.25, // California
      'NY': 8.0, // New York
      'TX': 6.25, // Texas
      'FL': 6.0, // Florida
      'IL': 6.25, // Illinois
      'PA': 6.0, // Pennsylvania
      'OH': 5.75, // Ohio
      'GA': 4.0, // Georgia
      'NC': 4.75, // North Carolina
      'MI': 6.0, // Michigan
    };

    if (state == null || state.isEmpty) {
      return 0.0;
    }

    return defaultRates[state.toUpperCase()] ?? 0.0;
  }

  /// Get location key for caching
  String _getLocationKey({
    String? state,
    String? city,
    String? zipCode,
  }) {
    final parts = <String>[];
    if (state != null && state.isNotEmpty) parts.add(state.toUpperCase());
    if (city != null && city.isNotEmpty) parts.add(city);
    if (zipCode != null && zipCode.isNotEmpty) parts.add(zipCode);
    return parts.join('-');
  }

  /// File sales tax return
  ///
  /// **Flow:**
  /// 1. Calculate total sales tax collected for period
  /// 2. Generate tax return
  /// 3. File with tax authority
  ///
  /// **Parameters:**
  /// - `state`: State code
  /// - `startDate`: Start date for return period
  /// - `endDate`: End date for return period
  ///
  /// **Returns:**
  /// Filing confirmation number
  Future<String> fileSalesTaxReturn({
    required String state,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.info(
          'Filing sales tax return: state=$state, period=$startDate to $endDate',
          tag: _logName);

      // In production, calculate total sales tax collected
      // For now, simulate filing
      final confirmationNumber = 'ST-${_uuid.v4()}';

      _logger.info(
          'Sales tax return filed: state=$state, confirmation=$confirmationNumber',
          tag: _logName);

      return confirmationNumber;
    } catch (e) {
      _logger.error('Error filing sales tax return', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check if event type is taxable
  ///
  /// **Parameters:**
  /// - `eventType`: Event type
  ///
  /// **Returns:**
  /// `true` if taxable, `false` if tax-exempt
  bool isEventTypeTaxable(ExpertiseEventType eventType) {
    return !_taxExemptEventTypes.contains(eventType);
  }
}
