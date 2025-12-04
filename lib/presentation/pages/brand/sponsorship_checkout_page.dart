import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/payment_service.dart';
// TODO: Import SponsorshipService when available (Agent 1, Week 11)
// import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/payment/payment_form_widget.dart';
import 'package:spots/presentation/widgets/brand/product_contribution_widget.dart';
import 'package:spots/presentation/widgets/brand/sponsorship_revenue_split_display.dart';
import 'package:spots/presentation/pages/payment/payment_success_page.dart';
import 'package:spots/presentation/widgets/common/page_transitions.dart';
import 'package:get_it/get_it.dart';

/// Brand Sponsorship Checkout Page
/// 
/// Multi-party checkout page for brand sponsorship contributions.
/// Supports financial, product, and hybrid sponsorship types.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
/// 
/// **Features:**
/// - Event details display
/// - Sponsorship contribution type selection
/// - Financial contribution payment
/// - Product contribution tracking
/// - Revenue split display (N-way with sponsors)
/// - Payment confirmation
class SponsorshipCheckoutPage extends StatefulWidget {
  final ExpertiseEvent event;
  final Sponsorship? sponsorship; // If editing existing sponsorship
  final SponsorshipType? preselectedType;

  const SponsorshipCheckoutPage({
    super.key,
    required this.event,
    this.sponsorship,
    this.preselectedType,
  });

  @override
  State<SponsorshipCheckoutPage> createState() => _SponsorshipCheckoutPageState();
}

class _SponsorshipCheckoutPageState extends State<SponsorshipCheckoutPage> {
  final _paymentService = GetIt.instance<PaymentService>();
  // TODO: Get SponsorshipService when available (Agent 1, Week 11)
  // final _sponsorshipService = GetIt.instance<SponsorshipService>();
  
  SponsorshipType _contributionType = SponsorshipType.financial;
  double? _cashAmount;
  double? _productValue;
  int _productQuantity = 1;
  String? _productName;
  bool _isProcessing = false;
  String? _error;
  RevenueSplit? _revenueSplit;
  
  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _contributionType = widget.preselectedType!;
    }
    if (widget.sponsorship != null) {
      _loadExistingSponsorship();
    }
    _calculateRevenueSplit();
  }
  
  void _loadExistingSponsorship() {
    final sponsorship = widget.sponsorship!;
    setState(() {
      _contributionType = sponsorship.type;
      _cashAmount = sponsorship.contributionAmount;
      _productValue = sponsorship.productValue;
    });
  }
  
  Future<void> _calculateRevenueSplit() async {
    try {
      // Calculate revenue split including this sponsorship
      final totalContribution = (_cashAmount ?? 0.0) + (_productValue ?? 0.0);
      
      if (totalContribution > 0) {
        // TODO: Integrate with SponsorshipService when available (Agent 1, Week 11)
        // Get existing revenue split for event
        // final existingSplit = await _sponsorshipService.getEventRevenueSplit(
        //   widget.event.id,
        // );
        // 
        // if (existingSplit != null) {
        //   _revenueSplit = await _sponsorshipService.calculateSponsorshipRevenueSplit(
        //     eventId: widget.event.id,
        //     sponsorshipContribution: totalContribution,
        //     existingSplit: existingSplit,
        //   );
        // }
        
        // For now, create placeholder revenue split
        // This will be replaced with actual service call
      }
    } catch (e) {
      // Handle error
      debugPrint('Error calculating revenue split: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final totalContribution = (_cashAmount ?? 0.0) + (_productValue ?? 0.0);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.sponsorship != null ? 'Edit Sponsorship' : 'Sponsor Event',
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details Card
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.event.getEventTypeEmoji(),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.event.getEventTypeDisplayName(),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.calendar_today, _formatDateTime(widget.event.startTime)),
                  if (widget.event.location != null)
                    _buildDetailRow(Icons.location_on, widget.event.location!),
                  _buildDetailRow(Icons.people, '${widget.event.attendeeCount} / ${widget.event.maxAttendees} attendees'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Contribution Type Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contribution Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContributionTypeOption(
                        SponsorshipType.financial,
                        'Financial',
                        'Cash contribution',
                        Icons.account_balance_wallet,
                      ),
                      const SizedBox(height: 12),
                      _buildContributionTypeOption(
                        SponsorshipType.product,
                        'Product',
                        'Product/in-kind contribution',
                        Icons.inventory_2,
                      ),
                      const SizedBox(height: 12),
                      _buildContributionTypeOption(
                        SponsorshipType.hybrid,
                        'Hybrid',
                        'Cash + Product combination',
                        Icons.all_inclusive,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Financial Contribution Section
            if (_contributionType == SponsorshipType.financial ||
                _contributionType == SponsorshipType.hybrid) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Contribution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            hintText: '500.00',
                            prefixText: '\$',
                            filled: true,
                            fillColor: AppColors.grey100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              _cashAmount = double.tryParse(value);
                              _calculateRevenueSplit();
                            });
                          },
                          initialValue: _cashAmount?.toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Product Contribution Section
            if (_contributionType == SponsorshipType.product ||
                _contributionType == SponsorshipType.hybrid) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ProductContributionWidget(
                  productName: _productName,
                  productQuantity: _productQuantity,
                  productValue: _productValue,
                  onProductNameChanged: (name) {
                    setState(() => _productName = name);
                  },
                  onQuantityChanged: (quantity) {
                    setState(() {
                      _productQuantity = quantity;
                      _calculateProductValue();
                    });
                  },
                  onUnitPriceChanged: (price) {
                    setState(() {
                      _productValue = price * _productQuantity;
                      _calculateRevenueSplit();
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Revenue Split Display (if contribution set)
            if (totalContribution > 0 && _revenueSplit != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SponsorshipRevenueSplitDisplay(
                  split: _revenueSplit!,
                  sponsorshipContribution: totalContribution,
                  showDetails: true,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Contribution Summary
            if (totalContribution > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contribution Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_cashAmount != null && _cashAmount! > 0)
                          _buildSummaryRow('Cash Contribution', _cashAmount!),
                        if (_productValue != null && _productValue! > 0)
                          _buildSummaryRow('Product Value', _productValue!),
                        const SizedBox(height: 12),
                        Divider(color: AppColors.grey300),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Contribution',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${totalContribution.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Payment Form (only for financial contributions)
            if ((_contributionType == SponsorshipType.financial ||
                _contributionType == SponsorshipType.hybrid) &&
                _cashAmount != null &&
                _cashAmount! > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PaymentFormWidget(
                  amount: _cashAmount!,
                  quantity: 1,
                  eventId: widget.event.id,
                  onPaymentSuccess: _handlePaymentSuccess,
                  onPaymentFailure: _handlePaymentFailure,
                  isProcessing: _isProcessing,
                  onProcessingChange: (processing) {
                    setState(() => _isProcessing = processing);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Submit Button (for product-only or after payment)
            if ((_contributionType == SponsorshipType.product ||
                (_cashAmount != null && _cashAmount! > 0 && !_isProcessing))) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: totalContribution > 0 && !_isProcessing
                        ? _submitSponsorship
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.sponsorship != null
                          ? 'Update Sponsorship'
                          : 'Submit Sponsorship Proposal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildContributionTypeOption(
    SponsorshipType type,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _contributionType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _contributionType = type;
          _calculateRevenueSplit();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  void _calculateProductValue() {
    // Calculate product value based on quantity and unit price
    // This would be set by the ProductContributionWidget
  }
  
  Future<void> _submitSponsorship() async {
    if (_cashAmount == null && _productValue == null) {
      setState(() {
        _error = 'Please specify a contribution amount or product value';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    
    try {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // TODO: Get brand account for user (when BrandAccountService is available)
      // final brandAccount = await GetIt.instance<BrandAccountService>().getBrandAccountByUserId(userId);
      // if (brandAccount == null) {
      //   throw Exception('Brand account not found');
      // }
      
      // TODO: Integrate with SponsorshipService when available (Agent 1, Week 11)
      // if (widget.sponsorship != null) {
      //   await _sponsorshipService.updateSponsorship(
      //     widget.sponsorship!.id,
      //     contributionAmount: _cashAmount,
      //     productValue: _productValue,
      //   );
      // } else {
      //   await _sponsorshipService.createSponsorship(
      //     eventId: widget.event.id,
      //     brandId: brandAccount.id,
      //     type: _contributionType,
      //     contributionAmount: _cashAmount,
      //     productValue: _productValue,
      //   );
      // }
      
      // For now, simulate success
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate to success page
      Navigator.pushReplacement(
        context,
        PageTransitions.scaleAndFade(
          PaymentSuccessPage(
            event: widget.event,
            paymentId: 'sponsorship-${DateTime.now().millisecondsSinceEpoch}',
            quantity: 1,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Failed to submit sponsorship: ${e.toString()}';
      });
    }
  }
  
  void _handlePaymentSuccess(String paymentId, String paymentIntentId) {
    // Payment successful, now submit sponsorship
    _submitSponsorship();
  }
  
  void _handlePaymentFailure(String errorMessage, String? errorCode) {
    setState(() {
      _isProcessing = false;
      _error = errorMessage;
    });
  }
  
  String _formatDateTime(DateTime dateTime) {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dateTime.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dateTime.day} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $ampm';
  }
}

