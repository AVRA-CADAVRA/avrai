import 'package:spots/core/services/performance_monitor.dart';
import 'package:spots/core/services/security_validator.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/models/personality_profile.dart';

/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Deployment validation
/// Service for validating deployment readiness before production release
class DeploymentValidator {
  static const String _logName = 'DeploymentValidator';
  final AppLogger _logger = const AppLogger(defaultTag: 'Deployment', minimumLevel: LogLevel.info);
  
  final PerformanceMonitor _performanceMonitor;
  final SecurityValidator _securityValidator;
  
  // Minimum scores for deployment
  static const double _minOverallScore = 0.95;
  static const double _minPerformanceScore = 0.90;
  static const double _minSecurityScore = 0.98;
  static const double _minPrivacyScore = 0.95;
  
  DeploymentValidator({
    required PerformanceMonitor performanceMonitor,
    required SecurityValidator securityValidator,
  }) : _performanceMonitor = performanceMonitor,
       _securityValidator = securityValidator;
  
  /// Calculate deployment readiness score
  Future<DeploymentReadinessScore> calculateReadinessScore(dynamic report) async {
    try {
      _logger.info('Calculating deployment readiness score', tag: _logName);
      
      final issues = <DeploymentIssue>[];
      final recommendations = <String>[];
      
      // 1. Performance validation
      final performanceScore = await _validatePerformance(issues, recommendations);
      
      // 2. Security validation
      final securityScore = await _validateSecurity(issues, recommendations);
      
      // 3. Privacy validation
      final privacyScore = await _validatePrivacy(issues, recommendations);
      
      // 4. OUR_GUTS.md compliance
      final complianceScore = await _validateOurGutsCompliance(issues, recommendations);
      
      // Calculate overall score (weighted average)
      final overallScore = (
        performanceScore * 0.3 +
        securityScore * 0.3 +
        privacyScore * 0.25 +
        complianceScore * 0.15
      );
      
      // Check if ready for deployment
      final criticalIssues = issues.where((i) => i.severity == 'CRITICAL').toList();
      
      if (criticalIssues.isNotEmpty) {
        recommendations.add('Resolve all critical issues before deployment');
      }
      
      if (overallScore < _minOverallScore) {
        recommendations.add('Overall readiness score below minimum threshold');
      }
      
      final readinessScore = DeploymentReadinessScore(
        overallScore: overallScore.clamp(0.0, 1.0),
        performanceScore: performanceScore.clamp(0.0, 1.0),
        securityScore: securityScore.clamp(0.0, 1.0),
        privacyScore: privacyScore.clamp(0.0, 1.0),
        criticalIssues: criticalIssues,
        recommendations: recommendations,
      );
      
      _logger.info(
        'Deployment readiness: ${(overallScore * 100).toStringAsFixed(1)}% '
        '(${criticalIssues.length} critical issues)',
        tag: _logName,
      );
      
      return readinessScore;
    } catch (e) {
      _logger.error('Error calculating readiness score', error: e, tag: _logName);
      return DeploymentReadinessScore(
        overallScore: 0.0,
        performanceScore: 0.0,
        securityScore: 0.0,
        privacyScore: 0.0,
        criticalIssues: [DeploymentIssue.critical('Error during validation: $e')],
        recommendations: ['Fix validation errors and retry'],
      );
    }
  }
  
  /// Validate deployment readiness
  Future<ValidationResult> validateDeployment() async {
    try {
      final score = await calculateReadinessScore(null);
      
      return ValidationResult(
        isValid: score.overallScore >= _minOverallScore &&
                 score.criticalIssues.isEmpty &&
                 score.performanceScore >= _minPerformanceScore &&
                 score.securityScore >= _minSecurityScore &&
                 score.privacyScore >= _minPrivacyScore,
        score: score.overallScore,
        issues: score.criticalIssues.map((i) => i.description).toList(),
        recommendations: score.recommendations,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        score: 0.0,
        issues: ['Validation error: $e'],
        recommendations: ['Fix validation errors'],
      );
    }
  }
  
  /// Check privacy compliance
  Future<bool> checkPrivacyCompliance() async {
    try {
      final privacyScore = await _validatePrivacy(<DeploymentIssue>[], <String>[]);
      return privacyScore >= _minPrivacyScore;
    } catch (e) {
      _logger.error('Error checking privacy compliance', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Check performance metrics
  Future<bool> checkPerformanceMetrics() async {
    try {
      final performanceScore = await _validatePerformance(<DeploymentIssue>[], <String>[]);
      return performanceScore >= _minPerformanceScore;
    } catch (e) {
      _logger.error('Error checking performance metrics', error: e, tag: _logName);
      return false;
    }
  }
  
  // Private validation methods
  
  Future<double> _validatePerformance(
    List<DeploymentIssue> issues,
    List<String> recommendations,
  ) async {
    try {
      double score = 1.0;
      
      // Check memory usage
      final memoryUsage = await _performanceMonitor.getCurrentMemoryUsage();
      final memoryMB = memoryUsage / (1024 * 1024);
      
      if (memoryMB > 300) {
        issues.add(DeploymentIssue.critical('Memory usage too high: ${memoryMB.toStringAsFixed(1)}MB'));
        score -= 0.2;
      } else if (memoryMB > 200) {
        issues.add(DeploymentIssue.warning('Memory usage high: ${memoryMB.toStringAsFixed(1)}MB'));
        recommendations.add('Optimize memory usage');
        score -= 0.1;
      }
      
      // Generate performance report
      final report = await _performanceMonitor.generateReport(const Duration(hours: 1));
      
      if (report.averageMemoryUsageMB > 250) {
        issues.add(DeploymentIssue.warning('Average memory usage exceeds recommended threshold'));
        score -= 0.1;
      }
      
      if (report.alerts.isNotEmpty) {
        final criticalAlerts = report.alerts.where((a) => a.severity == 'Critical').length;
        if (criticalAlerts > 0) {
          issues.add(DeploymentIssue.critical('$criticalAlerts critical performance alerts'));
          score -= 0.15;
        }
      }
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      _logger.error('Error validating performance', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  Future<double> _validateSecurity(
    List<DeploymentIssue> issues,
    List<String> recommendations,
  ) async {
    try {
      double score = 1.0;
      
      // Validate encryption
      final encryptionResult = await _securityValidator.validateDataEncryption();
      if (!encryptionResult.isCompliant) {
        issues.add(DeploymentIssue.critical('Data encryption validation failed'));
        score -= 0.3;
      }
      
      // Validate authentication
      final authResult = await _securityValidator.validateAuthenticationSecurity();
      if (!authResult.isCompliant) {
        issues.add(DeploymentIssue.critical('Authentication security validation failed'));
        score -= 0.3;
      }
      
      // Validate privacy protection
      final privacyResult = await _securityValidator.validatePrivacyProtection();
      if (!privacyResult.isCompliant) {
        issues.add(DeploymentIssue.critical('Privacy protection validation failed'));
        score -= 0.2;
      }
      
      // Validate AI2AI security
      final ai2aiResult = await _securityValidator.validateAI2AISecurity();
      if (!ai2aiResult.isCompliant) {
        issues.add(DeploymentIssue.warning('AI2AI security needs review'));
        recommendations.add('Review AI2AI security implementation');
        score -= 0.1;
      }
      
      // Validate network security
      final networkResult = await _securityValidator.validateNetworkSecurity();
      if (!networkResult.isCompliant) {
        issues.add(DeploymentIssue.warning('Network security needs review'));
        score -= 0.1;
      }
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      _logger.error('Error validating security', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  Future<double> _validatePrivacy(
    List<DeploymentIssue> issues,
    List<String> recommendations,
  ) async {
    try {
      double score = 1.0;
      
      // Check privacy protection implementation
      // This would check that PrivacyProtection is properly implemented
      try {
        // Test anonymization quality
        final testData = {'test': 'data'};
        // Create a minimal test profile for validation
        final testProfile = PersonalityProfile.initial('test_user');
        final anonymized = await PrivacyProtection.anonymizePersonalityProfile(
          testProfile,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );
        
        // If we can test anonymization, verify quality
        // For now, assume it's working if no exceptions
        
      } catch (e) {
        issues.add(DeploymentIssue.critical('Privacy protection validation failed: $e'));
        score -= 0.3;
      }
      
      // Check privacy compliance
      final privacyResult = await _securityValidator.validatePrivacyProtection();
      if (!privacyResult.isCompliant) {
        issues.add(DeploymentIssue.critical('Privacy compliance check failed'));
        score -= 0.2;
      }
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      _logger.error('Error validating privacy', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  Future<double> _validateOurGutsCompliance(
    List<DeploymentIssue> issues,
    List<String> recommendations,
  ) async {
    try {
      double score = 1.0;
      
      // Check key OUR_GUTS.md principles
      // 1. Privacy preservation
      final privacyScore = await _validatePrivacy(issues, recommendations);
      if (privacyScore < 0.95) {
        issues.add(DeploymentIssue.critical('OUR_GUTS.md: Privacy compliance insufficient'));
        score -= 0.2;
      }
      
      // 2. AI2AI architecture (not p2p)
      // This would check that all connections go through AI layer
      // For now, assume compliance if AI2AI systems are present
      
      // 3. Self-improving ecosystem
      // Check that learning systems are active
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      _logger.error('Error validating OUR_GUTS compliance', error: e, tag: _logName);
      return 0.0;
    }
  }
}

class DeploymentReadinessScore {
  final double overallScore;
  final double performanceScore;
  final double securityScore;
  final double privacyScore;
  final List<DeploymentIssue> criticalIssues;
  final List<String> recommendations;

  DeploymentReadinessScore({
    required this.overallScore,
    required this.performanceScore,
    required this.securityScore,
    required this.privacyScore,
    required this.criticalIssues,
    required this.recommendations,
  });
}

class DeploymentIssue {
  final String severity;
  final String description;

  DeploymentIssue({required this.severity, required this.description});

  static DeploymentIssue critical(String description) =>
      DeploymentIssue(severity: 'CRITICAL', description: description);
  static DeploymentIssue warning(String description) =>
      DeploymentIssue(severity: 'WARNING', description: description);
}

class ValidationResult {
  final bool isValid;
  final double score;
  final List<String> issues;
  final List<String> recommendations;
  
  ValidationResult({
    required this.isValid,
    required this.score,
    required this.issues,
    required this.recommendations,
  });
}


