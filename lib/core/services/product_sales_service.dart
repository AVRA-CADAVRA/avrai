import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Product Sales Service
/// 
/// Service for processing product sales at events and calculating revenue.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to product-based partnerships
/// - Enables transparent revenue tracking
/// - Supports product sales at events
/// - Creates pathways for product sponsorships
/// 
/// **Responsibilities:**
/// - Process product sales at events
/// - Track product sales revenue
/// - Calculate product revenue splits
/// - Generate sales reports
class ProductSalesService {
  static const String _logName = 'ProductSalesService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ProductTrackingService _productTrackingService;
  final RevenueSplitService _revenueSplitService;
  final PaymentService? _paymentService; // Optional for payment processing
  
  // In-memory storage for product sales (in production, use database)
  final Map<String, ProductSale> _productSales = {};
  
  ProductSalesService({
    required ProductTrackingService productTrackingService,
    required RevenueSplitService revenueSplitService,
    PaymentService? paymentService,
  }) : _productTrackingService = productTrackingService,
       _revenueSplitService = revenueSplitService,
       _paymentService = paymentService;
  
  /// Process product sale at event
  /// 
  /// **Flow:**
  /// 1. Get product tracking record
  /// 2. Validate quantity available
  /// 3. Create payment (if PaymentService available)
  /// 4. Record sale
  /// 5. Update product tracking
  /// 6. Calculate revenue split
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// - `quantity`: Quantity sold
  /// - `buyerId`: Buyer user ID
  /// - `salePrice`: Sale price (optional, defaults to unitPrice)
  /// - `paymentMethod`: Payment method (optional)
  /// 
  /// **Returns:**
  /// ProductSale record
  /// 
  /// **Throws:**
  /// - `Exception` if product tracking not found
  /// - `Exception` if insufficient quantity available
  Future<ProductSale> processProductSale({
    required String productTrackingId,
    required int quantity,
    required String buyerId,
    double? salePrice,
    String? paymentMethod,
  }) async {
    try {
      _logger.info('Processing product sale: tracking=$productTrackingId, quantity=$quantity', tag: _logName);
      
      // Step 1: Get product tracking record
      final tracking = await _productTrackingService.getProductTrackingById(productTrackingId);
      if (tracking == null) {
        throw Exception('Product tracking not found: $productTrackingId');
      }
      
      // Step 2: Validate quantity available
      if (tracking.quantityRemaining < quantity) {
        throw Exception('Insufficient quantity available: ${tracking.quantityRemaining} < $quantity');
      }
      
      // Step 3: Calculate sale details
      final price = salePrice ?? tracking.unitPrice;
      final saleTotal = quantity * price;
      
      // Step 4: Process payment (if PaymentService available)
      String? paymentIntentId;
      PaymentStatus paymentStatus = PaymentStatus.pending;
      
      if (_paymentService != null && paymentMethod != null) {
        // In production, process payment through PaymentService
        // For now, mark as completed
        paymentStatus = PaymentStatus.completed;
        paymentIntentId = _generatePaymentIntentId();
      }
      
      // Step 5: Record sale through ProductTrackingService
      final updatedTracking = await _productTrackingService.recordProductSale(
        productTrackingId: productTrackingId,
        quantity: quantity,
        buyerId: buyerId,
        salePrice: price,
        paymentMethod: paymentMethod,
      );
      
      // Step 6: Get the sale record that was created
      final sale = updatedTracking.sales.last;
      
      // Step 7: Calculate revenue attribution
      await _productTrackingService.calculateRevenueAttribution(
        productTrackingId: productTrackingId,
      );
      
      _logger.info('Processed product sale: ${sale.id}, total: \$${saleTotal.toStringAsFixed(2)}', tag: _logName);
      return sale;
    } catch (e) {
      _logger.error('Error processing product sale', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Calculate product revenue for a sponsorship
  /// 
  /// **Flow:**
  /// 1. Get all product tracking for sponsorship
  /// 2. Calculate total revenue
  /// 3. Return total
  /// 
  /// **Parameters:**
  /// - `sponsorshipId`: Sponsorship ID
  /// - `startDate`: Start date (optional)
  /// - `endDate`: End date (optional)
  /// 
  /// **Returns:**
  /// Total product revenue
  Future<double> calculateProductRevenue({
    required String sponsorshipId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Calculating product revenue: sponsorship=$sponsorshipId', tag: _logName);
      
      // Get product tracking for sponsorship
      final trackingList = await _productTrackingService.getProductTrackingForSponsorship(sponsorshipId);
      
      // Filter by date range if provided
      final filteredTracking = trackingList.where((tracking) {
        if (startDate != null && tracking.createdAt.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && tracking.createdAt.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
      
      // Calculate total revenue
      final totalRevenue = filteredTracking.fold<double>(
        0.0,
        (sum, tracking) => sum + tracking.totalSales,
      );
      
      _logger.info('Product revenue for $sponsorshipId: \$${totalRevenue.toStringAsFixed(2)}', tag: _logName);
      return totalRevenue;
    } catch (e) {
      _logger.error('Error calculating product revenue', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  /// Calculate product revenue split
  /// 
  /// **Flow:**
  /// 1. Get product tracking records
  /// 2. Calculate total sales
  /// 3. Calculate revenue split
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// 
  /// **Returns:**
  /// RevenueSplit for product sales
  Future<RevenueSplit> calculateProductRevenueSplit({
    required String productTrackingId,
  }) async {
    try {
      _logger.info('Calculating product revenue split: tracking=$productTrackingId', tag: _logName);
      
      // Get product tracking
      final tracking = await _productTrackingService.getProductTrackingById(productTrackingId);
      if (tracking == null) {
        throw Exception('Product tracking not found: $productTrackingId');
      }
      
      // Calculate revenue split
      return await _revenueSplitService.calculateProductSalesSplit(
        productTrackingId: productTrackingId,
        totalSales: tracking.totalSales,
      );
    } catch (e) {
      _logger.error('Error calculating product revenue split', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Generate event sales report
  /// 
  /// **Flow:**
  /// 1. Get all sponsorships for event
  /// 2. Get product tracking for each sponsorship
  /// 3. Calculate totals
  /// 4. Generate report
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// EventProductSalesReport with totals and breakdown
  Future<EventProductSalesReport> generateEventSalesReport({
    required String eventId,
  }) async {
    try {
      _logger.info('Generating event sales report: event=$eventId', tag: _logName);
      
      // Get product tracking for event (through sponsorships)
      // This would require getting sponsorships first
      // For now, return empty report structure
      
      final report = EventProductSalesReport(
        eventId: eventId,
        totalProducts: 0,
        totalQuantitySold: 0,
        totalSales: 0.0,
        totalPlatformFee: 0.0,
        totalNetRevenue: 0.0,
        products: [],
        generatedAt: DateTime.now(),
      );
      
      _logger.info('Generated event sales report for $eventId', tag: _logName);
      return report;
    } catch (e) {
      _logger.error('Error generating event sales report', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  String _generatePaymentIntentId() {
    return 'pi_${_uuid.v4()}';
  }
}

/// Event Product Sales Report
/// 
/// Represents a sales report for all products sold at an event.
class EventProductSalesReport {
  final String eventId;
  final int totalProducts;
  final int totalQuantitySold;
  final double totalSales;
  final double totalPlatformFee;
  final double totalNetRevenue;
  final List<ProductTracking> products;
  final DateTime generatedAt;
  
  const EventProductSalesReport({
    required this.eventId,
    required this.totalProducts,
    required this.totalQuantitySold,
    required this.totalSales,
    required this.totalPlatformFee,
    required this.totalNetRevenue,
    required this.products,
    required this.generatedAt,
  });
}

