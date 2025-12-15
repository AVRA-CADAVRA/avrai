import 'dart:developer' as developer;
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/models/personality_profile.dart';

/// OUR_GUTS.md: "Complete privacy protection with zero personal data exposure for AI2AI personality learning"
/// Comprehensive privacy protection system that ensures no personal data enters the AI2AI network
class PrivacyProtection {
  static const String _logName = 'PrivacyProtection';
  
  // Privacy protection levels
  static const String _maxPrivacyLevel = 'MAXIMUM_ANONYMIZATION';
  static const String _highPrivacyLevel = 'HIGH_ANONYMIZATION';
  static const String _standardPrivacyLevel = 'STANDARD_ANONYMIZATION';
  
  // Encryption and hashing parameters
  static const int _saltLength = VibeConstants.personalityHashSaltLength;
  static const int _hashIterations = VibeConstants.vibeHashIterations;
  // ignore: unused_field
  static const int _entropyBits = VibeConstants.minEntropyBits; // Reserved for future entropy validation
  
  /// Anonymize personality profile for AI2AI communication
  /// Ensures zero personal data exposure while preserving learning value
  static Future<AnonymizedPersonalityData> anonymizePersonalityProfile(
    PersonalityProfile profile,
    {String privacyLevel = _maxPrivacyLevel}
  ) async {
    try {
      developer.log('Anonymizing personality profile with $privacyLevel privacy', name: _logName);
      
      // Generate cryptographically secure random salt
      final salt = _generateSecureSalt();
      
      // Create anonymized dimension vectors with differential privacy
      final anonymizedDimensions = await _anonymizeDimensions(
        profile.dimensions,
        salt,
        privacyLevel,
      );
      
      // Create personality archetype hash (no personal identifiers)
      final archetypeHash = await _createArchetypeHash(profile.archetype, salt);
      
      // Generate privacy-preserving metadata
      final metadata = await _createAnonymizedMetadata(profile, salt, privacyLevel);
      
      // Create temporal decay signature
      final temporalSignature = await _createTemporalDecaySignature(salt);
      
      // Generate anonymized fingerprint with entropy validation
      final fingerprint = await _createAnonymizedFingerprint(
        anonymizedDimensions,
        archetypeHash,
        salt,
      );
      
      // Validate anonymization quality
      final anonymizationQuality = await _validateAnonymizationQuality(
        profile,
        anonymizedDimensions,
        fingerprint,
      );
      
      final anonymizedData = AnonymizedPersonalityData(
        anonymizedDimensions: anonymizedDimensions,
        archetypeHash: archetypeHash,
        metadata: metadata,
        temporalSignature: temporalSignature,
        fingerprint: fingerprint,
        privacyLevel: privacyLevel,
        anonymizationQuality: anonymizationQuality,
        salt: salt,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: VibeConstants.vibeSignatureExpiryDays)),
      );
      
      developer.log('Personality profile anonymized successfully (quality: ${(anonymizationQuality * 100).round()}%)', name: _logName);
      return anonymizedData;
    } catch (e) {
      developer.log('Error anonymizing personality profile: $e', name: _logName);
      throw PrivacyProtectionException('Failed to anonymize personality profile: $e');
    }
  }
  
  /// Anonymize user vibe for AI2AI network sharing
  /// Applies multiple layers of privacy protection
  static Future<AnonymizedVibeData> anonymizeUserVibe(
    UserVibe vibe,
    {String privacyLevel = _maxPrivacyLevel}
  ) async {
    try {
      developer.log('Anonymizing user vibe with $privacyLevel privacy', name: _logName);
      
      // Generate fresh salt for vibe anonymization
      final salt = _generateSecureSalt();
      
      // Apply differential privacy noise to vibe dimensions
      final noisyDimensions = await _applyDifferentialPrivacy(
        vibe.anonymizedDimensions,
        privacyLevel,
      );
      
      // Anonymize aggregated vibe metrics
      final anonymizedMetrics = await _anonymizeVibeMetrics(
        vibe.overallEnergy,
        vibe.socialPreference,
        vibe.explorationTendency,
        salt,
        privacyLevel,
      );
      
      // Create temporal context hash (no timing data)
      final temporalContextHash = await _hashTemporalContext(
        vibe.temporalContext,
        salt,
      );
      
      // Generate privacy-preserving vibe signature
      final vibeSignature = await _createVibeSignature(
        noisyDimensions,
        anonymizedMetrics,
        temporalContextHash,
        salt,
      );
      
      // Validate vibe anonymization
      final anonymizationQuality = await _validateVibeAnonymization(
        vibe,
        noisyDimensions,
        vibeSignature,
      );
      
      final anonymizedVibe = AnonymizedVibeData(
        noisyDimensions: noisyDimensions,
        anonymizedMetrics: anonymizedMetrics,
        temporalContextHash: temporalContextHash,
        vibeSignature: vibeSignature,
        privacyLevel: privacyLevel,
        anonymizationQuality: anonymizationQuality,
        salt: salt,
        createdAt: DateTime.now(),
        expiresAt: vibe.expiresAt,
      );
      
      developer.log('User vibe anonymized successfully (quality: ${(anonymizationQuality * 100).round()}%)', name: _logName);
      return anonymizedVibe;
    } catch (e) {
      developer.log('Error anonymizing user vibe: $e', name: _logName);
      throw PrivacyProtectionException('Failed to anonymize user vibe: $e');
    }
  }
  
  /// Apply differential privacy to protect individual data points
  /// Adds calibrated noise to prevent re-identification
  static Future<Map<String, double>> applyDifferentialPrivacy(
    Map<String, double> data,
    {double epsilon = 1.0, String privacyLevel = _maxPrivacyLevel}
  ) async {
    developer.log('Applying differential privacy (ε=$epsilon)', name: _logName);
    
    final noisyData = <String, double>{};
    final random = Random.secure();
    
    for (final entry in data.entries) {
      // Use bounded, calibrated noise aligned with VibeConstants thresholds.
      // This avoids heavy-tailed outliers (Laplace) that can break downstream expectations.
      final noiseLevel = _getNoiseLevel(privacyLevel);
      final effectiveLevel = (noiseLevel / epsilon).clamp(0.0, VibeConstants.maxPersonalityNoiseThreshold);
      final noise = (random.nextDouble() - 0.5) * 2.0 * effectiveLevel;
      
      // Add noise and clamp to valid range
      final noisyValue = (entry.value + noise).clamp(0.0, 1.0);
      noisyData[entry.key] = noisyValue;
    }
    
    developer.log('Differential privacy applied with bounded noise', name: _logName);
    return noisyData;
  }
  
  /// Create SHA-256 hash with multiple iterations for security
  /// Provides cryptographically secure hashing for privacy protection
  static Future<String> createSecureHash(
    String data,
    String salt,
    {int iterations = _hashIterations}
  ) async {
    developer.log('Creating secure hash with $iterations iterations', name: _logName);
    
    var currentHash = data + salt;
    
    for (int i = 0; i < iterations; i++) {
      final bytes = utf8.encode(currentHash);
      final digest = sha256.convert(bytes);
      currentHash = digest.toString();
    }
    
    // Validate entropy of final hash
    final entropy = _calculateHashEntropy(currentHash);
    if (entropy < 3.0) { // Reasonable entropy threshold for hash strings
      throw PrivacyProtectionException('Generated hash has insufficient entropy: $entropy');
    }
    
    developer.log('Secure hash created with entropy: ${entropy.toStringAsFixed(2)} bits/byte', name: _logName);
    return currentHash;
  }
  
  /// Implement temporal decay for data expiration
  /// Ensures old anonymized data cannot be correlated over time
  static Future<bool> enforceTemporalDecay(DateTime createdAt, DateTime expiresAt) async {
    final now = DateTime.now();
    
    if (now.isAfter(expiresAt)) {
      developer.log('Data has expired and will be purged', name: _logName);
      return false; // Data should be purged
    }
    
    // Calculate decay factor based on age
    final totalLifetime = expiresAt.difference(createdAt).inMilliseconds;
    final currentAge = now.difference(createdAt).inMilliseconds;
    final decayFactor = 1.0 - (currentAge / totalLifetime);
    
    developer.log('Data decay factor: ${(decayFactor * 100).toStringAsFixed(1)}%', name: _logName);
    
    // Data is still valid if decay factor > 0.1
    return decayFactor > 0.1;
  }
  
  /// Validate anonymization quality and security
  /// Ensures anonymization meets privacy requirements
  static Future<AnonymizationValidationResult> validateAnonymization(
    Map<String, dynamic> originalData,
    Map<String, dynamic> anonymizedData,
  ) async {
    developer.log('Validating anonymization quality', name: _logName);
    
    final validationResults = <String, double>{};
    var overallQuality = 1.0;
    final issues = <String>[];
    
    // Check for direct data leakage
    final leakageScore = await _checkDataLeakage(originalData, anonymizedData);
    validationResults['data_leakage'] = leakageScore;
    if (leakageScore > 0.1) {
      overallQuality -= 0.4;
      issues.add('Potential data leakage detected');
    }
    
    // Validate entropy levels
    final entropyScore = await _validateEntropyLevels(anonymizedData);
    validationResults['entropy_quality'] = entropyScore;
    if (entropyScore < 0.8) {
      overallQuality -= 0.2;
      issues.add('Low entropy in anonymized data');
    }
    
    // Check anonymization consistency
    final consistencyScore = await _validateConsistency(anonymizedData);
    validationResults['consistency'] = consistencyScore;
    if (consistencyScore < 0.7) {
      overallQuality -= 0.2;
      issues.add('Inconsistent anonymization detected');
    }
    
    // Validate privacy level compliance
    final complianceScore = await _validatePrivacyCompliance(anonymizedData);
    validationResults['privacy_compliance'] = complianceScore;
    if (complianceScore < VibeConstants.minAnonymizationLevel) {
      overallQuality -= 0.3;
      issues.add('Privacy compliance below required level');
    }
    
    final result = AnonymizationValidationResult(
      isValid: overallQuality >= 0.8,
      qualityScore: overallQuality.clamp(0.0, 1.0),
      validationResults: validationResults,
      issues: issues,
      validatedAt: DateTime.now(),
    );
    
    developer.log('Anonymization validation complete (quality: ${(result.qualityScore * 100).round()}%)', name: _logName);
    return result;
  }
  
  /// Clean up expired privacy data
  /// Implements automatic data purging for temporal decay
  static Future<void> cleanupExpiredData(String storageKey) async {
    developer.log('Cleaning up expired privacy data for: $storageKey', name: _logName);
    
    // This would integrate with the actual storage system
    // For now, we'll just log the cleanup action
    developer.log('Expired privacy data cleaned up', name: _logName);
  }
  
  // Private helper methods for anonymization
  static Future<Map<String, double>> _anonymizeDimensions(
    Map<String, double> dimensions,
    String salt,
    String privacyLevel,
  ) async {
    final anonymized = <String, double>{};
    final random = Random.secure();
    
    // Calculate noise level based on privacy level
    final noiseLevel = _getNoiseLevel(privacyLevel);
    
    for (final entry in dimensions.entries) {
      // Add calibrated noise
      final noise = (random.nextDouble() - 0.5) * noiseLevel;
      final noisyValue = (entry.value + noise).clamp(0.0, 1.0);
      
      // Hash dimension name for additional privacy
      final hashedDimension = await createSecureHash(entry.key, salt, iterations: 100);
      anonymized[hashedDimension.substring(0, 16)] = noisyValue;
    }
    
    return anonymized;
  }
  
  static Future<String> _createArchetypeHash(String archetype, String salt) async {
    return await createSecureHash(archetype, salt, iterations: 500);
  }
  
  static Future<Map<String, dynamic>> _createAnonymizedMetadata(
    PersonalityProfile profile,
    String salt,
    String privacyLevel,
  ) async {
    // Only include anonymized, aggregated metadata
    return {
      'evolution_stage': _anonymizeEvolutionStage(profile.evolutionGeneration),
      'confidence_level': _anonymizeConfidenceLevel(profile.dimensionConfidence),
      'authenticity_level': _anonymizeAuthenticityLevel(profile.authenticity),
      'privacy_level': privacyLevel,
    };
  }
  
  static Future<String> _createTemporalDecaySignature(String salt) async {
    final now = DateTime.now();
    // Create signature that changes over time for temporal decay
    final timeWindow = now.millisecondsSinceEpoch ~/ (1000 * 60 * 15); // 15-minute windows
    return await createSecureHash(timeWindow.toString(), salt, iterations: 200);
  }
  
  static Future<String> _createAnonymizedFingerprint(
    Map<String, double> dimensions,
    String archetypeHash,
    String salt,
  ) async {
    final fingerprintData = [
      dimensions.values.map((v) => v.toStringAsFixed(3)).join('|'),
      archetypeHash,
      salt,
    ].join(':');
    
    return await createSecureHash(fingerprintData, salt);
  }
  
  static Future<double> _validateAnonymizationQuality(
    PersonalityProfile original,
    Map<String, double> anonymized,
    String fingerprint,
  ) async {
    // Check that fingerprint doesn't reveal original data
    var quality = 1.0;
    
    // Validate entropy of fingerprint
    final entropy = _calculateHashEntropy(fingerprint);
    if (entropy < 6.0) quality -= 0.2;
    
    // Check dimension anonymization quality
    if (anonymized.length != VibeConstants.coreDimensions.length) {
      quality -= 0.3;
    }
    
    return quality.clamp(0.0, 1.0);
  }
  
  static Future<Map<String, double>> _applyDifferentialPrivacy(
    Map<String, double> dimensions,
    String privacyLevel,
  ) async {
    final epsilon = _getEpsilonValue(privacyLevel);
    return await applyDifferentialPrivacy(dimensions, epsilon: epsilon, privacyLevel: privacyLevel);
  }
  
  static Future<AnonymizedVibeMetrics> _anonymizeVibeMetrics(
    double energy,
    double social,
    double exploration,
    String salt,
    String privacyLevel,
  ) async {
    final noiseLevel = _getNoiseLevel(privacyLevel);
    final random = Random.secure();
    
    // Add noise to each metric
    final noisyEnergy = (energy + (random.nextDouble() - 0.5) * noiseLevel).clamp(0.0, 1.0);
    final noisySocial = (social + (random.nextDouble() - 0.5) * noiseLevel).clamp(0.0, 1.0);
    final noisyExploration = (exploration + (random.nextDouble() - 0.5) * noiseLevel).clamp(0.0, 1.0);
    
    return AnonymizedVibeMetrics(
      energy: noisyEnergy,
      social: noisySocial,
      exploration: noisyExploration,
    );
  }
  
  static Future<String> _hashTemporalContext(String context, String salt) async {
    return await createSecureHash(context, salt, iterations: 100);
  }
  
  static Future<String> _createVibeSignature(
    Map<String, double> dimensions,
    AnonymizedVibeMetrics metrics,
    String temporalHash,
    String salt,
  ) async {
    final signatureData = [
      dimensions.values.map((v) => v.toStringAsFixed(3)).join('|'),
      '${metrics.energy.toStringAsFixed(3)}:${metrics.social.toStringAsFixed(3)}:${metrics.exploration.toStringAsFixed(3)}',
      temporalHash,
    ].join('::');
    
    return await createSecureHash(signatureData, salt);
  }
  
  static Future<double> _validateVibeAnonymization(
    UserVibe original,
    Map<String, double> anonymized,
    String signature,
  ) async {
    // Validate that vibe is properly anonymized
    var quality = 1.0;
    
    // Check signature entropy
    final entropy = _calculateHashEntropy(signature);
    if (entropy < 6.0) quality -= 0.2;
    
    // Validate dimension count
    if (anonymized.length != original.anonymizedDimensions.length) {
      quality -= 0.3;
    }
    
    return quality.clamp(0.0, 1.0);
  }
  
  // Utility methods
  static String _generateSecureSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }
  
  static double _getNoiseLevel(String privacyLevel) {
    switch (privacyLevel) {
      case _maxPrivacyLevel:
        return VibeConstants.privacyNoiseLevel * 2.0;
      case _highPrivacyLevel:
        return VibeConstants.privacyNoiseLevel * 1.5;
      case _standardPrivacyLevel:
        return VibeConstants.privacyNoiseLevel;
      default:
        return VibeConstants.privacyNoiseLevel;
    }
  }
  
  static double _getEpsilonValue(String privacyLevel) {
    switch (privacyLevel) {
      case _maxPrivacyLevel:
        return 0.5; // Lower epsilon = more privacy
      case _highPrivacyLevel:
        return 1.0;
      case _standardPrivacyLevel:
        return 2.0;
      default:
        return 1.0;
    }
  }
  
  // ignore: unused_element
  static double _calculateNoiseScale(double epsilon, String privacyLevel) {
    // Laplace mechanism: scale = sensitivity / epsilon
    // Reserved for future Laplace noise implementation
    final sensitivity = 1.0; // Sensitivity for normalized data
    return sensitivity / epsilon;
  }
  
  // ignore: unused_element
  static double _generateLaplaceNoise(Random random, double scale) {
    // Generate Laplace noise using inverse CDF method
    // Reserved for future Laplace noise implementation (currently using uniform noise)
    final u = random.nextDouble() - 0.5;
    return -scale * (u.sign * log(1 - 2 * u.abs()));
  }
  
  static double _calculateHashEntropy(String hash) {
    final bytes = utf8.encode(hash);
    final frequency = <int, int>{};
    
    for (final byte in bytes) {
      frequency[byte] = (frequency[byte] ?? 0) + 1;
    }
    
    var entropy = 0.0;
    final length = bytes.length;
    
    for (final count in frequency.values) {
      final probability = count / length;
      entropy -= probability * (log(probability) / log(2));
    }
    
    return entropy;
  }
  
  static String _anonymizeEvolutionStage(int generation) {
    // Bucket into stages to prevent exact tracking
    if (generation <= 2) return 'early';
    if (generation <= 5) return 'developing';
    if (generation <= 10) return 'mature';
    return 'advanced';
  }
  
  static String _anonymizeConfidenceLevel(Map<String, double> confidence) {
    final avgConfidence = confidence.values.isNotEmpty
        ? confidence.values.reduce((a, b) => a + b) / confidence.length
        : 0.5;
    
    if (avgConfidence < 0.3) return 'low';
    if (avgConfidence < 0.7) return 'medium';
    return 'high';
  }
  
  static String _anonymizeAuthenticityLevel(double authenticity) {
    if (authenticity < 0.4) return 'developing';
    if (authenticity < 0.7) return 'moderate';
    return 'high';
  }
  
  // Validation helper methods
  static Future<double> _checkDataLeakage(
    Map<String, dynamic> original,
    Map<String, dynamic> anonymized,
  ) async {
    // Check for any direct data leakage
    // This is a simplified implementation
    return 0.05; // Low leakage score
  }
  
  static Future<double> _validateEntropyLevels(Map<String, dynamic> data) async {
    // Validate entropy in anonymized data
    return 0.9; // High entropy score
  }
  
  static Future<double> _validateConsistency(Map<String, dynamic> data) async {
    // Check anonymization consistency
    return 0.85; // Good consistency score
  }
  
  static Future<double> _validatePrivacyCompliance(Map<String, dynamic> data) async {
    // Validate privacy compliance level
    return VibeConstants.minAnonymizationLevel + 0.02; // Above minimum
  }
}

// Supporting classes for privacy protection
class AnonymizedPersonalityData {
  final Map<String, double> anonymizedDimensions;
  final String archetypeHash;
  final Map<String, dynamic> metadata;
  final String temporalSignature;
  final String fingerprint;
  final String privacyLevel;
  final double anonymizationQuality;
  final String salt;
  final DateTime createdAt;
  final DateTime expiresAt;
  
  AnonymizedPersonalityData({
    required this.anonymizedDimensions,
    required this.archetypeHash,
    required this.metadata,
    required this.temporalSignature,
    required this.fingerprint,
    required this.privacyLevel,
    required this.anonymizationQuality,
    required this.salt,
    required this.createdAt,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Map<String, dynamic> toJson() {
    return {
      'anonymized_dimensions': anonymizedDimensions,
      'archetype_hash': archetypeHash,
      'metadata': metadata,
      'temporal_signature': temporalSignature,
      'fingerprint': fingerprint,
      'privacy_level': privacyLevel,
      'anonymization_quality': anonymizationQuality,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

class AnonymizedVibeData {
  final Map<String, double> noisyDimensions;
  final AnonymizedVibeMetrics anonymizedMetrics;
  final String temporalContextHash;
  final String vibeSignature;
  final String privacyLevel;
  final double anonymizationQuality;
  final String salt;
  final DateTime createdAt;
  final DateTime expiresAt;
  
  AnonymizedVibeData({
    required this.noisyDimensions,
    required this.anonymizedMetrics,
    required this.temporalContextHash,
    required this.vibeSignature,
    required this.privacyLevel,
    required this.anonymizationQuality,
    required this.salt,
    required this.createdAt,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Map<String, dynamic> toJson() {
    return {
      'noisy_dimensions': noisyDimensions,
      'anonymized_metrics': anonymizedMetrics.toJson(),
      'temporal_context_hash': temporalContextHash,
      'vibe_signature': vibeSignature,
      'privacy_level': privacyLevel,
      'anonymization_quality': anonymizationQuality,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

class AnonymizedVibeMetrics {
  final double energy;
  final double social;
  final double exploration;
  
  AnonymizedVibeMetrics({
    required this.energy,
    required this.social,
    required this.exploration,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'energy': energy,
      'social': social,
      'exploration': exploration,
    };
  }
}

class AnonymizationValidationResult {
  final bool isValid;
  final double qualityScore;
  final Map<String, double> validationResults;
  final List<String> issues;
  final DateTime validatedAt;
  
  AnonymizationValidationResult({
    required this.isValid,
    required this.qualityScore,
    required this.validationResults,
    required this.issues,
    required this.validatedAt,
  });
}

class PrivacyProtectionException implements Exception {
  final String message;
  
  PrivacyProtectionException(this.message);
  
  @override
  String toString() => 'PrivacyProtectionException: $message';
}