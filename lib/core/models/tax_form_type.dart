/// Tax Form Type Enum
/// 
/// Represents different types of tax forms.
/// 
/// **Form Types:**
/// - `form1099K`: Payment card and third party network transactions (1099-K)
/// - `form1099NEC`: Nonemployee compensation (1099-NEC)
/// - `formW9`: Request for taxpayer identification number and certification (W-9)
enum TaxFormType {
  form1099K,
  form1099NEC,
  formW9;

  /// Get display name for tax form type
  String get displayName {
    switch (this) {
      case TaxFormType.form1099K:
        return 'Form 1099-K';
      case TaxFormType.form1099NEC:
        return 'Form 1099-NEC';
      case TaxFormType.formW9:
        return 'Form W-9';
    }
  }

  /// Get description for tax form type
  String get description {
    switch (this) {
      case TaxFormType.form1099K:
        return 'Payment card and third party network transactions';
      case TaxFormType.form1099NEC:
        return 'Nonemployee compensation';
      case TaxFormType.formW9:
        return 'Request for taxpayer identification number and certification';
    }
  }

  /// Get form number as string
  String get formNumber {
    switch (this) {
      case TaxFormType.form1099K:
        return '1099-K';
      case TaxFormType.form1099NEC:
        return '1099-NEC';
      case TaxFormType.formW9:
        return 'W-9';
    }
  }

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static TaxFormType fromJson(String value) {
    return TaxFormType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TaxFormType.form1099K,
    );
  }
}

