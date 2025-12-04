import 'package:equatable/equatable.dart';
import 'package:spots/core/models/payment_status.dart';

/// Product Tracking Model
/// 
/// Tracks product sales, inventory, and revenue attribution for sponsored products.
/// Supports products sold at events, samples given away, and products used in events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to product-based partnerships
/// - Enables transparent revenue tracking
/// - Supports product sales at events
/// - Creates pathways for product sponsorships
/// 
/// **Usage:**
/// ```dart
/// final tracking = ProductTracking(
///   id: 'product-track-123',
///   sponsorshipId: 'sponsor-456',
///   productName: 'Premium Olive Oil',
///   quantityProvided: 20,
///   quantitySold: 15,
///   unitPrice: 25.00,
///   totalSales: 375.00,
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class ProductTracking extends Equatable {
  /// Product tracking ID
  final String id;
  
  /// Sponsorship reference (the sponsorship this product is part of)
  final String sponsorshipId;
  
  /// Product name
  final String productName;
  
  /// Product SKU (optional)
  final String? sku;
  
  /// Product description
  final String? description;
  
  /// Product image URL
  final String? imageUrl;
  
  /// Quantity provided by sponsor
  final int quantityProvided;
  
  /// Quantity sold
  final int quantitySold;
  
  /// Quantity given away (samples)
  final int quantityGivenAway;
  
  /// Quantity used in event (e.g., cooking ingredients)
  final int quantityUsedInEvent;
  
  /// Remaining quantity
  int get quantityRemaining {
    return quantityProvided -
        quantitySold -
        quantityGivenAway -
        quantityUsedInEvent;
  }
  
  /// Unit price (selling price per unit)
  final double unitPrice;
  
  /// Unit cost price (for margin calculation)
  final double? unitCostPrice;
  
  /// Total sales revenue
  final double totalSales;
  
  /// Platform fee (SPOTS 10%)
  final double platformFee;
  
  /// Revenue attribution (map of partnerId -> amount)
  final Map<String, double> revenueDistribution;
  
  /// Individual sale records
  final List<ProductSale> sales;
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;

  const ProductTracking({
    required this.id,
    required this.sponsorshipId,
    required this.productName,
    this.sku,
    this.description,
    this.imageUrl,
    required this.quantityProvided,
    this.quantitySold = 0,
    this.quantityGivenAway = 0,
    this.quantityUsedInEvent = 0,
    required this.unitPrice,
    this.unitCostPrice,
    this.totalSales = 0.0,
    this.platformFee = 0.0,
    this.revenueDistribution = const {},
    this.sales = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate total revenue after platform fee
  double get netRevenue => totalSales - platformFee;

  /// Calculate profit margin (if cost price available)
  double? get profitMargin {
    if (unitCostPrice == null || unitPrice == 0) return null;
    return ((unitPrice - unitCostPrice!) / unitPrice) * 100;
  }

  /// Check if product is sold out
  bool get isSoldOut => quantityRemaining <= 0;

  /// Check if product has sales
  bool get hasSales => quantitySold > 0;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sponsorshipId': sponsorshipId,
      'productName': productName,
      'sku': sku,
      'description': description,
      'imageUrl': imageUrl,
      'quantityProvided': quantityProvided,
      'quantitySold': quantitySold,
      'quantityGivenAway': quantityGivenAway,
      'quantityUsedInEvent': quantityUsedInEvent,
      'unitPrice': unitPrice,
      'unitCostPrice': unitCostPrice,
      'totalSales': totalSales,
      'platformFee': platformFee,
      'revenueDistribution': revenueDistribution,
      'sales': sales.map((s) => s.toJson()).toList(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ProductTracking.fromJson(Map<String, dynamic> json) {
    return ProductTracking(
      id: json['id'] as String,
      sponsorshipId: json['sponsorshipId'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      quantityProvided: (json['quantityProvided'] as num).toInt(),
      quantitySold: (json['quantitySold'] as num?)?.toInt() ?? 0,
      quantityGivenAway: (json['quantityGivenAway'] as num?)?.toInt() ?? 0,
      quantityUsedInEvent:
          (json['quantityUsedInEvent'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      unitCostPrice: (json['unitCostPrice'] as num?)?.toDouble(),
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      revenueDistribution: json['revenueDistribution'] != null
          ? Map<String, double>.from(
              (json['revenueDistribution'] as Map).map(
                (key, value) => MapEntry(key as String, (value as num).toDouble()),
              ),
            )
          : {},
      sales: (json['sales'] as List?)
              ?.map((s) => ProductSale.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  ProductTracking copyWith({
    String? id,
    String? sponsorshipId,
    String? productName,
    String? sku,
    String? description,
    String? imageUrl,
    int? quantityProvided,
    int? quantitySold,
    int? quantityGivenAway,
    int? quantityUsedInEvent,
    double? unitPrice,
    double? unitCostPrice,
    double? totalSales,
    double? platformFee,
    Map<String, double>? revenueDistribution,
    List<ProductSale>? sales,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductTracking(
      id: id ?? this.id,
      sponsorshipId: sponsorshipId ?? this.sponsorshipId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      quantityProvided: quantityProvided ?? this.quantityProvided,
      quantitySold: quantitySold ?? this.quantitySold,
      quantityGivenAway: quantityGivenAway ?? this.quantityGivenAway,
      quantityUsedInEvent: quantityUsedInEvent ?? this.quantityUsedInEvent,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCostPrice: unitCostPrice ?? this.unitCostPrice,
      totalSales: totalSales ?? this.totalSales,
      platformFee: platformFee ?? this.platformFee,
      revenueDistribution: revenueDistribution ?? this.revenueDistribution,
      sales: sales ?? this.sales,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sponsorshipId,
        productName,
        sku,
        description,
        imageUrl,
        quantityProvided,
        quantitySold,
        quantityGivenAway,
        quantityUsedInEvent,
        unitPrice,
        unitCostPrice,
        totalSales,
        platformFee,
        revenueDistribution,
        sales,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Product Sale Record
/// 
/// Represents an individual product sale transaction.
class ProductSale extends Equatable {
  /// Sale ID
  final String id;
  
  /// Product tracking ID
  final String productTrackingId;
  
  /// Buyer ID (who purchased the product)
  final String buyerId;
  
  /// Quantity purchased
  final int quantity;
  
  /// Unit price at time of sale
  final double unitPrice;
  
  /// Total amount
  final double totalAmount;
  
  /// When sale occurred
  final DateTime soldAt;
  
  /// Stripe payment intent ID (if using Stripe)
  final String? paymentIntentId;
  
  /// Payment status
  final PaymentStatus paymentStatus;
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;

  const ProductSale({
    required this.id,
    required this.productTrackingId,
    required this.buyerId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.soldAt,
    this.paymentIntentId,
    required this.paymentStatus,
    this.metadata = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productTrackingId': productTrackingId,
      'buyerId': buyerId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'soldAt': soldAt.toIso8601String(),
      'paymentIntentId': paymentIntentId,
      'paymentStatus': paymentStatus.name,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ProductSale.fromJson(Map<String, dynamic> json) {
    return ProductSale(
      id: json['id'] as String,
      productTrackingId: json['productTrackingId'] as String,
      buyerId: json['buyerId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      soldAt: DateTime.parse(json['soldAt'] as String),
      paymentIntentId: json['paymentIntentId'] as String?,
      paymentStatus: PaymentStatus.fromJson(json['paymentStatus'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Create a copy with updated fields
  ProductSale copyWith({
    String? id,
    String? productTrackingId,
    String? buyerId,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? soldAt,
    String? paymentIntentId,
    PaymentStatus? paymentStatus,
    Map<String, dynamic>? metadata,
  }) {
    return ProductSale(
      id: id ?? this.id,
      productTrackingId: productTrackingId ?? this.productTrackingId,
      buyerId: buyerId ?? this.buyerId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      soldAt: soldAt ?? this.soldAt,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productTrackingId,
        buyerId,
        quantity,
        unitPrice,
        totalAmount,
        soldAt,
        paymentIntentId,
        paymentStatus,
        metadata,
      ];
}

