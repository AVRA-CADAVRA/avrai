import 'package:flutter/material.dart';
import 'package:spots/presentation/pages/legal/terms_of_service_page.dart';
import 'package:spots/presentation/pages/legal/privacy_policy_page.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Legal Acceptance Dialog
/// 
/// Shows during onboarding to require Terms and Privacy Policy acceptance
class LegalAcceptanceDialog extends StatelessWidget {
  final bool requireTerms;
  final bool requirePrivacy;

  const LegalAcceptanceDialog({
    super.key,
    required this.requireTerms,
    required this.requirePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Legal Agreements Required'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To continue, please review and accept our legal agreements:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (requireTerms)
              ListTile(
                leading: const Icon(Icons.gavel, color: AppTheme.primaryColor),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServicePage(requireAcceptance: true),
                    ),
                  ).then((accepted) {
                    if (accepted == true && mounted) {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => LegalAcceptanceDialog(
                          requireTerms: false,
                          requirePrivacy: requirePrivacy,
                        ),
                      );
                    }
                  });
                },
              ),
            if (requirePrivacy)
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(requireAcceptance: true),
                    ),
                  ).then((accepted) {
                    if (accepted == true && mounted) {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => LegalAcceptanceDialog(
                          requireTerms: requireTerms,
                          requirePrivacy: false,
                        ),
                      );
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        if (!requireTerms && !requirePrivacy)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Continue'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}

