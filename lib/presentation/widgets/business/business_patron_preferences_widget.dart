import 'package:flutter/material.dart';
import 'package:avrai/core/models/business_patron_preferences.dart';
import 'package:avrai/core/models/business_expert_preferences.dart';
import 'package:avrai/core/theme/colors.dart';

/// Business Patron Preferences Widget
/// Allows businesses to set preferences for the types of patrons they want to attract
class BusinessPatronPreferencesWidget extends StatefulWidget {
  final BusinessPatronPreferences? initialPreferences;
  final Function(BusinessPatronPreferences) onPreferencesChanged;

  const BusinessPatronPreferencesWidget({
    super.key,
    this.initialPreferences,
    required this.onPreferencesChanged,
  });

  @override
  State<BusinessPatronPreferencesWidget> createState() => _BusinessPatronPreferencesWidgetState();
}

class _BusinessPatronPreferencesWidgetState extends State<BusinessPatronPreferencesWidget> {
  late BusinessPatronPreferences _preferences;

  // Demographics
  int? _minAge;
  int? _maxAge;
  final List<String> _preferredLanguages = [];
  final List<String> _preferredLocations = [];

  // Interests & Lifestyle
  final List<String> _preferredInterests = [];
  final List<String> _preferredLifestyleTraits = [];
  final List<String> _preferredActivities = [];

  // Personality & Behavior
  final List<String> _preferredPersonalityTraits = [];
  final List<String> _preferredSocialStyles = [];
  final List<String> _preferredVibePreferences = [];

  // Spending & Engagement
  SpendingLevel? _preferredSpendingLevel;
  final List<String> _preferredVisitFrequency = [];
  bool _preferLoyalCustomers = false;
  bool _preferNewCustomers = false;

  // Expertise & Knowledge
  final List<String> _preferredExpertiseLevels = [];
  bool _preferEducatedPatrons = false;
  final List<String> _preferredKnowledgeAreas = [];

  // Community & Social
  bool _preferCommunityMembers = false;
  final List<String> _preferredCommunities = [];
  bool _preferLocalPatrons = false;
  bool _preferTourists = false;

  // Time & Availability
  final List<String> _preferredVisitTimes = [];
  final List<String> _preferredDaysOfWeek = [];

  // Special Preferences
  bool _preferAgeVerified = false;
  bool _preferPetOwners = false;
  bool _preferAccessibilityNeeds = false;
  final List<String> _preferredSpecialNeeds = [];

  // AI/ML
  final List<String> _aiKeywords = [];
  String? _aiMatchingPrompt;

  // Exclusion
  final List<String> _excludedInterests = [];
  final List<String> _excludedPersonalityTraits = [];
  final List<String> _excludedLocations = [];

  static const List<String> _interestOptions = [
    'Food', 'Coffee', 'Art', 'Music', 'Outdoor', 'Fitness',
    'Travel', 'Technology', 'Fashion', 'Books', 'Gaming', 'Wellness',
  ];

  static const List<String> _lifestyleTraits = [
    'Health-conscious', 'Eco-friendly', 'Social', 'Minimalist',
    'Luxury-oriented', 'Budget-conscious', 'Adventurous', 'Family-oriented',
  ];

  static const List<String> _activityOptions = [
    'Dining', 'Socializing', 'Working', 'Studying', 'Networking',
    'Entertainment', 'Relaxation', 'Exercise', 'Shopping',
  ];

  static const List<String> _personalityTraits = [
    'Outgoing', 'Quiet', 'Adventurous', 'Conservative',
    'Creative', 'Analytical', 'Social', 'Introverted',
  ];

  static const List<String> _socialStyles = [
    'Group-oriented', 'Solo', 'Family-friendly', 'Couples',
    'Business', 'Casual', 'Formal', 'Mixed',
  ];

  static const List<String> _vibePreferences = [
    'Casual', 'Upscale', 'Trendy', 'Cozy', 'Lively',
    'Quiet', 'Romantic', 'Professional', 'Artistic',
  ];

  static const List<String> _visitFrequencyOptions = [
    'Regular', 'Occasional', 'One-time', 'Weekly', 'Monthly',
  ];

  // ignore: unused_field
  static const List<String> _expertiseLevels = [
    'Novice', 'Intermediate', 'Expert', 'Enthusiast',
  ];

  static const List<String> _visitTimeOptions = [
    'Morning', 'Lunch', 'Afternoon', 'Evening', 'Late Night',
  ];

  static const List<String> _daysOfWeekOptions = [
    'Weekdays', 'Weekends', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences ?? const BusinessPatronPreferences();
    _loadPreferences();
  }

  void _loadPreferences() {
    _minAge = _preferences.preferredAgeRange?.minAge;
    _maxAge = _preferences.preferredAgeRange?.maxAge;
    
    _preferredLanguages.clear();
    _preferredLanguages.addAll(_preferences.preferredLanguages ?? []);
    
    _preferredLocations.clear();
    _preferredLocations.addAll(_preferences.preferredLocations ?? []);
    
    _preferredInterests.clear();
    _preferredInterests.addAll(_preferences.preferredInterests ?? []);
    
    _preferredLifestyleTraits.clear();
    _preferredLifestyleTraits.addAll(_preferences.preferredLifestyleTraits ?? []);
    
    _preferredActivities.clear();
    _preferredActivities.addAll(_preferences.preferredActivities ?? []);
    
    _preferredPersonalityTraits.clear();
    _preferredPersonalityTraits.addAll(_preferences.preferredPersonalityTraits ?? []);
    
    _preferredSocialStyles.clear();
    _preferredSocialStyles.addAll(_preferences.preferredSocialStyles ?? []);
    
    _preferredVibePreferences.clear();
    _preferredVibePreferences.addAll(_preferences.preferredVibePreferences ?? []);
    
    _preferredSpendingLevel = _preferences.preferredSpendingLevel;
    
    _preferredVisitFrequency.clear();
    _preferredVisitFrequency.addAll(_preferences.preferredVisitFrequency ?? []);
    
    _preferLoyalCustomers = _preferences.preferLoyalCustomers;
    _preferNewCustomers = _preferences.preferNewCustomers;
    
    _preferredExpertiseLevels.clear();
    _preferredExpertiseLevels.addAll(_preferences.preferredExpertiseLevels ?? []);
    
    _preferEducatedPatrons = _preferences.preferEducatedPatrons;
    
    _preferredKnowledgeAreas.clear();
    _preferredKnowledgeAreas.addAll(_preferences.preferredKnowledgeAreas ?? []);
    
    _preferCommunityMembers = _preferences.preferCommunityMembers;
    _preferredCommunities.clear();
    _preferredCommunities.addAll(_preferences.preferredCommunities ?? []);
    
    _preferLocalPatrons = _preferences.preferLocalPatrons;
    _preferTourists = _preferences.preferTourists;
    
    _preferredVisitTimes.clear();
    _preferredVisitTimes.addAll(_preferences.preferredVisitTimes ?? []);
    
    _preferredDaysOfWeek.clear();
    _preferredDaysOfWeek.addAll(_preferences.preferredDaysOfWeek ?? []);
    
    _preferAgeVerified = _preferences.preferAgeVerified;
    _preferPetOwners = _preferences.preferPetOwners;
    _preferAccessibilityNeeds = _preferences.preferAccessibilityNeeds;
    
    _preferredSpecialNeeds.clear();
    _preferredSpecialNeeds.addAll(_preferences.preferredSpecialNeeds ?? []);
    
    _aiKeywords.clear();
    _aiKeywords.addAll(_preferences.aiKeywords ?? []);
    _aiMatchingPrompt = _preferences.aiMatchingPrompt;
    
    _excludedInterests.clear();
    _excludedInterests.addAll(_preferences.excludedInterests ?? []);
    
    _excludedPersonalityTraits.clear();
    _excludedPersonalityTraits.addAll(_preferences.excludedPersonalityTraits ?? []);
    
    _excludedLocations.clear();
    _excludedLocations.addAll(_preferences.excludedLocations ?? []);
  }

  void _updatePreferences() {
    setState(() {
      _preferences = BusinessPatronPreferences(
        preferredAgeRange: (_minAge != null || _maxAge != null)
            ? AgeRange(minAge: _minAge, maxAge: _maxAge)
            : null,
        preferredLanguages: _preferredLanguages.isEmpty ? null : _preferredLanguages,
        preferredLocations: _preferredLocations.isEmpty ? null : _preferredLocations,
        preferredInterests: _preferredInterests.isEmpty ? null : _preferredInterests,
        preferredLifestyleTraits: _preferredLifestyleTraits.isEmpty ? null : _preferredLifestyleTraits,
        preferredActivities: _preferredActivities.isEmpty ? null : _preferredActivities,
        preferredPersonalityTraits: _preferredPersonalityTraits.isEmpty ? null : _preferredPersonalityTraits,
        preferredSocialStyles: _preferredSocialStyles.isEmpty ? null : _preferredSocialStyles,
        preferredVibePreferences: _preferredVibePreferences.isEmpty ? null : _preferredVibePreferences,
        preferredSpendingLevel: _preferredSpendingLevel,
        preferredVisitFrequency: _preferredVisitFrequency.isEmpty ? null : _preferredVisitFrequency,
        preferLoyalCustomers: _preferLoyalCustomers,
        preferNewCustomers: _preferNewCustomers,
        preferredExpertiseLevels: _preferredExpertiseLevels.isEmpty ? null : _preferredExpertiseLevels,
        preferEducatedPatrons: _preferEducatedPatrons,
        preferredKnowledgeAreas: _preferredKnowledgeAreas.isEmpty ? null : _preferredKnowledgeAreas,
        preferCommunityMembers: _preferCommunityMembers,
        preferredCommunities: _preferredCommunities.isEmpty ? null : _preferredCommunities,
        preferLocalPatrons: _preferLocalPatrons,
        preferTourists: _preferTourists,
        preferredVisitTimes: _preferredVisitTimes.isEmpty ? null : _preferredVisitTimes,
        preferredDaysOfWeek: _preferredDaysOfWeek.isEmpty ? null : _preferredDaysOfWeek,
        preferAgeVerified: _preferAgeVerified,
        preferPetOwners: _preferPetOwners,
        preferAccessibilityNeeds: _preferAccessibilityNeeds,
        preferredSpecialNeeds: _preferredSpecialNeeds.isEmpty ? null : _preferredSpecialNeeds,
        aiKeywords: _aiKeywords.isEmpty ? null : _aiKeywords,
        aiMatchingPrompt: _aiMatchingPrompt,
        excludedInterests: _excludedInterests.isEmpty ? null : _excludedInterests,
        excludedPersonalityTraits: _excludedPersonalityTraits.isEmpty ? null : _excludedPersonalityTraits,
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
            'Patron Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about the types of patrons you want to attract. The central AI will use these preferences to recommend your business to appropriate users.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Demographics
          _buildSectionTitle('Demographics'),
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

          // Interests & Lifestyle
          _buildSectionTitle('Interests & Lifestyle'),
          _buildChipSelector(
            label: 'Preferred Interests',
            options: _interestOptions,
            selected: _preferredInterests,
            onChanged: (selected) {
              setState(() {
                _preferredInterests.clear();
                _preferredInterests.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Lifestyle Traits',
            options: _lifestyleTraits,
            selected: _preferredLifestyleTraits,
            onChanged: (selected) {
              setState(() {
                _preferredLifestyleTraits.clear();
                _preferredLifestyleTraits.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Preferred Activities',
            options: _activityOptions,
            selected: _preferredActivities,
            onChanged: (selected) {
              setState(() {
                _preferredActivities.clear();
                _preferredActivities.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Personality & Vibe
          _buildSectionTitle('Personality & Vibe'),
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
            label: 'Social Styles',
            options: _socialStyles,
            selected: _preferredSocialStyles,
            onChanged: (selected) {
              setState(() {
                _preferredSocialStyles.clear();
                _preferredSocialStyles.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Vibe Preferences',
            options: _vibePreferences,
            selected: _preferredVibePreferences,
            onChanged: (selected) {
              setState(() {
                _preferredVibePreferences.clear();
                _preferredVibePreferences.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Spending & Engagement
          _buildSectionTitle('Spending & Engagement'),
          DropdownButtonFormField<SpendingLevel?>(
            initialValue: _preferredSpendingLevel,
            decoration: const InputDecoration(
              labelText: 'Preferred Spending Level',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...SpendingLevel.values.map((level) => DropdownMenuItem(
                value: level,
                child: Text(level.displayName),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _preferredSpendingLevel = value;
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Visit Frequency',
            options: _visitFrequencyOptions,
            selected: _preferredVisitFrequency,
            onChanged: (selected) {
              setState(() {
                _preferredVisitFrequency.clear();
                _preferredVisitFrequency.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Loyal Customers'),
                  value: _preferLoyalCustomers,
                  onChanged: (value) {
                    setState(() {
                      _preferLoyalCustomers = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer New Customers'),
                  value: _preferNewCustomers,
                  onChanged: (value) {
                    setState(() {
                      _preferNewCustomers = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Community & Location
          _buildSectionTitle('Community & Location'),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Community Members'),
                  value: _preferCommunityMembers,
                  onChanged: (value) {
                    setState(() {
                      _preferCommunityMembers = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Local Patrons'),
                  value: _preferLocalPatrons,
                  onChanged: (value) {
                    setState(() {
                      _preferLocalPatrons = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Tourists'),
                  value: _preferTourists,
                  onChanged: (value) {
                    setState(() {
                      _preferTourists = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Educated Patrons'),
                  value: _preferEducatedPatrons,
                  onChanged: (value) {
                    setState(() {
                      _preferEducatedPatrons = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Visit Times
          _buildSectionTitle('Preferred Visit Times'),
          _buildChipSelector(
            label: 'Times',
            options: _visitTimeOptions,
            selected: _preferredVisitTimes,
            onChanged: (selected) {
              setState(() {
                _preferredVisitTimes.clear();
                _preferredVisitTimes.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildChipSelector(
            label: 'Days of Week',
            options: _daysOfWeekOptions,
            selected: _preferredDaysOfWeek,
            onChanged: (selected) {
              setState(() {
                _preferredDaysOfWeek.clear();
                _preferredDaysOfWeek.addAll(selected);
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // Special Preferences
          _buildSectionTitle('Special Preferences'),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Age Verified (18+)'),
                  value: _preferAgeVerified,
                  onChanged: (value) {
                    setState(() {
                      _preferAgeVerified = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Prefer Pet Owners'),
                  value: _preferPetOwners,
                  onChanged: (value) {
                    setState(() {
                      _preferPetOwners = value ?? false;
                      _updatePreferences();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Prefer Accessibility Needs'),
            value: _preferAccessibilityNeeds,
            onChanged: (value) {
              setState(() {
                _preferAccessibilityNeeds = value ?? false;
                _updatePreferences();
              });
            },
          ),
          const SizedBox(height: 24),

          // AI/ML Keywords
          _buildSectionTitle('AI Matching Keywords'),
          const Text(
            'Add keywords to help the central AI recommend your business to appropriate users',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Keywords (comma-separated)',
              hintText: 'e.g., family-friendly, upscale, trendy',
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
              hintText: 'Describe your ideal patrons in your own words...',
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
            label: 'Excluded Interests',
            options: _interestOptions,
            selected: _excludedInterests,
            onChanged: (selected) {
              setState(() {
                _excludedInterests.clear();
                _excludedInterests.addAll(selected);
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

