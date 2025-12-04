import 'package:flutter/material.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/widgets/business/business_account_form_widget.dart';

/// Business Account Creation Page
/// Main page for businesses to create accounts
class BusinessAccountCreationPage extends StatelessWidget {
  final UnifiedUser user;

  const BusinessAccountCreationPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Business Account'),
        backgroundColor: AppColors.electricGreen,
        foregroundColor: AppColors.white,
      ),
      body: BusinessAccountFormWidget(
        creator: user,
        onAccountCreated: (account) {
          // Navigate to business dashboard or show success
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Business account "${account.name}" created successfully!'),
              backgroundColor: AppColors.electricGreen,
              action: SnackBarAction(
                label: 'View',
                textColor: AppColors.white,
                onPressed: () {
                  // Navigate to business dashboard
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

