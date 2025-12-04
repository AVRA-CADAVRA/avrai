import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_safety_guidelines.dart';
import 'package:spots/core/services/event_safety_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Safety Checklist Widget
/// 
/// Agent 2: Phase 5, Week 16-17 - Safety Checklist UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Checklist of safety requirements
/// - Emergency contact form
/// - Insurance recommendation display
/// - Acknowledgment checkbox
/// - Educational tooltips
class SafetyChecklistWidget extends StatefulWidget {
  final ExpertiseEvent event;
  final bool showAcknowledgment;
  final ValueChanged<bool>? onAcknowledged;
  final bool readOnly;

  const SafetyChecklistWidget({
    super.key,
    required this.event,
    this.showAcknowledgment = true,
    this.onAcknowledged,
    this.readOnly = false,
  });

  @override
  State<SafetyChecklistWidget> createState() => _SafetyChecklistWidgetState();
}

class _SafetyChecklistWidgetState extends State<SafetyChecklistWidget> {
  final EventSafetyService _safetyService = EventSafetyService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  EventSafetyGuidelines? _guidelines;
  bool _isLoading = true;
  bool _acknowledged = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuidelines();
  }

  Future<void> _loadGuidelines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guidelines = await _safetyService.generateGuidelines(widget.event.id);
      setState(() {
        _guidelines = guidelines;
        _acknowledged = guidelines.acknowledged;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledgeGuidelines() async {
    if (_guidelines == null || widget.readOnly) return;

    try {
      await _safetyService.acknowledgeGuidelines(widget.event.id);
      setState(() {
        _acknowledged = true;
        _guidelines = _guidelines!.copyWith(
          acknowledged: true,
          acknowledgedAt: DateTime.now(),
        );
      });

      if (widget.onAcknowledged != null) {
        widget.onAcknowledged!(true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Safety guidelines acknowledged'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              'Error loading safety guidelines',
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadGuidelines,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_guidelines == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildRequirementsList(),
          if (_guidelines!.emergencyInfo != null) ...[
            const SizedBox(height: 24),
            _buildEmergencyInfo(),
          ],
          if (_guidelines!.insurance != null) ...[
            const SizedBox(height: 24),
            _buildInsuranceRecommendation(),
          ],
          if (widget.showAcknowledgment) ...[
            const SizedBox(height: 24),
            _buildAcknowledgment(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.security,
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
                'Safety Checklist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ensure your event meets safety requirements',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    final requirements = _guidelines!.requirements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Requirements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...requirements.map((requirement) => _buildRequirementItem(requirement)),
      ],
    );
  }

  Widget _buildRequirementItem(SafetyRequirement requirement) {
    final displayName = _getRequirementDisplayName(requirement);
    final description = _getRequirementDescription(requirement);
    final icon = _getRequirementIcon(requirement);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.electricGreen,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    final emergencyInfo = _guidelines!.emergencyInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Emergency Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (emergencyInfo.contacts.isNotEmpty) ...[
                Text(
                  'Emergency Contacts:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...emergencyInfo.contacts.map((contact) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${contact.name} (${contact.role})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  contact.phone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              if (emergencyInfo.nearestHospital != null) ...[
                Text(
                  'Nearest Hospital:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emergencyInfo.nearestHospital!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (emergencyInfo.nearestHospitalAddress != null) ...[
                  Text(
                    emergencyInfo.nearestHospitalAddress!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (emergencyInfo.nearestHospitalPhone != null) ...[
                  Text(
                    emergencyInfo.nearestHospitalPhone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              if (emergencyInfo.meetingPoint != null) ...[
                Text(
                  'Emergency Meeting Point:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emergencyInfo.meetingPoint!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceRecommendation() {
    final insurance = _guidelines!.insurance!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shield,
              color: insurance.required ? AppColors.error : AppTheme.warningColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Insurance Recommendation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (insurance.required ? AppColors.error : AppTheme.warningColor)
                .withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (insurance.required ? AppColors.error : AppTheme.warningColor)
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: insurance.required
                          ? AppColors.error
                          : AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      insurance.required ? 'REQUIRED' : 'RECOMMENDED',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insurance.explanation,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Suggested Coverage: \$${insurance.suggestedCoverageAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (insurance.insuranceProviders.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Recommended Providers:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                ...insurance.insuranceProviders.map((provider) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.electricGreen),
                          const SizedBox(width: 4),
                          Text(
                            provider,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _acknowledged ? AppColors.electricGreen : AppColors.grey300,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _acknowledged,
            onChanged: widget.readOnly
                ? null
                : (value) {
                    if (value == true) {
                      _acknowledgeGuidelines();
                    }
                  },
            activeColor: AppTheme.primaryColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I acknowledge the safety requirements',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By checking this box, you confirm that you understand and will comply with all safety requirements for this event.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRequirementDisplayName(SafetyRequirement requirement) {
    switch (requirement) {
      case SafetyRequirement.capacityLimit:
        return 'Capacity Limit';
      case SafetyRequirement.emergencyExits:
        return 'Emergency Exits';
      case SafetyRequirement.firstAidKit:
        return 'First Aid Kit';
      case SafetyRequirement.emergencyContacts:
        return 'Emergency Contacts';
      case SafetyRequirement.weatherPlan:
        return 'Weather Plan';
      case SafetyRequirement.alcoholPolicy:
        return 'Alcohol Policy';
      case SafetyRequirement.minorPolicy:
        return 'Minor Policy';
      case SafetyRequirement.foodSafety:
        return 'Food Safety';
      case SafetyRequirement.accessibilityPlan:
        return 'Accessibility Plan';
      case SafetyRequirement.covidProtocol:
        return 'COVID Protocol';
      case SafetyRequirement.securityPersonnel:
        return 'Security Personnel';
      case SafetyRequirement.fireSafety:
        return 'Fire Safety';
      case SafetyRequirement.crowdControl:
        return 'Crowd Control';
    }
  }

  String? _getRequirementDescription(SafetyRequirement requirement) {
    switch (requirement) {
      case SafetyRequirement.capacityLimit:
        return 'Event must not exceed maximum attendee capacity';
      case SafetyRequirement.emergencyExits:
        return 'Clear emergency exit routes must be identified and accessible';
      case SafetyRequirement.firstAidKit:
        return 'First aid kit must be available on-site';
      case SafetyRequirement.emergencyContacts:
        return 'Emergency contact information must be readily available';
      case SafetyRequirement.weatherPlan:
        return 'Plan for weather-related contingencies';
      case SafetyRequirement.alcoholPolicy:
        return 'Alcohol service must comply with local regulations';
      case SafetyRequirement.minorPolicy:
        return 'Special considerations for events with minors';
      case SafetyRequirement.foodSafety:
        return 'Food handling must comply with health regulations';
      case SafetyRequirement.accessibilityPlan:
        return 'Event must be accessible to all attendees';
      case SafetyRequirement.covidProtocol:
        return 'COVID-19 safety protocols must be followed';
      case SafetyRequirement.securityPersonnel:
        return 'Security personnel may be required for large events';
      case SafetyRequirement.fireSafety:
        return 'Fire safety measures must be in place';
      case SafetyRequirement.crowdControl:
        return 'Crowd control measures must be implemented';
    }
  }

  IconData _getRequirementIcon(SafetyRequirement requirement) {
    switch (requirement) {
      case SafetyRequirement.capacityLimit:
        return Icons.people;
      case SafetyRequirement.emergencyExits:
        return Icons.exit_to_app;
      case SafetyRequirement.firstAidKit:
        return Icons.medical_services;
      case SafetyRequirement.emergencyContacts:
        return Icons.phone;
      case SafetyRequirement.weatherPlan:
        return Icons.wb_sunny;
      case SafetyRequirement.alcoholPolicy:
        return Icons.local_bar;
      case SafetyRequirement.minorPolicy:
        return Icons.child_care;
      case SafetyRequirement.foodSafety:
        return Icons.restaurant;
      case SafetyRequirement.accessibilityPlan:
        return Icons.accessible;
      case SafetyRequirement.covidProtocol:
        return Icons.health_and_safety;
      case SafetyRequirement.securityPersonnel:
        return Icons.security;
      case SafetyRequirement.fireSafety:
        return Icons.local_fire_department;
      case SafetyRequirement.crowdControl:
        return Icons.groups;
    }
  }
}

