import 'package:flutter/material.dart';
import 'package:avrai/core/models/business_expert_preferences.dart';
import 'package:avrai/core/theme/colors.dart';

/// Business Expert Preferences Widget
/// Allows businesses to set detailed preferences for expert matching
class BusinessExpertPreferencesWidget extends StatefulWidget {
  final BusinessExpertPreferences? initialPreferences;
  final Function(BusinessExpertPreferences) onPreferencesChanged;

  const BusinessExpertPreferencesWidget({
    super.key,
    this.initialPreferences,
    required this.onPreferencesChanged,
  });

  @override
  State<BusinessExpertPreferencesWidget> createState() => _BusinessExpertPreferencesWidgetState();
}

class _BusinessExpertPreferencesWidgetState extends State<BusinessExpertPreferencesWidget> {
  late BusinessExpertPreferences _preferences;

  // Expertise
  final List<String> _requiredExpertise = [];
  final List<String> _preferredExpertise = [];
  int? _minExpertLevel;
  int? _preferredExpertLevel;

  // Location
  String? _preferredLocation;
  int? _maxDistanceKm;
  bool _allowRemote = false;

  // Demographics
  int? _minAge;
  int? _maxAge;
  final List<String> _preferredLanguages = [];

  // Experience
  int? _minYearsExperience;
  final List<String> _preferredBackgrounds = [];
  final List<String> _preferredSkills = [];

  // Personality & Work Style
  final List<String> _preferredPersonalityTraits = [];
  final List<String> _preferredWorkStyles = [];
  final List<String> _preferredCommunicationStyles = [];

  // Availability
  final List<String> _preferredAvailability = [];
  bool _requireFlexibleSchedule = false;

  // Engagement
  final List<String> _preferredEngagementTypes = [];
  int? _preferredCommitmentLevel;
  bool _preferLongTermRelationships = false;

  // AI/ML
  final List<String> _aiKeywords = [];
  String? _aiMatchingPrompt;

  // Exclusion
  final List<String> _excludedExpertise = [];
  final List<String> _excludedLocations = [];

  static const List<String> _expertiseOptions = [
    'Coffee', 'Restaurants', 'Bars', 'Pastry', 'Wine', 'Cocktails',
    'Food', 'Dining', 'Retail', 'Shopping', 'Hospitality', 'Service',
  ];

  static const List<String> _personalityTraits = [
    'Outgoing', 'Detail-oriented', 'Creative', 'Analytical',
    'Collaborative', 'Independent', 'Leadership', 'Patient',
    'Enthusiastic', 'Professional', 'Innovative', 'Reliable',
  ];

  static const List<String> _workStyles = [
    'Collaborative', 'Independent', 'Leadership', 'Team Player',
    'Self-directed', 'Structured', 'Flexible', 'Fast-paced',
  ];

  static const List<String> _communicationStyles = [
    'Direct', 'Diplomatic', 'Enthusiastic', 'Professional',
    'Casual', 'Formal', 'Clear', 'Concise',
  ];

  static const List<String> _availabilityOptions = [
    'Weekdays', 'Evenings', 'Weekends', 'Morning', 'Afternoon',
    'Night', 'Flexible', 'By Appointment',
  ];

  static const List<String> _engagementTypes = [
    'Consulting', 'Partnership', 'Mentorship', 'Advisory',
    'Collaboration', 'Project-based', 'Ongoing', 'One-time',
  ];

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences ?? const BusinessExpertPreferences();
    _loadPreferences();
  }

  void _loadPreferences() {
    _requiredExpertise.clear();
    _requiredExpertise.addAll(_preferences.requiredExpertiseCategories);
    
    _preferredExpertise.clear();
    _preferredExpertise.addAll(_preferences.preferredExpertiseCategories);
    
    _minExpertLevel = _preferences.minExpertLevel;
    _preferredExpertLevel = _preferences.preferredExpertLevel;
    _preferredLocation = _preferences.preferredLocation;
    _maxDistanceKm = _preferences.maxDistanceKm;
    _allowRemote = _preferences.allowRemote;
    
    _minAge = _preferences.preferredAgeRange?.minAge;
    _maxAge = _preferences.preferredAgeRange?.maxAge;
    
    _preferredLanguages.clear();
    _preferredLanguages.addAll(_preferences.preferredLanguages ?? []);
    
    _minYearsExperience = _preferences.minYearsExperience;
    _preferredBackgrounds.clear();
    _preferredBackgrounds.addAll(_preferences.preferredBackgrounds ?? []);
    _preferredSkills.clear();
    _preferredSkills.addAll(_preferences.preferredSkills ?? []);
    
    _preferredPersonalityTraits.clear();
    _preferredPersonalityTraits.addAll(_preferences.preferredPersonalityTraits ?? []);
    _preferredWorkStyles.clear();
    _preferredWorkStyles.addAll(_preferences.preferredWorkStyles ?? []);
    _preferredCommunicationStyles.clear();
    _preferredCommunicationStyles.addAll(_preferences.preferredCommunicationStyles ?? []);
    
    _preferredAvailability.clear();
    _preferredAvailability.addAll(_preferences.preferredAvailability ?? []);
    _requireFlexibleSchedule = _preferences.requireFlexibleSchedule;
    
    _preferredEngagementTypes.clear();
    _preferredEngagementTypes.addAll(_preferences.preferredEngagementTypes ?? []);
    _preferredCommitmentLevel = _preferences.preferredCommitmentLevel;
    _preferLongTermRelationships = _preferences.preferLongTermRelationships;
    
    _aiKeywords.clear();
    _aiKeywords.addAll(_preferences.aiKeywords ?? []);
    _aiMatchingPrompt = _preferences.aiMatchingPrompt;
    
    _excludedExpertise.clear();
    _excludedExpertise.addAll(_preferences.excludedExpertise ?? []);
    _excludedLocations.clear();
    _excludedLocations.addAll(_preferences.excludedLocations ?? []);
  }

  void _updatePreferences() {
    setState(() {
      _preferences = BusinessExpertPreferences(
        requiredExpertiseCategories: _requiredExpertise,
        preferredExpertiseCategories: _preferredExpertise,
        minExpertLevel: _minExpertLevel,
        preferredExpertLevel: _preferredExpertLevel,
        preferredLocation: _preferredLocation,
        maxDistanceKm: _maxDistanceKm,
        allowRemote: _allowRemote,
        preferredAgeRange: (_minAge != null || _maxAge != null)
            ? AgeRange(minAge: _minAge, maxAge: _maxAge)
            : null,
        preferredLanguages: _preferredLanguages.isEmpty ? null : _preferredLanguages,
        minYearsExperience: _minYearsExperience,
        preferredBackgrounds: _preferredBackgrounds.isEmpty ? null : _preferredBackgrounds,
        preferredSkills: _preferredSkills.isEmpty ? null : _preferredSkills,
        preferredPersonalityTraits: _preferredPersonalityTraits.isEmpty ? null : _preferredPersonalityTraits,
        preferredWorkStyles: _preferredWorkStyles.isEmpty ? null : _preferredWorkStyles,
        preferredCommunicationStyles: _preferredCommunicationStyles.isEmpty ? null : _preferredCommunicationStyles,
        preferredAvailability: _preferredAvailability.isEmpty ? null : _preferredAvailability,
        requireFlexibleSchedule: _requireFlexibleSchedule,
        preferredEngagementTypes: _preferredEngagementTypes.isEmpty ? null : _preferredEngagementTypes,
        preferredCommitmentLevel: _preferredCommitmentLevel,
        preferLongTermRelationships: _preferLongTermRelationships,
        aiKeywords: _aiKeywords.isEmpty ? null : _aiKeywords,
        aiMatchingPrompt: _aiMatchingPrompt,
        excludedExpertise: _excludedExpertise.isEmpty ? null : _excludedExpertise,
        excludedLocations: _excludedLocations.isEmpty ? null : _excludedLocations,
      );
    });
    widget.onPreferencesChanged(_preferences);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expert Matching Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about the types of experts you want to connect with. The AI will use these preferences to find the best matches.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Required Expertise
          _buildSectionTitle('Required Expertise *'),
          _buildChipSelector(
            options: _expertiseOptions,
            selected: _requiredExpertise,
            onChanged: (selected) {
              setState(() {
                _requiredExpertise.clear();
                _requiredExpertise.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Preferred Expertise
          _buildSectionTitle('Preferred Expertise'),
          _buildChipSelector(
            options: _expertiseOptions,
            selected: _preferredExpertise,
            onChanged: (selected) {
              setState(() {
                _preferredExpertise.clear();
                _preferredExpertise.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Expert Level
          _buildSectionTitle('Expertise Level'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _minExpertLevel,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(6, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Level $i'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _minExpertLevel = value;
                      _updatePreferences();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _preferredExpertLevel,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(6, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Level $i'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _preferredExpertLevel = value;
                      _updatePreferences();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Location Preferences
          _buildSectionTitle('Location Preferences'),
          TextFormField(
            initialValue: _preferredLocation,
            decoration: const InputDecoration(
              labelText: 'Preferred Location',
              hintText: 'e.g., Brooklyn, NYC',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _preferredLocation = value.trim().isEmpty ? null : value.trim();
              _updatePreferences();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _maxDistanceKm?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Max Distance (km)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxDistanceKm = value.isEmpty ? null : int.tryParse(value);
                    _updatePreferences();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Allow Remote'),
                  value: _allowRemote,
                  onChanged: (value) {
                    setState(() {
                      _allowRemote = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Age Range
          _buildSectionTitle('Age Preferences (Optional)'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _minAge?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Min Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _minAge = value.isEmpty ? null : int.tryParse(value);
                    _updatePreferences();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _maxAge?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Max Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxAge = value.isEmpty ? null : int.tryParse(value);
                    _updatePreferences();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Personality & Work Style
          _buildSectionTitle('Personality & Work Style'),
          _buildChipSelector(
            label: 'Personality Traits',
            options: _personalityTraits,
            selected: _preferredPersonalityTraits,
            onChanged: (selected) {
              setState(() {
                _preferredPersonalityTraits.clear();
                _preferredPersonalityTraits.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Work Styles',
            options: _workStyles,
            selected: _preferredWorkStyles,
            onChanged: (selected) {
              setState(() {
                _preferredWorkStyles.clear();
                _preferredWorkStyles.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Communication Styles',
            options: _communicationStyles,
            selected: _preferredCommunicationStyles,
            onChanged: (selected) {
              setState(() {
                _preferredCommunicationStyles.clear();
                _preferredCommunicationStyles.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Availability
          _buildSectionTitle('Availability Preferences'),
          _buildChipSelector(
            options: _availabilityOptions,
            selected: _preferredAvailability,
            onChanged: (selected) {
              setState(() {
                _preferredAvailability.clear();
                _preferredAvailability.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Require Flexible Schedule'),
            value: _requireFlexibleSchedule,
            onChanged: (value) {
              setState(() {
                _requireFlexibleSchedule = value ?? false;
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Engagement Types
          _buildSectionTitle('Engagement Preferences'),
          _buildChipSelector(
            options: _engagementTypes,
            selected: _preferredEngagementTypes,
            onChanged: (selected) {
              setState(() {
                _preferredEngagementTypes.clear();
                _preferredEngagementTypes.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _preferredCommitmentLevel,
            decoration: const InputDecoration(
              labelText: 'Preferred Commitment Level',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...List.generate(5, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('Level ${i + 1}'),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _preferredCommitmentLevel = value;
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Prefer Long-term Relationships'),
            value: _preferLongTermRelationships,
            onChanged: (value) {
              setState(() {
                _preferLongTermRelationships = value ?? false;
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // AI/ML Keywords
          _buildSectionTitle('AI Matching Keywords'),
          const Text(
            'Add keywords to help AI find better matches',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Keywords (comma-separated)',
              hintText: 'e.g., innovative, creative, experienced',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _aiKeywords.clear();
              if (value.isNotEmpty) {
                _aiKeywords.addAll(
                  value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
                );
              }
              _updatePreferences();
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _aiMatchingPrompt,
            decoration: const InputDecoration(
              labelText: 'Custom AI Matching Prompt (Optional)',
              hintText: 'Describe the ideal expert in your own words...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _aiMatchingPrompt = value.trim().isEmpty ? null : value.trim();
              _updatePreferences();
            },
          ),
          const SizedBox(height: 24),

          // Exclusion Criteria
          _buildSectionTitle('Exclusion Criteria'),
          const Text(
            'Specify what to avoid (optional)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildChipSelector(
            label: 'Excluded Expertise',
            options: _expertiseOptions,
            selected: _excludedExpertise,
            onChanged: (selected) {
              setState(() {
                _excludedExpertise.clear();
                _excludedExpertise.addAll(selected);
                _updatePreferences();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    String? label,
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (isSelectedNow) {
                final newSelection = List<String>.from(selected);
                if (isSelectedNow) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onChanged(newSelection);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

