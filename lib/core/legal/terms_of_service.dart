/// Terms of Service Class
/// 
/// Contains the Terms of Service document text and version information.
/// Used for displaying terms and tracking user acceptance.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables transparent terms presentation
/// - Supports user protection
/// 
/// **Usage:**
/// ```dart
/// final terms = TermsOfService.current();
/// print(terms.version); // '1.0.0'
/// print(terms.effectiveDate); // DateTime
/// print(terms.content); // Full terms text
/// ```
class TermsOfService {
  /// Current version of Terms of Service
  static const String version = '1.0.0';
  
  /// Effective date of current version
  static final DateTime effectiveDate = DateTime(2025, 12, 1);
  
  /// Terms of Service content
  static const String content = '''
SPOTS Terms of Service

1. ACCEPTANCE OF TERMS
By using SPOTS, you agree to these Terms of Service. If you do not agree, do not use the platform.

2. PLATFORM FEES
SPOTS charges a 10% platform fee on all paid transactions. Processing fees (~3%) are additional.

3. REFUND POLICY
Refund policies vary by event. Standard policy: Full refund >48h before event, 50% refund 24-48h before, no refund <24h before. Force majeure events receive full refunds.

4. LIABILITY LIMITATIONS
SPOTS is a platform connecting hosts and attendees. SPOTS is not responsible for:
- Event quality or safety
- Injuries or damages at events
- Disputes between parties
- Acts of God, weather, emergencies

Maximum liability limited to amount paid for event ticket.

5. INDEMNIFICATION
Hosts agree to indemnify SPOTS against claims arising from events they host.

6. INSURANCE REQUIREMENTS
Hosts must maintain appropriate insurance for high-risk events. SPOTS may require proof of insurance.

7. COMPLIANCE
Users must comply with all local laws, permits, licenses, and regulations for events.

8. DISPUTE RESOLUTION
Disputes resolved through binding arbitration. Class action waivers apply.

9. INTELLECTUAL PROPERTY
Users retain rights to their content. By using SPOTS, users grant SPOTS license to use content for platform purposes.

10. TERMINATION
SPOTS may terminate accounts for violations of these terms, illegal activity, or platform abuse.

11. MODIFICATIONS
SPOTS may modify these terms. Users will be notified of changes. Continued use constitutes acceptance.

12. GOVERNING LAW
These terms are governed by [Jurisdiction] law.

Last Updated: December 1, 2025
''';

  /// Get current Terms of Service instance
  static TermsOfService current() {
    return TermsOfService();
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

