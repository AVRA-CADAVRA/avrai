import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AgeCollectionPage extends StatefulWidget {
  final DateTime? selectedBirthday;
  final Function(DateTime?) onBirthdayChanged;

  const AgeCollectionPage({
    super.key,
    this.selectedBirthday,
    required this.onBirthdayChanged,
  });

  @override
  State<AgeCollectionPage> createState() => _AgeCollectionPageState();
}

class _AgeCollectionPageState extends State<AgeCollectionPage> {
  DateTime? _selectedBirthday;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBirthday = widget.selectedBirthday;
    if (_selectedBirthday != null) {
      _dateController.text = DateFormat('MM/dd/yyyy').format(_selectedBirthday!);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  String _getAgeGroup(int age) {
    if (age < 13) return 'Under 13';
    if (age < 18) return 'Teen (13-17)';
    if (age < 26) return 'Young Adult (18-25)';
    if (age < 65) return 'Adult (26-64)';
    return 'Senior (65+)';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
      widget.onBirthdayChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(_selectedBirthday);
    final ageGroup = age != null ? _getAgeGroup(age) : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Age Verification',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need your age to provide age-appropriate content and ensure legal compliance.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 32),

          // Birthday Input
          Card(
            child: InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birthday',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.grey600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedBirthday != null
                                ? DateFormat('MMMM dd, yyyy').format(_selectedBirthday!)
                                : 'Tap to select your birthday',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedBirthday != null) ...[
            const SizedBox(height: 24),
            // Age Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age: $age years old',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age Group: $ageGroup',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.grey700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Privacy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.grey600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your age is stored securely and used only to provide age-appropriate content. We respect your privacy per OUR_GUTS.md principles.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

