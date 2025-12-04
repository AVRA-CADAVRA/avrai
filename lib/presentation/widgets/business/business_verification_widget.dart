import 'package:flutter/material.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_verification.dart';
import 'package:spots/core/services/business_verification_service.dart';
import 'package:spots/core/theme/colors.dart';

/// Business Verification Widget
/// Allows businesses to submit verification documents and track verification status
class BusinessVerificationWidget extends StatefulWidget {
  final BusinessAccount business;
  final Function(BusinessVerification)? onVerificationSubmitted;

  const BusinessVerificationWidget({
    super.key,
    required this.business,
    this.onVerificationSubmitted,
  });

  @override
  State<BusinessVerificationWidget> createState() => _BusinessVerificationWidgetState();
}

class _BusinessVerificationWidgetState extends State<BusinessVerificationWidget> {
  final _service = BusinessVerificationService();
  final _formKey = GlobalKey<FormState>();
  
  final _legalNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  
  String? _businessLicenseUrl;
  String? _taxIdDocumentUrl;
  final String? _proofOfAddressUrl = null;
  
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingVerification();
  }

  void _loadExistingVerification() {
    final verification = widget.business.verification;
    if (verification != null) {
      _legalNameController.text = verification.legalBusinessName ?? '';
      _taxIdController.text = verification.taxId ?? '';
      _addressController.text = verification.businessAddress ?? '';
      _phoneController.text = verification.phoneNumber ?? '';
      _websiteController.text = verification.websiteUrl ?? '';
      _businessLicenseUrl = verification.businessLicenseUrl;
      _taxIdDocumentUrl = verification.taxIdDocumentUrl;
    } else {
      // Pre-fill from business account
      _legalNameController.text = widget.business.name;
      _addressController.text = widget.business.location ?? '';
      _phoneController.text = widget.business.phone ?? '';
      _websiteController.text = widget.business.website ?? '';
    }
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final verification = await _service.submitVerification(
        business: widget.business,
        legalBusinessName: _legalNameController.text.trim(),
        taxId: _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
        businessAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        websiteUrl: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        businessLicenseUrl: _businessLicenseUrl,
        taxIdDocumentUrl: _taxIdDocumentUrl,
        proofOfAddressUrl: _proofOfAddressUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted successfully! We\'ll review your submission.'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
        
        widget.onVerificationSubmitted?.call(verification);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _tryAutomaticVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final verification = await _service.verifyAutomatically(widget.business);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business verified automatically!'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
        
        widget.onVerificationSubmitted?.call(verification);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automatic verification failed: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = widget.business.verification;
    final isVerified = verification?.isComplete ?? false;
    final isPending = verification?.isPending ?? false;
    final isRejected = verification?.isRejected ?? false;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Header
          _buildStatusHeader(verification),
          const SizedBox(height: 24),

          if (isVerified) ...[
            _buildVerifiedContent(verification!),
          ] else if (isPending) ...[
            _buildPendingContent(verification!),
          ] else if (isRejected) ...[
            _buildRejectedContent(verification!),
            const SizedBox(height: 24),
            _buildVerificationForm(),
          ] else ...[
            // Not yet submitted
            _buildVerificationForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BusinessVerification? verification) {
    final status = verification?.status ?? VerificationStatus.pending;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Status: ${status.displayName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (verification != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      verification.status == VerificationStatus.verified
                          ? 'Your business is verified and trusted'
                          : verification.status == VerificationStatus.pending
                              ? 'Your submission is under review'
                              : 'Please resubmit with additional information',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedContent(BusinessVerification verification) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: AppColors.electricGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  'Verified Business',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (verification.verifiedAt != null) ...[
              Text(
                'Verified on: ${_formatDate(verification.verifiedAt!)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Your business has been verified. Users can trust that you are a legitimate business.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingContent(BusinessVerification verification) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hourglass_empty, color: AppColors.warning, size: 24),
                SizedBox(width: 8),
                Text(
                  'Verification Pending',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Submitted on: ${_formatDate(verification.submittedAt)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your verification request is being reviewed. We\'ll notify you once the review is complete.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: verification.progress,
              backgroundColor: AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.electricGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${(verification.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedContent(BusinessVerification verification) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cancel, color: AppColors.error, size: 24),
                SizedBox(width: 8),
                Text(
                  'Verification Rejected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (verification.rejectionReason != null) ...[
              Text(
                'Reason: ${verification.rejectionReason}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Please review the requirements and resubmit your verification with the necessary documents.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Verify Your Business',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help us verify that you are a legitimate business. This builds trust with users and experts.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Try Automatic Verification First
          if (widget.business.website != null && widget.business.website!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Quick Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We can verify your business automatically using your website.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _tryAutomaticVerification,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Try Automatic Verification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricGreen,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],

          // Manual Verification Form
          const Text(
            'Manual Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Legal Business Name
          TextFormField(
            controller: _legalNameController,
            decoration: const InputDecoration(
              labelText: 'Legal Business Name *',
              hintText: 'As registered with government',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter legal business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Tax ID
          TextFormField(
            controller: _taxIdController,
            decoration: const InputDecoration(
              labelText: 'Tax ID / EIN (Optional)',
              hintText: 'For US businesses',
              prefixIcon: Icon(Icons.receipt),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Business Address
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Business Address *',
              hintText: 'Physical business address',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter business address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Business Phone *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter business phone';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Website
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Website URL',
              hintText: 'https://yourbusiness.com',
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),

          // Document Upload Section
          const Text(
            'Verification Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload at least one document to verify your business',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Business License Upload
          _buildDocumentUpload(
            label: 'Business License',
            currentUrl: _businessLicenseUrl,
            onUploaded: (url) {
              setState(() {
                _businessLicenseUrl = url;
              });
            },
          ),
          const SizedBox(height: 16),

          // Tax ID Document Upload
          _buildDocumentUpload(
            label: 'Tax ID Document',
            currentUrl: _taxIdDocumentUrl,
            onUploaded: (url) {
              setState(() {
                _taxIdDocumentUrl = url;
              });
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Text(
                    'Submit for Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String label,
    String? currentUrl,
    required Function(String) onUploaded,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.description, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (currentUrl != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Document uploaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.electricGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // In production, would open file picker and upload
                // For now, simulate upload
                onUploaded('https://example.com/documents/$label');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label uploaded (simulated)'),
                    backgroundColor: AppColors.electricGreen,
                  ),
                );
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(currentUrl != null ? 'Replace' : 'Upload'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.electricGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return AppColors.electricGreen;
      case VerificationStatus.pending:
      case VerificationStatus.inReview:
        return AppColors.warning;
      case VerificationStatus.rejected:
        return AppColors.error;
      case VerificationStatus.expired:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.pending:
      case VerificationStatus.inReview:
        return Icons.hourglass_empty;
      case VerificationStatus.rejected:
        return Icons.cancel;
      case VerificationStatus.expired:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

