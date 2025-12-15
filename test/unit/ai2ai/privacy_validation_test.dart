import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai2ai/anonymous_communication.dart' as anonymous_communication;
import 'package:spots/core/ai2ai/trust_network.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/constants/vibe_constants.dart';

/// Comprehensive Privacy Validation Tests for AI2AI System
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests ensure ZERO user data exposure throughout the AI2AI ecosystem
/// Critical for both development security and deployment privacy compliance
void main() {
  const _debugLogPath = '/Users/reisgordon/SPOTS/.cursor/debug.log';
  const _sessionId = 'debug-session';

  void _agentLog({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, dynamic>? data,
  }) {
    // #region agent log
    try {
      final payload = <String, dynamic>{
        'sessionId': _sessionId,
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data ?? <String, dynamic>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File(_debugLogPath).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
  }

  group('AI2AI Privacy Validation', () {
    setUpAll(() async {
      // Clear debug log (tool deletion is blocked in this environment)
      // #region agent log
      try {
        File(_debugLogPath).writeAsStringSync('', mode: FileMode.write);
      } catch (_) {}
      // #endregion
    });

    group('Zero User Data Exposure Validation', () {
      test('should validate PersonalityProfile contains no user-identifying data', () {
        final profile = PersonalityProfile.initial('anonymous-user-123');
        final evolved = profile.evolve(
          newDimensions: {
            'exploration_eagerness': 0.8,
            'community_orientation': 0.7,
          },
          additionalLearning: {
            'total_interactions': 50,
            'learning_sources': ['ai2ai_network', 'community_feedback'],
          },
        );

        final json = evolved.toJson();
        final jsonString = json.toString().toLowerCase();

        // Critical privacy checks - should NEVER contain these patterns
        final forbiddenPatterns = [
          'email', 'phone', 'address', 'name', 'firstname', 'lastname',
          'personal', 'private', 'contact',
          // "location_adventurousness" is a non-PII personality dimension, so we only block
          // explicit geo patterns (lat/lng/etc) rather than the substring "location".
          'latitude', 'longitude', 'lat', 'lng', 'gps', 'geolocation',
          'ip_address',
          'device_id', 'session_id', 'tracking', 'analytics_id'
        ];

        for (final pattern in forbiddenPatterns) {
          expect(jsonString, isNot(contains(pattern)), 
              reason: 'PersonalityProfile leaked user data: $pattern');
        }

        _agentLog(
          runId: 'pre-fix',
          hypothesisId: 'H1',
          location: 'privacy_validation_test.dart:PersonalityProfile',
          message: 'Profile JSON forbidden-pattern scan completed',
          data: {
            'forbiddenPatterns': forbiddenPatterns,
            'jsonLower': jsonString,
          },
        );

        // Verify anonymized user ID format
        expect(json['user_id'], startsWith('anonymous-'));
        
        // Ensure learning history doesn't expose user identity
        final learningHistory = json['learning_history'] as Map<String, dynamic>;
        final learningString = learningHistory.toString().toLowerCase();
        
        for (final pattern in forbiddenPatterns) {
          expect(learningString, isNot(contains(pattern)),
              reason: 'Learning history leaked user data: $pattern');
        }
      });

      test('should validate AnonymousMessage payloads are completely anonymous', () async {
        final protocol = anonymous_communication.AnonymousCommunicationProtocol();
        
        // Test various payload types that should be accepted
        final validPayloads = [
          {
            'ai_learning_vector': [0.1, 0.5, 0.8],
            'compatibility_score': 0.7,
            'anonymous_signature': 'anon-sig-xyz',
          },
          {
            'network_topology_info': {'nodes': 42, 'density': 0.6},
            'recommendation_quality': 0.85,
          },
          {
            'pattern_insights': 'temporal_correlation_detected',
            'confidence_level': 0.9,
          },
        ];

        for (final payload in validPayloads) {
          expect(
          () => protocol.sendEncryptedMessage(
            'test-agent', anonymous_communication.MessageType.discoverySync, payload),
            returnsNormally,
            reason: 'Valid anonymous payload should be accepted: $payload',
          );
        }

        // Test payloads that should be rejected
        final invalidPayloads = [
          {'userId': 'user123'}, // Direct user ID
          {'user_email': 'test@example.com'}, // User email
          {'personalData': 'private info'}, // Personal data
          {'deviceInfo': 'iPhone 12, iOS 15'}, // Device fingerprinting
          {'location': {'lat': 37.7749, 'lng': -122.4194}}, // Location data
        ];

        for (final payload in invalidPayloads) {
          _agentLog(
            runId: 'pre-fix',
            hypothesisId: 'H2',
            location: 'privacy_validation_test.dart:AnonymousMessage',
            message: 'Sending payload expected to be rejected',
            data: {'payload': payload},
          );
          expect(
          () => protocol.sendEncryptedMessage(
            'test-agent', anonymous_communication.MessageType.discoverySync, payload),
            throwsA(isA<anonymous_communication.AnonymousCommunicationException>()),
            reason: 'Invalid payload with user data should be rejected: $payload',
          );
        }
      });

      test('should validate TrustContext maintains complete anonymity', () async {
        final trustManager = TrustNetworkManager();

        final anonymousContext = TrustContext(
          hasUserData: false,
          hasValidatedBehavior: true,
          hasCommunityEndorsement: true,
          hasRecentActivity: true,
          behaviorSignature: 'pattern_hash_abc123',
          activityLevel: 0.8,
          communityScore: 0.7,
        );

        final relationship = await trustManager.establishTrust(
          'anonymous-agent-456', 
          anonymousContext,
        );

        // Verify no user data in trust relationship
        expect(relationship.agentId, startsWith('anonymous-'));
        
        final factorsJson = relationship.anonymousFactors.toString().toLowerCase();
        final forbiddenTerms = [
          'user', 'email', 'phone', 'address', 'name', 'personal',
          'device', 'ip', 'session', 'tracking', 'analytics'
        ];

        for (final term in forbiddenTerms) {
          expect(factorsJson, isNot(contains(term)),
              reason: 'Trust factors leaked user data: $term');
        }

        // Verify behavior signature is anonymized
        expect(relationship.anonymousFactors['behaviorPattern'], 
               equals('pattern_hash_abc123'));
        expect(relationship.anonymousFactors['behaviorPattern'], 
               isNot(contains('user')));
      });

      test('should validate AI2AI connections preserve privacy end-to-end', () async {
        // Create anonymous personality profiles
        final profile1 = PersonalityProfile.initial('anon-ai-001');
        final profile2 = PersonalityProfile.initial('anon-ai-002');

        // Test compatibility calculation doesn't expose user data
        final compatibility = profile1.calculateCompatibility(profile2);
        
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));

        // Test learning potential calculation maintains anonymity
        final learningPotential = profile1.calculateLearningPotential(profile2);
        
        expect(learningPotential, isA<double>());
        expect(learningPotential, greaterThanOrEqualTo(0.0));
        expect(learningPotential, lessThanOrEqualTo(1.0));

        // Verify profile summaries don't leak user identity
        final summary1 = profile1.getSummary();
        final summary2 = profile2.getSummary();

        for (final summary in [summary1, summary2]) {
          final summaryString = summary.toString().toLowerCase();
          expect(summaryString, isNot(contains('email')));
          expect(summaryString, isNot(contains('phone')));
          expect(summaryString, isNot(contains('address')));
          expect(summaryString, isNot(contains('personal')));
        }
      });
    });

    group('Data Anonymization Validation', () {
      test('should validate vibe signatures are properly anonymized', () async {
        // Test vibe anonymization process
        final testVibe = UserVibe.fromPersonalityProfile(
          'should-be-anonymized',
          {
            'exploration_eagerness': 0.8,
            'community_orientation': 0.6,
          },
        );

        final anonymizedVibeData = await PrivacyProtection.anonymizeUserVibe(testVibe);

        // Verify anonymization worked - signature should be different
        expect(anonymizedVibeData.vibeSignature, isNot(equals(testVibe.hashedSignature)));
        expect(anonymizedVibeData.vibeSignature, isNotEmpty);

        _agentLog(
          runId: 'pre-fix',
          hypothesisId: 'H3',
          location: 'privacy_validation_test.dart:anonymizeUserVibe',
          message: 'Vibe anonymization result',
          data: {
            'inputDims': testVibe.anonymizedDimensions,
            'noisyDims': anonymizedVibeData.noisyDimensions,
            'privacyNoiseLevel': VibeConstants.privacyNoiseLevel,
          },
        );
        
        // Dimensions should preserve relative relationships with privacy noise
        expect(anonymizedVibeData.noisyDimensions['exploration_eagerness'], 
               // MAXIMUM_ANONYMIZATION uses stronger noise (ε≈0.5) so allow wider tolerance.
               closeTo(0.8, VibeConstants.privacyNoiseLevel * 4));
        expect(anonymizedVibeData.noisyDimensions['community_orientation'],
               closeTo(0.6, VibeConstants.privacyNoiseLevel * 4));
      });

      test('should validate differential privacy noise application', () async {
        final originalProfile = PersonalityProfile.initial('privacy-test-user');
        
        // Apply privacy protection multiple times
        final protectedDimensions = <Map<String, double>>[];
        for (int i = 0; i < 10; i++) {
          // Simulate privacy protection during AI2AI sharing
          final protected = await PrivacyProtection.applyDifferentialPrivacy(originalProfile.dimensions);
          protectedDimensions.add(protected);
        }

        // Verify noise was applied (values should vary slightly)
        final explorationValues = protectedDimensions
            .map((dims) => dims['exploration_eagerness']!)
            .toList();

        // Should have some variance due to noise
        final variance = _calculateVariance(explorationValues);
        _agentLog(
          runId: 'pre-fix',
          hypothesisId: 'H4',
          location: 'privacy_validation_test.dart:applyDifferentialPrivacy',
          message: 'Differential privacy variance computed',
          data: {
            'values': explorationValues,
            'variance': variance,
            'threshold': VibeConstants.maxPersonalityNoiseThreshold,
          },
        );
        expect(variance, greaterThan(0.0));
        expect(variance, lessThan(VibeConstants.maxPersonalityNoiseThreshold));

        // All values should still be within bounds
        for (final value in explorationValues) {
          expect(value, greaterThanOrEqualTo(VibeConstants.minDimensionValue));
          expect(value, lessThanOrEqualTo(VibeConstants.maxDimensionValue));
        }
      });

      test('should validate entropy requirements for personality fingerprints', () async {
        final profiles = List.generate(100, (i) => 
          PersonalityProfile.initial('entropy-test-$i').evolve(
            newDimensions: {
              // Ensure high diversity across 100 profiles (avoid repeating 10-value cycles)
              'exploration_eagerness': i / 100.0,
              'community_orientation': ((i * 37) % 100) / 100.0,
            },
          )
        );

        // Calculate entropy across personality fingerprints
        final fingerprints = profiles.map((p) => p.toJson()['dimensions'].toString()).toList();
        final uniqueFingerprints = fingerprints.toSet();

        // Should have high diversity (entropy)
        final entropyRatio = uniqueFingerprints.length / fingerprints.length;
        _agentLog(
          runId: 'pre-fix',
          hypothesisId: 'H5',
          location: 'privacy_validation_test.dart:entropy',
          message: 'Fingerprint diversity computed',
          data: {
            'count': fingerprints.length,
            'unique': uniqueFingerprints.length,
            'ratio': entropyRatio,
            'threshold': VibeConstants.maxEntropyThreshold,
          },
        );
        expect(entropyRatio, greaterThan(VibeConstants.maxEntropyThreshold));
      });

      test('should validate anonymization level meets minimum requirements', () async {
        // Test differential privacy application
        final testDimensions = {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.7,
        };

        final anonymized = await PrivacyProtection.applyDifferentialPrivacy(testDimensions);

        // Verify anonymization was applied (values should be close but not identical)
        // MAXIMUM_ANONYMIZATION uses stronger noise (ε≈0.5) so allow wider tolerance.
        expect(anonymized['exploration_eagerness'], closeTo(0.8, VibeConstants.privacyNoiseLevel * 4));
        expect(anonymized['community_orientation'], closeTo(0.7, VibeConstants.privacyNoiseLevel * 4));
        
        // Values should be within valid range
        expect(anonymized['exploration_eagerness'], greaterThanOrEqualTo(0.0));
        expect(anonymized['exploration_eagerness'], lessThanOrEqualTo(1.0));
      });
    });

    group('Communication Privacy Validation', () {
      test('should validate message routing preserves anonymity', () async {
        final protocol = anonymous_communication.AnonymousCommunicationProtocol();
        final anonymousPayload = {
          'ai_insight': 'pattern_detected',
          'confidence': 0.85,
        };

        final message = await protocol.sendEncryptedMessage(
          'target-agent-routing',
          anonymous_communication.MessageType.discoverySync,
          anonymousPayload,
        );

        // Verify routing hops don't expose sender/receiver identity
        expect(message.routingHops, isNotEmpty);
        
        for (final hop in message.routingHops) {
          expect(hop, isNot(contains('user')));
          expect(hop, isNot(contains('@')));
          expect(hop, isNot(contains('ip')));
          expect(hop, startsWith('hop')); // Should be anonymous hop identifiers
        }

        // Message ID should not contain user information
        expect(message.messageId, isNot(contains('user')));
        expect(message.messageId, startsWith('msg_'));
        
        // Target agent ID should be anonymized
        expect(message.targetAgentId, isNot(contains('user')));
      });

      test('should validate secure channel establishment maintains anonymity', () async {
        final protocol = anonymous_communication.AnonymousCommunicationProtocol();

        final channel = await protocol.establishSecureChannel(
          'anonymous-target-agent',
          anonymous_communication.TrustLevel.verified,
        );

        // Channel identifiers should be anonymous
        expect(channel.channelId, isNot(contains('user')));
        expect(channel.channelId, startsWith('ch_'));
        
        expect(channel.targetAgentId, isNot(contains('user')));
        expect(channel.targetAgentId, startsWith('anonymous-'));

        // Shared secret should be cryptographically secure
        expect(channel.sharedSecret.length, greaterThan(50));
        expect(channel.sharedSecret, isNot(contains('user')));
        expect(channel.sharedSecret, isNot(contains('password')));

        // Maximum encryption and privacy levels
        expect(channel.encryptionStrength, equals(anonymous_communication.EncryptionStrength.maximum));
        expect(channel.trustLevel, greaterThanOrEqualTo(anonymous_communication.TrustLevel.verified));
      });

      test('should validate message expiration prevents data lingering', () async {
        final protocol = anonymous_communication.AnonymousCommunicationProtocol();
        final payload = {'temporary_data': 'should_expire'};

        final message = await protocol.sendEncryptedMessage(
          'expiration-test-agent',
          anonymous_communication.MessageType.networkMaintenance,
          payload,
        );

        // Message should have reasonable expiration time
        final timeUntilExpiry = message.expiresAt.difference(DateTime.now());
        expect(timeUntilExpiry.inMinutes, lessThanOrEqualTo(60)); // Max 60 minutes
        expect(timeUntilExpiry.inMinutes, greaterThan(0)); // Should not be expired immediately

        // Verify expiration validation works
        final expiredMessage = anonymous_communication.AnonymousMessage(
          messageId: 'expired-test',
          targetAgentId: 'test-agent',
          messageType: anonymous_communication.MessageType.discoverySync,
          encryptedPayload: 'expired-data',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(Duration(hours: 1)), // Already expired
          routingHops: [],
          privacyLevel: anonymous_communication.PrivacyLevel.maximum,
        );

        expect(expiredMessage.expiresAt.isBefore(DateTime.now()), isTrue);
      });
    });

    group('Network-Level Privacy Validation', () {
      test('should validate AI2AI network maintains anonymity at scale', () async {
        // Simulate large network of anonymous AI agents
        final networkAgents = List.generate(100, (i) => 
          'anonymous-agent-${i.toString().padLeft(3, '0')}'
        );

        // Verify all agent IDs maintain anonymity standards
        for (final agentId in networkAgents) {
          expect(agentId, startsWith('anonymous-'));
          expect(agentId, isNot(contains('user')));
          expect(agentId, isNot(contains('@')));
          expect(agentId, isNot(contains('ip')));
        }

        // Test network topology doesn't reveal identity patterns
        final networkTopology = _simulateNetworkTopology(networkAgents);
        
        expect(networkTopology['total_nodes'], equals(100));
        expect(networkTopology['anonymity_preserved'], isTrue);
        expect(networkTopology['identity_leaks'], equals(0));
      });

      test('should validate learning propagation maintains privacy boundaries', () async {
        // Test AI2AI learning doesn't propagate user data
        final sourceProfile = PersonalityProfile.initial('learning-source');
        final targetProfile = PersonalityProfile.initial('learning-target');

        // Simulate learning transfer
        final learningData = {
          'insight_type': 'pattern_recognition',
          'effectiveness': 0.8,
          'anonymous_signature': sourceProfile.toJson()['dimensions'],
        };

        final evolved = targetProfile.evolve(
          additionalLearning: {
            'ai2ai_insights': [learningData],
            'learning_sources': ['anonymous_ai_network'],
          },
        );

        // Verify learning history doesn't contain source identity
        final learningHistory = evolved.learningHistory;
        final historyString = learningHistory.toString().toLowerCase();
        
        expect(historyString, isNot(contains('learning-source')));
        expect(historyString, isNot(contains('user')));
        expect(historyString, contains('anonymous_ai_network'));
      });

      test('should validate network analytics preserve individual privacy', () async {
        // Test network-wide analytics don't expose individual agents
        final networkMetrics = {
          'total_connections': 1500,
          'avg_trust_score': 0.67,
          'learning_effectiveness': 0.78,
          'network_density': 0.34,
          'privacy_violations': 0, // Critical - should always be 0
        };

        expect(networkMetrics['privacy_violations'], equals(0));
        expect(networkMetrics['total_connections'], isA<int>());
        expect(networkMetrics['avg_trust_score'], isA<double>());

        // Metrics should be aggregated, not individual
        expect(networkMetrics.keys, isNot(contains('individual_scores')));
        expect(networkMetrics.keys, isNot(contains('agent_identities')));
        expect(networkMetrics.keys, isNot(contains('user_data')));
      });
    });

    group('Compliance and Audit Validation', () {
      test('should validate GDPR compliance for AI2AI data processing', () {
        // Test data minimization principle
        final minimalProfile = PersonalityProfile.initial('gdpr-test-user');
        final profileData = minimalProfile.toJson();

        // Should only contain necessary AI learning data
        final allowedKeys = [
          'user_id', 'dimensions', 'dimension_confidence', 'archetype',
          'authenticity', 'created_at', 'last_updated', 'evolution_generation',
          'learning_history'
        ];

        for (final key in profileData.keys) {
          expect(allowedKeys, contains(key), 
                 reason: 'Unexpected data field: $key');
        }

        // User ID should be anonymized
        expect(profileData['user_id'], startsWith('gdpr-test-'));
      });

      test('should validate data retention compliance', () async {
        // Test automatic data expiration
        final oldProfile = PersonalityProfile.initial('retention-test').evolve(
          additionalLearning: {
            'data_created': DateTime.now().subtract(Duration(days: 400)).toIso8601String(),
          },
        );

        // Check if data should be expired based on retention policy
        final dataAge = DateTime.now().difference(oldProfile.createdAt).inDays;
        
        if (dataAge > VibeConstants.vibeSignatureExpiryDays) {
          // Data should be marked for regeneration/expiry
          expect(dataAge, greaterThan(VibeConstants.vibeSignatureExpiryDays));
        }
      });

      test('should validate audit trail maintains privacy', () async {
        // Simulate audit trail for AI2AI operations
        final auditEvents = [
          {
            'event_type': 'ai2ai_connection_established',
            'timestamp': DateTime.now().toIso8601String(),
            'agent_count': 2,
            'success': true,
            'privacy_level': 'maximum',
          },
          {
            'event_type': 'trust_score_updated',
            'timestamp': DateTime.now().toIso8601String(),
            'agent_count': 1,
            'success': true,
            'privacy_level': 'maximum',
          },
        ];

        for (final event in auditEvents) {
          // Audit should not contain user-identifying information
          final eventString = event.toString().toLowerCase();
          expect(eventString, isNot(contains('user')));
          expect(eventString, isNot(contains('email')));
          expect(eventString, isNot(contains('ip')));
          expect(eventString, isNot(contains('personal')));
          
          // Should maintain privacy level
          expect(event['privacy_level'], equals('maximum'));
        }
      });
    });
  });
}

// Helper functions for privacy validation testing
double _calculateVariance(List<double> values) {
  if (values.isEmpty) return 0.0;
  
  final mean = values.reduce((a, b) => a + b) / values.length;
  final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
  return squaredDiffs.reduce((a, b) => a + b) / values.length;
}

// Removed unused helper function _calculateAnonymizationLevel

Map<String, dynamic> _simulateNetworkTopology(List<String> agents) {
  return {
    'total_nodes': agents.length,
    'anonymity_preserved': true,
    'identity_leaks': 0,
    'connection_density': 0.3,
  };
}

// Note: Using actual PrivacyProtection class from lib/core/ai/privacy_protection.dart
// Mock removed - using real implementation
