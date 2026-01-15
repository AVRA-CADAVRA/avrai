/// Privacy Policy Class
///
/// Contains the Privacy Policy document text and version information.
/// Used for displaying privacy policy and tracking user acceptance.
///
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables transparent privacy practices
/// - Supports user data protection
///
/// **Usage:**
/// ```dart
/// final policy = PrivacyPolicy.current();
/// print(policy.version); // '1.0.0'
/// print(policy.effectiveDate); // DateTime
/// print(policy.content); // Full privacy policy text
/// ```
class PrivacyPolicy {
  /// Current version of Privacy Policy
  static const String version = '1.0.0';

  /// Effective date of current version
  static final DateTime effectiveDate = DateTime(2025, 12, 1);

  /// Privacy Policy content
  static const String content = '''
SPOTS Privacy Policy

Last Updated: December 1, 2025

1. INFORMATION WE COLLECT
We collect information you provide directly, including:
- Account information (name, email, phone)
- Event information (titles, descriptions, locations)
- Payment information (processed securely through Stripe)
- Profile information (expertise, interests, preferences)
- Usage data (events attended, searches, interactions)

2. HOW WE USE YOUR INFORMATION
We use your information to:
- Provide and improve the SPOTS platform
- Process payments and transactions
- Send you event recommendations and updates
- Enable AI-powered matching and discovery
- Ensure platform safety and security
- Comply with legal obligations

3. AI2AI LEARNING
SPOTS uses AI2AI learning to improve recommendations:
- Your data is anonymized before AI learning
- No personal information is shared between AI agents
- You can opt out of AI learning in settings
- Your privacy is protected throughout the process

4. DATA SHARING
We do NOT sell your personal information. We share data only:
- With service providers (Stripe for payments, hosting providers)
- When required by law or legal process
- To protect rights, property, or safety
- With your explicit consent

5. DATA SECURITY
We implement industry-standard security measures:
- Encryption of sensitive data
- Secure payment processing
- Regular security audits
- Access controls and monitoring

6. YOUR RIGHTS
You have the right to:
- Access your personal data
- Correct inaccurate data
- Delete your account and data
- Export your data
- Opt out of certain data uses
- Object to processing

7. COOKIES AND TRACKING
We use cookies and similar technologies to:
- Maintain your session
- Remember your preferences
- Analyze platform usage
- Improve user experience

8. CHILDREN'S PRIVACY
SPOTS is not intended for users under 18. We do not knowingly collect data from children.

9. INTERNATIONAL USERS
If you are outside the United States, your data may be transferred to and processed in the United States.

10. CHANGES TO THIS POLICY
We may update this policy. We will notify you of material changes. Continued use constitutes acceptance.

11. CONTACT US
For privacy questions, contact: privacy@avrai.app
''';

  /// Get current Privacy Policy instance
  static PrivacyPolicy current() {
    return PrivacyPolicy();
  }

  /// Check if version is current
  static bool isCurrentVersion(String versionToCheck) {
    return versionToCheck == version;
  }

  /// Get version history (for future versions)
  static List<String> getVersionHistory() {
    return [version];
  }
}
