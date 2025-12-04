/// Tax Classification Enum
/// 
/// Represents the tax classification of a user/business entity.
/// Used for W-9 form and tax document generation.
/// 
/// **Classifications:**
/// - `individual`: Individual/sole proprietor
/// - `soleProprietor`: Sole proprietorship
/// - `partnership`: Partnership
/// - `corporation`: C or S corporation
/// - `llc`: Limited Liability Company
enum TaxClassification {
  individual,
  soleProprietor,
  partnership,
  corporation,
  llc;

  /// Get display name for tax classification
  String get displayName {
    switch (this) {
      case TaxClassification.individual:
        return 'Individual';
      case TaxClassification.soleProprietor:
        return 'Sole Proprietor';
      case TaxClassification.partnership:
        return 'Partnership';
      case TaxClassification.corporation:
        return 'Corporation';
      case TaxClassification.llc:
        return 'LLC';
    }
  }

  /// Get description for tax classification
  String get description {
    switch (this) {
      case TaxClassification.individual:
        return 'Individual taxpayer';
      case TaxClassification.soleProprietor:
        return 'Sole proprietorship';
      case TaxClassification.partnership:
        return 'Partnership';
      case TaxClassification.corporation:
        return 'C or S corporation';
      case TaxClassification.llc:
        return 'Limited Liability Company';
    }
  }

  /// Check if this classification requires EIN (instead of SSN)
  bool get requiresEIN {
    return this != TaxClassification.individual &&
        this != TaxClassification.soleProprietor;
  }

  /// Check if this is a business entity
  bool get isBusiness {
    return this != TaxClassification.individual;
  }

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static TaxClassification fromJson(String value) {
    return TaxClassification.values.firstWhere(
      (classification) => classification.name == value,
      orElse: () => TaxClassification.individual,
    );
  }
}

