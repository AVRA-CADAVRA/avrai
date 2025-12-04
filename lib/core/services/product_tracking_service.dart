import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Product Tracking Service
/// 
/// Service for tracking product contributions and sales for sponsorships.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to product-based partnerships
/// - Enables transparent revenue tracking
/// - Supports product sales at events
/// - Creates pathways for product sponsorships
/// 
/// **Responsibilities:**
/// - Track product contributions
/// - Track product sales
/// - Calculate revenue attribution
/// - Manage inventory
/// - Generate sales reports
class ProductTrackingService {
  static const String _logName = 'ProductTrackingService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final SponsorshipService _sponsorshipService;
  final RevenueSplitService? _revenueSplitService;
  
  // In-memory storage for product tracking (in production, use database)
  final Map<String, ProductTracking> _productTracking = {};
  
  ProductTrackingService({
    required SponsorshipService sponsorshipService,
    RevenueSplitService? revenueSplitService,
  }) : _sponsorshipService = sponsorshipService,
       _revenueSplitService = revenueSplitService;
  
  /// Record product contribution
  /// 
  /// **Flow:**
  /// 1. Validate sponsorship exists
  /// 2. Validate sponsorship type supports products
  /// 3. Create ProductTracking record
  /// 4. Return product tracking
  /// 
  /// **Parameters:**
  /// - `sponsorshipId`: Sponsorship ID
  /// - `productName`: Product name
  /// - `quantityProvided`: Quantity provided by sponsor
  /// - `unitPrice`: Unit price (selling price)
  /// - `sku`: Product SKU (optional)
  /// - `description`: Product description (optional)
  /// - `imageUrl`: Product image URL (optional)
  /// - `unitCostPrice`: Unit cost price (optional, for margin calculation)
  /// 
  /// **Returns:**
  /// ProductTracking record
  /// 
  /// **Throws:**
  /// - `Exception` if sponsorship not found
  /// - `Exception` if sponsorship type doesn't support products
  Future<ProductTracking> recordProductContribution({
    required String sponsorshipId,
    required String productName,
    required int quantityProvided,
    required double unitPrice,
    String? sku,
    String? description,
    String? imageUrl,
    double? unitCostPrice,
  }) async {
    try {
      _logger.info('Recording product contribution: sponsorship=$sponsorshipId, product=$productName', tag: _logName);
      
      // Step 1: Validate sponsorship exists
      final sponsorship = await _sponsorshipService.getSponsorshipById(sponsorshipId);
      if (sponsorship == null) {
        throw Exception('Sponsorship not found: $sponsorshipId');
      }
      
      // Step 2: Validate sponsorship type supports products
      if (sponsorship.type == SponsorshipType.financial) {
        throw Exception('Financial sponsorship does not support products');
      }
      
      // Step 3: Calculate product value
      final productValue = quantityProvided * unitPrice;
      
      // Step 4: Create ProductTracking record
      final tracking = ProductTracking(
        id: _generateProductTrackingId(),
        sponsorshipId: sponsorshipId,
        productName: productName,
        sku: sku,
        description: description,
        imageUrl: imageUrl,
        quantityProvided: quantityProvided,
        quantitySold: 0,
        quantityGivenAway: 0,
        quantityUsedInEvent: 0,
        unitPrice: unitPrice,
        unitCostPrice: unitCostPrice,
        totalSales: 0.0,
        platformFee: 0.0,
        revenueDistribution: {},
        sales: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Step 5: Save product tracking
      await _saveProductTracking(tracking);
      
      // Step 6: Update sponsorship product value if needed
      if (sponsorship.type == SponsorshipType.product || sponsorship.type == SponsorshipType.hybrid) {
        // Product value is already tracked in ProductTracking
        // Sponsorship productValue can be updated separately if needed
      }
      
      _logger.info('Recorded product contribution: ${tracking.id}', tag: _logName);
      return tracking;
    } catch (e) {
      _logger.error('Error recording product contribution', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Record product sale
  /// 
  /// **Flow:**
  /// 1. Get product tracking record
  /// 2. Validate quantity available
  /// 3. Record sale
  /// 4. Update totals
  /// 5. Calculate platform fee
  /// 6. Return updated tracking
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// - `quantity`: Quantity sold
  /// - `buyerId`: Buyer user ID
  /// - `salePrice`: Sale price (optional, defaults to unitPrice)
  /// - `paymentMethod`: Payment method (optional)
  /// 
  /// **Returns:**
  /// Updated ProductTracking record
  /// 
  /// **Throws:**
  /// - `Exception` if product tracking not found
  /// - `Exception` if insufficient quantity available
  Future<ProductTracking> recordProductSale({
    required String productTrackingId,
    required int quantity,
    required String buyerId,
    double? salePrice,
    String? paymentMethod,
  }) async {
    try {
      _logger.info('Recording product sale: tracking=$productTrackingId, quantity=$quantity', tag: _logName);
      
      // Step 1: Get product tracking record
      final tracking = await getProductTrackingById(productTrackingId);
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
      const platformFeePercentage = 0.10; // 10% platform fee
      final platformFee = saleTotal * platformFeePercentage;
      
      // Step 4: Create sale record
      final sale = ProductSale(
        id: _generateSaleId(),
        productTrackingId: productTrackingId,
        buyerId: buyerId,
        quantity: quantity,
        unitPrice: price,
        totalAmount: saleTotal,
        soldAt: DateTime.now(),
        paymentIntentId: paymentMethod,
        paymentStatus: PaymentStatus.completed,
      );
      
      // Step 5: Update product tracking
      final updatedTracking = tracking.copyWith(
        quantitySold: tracking.quantitySold + quantity,
        totalSales: tracking.totalSales + saleTotal,
        platformFee: tracking.platformFee + platformFee,
        sales: [...tracking.sales, sale],
        updatedAt: DateTime.now(),
      );
      
      // Step 6: Save updated tracking
      await _saveProductTracking(updatedTracking);
      
      _logger.info('Recorded product sale: ${sale.id}, total: \$${saleTotal.toStringAsFixed(2)}', tag: _logName);
      return updatedTracking;
    } catch (e) {
      _logger.error('Error recording product sale', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Calculate revenue attribution
  /// 
  /// **Flow:**
  /// 1. Get product tracking record
  /// 2. Calculate net revenue (after platform fee)
  /// 3. Attribute revenue to sponsor (and partners if applicable)
  /// 4. Update revenue distribution
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// 
  /// **Returns:**
  /// Map of partyId → amount (revenue distribution)
  Future<Map<String, double>> calculateRevenueAttribution({
    required String productTrackingId,
  }) async {
    try {
      _logger.info('Calculating revenue attribution: tracking=$productTrackingId', tag: _logName);
      
      // Step 1: Get product tracking record
      final tracking = await getProductTrackingById(productTrackingId);
      if (tracking == null) {
        throw Exception('Product tracking not found: $productTrackingId');
      }
      
      // Step 2: Get sponsorship
      final sponsorship = await _sponsorshipService.getSponsorshipById(tracking.sponsorshipId);
      if (sponsorship == null) {
        throw Exception('Sponsorship not found: ${tracking.sponsorshipId}');
      }
      
      // Step 3: Calculate net revenue (after platform fee)
      final netRevenue = tracking.totalSales - tracking.platformFee;
      
      // Step 4: Attribute revenue
      final distribution = <String, double>{};
      
      // If revenue split service available, use it for multi-party attribution
      if (_revenueSplitService != null && sponsorship.revenueSharePercentage != null) {
        // Use revenue split for distribution
        // For now, attribute 100% to sponsor (to be extended in Week 11)
        distribution[sponsorship.brandId] = netRevenue;
      } else {
        // Simple attribution: 100% to sponsor
        distribution[sponsorship.brandId] = netRevenue;
      }
      
      // Step 5: Update tracking with revenue distribution
      final updatedTracking = tracking.copyWith(
        revenueDistribution: distribution,
        updatedAt: DateTime.now(),
      );
      
      await _saveProductTracking(updatedTracking);
      
      _logger.info('Calculated revenue attribution: ${distribution.length} parties', tag: _logName);
      return distribution;
    } catch (e) {
      _logger.error('Error calculating revenue attribution', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Update product quantity
  /// 
  /// **Flow:**
  /// 1. Get product tracking record
  /// 2. Update quantity fields
  /// 3. Save updated tracking
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// - `quantitySold`: Quantity sold (optional)
  /// - `quantityGivenAway`: Quantity given away (optional)
  /// - `quantityUsedInEvent`: Quantity used in event (optional)
  /// 
  /// **Returns:**
  /// Updated ProductTracking record
  Future<ProductTracking> updateProductQuantity({
    required String productTrackingId,
    int? quantitySold,
    int? quantityGivenAway,
    int? quantityUsedInEvent,
  }) async {
    try {
      _logger.info('Updating product quantity: tracking=$productTrackingId', tag: _logName);
      
      final tracking = await getProductTrackingById(productTrackingId);
      if (tracking == null) {
        throw Exception('Product tracking not found: $productTrackingId');
      }
      
      final updatedTracking = tracking.copyWith(
        quantitySold: quantitySold ?? tracking.quantitySold,
        quantityGivenAway: quantityGivenAway ?? tracking.quantityGivenAway,
        quantityUsedInEvent: quantityUsedInEvent ?? tracking.quantityUsedInEvent,
        updatedAt: DateTime.now(),
      );
      
      await _saveProductTracking(updatedTracking);
      
      _logger.info('Updated product quantity: ${updatedTracking.id}', tag: _logName);
      return updatedTracking;
    } catch (e) {
      _logger.error('Error updating product quantity', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get product tracking by ID
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// 
  /// **Returns:**
  /// ProductTracking if found, null otherwise
  Future<ProductTracking?> getProductTrackingById(String productTrackingId) async {
    try {
      return _productTracking[productTrackingId];
    } catch (e) {
      _logger.error('Error getting product tracking by ID', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get all product tracking for a sponsorship
  /// 
  /// **Parameters:**
  /// - `sponsorshipId`: Sponsorship ID
  /// 
  /// **Returns:**
  /// List of ProductTracking records
  Future<List<ProductTracking>> getProductTrackingForSponsorship(String sponsorshipId) async {
    try {
      _logger.info('Getting product tracking for sponsorship: $sponsorshipId', tag: _logName);
      
      return _productTracking.values
          .where((tracking) => tracking.sponsorshipId == sponsorshipId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting product tracking for sponsorship', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Generate sales report
  /// 
  /// **Flow:**
  /// 1. Get product tracking for sponsorship
  /// 2. Calculate totals
  /// 3. Return report
  /// 
  /// **Parameters:**
  /// - `sponsorshipId`: Sponsorship ID
  /// - `startDate`: Start date (optional)
  /// - `endDate`: End date (optional)
  /// 
  /// **Returns:**
  /// ProductSalesReport with totals and breakdown
  Future<ProductSalesReport> generateSalesReport({
    required String sponsorshipId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Generating sales report: sponsorship=$sponsorshipId', tag: _logName);
      
      // Get all product tracking for sponsorship
      final trackingList = await getProductTrackingForSponsorship(sponsorshipId);
      
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
      
      // Calculate totals
      var totalQuantitySold = 0;
      var totalSales = 0.0;
      var totalPlatformFee = 0.0;
      var totalNetRevenue = 0.0;
      
      for (final tracking in filteredTracking) {
        totalQuantitySold += tracking.quantitySold;
        totalSales += tracking.totalSales;
        totalPlatformFee += tracking.platformFee;
        totalNetRevenue += tracking.netRevenue;
      }
      
      // Create report
      final report = ProductSalesReport(
        sponsorshipId: sponsorshipId,
        startDate: startDate,
        endDate: endDate,
        totalProducts: filteredTracking.length,
        totalQuantitySold: totalQuantitySold,
        totalSales: totalSales,
        totalPlatformFee: totalPlatformFee,
        totalNetRevenue: totalNetRevenue,
        products: filteredTracking,
        generatedAt: DateTime.now(),
      );
      
      _logger.info('Generated sales report: ${filteredTracking.length} products, \$${totalSales.toStringAsFixed(2)} total', tag: _logName);
      return report;
    } catch (e) {
      _logger.error('Error generating sales report', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  String _generateProductTrackingId() {
    return 'product_tracking_${_uuid.v4()}';
  }
  
  String _generateSaleId() {
    return 'sale_${_uuid.v4()}';
  }
  
  Future<void> _saveProductTracking(ProductTracking tracking) async {
    // In production, save to database
    _productTracking[tracking.id] = tracking;
  }
}

/// Product Sales Report
/// 
/// Represents a sales report for product tracking.
class ProductSalesReport {
  final String sponsorshipId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalProducts;
  final int totalQuantitySold;
  final double totalSales;
  final double totalPlatformFee;
  final double totalNetRevenue;
  final List<ProductTracking> products;
  final DateTime generatedAt;
  
  const ProductSalesReport({
    required this.sponsorshipId,
    this.startDate,
    this.endDate,
    required this.totalProducts,
    required this.totalQuantitySold,
    required this.totalSales,
    required this.totalPlatformFee,
    required this.totalNetRevenue,
    required this.products,
    required this.generatedAt,
  });
}

