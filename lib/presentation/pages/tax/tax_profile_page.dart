import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/tax_profile.dart';
import 'package:spots/core/services/tax_compliance_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Tax Profile Page
/// 
/// Agent 2: Phase 5, Week 18-19 - Tax UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - W-9 form
/// - Tax classification selection
/// - SSN/EIN input (encrypted)
/// - Business name (if applicable)
/// - Submit button
class TaxProfilePage extends StatefulWidget {
  const TaxProfilePage({super.key});

  @override
  State<TaxProfilePage> createState() => _TaxProfilePageState();
}

class _TaxProfilePageState extends State<TaxProfilePage> {
  final TaxComplianceService _taxService = TaxComplianceService(
    paymentService: GetIt.instance<PaymentService>(),
  );

  final _formKey = GlobalKey<FormState>();
  final _ssnController = TextEditingController();
  final _einController = TextEditingController();
  final _businessNameController = TextEditingController();

  TaxClassification? _selectedClassification;
  TaxProfile? _existingProfile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ssnController.dispose();
    _einController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to view tax profile');
      }

      final profile = await _taxService.getTaxProfile(authState.user.id);
      setState(() {
        _existingProfile = profile;
        _selectedClassification = profile.classification;
        if (profile.ssnLast4 != null) {
          _ssnController.text = '****-**-${profile.ssnLast4!.substring(profile.ssnLast4!.length - 4)}';
        }
        if (profile.einMasked != null) {
          _einController.text = profile.einMasked!;
        }
        if (profile.businessName != null) {
          _businessNameController.text = profile.businessName!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitW9() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tax classification'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to submit W-9');
      }

      // Get SSN (if not already submitted)
      String? ssn;
      if (_existingProfile == null || !_existingProfile!.w9Submitted) {
        // Extract SSN from masked format or get new input
        if (_ssnController.text.contains('****')) {
          throw Exception('Please enter your full SSN');
        }
        ssn = _ssnController.text.replaceAll(RegExp(r'[^\d]'), '');
        if (ssn.length != 9) {
          throw Exception('SSN must be 9 digits');
        }
      }

      // Get EIN if business classification
      String? ein;
      if (_needsEIN(_selectedClassification!)) {
        if (_einController.text.isEmpty) {
          throw Exception('EIN is required for business classifications');
        }
        ein = _einController.text.replaceAll(RegExp(r'[^\d]'), '');
      }

      await _taxService.submitW9(
        userId: authState.user.id,
        ssn: ssn ?? '',
        classification: _selectedClassification!,
        ein: ein,
        businessName: _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('W-9 submitted successfully'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  bool _needsEIN(TaxClassification classification) {
    return classification == TaxClassification.partnership ||
        classification == TaxClassification.corporation ||
        classification == TaxClassification.llc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tax Profile',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      _buildInfoCard(),
                      const SizedBox(height: 24),

                      // Tax Classification
                      _buildClassificationSelection(),
                      const SizedBox(height: 24),

                      // SSN Input
                      if (!_needsEIN(_selectedClassification ?? TaxClassification.individual))
                        _buildSSNInput(),
                      if (!_needsEIN(_selectedClassification ?? TaxClassification.individual))
                        const SizedBox(height: 24),

                      // EIN Input (for businesses)
                      if (_selectedClassification != null &&
                          _needsEIN(_selectedClassification!)) ...[
                        _buildEINInput(),
                        const SizedBox(height: 24),
                        _buildBusinessNameInput(),
                        const SizedBox(height: 24),
                      ],

                      // Existing Profile Info
                      if (_existingProfile?.w9Submitted ?? false) ...[
                        _buildSubmittedInfo(),
                        const SizedBox(height: 24),
                      ],

                      // Error Display
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Submit Button
                      if (!(_existingProfile?.w9Submitted ?? false))
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitW9,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(double.infinity, 48),
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
                              : const Text('Submit W-9'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'SPOTS Tax Service - Free & Easy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you earn \$600 or more in a calendar year, SPOTS will automatically handle your tax reporting. We\'ll generate your 1099-K form and file it with the IRS—all free, all easy.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.electricGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Why choose SPOTS tax service?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBenefitPoint('✓ Free - No accountant fees'),
                _buildBenefitPoint('✓ Automatic - We handle everything'),
                _buildBenefitPoint('✓ Secure - Your info is encrypted'),
                _buildBenefitPoint('✓ Simple - Just submit once'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Important: IRS Reporting Requirement',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'SPOTS is legally required to report all earnings over \$600 to the IRS, even if you don\'t submit a W-9. If you don\'t submit a W-9, the IRS will contact you directly to obtain your tax information. Submitting your W-9 now makes everything easier and ensures accurate reporting.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBenefitPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildClassificationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Classification *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...TaxClassification.values.map((classification) {
          return RadioListTile<TaxClassification>(
            title: Text(
              _getClassificationDisplayName(classification),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              _getClassificationDescription(classification),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: classification,
            groupValue: _selectedClassification,
            onChanged: (value) {
              setState(() {
                _selectedClassification = value;
                // Clear EIN/business name if switching to individual
                if (value == TaxClassification.individual) {
                  _einController.clear();
                  _businessNameController.clear();
                }
              });
            },
            activeColor: AppTheme.primaryColor,
          );
        }),
      ],
    );
  }

  Widget _buildSSNInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Security Number (SSN) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ssnController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
            _SSNFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'XXX-XX-XXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: Icon(Icons.lock, color: AppColors.textSecondary),
          ),
          style: TextStyle(color: AppColors.textPrimary),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'SSN is required';
            }
            final digits = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length != 9) {
              return 'SSN must be 9 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Your SSN is encrypted and stored securely. Only the last 4 digits will be displayed after submission.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEINInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employer Identification Number (EIN) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _einController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
            _EINFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'XX-XXXXXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: TextStyle(color: AppColors.textPrimary),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'EIN is required for business classifications';
            }
            final digits = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length != 9) {
              return 'EIN must be 9 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBusinessNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Name (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessNameController,
          decoration: InputDecoration(
            hintText: 'Enter business name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSubmittedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.electricGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.electricGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'W-9 Submitted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
                if (_existingProfile?.w9SubmittedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Submitted on ${_formatDate(_existingProfile!.w9SubmittedAt!)}',
                    style: TextStyle(
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
    );
  }

  String _getClassificationDisplayName(TaxClassification classification) {
    switch (classification) {
      case TaxClassification.individual:
        return 'Individual';
      case TaxClassification.soleProprietor:
        return 'Sole Proprietor';
      case TaxClassification.partnership:
        return 'Partnership';
      case TaxClassification.corporation:
        return 'Corporation';
      case TaxClassification.llc:
        return 'LLC';
    }
  }

  String _getClassificationDescription(TaxClassification classification) {
    switch (classification) {
      case TaxClassification.individual:
        return 'Personal tax identification';
      case TaxClassification.soleProprietor:
        return 'Single-owner business';
      case TaxClassification.partnership:
        return 'Business partnership (EIN required)';
      case TaxClassification.corporation:
        return 'Corporation (EIN required)';
      case TaxClassification.llc:
        return 'Limited Liability Company (EIN required)';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// SSN Formatter - Formats as XXX-XX-XXXX
class _SSNFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isEmpty) return newValue;

    String formatted = '';
    if (text.length > 0) {
      formatted = text.substring(0, text.length > 3 ? 3 : text.length);
    }
    if (text.length > 3) {
      formatted += '-${text.substring(3, text.length > 5 ? 5 : text.length)}';
    }
    if (text.length > 5) {
      formatted += '-${text.substring(5, text.length > 9 ? 9 : text.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// EIN Formatter - Formats as XX-XXXXXXX
class _EINFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isEmpty) return newValue;

    String formatted = '';
    if (text.length > 0) {
      formatted = text.substring(0, text.length > 2 ? 2 : text.length);
    }
    if (text.length > 2) {
      formatted += '-${text.substring(2, text.length > 9 ? 9 : text.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

