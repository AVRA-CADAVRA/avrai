import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/business_account.dart';
import 'package:avrai/core/models/event_partnership.dart';
import 'package:avrai/core/controllers/partnership_proposal_controller.dart';
import 'package:avrai/core/services/partnership_matching_service.dart';
import 'package:avrai/core/services/business_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:get_it/get_it.dart';

/// Partnership Proposal Page
/// 
/// Allows users to propose partnerships with businesses for events.
/// Shows AI-suggested partners (70%+ compatibility) and allows search.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipProposalPage extends StatefulWidget {
  final ExpertiseEvent event;

  const PartnershipProposalPage({
    super.key,
    required this.event,
  });

  @override
  State<PartnershipProposalPage> createState() => _PartnershipProposalPageState();
}

class _PartnershipProposalPageState extends State<PartnershipProposalPage> {
  final _matchingService = GetIt.instance<PartnershipMatchingService>();
  final _businessService = GetIt.instance<BusinessService>();
  
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<PartnershipSuggestion> _suggestions = [];
  List<BusinessAccount> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Defer loading suggestions until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      final suggestions = await _matchingService.findMatchingPartners(
        userId: authState.user.id,
        eventId: widget.event.id,
        minCompatibility: 0.70, // 70% threshold
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error loading partnership suggestions: $e',
        name: 'PartnershipProposalPage',
        error: e,
        stackTrace: stackTrace,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading suggestions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _searchBusinesses(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _businessService.findBusinesses(
        category: query.isNotEmpty ? query : null,
        verifiedOnly: true,
        maxResults: 20,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error searching businesses: $e',
        name: 'PartnershipProposalPage',
        error: e,
        stackTrace: stackTrace,
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProposalForm(BusinessAccount business, double? compatibility) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnershipProposalFormPage(
          event: widget.event,
          business: business,
          compatibility: compatibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Partnership Proposal',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Business Partner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Partner with businesses to host events together',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 Search businesses...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _searchBusinesses('');
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: _searchBusinesses,
              ),
            ),

            const SizedBox(height: 24),

            // Search Results or Suggestions
            if (_searchController.text.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No businesses found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._searchResults.map((business) => _buildBusinessCard(
                      business,
                      null, // No compatibility score for search results
                    )),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Suggested Partners (Vibe Match)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No suggested partners yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try searching for businesses or check back later',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._suggestions.where((s) => s.business != null).map((suggestion) => _buildBusinessCard(
                    suggestion.business!,
                    suggestion.compatibility,
                  )),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BusinessAccount business, double? compatibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Business Icon/Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: business.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              business.logoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (business.categories.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            business.categories.join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (compatibility != null)
                    CompatibilityBadge(compatibility: compatibility),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // View profile
                        // TODO: Navigate to business profile
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showProposalForm(business, compatibility),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Propose'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Partnership Proposal Form Page
/// 
/// Form for creating a partnership proposal with terms and revenue split.
class PartnershipProposalFormPage extends StatefulWidget {
  final ExpertiseEvent event;
  final BusinessAccount business;
  final double? compatibility;

  const PartnershipProposalFormPage({
    super.key,
    required this.event,
    required this.business,
    this.compatibility,
  });

  @override
  State<PartnershipProposalFormPage> createState() => _PartnershipProposalFormPageState();
}

class _PartnershipProposalFormPageState extends State<PartnershipProposalFormPage> {
  final _partnershipController = GetIt.instance<PartnershipProposalController>();
  final _formKey = GlobalKey<FormState>();
  
  PartnershipType _partnershipType = PartnershipType.eventBased;
  double _userPercentage = 50.0;
  double _businessPercentage = 50.0;
  final List<String> _selectedResponsibilities = [];
  final _customTermsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _availableResponsibilities = [
    'Provide venue',
    'Marketing support',
    'Equipment',
    'Catering',
    'Staff support',
  ];

  @override
  void dispose() {
    _customTermsController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      // Create partnership agreement with terms
      final agreement = PartnershipAgreement(
        id: 'agreement_${DateTime.now().millisecondsSinceEpoch}',
        partnershipId: '', // Will be set by service
        terms: {
          'revenueSplit': {
            'userPercentage': _userPercentage,
            'businessPercentage': _businessPercentage,
          },
          'responsibilities': _selectedResponsibilities,
        },
        customArrangementDetails: _customTermsController.text.trim().isEmpty
            ? null
            : _customTermsController.text.trim(),
        agreedAt: DateTime.now(),
        agreedBy: authState.user.id,
      );

      // Create partnership proposal using controller
      final proposalData = PartnershipProposalData(
        agreement: agreement,
        type: _partnershipType,
        sharedResponsibilities: _selectedResponsibilities,
        vibeCompatibilityScore: widget.compatibility,
      );

      final result = await _partnershipController.createProposal(
        eventId: widget.event.id,
        proposerId: authState.user.id,
        businessId: widget.business.id,
        data: proposalData,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result.success) {
          Navigator.pop(context); // Close form
          Navigator.pop(context); // Close proposal page
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Partnership proposal sent to ${widget.business.name}!'),
              backgroundColor: AppColors.electricGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending proposal: ${result.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error sending partnership proposal: $e',
        name: 'PartnershipProposalFormPage',
        error: e,
        stackTrace: stackTrace,
      );
      
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending proposal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Partnership Proposal',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.business.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (widget.compatibility != null) ...[
                                const SizedBox(height: 4),
                                CompatibilityBadge(compatibility: widget.compatibility!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Partnership Type
                const Text(
                  'Partnership Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<PartnershipType>(
                  groupValue: _partnershipType,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _partnershipType = val;
                      });
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<PartnershipType>(
                        title: const Text('Co-Host (Equal partners)'),
                        subtitle: const Text('Share responsibilities equally'),
                        value: PartnershipType.eventBased,
                      ),
                      RadioListTile<PartnershipType>(
                        title: const Text('Venue Provider (Business venue)'),
                        subtitle: const Text('Business provides venue space'),
                        value: PartnershipType.ongoing,
                      ),
                      RadioListTile<PartnershipType>(
                        title: const Text('Sponsorship'),
                        subtitle: const Text('Business sponsors the event'),
                        value: PartnershipType.exclusive,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Revenue Split
                const Text(
                  'Revenue Split',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_userPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.business.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_businessPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _userPercentage,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_userPercentage.toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      _userPercentage = value;
                      _businessPercentage = 100.0 - value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Responsibilities
                const Text(
                  'Responsibilities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._availableResponsibilities.map((responsibility) => CheckboxListTile(
                      title: Text(responsibility),
                      value: _selectedResponsibilities.contains(responsibility),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedResponsibilities.add(responsibility);
                          } else {
                            _selectedResponsibilities.remove(responsibility);
                          }
                        });
                      },
                    )),

                const SizedBox(height: 24),

                // Custom Terms
                const Text(
                  'Custom Terms (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customTermsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional terms or notes...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Send Proposal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

