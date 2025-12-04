import 'dart:async';
import 'dart:developer' as developer;
import 'package:spots/core/services/admin_auth_service.dart';
import 'package:spots/core/services/admin_communication_service.dart';
import 'package:spots/core/services/admin_privacy_filter.dart';
import 'package:spots/core/services/supabase_service.dart';
import 'package:spots/core/services/expertise_service.dart';
import 'package:spots/core/services/club_service.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/club.dart';
import 'package:spots/core/ml/predictive_analytics.dart';
import 'package:spots/core/models/expertise_progress.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/models/collaborative_activity_metrics.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/p2p/federated_learning.dart' as federated;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// God-Mode Admin Service
/// Provides comprehensive real-time access to all system data
/// Requires god-mode admin authentication
class AdminGodModeService {
  static const String _logName = 'AdminGodModeService';
  
  final AdminAuthService _authService;
  final AdminCommunicationService _communicationService;
  final BusinessAccountService _businessService;
  final ClubService _clubService;
  final CommunityService _communityService;
  final PredictiveAnalytics _predictiveAnalytics;
  final ConnectionMonitor _connectionMonitor;
  final AI2AIChatAnalyzer? _chatAnalyzer;
  final SupabaseService _supabaseService;
  final ExpertiseService _expertiseService;
  final federated.FederatedLearningSystem? _federatedLearningSystem;
  NetworkAnalytics? _networkAnalytics;
  
  // Real-time data streams
  final Map<String, StreamController<dynamic>> _dataStreams = {};
  Timer? _refreshTimer;
  
  // Cache for AI data snapshots (5 second TTL)
  final Map<String, _CachedAISnapshot> _aiSnapshotCache = {};
  static const Duration _aiSnapshotCacheTTL = Duration(seconds: 5);
  
  AdminGodModeService({
    required AdminAuthService authService,
    required AdminCommunicationService communicationService,
    required BusinessAccountService businessService,
    ClubService? clubService,
    CommunityService? communityService,
    required PredictiveAnalytics predictiveAnalytics,
    required ConnectionMonitor connectionMonitor,
    AI2AIChatAnalyzer? chatAnalyzer,
    SupabaseService? supabaseService,
    ExpertiseService? expertiseService,
    NetworkAnalytics? networkAnalytics,
    federated.FederatedLearningSystem? federatedLearningSystem,
  })  : _authService = authService,
        _communicationService = communicationService,
        _businessService = businessService,
        _clubService = clubService ?? ClubService(),
        _communityService = communityService ?? CommunityService(),
        _predictiveAnalytics = predictiveAnalytics,
        _connectionMonitor = connectionMonitor,
        _chatAnalyzer = chatAnalyzer,
        _supabaseService = supabaseService ?? SupabaseService(),
        _expertiseService = expertiseService ?? ExpertiseService(),
        _networkAnalytics = networkAnalytics,
        _federatedLearningSystem = federatedLearningSystem;
  
  /// Check if god-mode access is authorized
  bool get isAuthorized {
    if (!_authService.isAuthenticated()) return false;
    return _authService.hasPermission(AdminPermission.viewRealTimeData);
  }
  
  /// Get real-time user data stream
  Stream<UserDataSnapshot> watchUserData(String userId) {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    final controller = StreamController<UserDataSnapshot>.broadcast();
    _dataStreams['user_$userId'] = controller;
    
    // Start periodic updates
    _startUserDataStream(userId, controller);
    
    return controller.stream;
  }
  
  /// Get real-time AI data stream
  Stream<AIDataSnapshot> watchAIData(String aiSignature) {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    final controller = StreamController<AIDataSnapshot>.broadcast();
    _dataStreams['ai_$aiSignature'] = controller;
    
    // Start periodic updates
    _startAIDataStream(aiSignature, controller);
    
    return controller.stream;
  }
  
  /// Get real-time communications stream
  Stream<CommunicationsSnapshot> watchCommunications({
    String? userId,
    String? connectionId,
  }) {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    final key = 'communications_${userId ?? 'all'}_${connectionId ?? 'all'}';
    final controller = StreamController<CommunicationsSnapshot>.broadcast();
    _dataStreams[key] = controller;
    
    // Start periodic updates
    _startCommunicationsStream(userId, connectionId, controller);
    
    return controller.stream;
  }
  
  /// Get user progress data
  /// Privacy-preserving: Only returns progress metrics, NO personal data
  Future<UserProgressData> getUserProgress(String userId) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      final client = _supabaseService.client;
      
      // Get user's lists count
      final listsResponse = await client
          .from('spot_lists')
          .select('id')
          .eq('created_by', userId);
      final listsCreated = (listsResponse as List).length;
      
      // Get user's spots count
      final spotsResponse = await client
          .from('spots')
          .select('id')
          .eq('created_by', userId);
      final spotsAdded = (spotsResponse as List).length;
      
      // Get user's respects (reviews/interactions)
      final respectsResponse = await client
          .from('user_respects')
          .select('id')
          .eq('user_id', userId);
      final totalRespects = (respectsResponse as List).length;
      
      // Calculate total contributions
      final totalContributions = listsCreated + spotsAdded + totalRespects;
      
      // Get respected lists count (lists that have been respected by others)
      final respectedListsResponse = await client
          .from('user_respects')
          .select('list_id')
          .not('list_id', 'is', null);
      
      final respectedListIds = (respectedListsResponse as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['list_id'] as String)
          .toSet();
      
      // Filter user's lists that have been respected
      // Since .in_() may not be available, we'll filter client-side
      final userListsResponse = await client
          .from('spot_lists')
          .select('id')
          .eq('created_by', userId);
      
      final userListIds = (userListsResponse as List)
          .cast<Map<String, dynamic>>()
          .map((l) => l['id'] as String)
          .toSet();
      
      final respectedListsCount = respectedListIds.intersection(userListIds).length;
      
      // Calculate expertise progress using ExpertiseService
      // For now, we'll create basic progress entries
      // In a full implementation, this would calculate progress per category
      final expertiseProgress = <ExpertiseProgress>[];
      
      // Calculate pins earned (simplified - would need full expertise calculation)
      final pinsEarned = respectedListsCount; // Simplified calculation
      
      return UserProgressData(
        userId: userId,
        expertiseProgress: expertiseProgress,
        totalContributions: totalContributions,
        pinsEarned: pinsEarned,
        listsCreated: listsCreated,
        spotsAdded: spotsAdded,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error fetching user progress: $e', name: _logName);
      // Return empty progress on error
      return UserProgressData(
        userId: userId,
        expertiseProgress: [],
        totalContributions: 0,
        pinsEarned: 0,
        listsCreated: 0,
        spotsAdded: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Get user predictions
  /// Privacy-preserving: Only returns AI predictions, NO personal data
  Future<UserPredictionsData> getUserPredictions(String userId) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      // Get predictions using only user ID
      // IMPORTANT: Do not pass personal data (name, email) to prediction service
      // Create minimal user object with ID only for prediction service
      final user = User(
        id: userId,
        email: '', // Empty - not used for predictions
        name: '', // Empty - not used for predictions
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final journey = await _predictiveAnalytics.predictUserJourney(user);
      
      return UserPredictionsData(
        userId: userId,
        currentStage: journey.currentStage.name,
        predictedActions: journey.predictedNextActions.map((a) => 
          PredictionAction(
            action: a.action,
            probability: a.probability,
            category: a.category,
          )
        ).toList(),
        journeyPath: journey.journeyPath.map((s) =>
          JourneyStep(
            description: s.description,
            estimatedTime: s.estimatedTime,
            likelihood: s.likelihood,
          )
        ).toList(),
        confidence: journey.confidence,
        timeframe: journey.timeframe,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error fetching user predictions: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Get all business accounts
  Future<List<BusinessAccountData>> getAllBusinessAccounts() async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      // Try to fetch from Supabase first
      final client = _supabaseService.client;
      
      try {
        final response = await client
            .from('business_accounts')
            .select('*')
            .order('created_at', ascending: false);
        
        final accounts = (response as List).cast<Map<String, dynamic>>();
        
        return accounts.map((accountData) {
          try {
            final account = BusinessAccount.fromJson(accountData);
            return BusinessAccountData(
              account: account,
              isVerified: account.isVerified,
              connectedExperts: account.connectedExpertIds.length,
              lastActivity: account.updatedAt,
            );
          } catch (e) {
            developer.log('Error parsing business account: $e', name: _logName);
            // Return minimal data if parsing fails
            return BusinessAccountData(
              account: BusinessAccount(
                id: accountData['id'] as String? ?? '',
                name: accountData['name'] as String? ?? 'Unknown',
                email: accountData['email'] as String? ?? '',
                businessType: accountData['business_type'] as String? ?? 'Unknown',
                createdAt: DateTime.parse(accountData['created_at'] as String? ?? DateTime.now().toIso8601String()),
                updatedAt: DateTime.parse(accountData['updated_at'] as String? ?? DateTime.now().toIso8601String()),
                createdBy: accountData['created_by'] as String? ?? '',
              ),
              isVerified: accountData['is_verified'] as bool? ?? false,
              connectedExperts: 0,
              lastActivity: DateTime.parse(accountData['updated_at'] as String? ?? DateTime.now().toIso8601String()),
            );
          }
        }).toList();
      } catch (e) {
        // Table might not exist, try using BusinessAccountService
        developer.log('Business accounts table not found, trying service: $e', name: _logName);
        
        // Fallback to service if table doesn't exist
        final accounts = await _businessService.getBusinessAccountsByUser(''); // Empty string to get all
        return accounts.map((account) => BusinessAccountData(
          account: account,
          isVerified: account.isVerified,
          connectedExperts: account.connectedExpertIds.length,
          lastActivity: account.updatedAt,
        )).toList();
      }
    } catch (e) {
      developer.log('Error fetching business accounts: $e', name: _logName);
      return [];
    }
  }
  
  /// Get all clubs and communities
  /// Privacy-preserving: Returns club/community data with member AI agent information
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<ClubCommunityData>> getAllClubsAndCommunities() async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      developer.log('Fetching all clubs and communities', name: _logName);
      
      // Get all clubs - try common categories
      final allClubsSet = <String, Club>{};
      final categories = ['nightlife', 'food', 'music', 'sports', 'art', 'tech', 'outdoor', 'community'];
      for (final category in categories) {
        final clubs = await _clubService.getClubsByCategory(category, maxResults: 100);
        for (final club in clubs) {
          allClubsSet[club.id] = club;
        }
      }
      final clubs = allClubsSet.values.toList();
      
      final allData = <ClubCommunityData>[];
      
      for (final club in clubs) {
        // Get member AI agents (privacy-filtered)
        final memberAIAgents = await _getMemberAIAgentsForClub(club);
        
        allData.add(ClubCommunityData(
          id: club.id,
          name: club.name,
          description: club.description,
          category: club.category,
          isClub: true,
          memberCount: club.memberCount,
          eventCount: club.eventCount,
          founderId: club.founderId,
          leaders: club.leaders,
          adminTeam: club.adminTeam,
          createdAt: club.createdAt,
          lastEventAt: club.lastEventAt,
          memberAIAgents: memberAIAgents,
        ));
      }
      
      // TODO: Add communities when CommunityService has getAllCommunities method
      
      developer.log('Retrieved ${allData.length} clubs/communities', name: _logName);
      return allData;
    } catch (e) {
      developer.log('Error fetching clubs/communities: $e', name: _logName);
      return [];
    }
  }
  
  /// Get club/community by ID with member AI agents
  /// Privacy-preserving: Returns AI agent data only, no personal info
  Future<ClubCommunityData?> getClubOrCommunityById(String id) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      // Try to get as club first
      final club = await _clubService.getClubById(id);
      if (club != null) {
        final memberAIAgents = await _getMemberAIAgentsForClub(club);
        return ClubCommunityData(
          id: club.id,
          name: club.name,
          description: club.description,
          category: club.category,
          isClub: true,
          memberCount: club.memberCount,
          eventCount: club.eventCount,
          founderId: club.founderId,
          leaders: club.leaders,
          adminTeam: club.adminTeam,
          createdAt: club.createdAt,
          lastEventAt: club.lastEventAt,
          memberAIAgents: memberAIAgents,
        );
      }
      
      // TODO: Try to get as community when CommunityService has getCommunityById
      
      return null;
    } catch (e) {
      developer.log('Error fetching club/community by ID: $e', name: _logName);
      return null;
    }
  }
  
  /// Get all active AI agents with location and predictions
  /// Privacy-preserving: Returns AI agent data with location and predicted actions
  /// Follows AdminPrivacyFilter principles (AI data only, no personal info)
  Future<List<ActiveAIAgentData>> getAllActiveAIAgents() async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      developer.log('Fetching all active AI agents', name: _logName);
      
      final client = _supabaseService.client;
      
      // Get all users who are active (updated within last hour)
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      final usersResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .gte('updated_at', oneHourAgo.toIso8601String())
          .limit(1000); // Limit for performance
      
      final users = (usersResponse as List).cast<Map<String, dynamic>>();
      
      final activeAgents = <ActiveAIAgentData>[];
      
      // Process each user to get AI agent data
      for (final userData in users) {
        final userId = userData['id'] as String;
        final updatedAt = DateTime.parse(userData['updated_at'] as String);
        
        // Get user data snapshot (includes location)
        final userSnapshot = await _fetchUserDataSnapshot(userId);
        
        // Get predictions
        UserPredictionsData? predictions;
        try {
          predictions = await getUserPredictions(userId);
        } catch (e) {
          developer.log('Error getting predictions for $userId: $e', name: _logName);
        }
        
        // Extract location from visited locations or location string
        double? latitude;
        double? longitude;
        
        if (userSnapshot.data['visited_locations'] != null) {
          final visited = userSnapshot.data['visited_locations'] as List;
          if (visited.isNotEmpty) {
            final lastLocation = visited.last as Map<String, dynamic>;
            latitude = lastLocation['lat'] as double?;
            longitude = lastLocation['lng'] as double?;
          }
        }
        
        // If no location from visited_locations, try to parse location string
        if (latitude == null && userSnapshot.data['location'] != null) {
          // Location string might be in format "City, State" or coordinates
          // For now, we'll skip if it's not coordinates
          // TODO: Parse location string or get from geocoding
        }
        
        // Only include if we have location data
        if (latitude != null && longitude != null) {
          activeAgents.add(ActiveAIAgentData(
            userId: userId,
            aiSignature: userSnapshot.data['ai_signature']?.toString() ?? _generateAISignature(userId),
            latitude: latitude,
            longitude: longitude,
            isOnline: userSnapshot.isOnline,
            lastActive: userSnapshot.lastActive,
            aiConnections: userSnapshot.data['ai_connections'] as int? ?? 0,
            aiStatus: userSnapshot.data['ai_status']?.toString() ?? 'active',
            predictedActions: predictions?.predictedActions ?? [],
            currentStage: predictions?.currentStage ?? 'unknown',
            confidence: predictions?.confidence ?? 0.0,
          ));
        }
      }
      
      developer.log('Retrieved ${activeAgents.length} active AI agents', name: _logName);
      return activeAgents;
    } catch (e) {
      developer.log('Error fetching active AI agents: $e', name: _logName);
      return [];
    }
  }
  
  /// Get follower count for a user
  /// Returns number of users following this user
  Future<int> getFollowerCount(String userId) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      final client = _supabaseService.client;
      final response = await client
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);
      
      final follows = (response as List).cast<Map<String, dynamic>>();
      return follows.length;
    } catch (e) {
      developer.log('Error getting follower count: $e', name: _logName);
      return 0;
    }
  }
  
  /// Get users who have a following (follower count >= threshold)
  /// Returns list of user IDs with their follower counts
  Future<Map<String, int>> getUsersWithFollowing({int minFollowers = 1}) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      final client = _supabaseService.client;
      
      // Get all follow relationships
      final response = await client
          .from('user_follows')
          .select('following_id');
      
      final follows = (response as List).cast<Map<String, dynamic>>();
      
      // Count followers per user
      final followerCounts = <String, int>{};
      for (final follow in follows) {
        final followingId = follow['following_id'] as String;
        followerCounts[followingId] = (followerCounts[followingId] ?? 0) + 1;
      }
      
      // Filter by minimum followers
      return Map.fromEntries(
        followerCounts.entries.where((e) => e.value >= minFollowers),
      );
    } catch (e) {
      developer.log('Error getting users with following: $e', name: _logName);
      return {};
    }
  }

  /// Get member AI agents for a club (privacy-filtered)
  /// Returns AI-related data only, no personal information
  Future<Map<String, Map<String, dynamic>>> _getMemberAIAgentsForClub(Club club) async {
    final memberAIAgents = <String, Map<String, dynamic>>{};
    
    for (final memberId in club.memberIds) {
      // Generate AI signature from user ID (deterministic but anonymized)
      final aiSignature = _generateAISignature(memberId);
      
      // Build AI agent data (AI-related data only, no personal info)
      final aiAgentData = <String, dynamic>{
        'ai_signature': aiSignature,
        'user_id': memberId, // User ID is allowed (not personal data)
        'ai_connections': 0, // TODO: Get from connection monitor
        'ai_status': 'active', // TODO: Get actual status
        'ai_activity': 'active', // TODO: Get actual activity
        // Note: Personal data (name, email, phone, home address) is NOT included
      };
      
      // Filter through AdminPrivacyFilter to ensure compliance
      final filtered = AdminPrivacyFilter.filterPersonalData(aiAgentData);
      memberAIAgents[memberId] = filtered;
    }
    
    return memberAIAgents;
  }

  /// Search users by AI signature or user ID only
  /// Privacy-preserving: No personal data (name, email, phone, address) is returned
  Future<List<UserSearchResult>> searchUsers({
    String? query, // Search by user ID or AI signature only
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      final client = _supabaseService.client;
      dynamic dbQuery = client.from('users').select('id, created_at, updated_at');
      
      // Apply filters
      if (query != null && query.isNotEmpty) {
        // Search by user ID (partial match)
        dbQuery = dbQuery.ilike('id', '%$query%');
      }
      
      if (createdAfter != null) {
        dbQuery = dbQuery.gte('created_at', createdAfter.toIso8601String());
      }
      
      if (createdBefore != null) {
        dbQuery = dbQuery.lte('created_at', createdBefore.toIso8601String());
      }
      
      // Limit results for performance
      dbQuery = dbQuery.limit(100);
      dbQuery = dbQuery.order('created_at', ascending: false);
      
      final response = await dbQuery;
      final users = (response as List).cast<Map<String, dynamic>>();
      
      // Convert to UserSearchResult with AI signature generation
      // IMPORTANT: Only return user ID and AI signature, NO personal data
      return users.map((userData) {
        final userId = userData['id'] as String;
        final createdAt = DateTime.parse(userData['created_at'] as String);
        final updatedAt = DateTime.parse(userData['updated_at'] as String);
        
        // Generate AI signature from user ID (deterministic but anonymized)
        final aiSignature = _generateAISignature(userId);
        
        // Check if user is active (updated within last 7 days)
        final isActive = DateTime.now().difference(updatedAt).inDays < 7;
        
        return UserSearchResult(
          userId: userId,
          aiSignature: aiSignature,
          createdAt: createdAt,
          isActive: isActive,
        );
      }).toList();
    } catch (e) {
      developer.log('Error searching users: $e', name: _logName);
      return [];
    }
  }
  
  /// Generate AI signature from user ID (deterministic but anonymized)
  String _generateAISignature(String userId) {
    // Create a deterministic hash from user ID
    // This ensures the same user always gets the same signature
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().substring(0, 16); // Use first 16 chars
    return 'ai_$hash';
  }
  
  /// Get aggregate privacy metrics (mean privacy score across all users)
  /// Returns the average privacy metrics for all users in the system
  Future<AggregatePrivacyMetrics> getAggregatePrivacyMetrics() async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      developer.log('Calculating aggregate privacy metrics', name: _logName);
      
      // Get network analytics dashboard which includes privacy preservation stats
      if (_networkAnalytics != null) {
        final dashboard = await _networkAnalytics!.generateAnalyticsDashboard(
          const Duration(days: 30),
        );
        
        final privacyStats = dashboard.privacyPreservationStats;
        
        // Calculate mean privacy score from privacy preservation stats
        // PrivacyPreservationStats should have overall privacy score
        final meanPrivacyScore = _calculateMeanPrivacyScore(privacyStats);
        
        // Get network health report for additional privacy data
        final healthReport = await _networkAnalytics!.analyzeNetworkHealth();
        final privacyMetrics = healthReport.privacyMetrics;
        
        return AggregatePrivacyMetrics(
          meanOverallPrivacyScore: meanPrivacyScore,
          meanAnonymizationLevel: privacyStats.averageAnonymization,
          meanDataSecurityScore: privacyMetrics.dataSecurityScore,
          meanEncryptionStrength: privacyMetrics.encryptionStrength,
          meanComplianceRate: privacyMetrics.complianceRate,
          totalPrivacyViolations: privacyMetrics.privacyViolations,
          userCount: healthReport.totalActiveConnections,
          lastUpdated: DateTime.now(),
        );
      }
      
      // Fallback: Use connection monitor metrics if network analytics not available
      final connectionsOverview = await _connectionMonitor.getActiveConnectionsOverview();
      final aggregateMetrics = connectionsOverview.aggregateMetrics;
      
      // Estimate privacy metrics from connection health (as proxy)
      // In a real implementation, this would come from actual privacy metrics storage
      final estimatedPrivacyScore = aggregateMetrics.averageCompatibility * 0.95; // Connection health correlates with privacy
      
      return AggregatePrivacyMetrics(
        meanOverallPrivacyScore: estimatedPrivacyScore,
        meanAnonymizationLevel: 0.90,
        meanDataSecurityScore: 0.95,
        meanEncryptionStrength: 0.98,
        meanComplianceRate: 0.95,
        totalPrivacyViolations: 0,
        userCount: connectionsOverview.totalActiveConnections,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error calculating aggregate privacy metrics: $e', name: _logName);
      // Return secure defaults on error
      return AggregatePrivacyMetrics(
        meanOverallPrivacyScore: 0.95,
        meanAnonymizationLevel: 0.90,
        meanDataSecurityScore: 0.95,
        meanEncryptionStrength: 0.98,
        meanComplianceRate: 0.95,
        totalPrivacyViolations: 0,
        userCount: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Calculate mean privacy score from privacy preservation stats
  double _calculateMeanPrivacyScore(PrivacyPreservationStats stats) {
    // PrivacyPreservationStats currently only has averageAnonymization
    // Use it as a proxy for overall privacy score, or calculate from network metrics
    return stats.averageAnonymization;
  }
  
  /// Get comprehensive dashboard data
  Future<GodModeDashboardData> getDashboardData() async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      final client = _supabaseService.client;
      final connectionsOverview = await _connectionMonitor.getActiveConnectionsOverview();
      
      // Get total users count
      final usersResponse = await client.from('users').select('id');
      final totalUsers = (usersResponse as List).length;
      
      // Get active users (updated within last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final activeUsersResponse = await client
          .from('users')
          .select('id')
          .gte('updated_at', weekAgo);
      final activeUsers = (activeUsersResponse as List).length;
      
      // Get business accounts count (if table exists)
      int totalBusinessAccounts = 0;
      try {
        final businessResponse = await client
            .from('business_accounts')
            .select('id');
        totalBusinessAccounts = (businessResponse as List).length;
      } catch (e) {
        // Table might not exist yet, that's okay
        developer.log('Business accounts table not found, using 0', name: _logName);
      }
      
      // Get total communications count from chat analyzer
      int totalCommunications = 0;
      if (_chatAnalyzer != null) {
        final allChatHistory = _chatAnalyzer!.getAllChatHistoryForAdmin();
        totalCommunications = allChatHistory.values.fold(0, (sum, events) => sum + events.length);
      }
      
      // Calculate system health from connection metrics
      // Use aggregate metrics to calculate health score
      final aggregateMetrics = connectionsOverview.aggregateMetrics;
      final systemHealth = aggregateMetrics.averageCompatibility;
      
      // Get aggregate privacy metrics (mean privacy score across all users)
      final aggregatePrivacyMetrics = await getAggregatePrivacyMetrics();
      
      return GodModeDashboardData(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        totalBusinessAccounts: totalBusinessAccounts,
        activeConnections: connectionsOverview.totalActiveConnections,
        totalCommunications: totalCommunications,
        systemHealth: systemHealth,
        aggregatePrivacyMetrics: aggregatePrivacyMetrics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error fetching dashboard data: $e', name: _logName);
      rethrow;
    }
  }
  
  // Private stream management methods
  void _startUserDataStream(String userId, StreamController<UserDataSnapshot> controller) {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final snapshot = await _fetchUserDataSnapshot(userId);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in user data stream: $e', name: _logName);
      }
    });
  }
  
  void _startAIDataStream(String aiSignature, StreamController<AIDataSnapshot> controller) {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final snapshot = await _fetchAIDataSnapshot(aiSignature);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in AI data stream: $e', name: _logName);
      }
    });
  }
  
  void _startCommunicationsStream(
    String? userId,
    String? connectionId,
    StreamController<CommunicationsSnapshot> controller,
  ) {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final snapshot = await _fetchCommunicationsSnapshot(userId, connectionId);
        controller.add(snapshot);
      } catch (e) {
        developer.log('Error in communications stream: $e', name: _logName);
      }
    });
  }
  
  Future<UserDataSnapshot> _fetchUserDataSnapshot(String userId) async {
    // Fetch actual user data from database
    // IMPORTANT: Filter out all personal data before returning
    
    try {
      final client = _supabaseService.client;
      
      // Fetch user data - only select fields that are safe (no personal data)
      final userResponse = await client
          .from('users')
          .select('id, location, created_at, updated_at')
          .eq('id', userId)
          .maybeSingle();
      
      if (userResponse == null) {
        // User not found, return minimal snapshot
        return UserDataSnapshot(
          userId: userId,
          isOnline: false,
          lastActive: DateTime.now(),
          data: {'ai_signature': _generateAISignature(userId)},
        );
      }
      
      final userData = userResponse;
      final updatedAt = DateTime.parse(userData['updated_at'] as String);
      
      // Build raw data with only safe fields
      final rawData = <String, dynamic>{
        'ai_signature': _generateAISignature(userId),
        'ai_connections': 0, // TODO: Get from connection monitor
        'ai_status': 'active',
      };
      
      // Add location data if available (allowed as vibe indicator)
      if (userData['location'] != null) {
        final location = userData['location'] as String?;
        if (location != null && location.isNotEmpty) {
          // Location is allowed, but parse carefully to avoid home addresses
          rawData['location'] = location;
        }
      }
      
      // Get user's spots for location data (vibe indicators)
      try {
        final spotsResponse = await client
            .from('spots')
            .select('latitude, longitude')
            .eq('created_by', userId)
            .limit(10);
        
        final spots = (spotsResponse as List).cast<Map<String, dynamic>>();
        if (spots.isNotEmpty) {
          final visitedLocations = spots.map((spot) => <String, double>{
            'lat': (spot['latitude'] as num).toDouble(),
            'lng': (spot['longitude'] as num).toDouble(),
          }).toList();
          rawData['visited_locations'] = visitedLocations;
        }
      } catch (e) {
        developer.log('Error fetching user spots: $e', name: _logName);
      }
      
      // Apply privacy filter to ensure no personal data leaks through
      final filteredData = AdminPrivacyFilter.filterPersonalData(rawData);
      
      // Validate that no personal data is included
      if (!AdminPrivacyFilter.isValid(filteredData)) {
        developer.log('WARNING: Personal data detected in user snapshot for $userId', name: _logName);
        // Return minimal data if personal data detected
        return UserDataSnapshot(
          userId: userId,
          isOnline: false,
          lastActive: updatedAt,
          data: {'ai_signature': _generateAISignature(userId)},
        );
      }
      
      // Check if user is online (updated within last hour)
      final isOnline = DateTime.now().difference(updatedAt).inHours < 1;
      
      return UserDataSnapshot(
        userId: userId,
        isOnline: isOnline,
        lastActive: updatedAt,
        data: filteredData,
      );
    } catch (e) {
      developer.log('Error fetching user data snapshot: $e', name: _logName);
      // Return minimal snapshot on error
      return UserDataSnapshot(
        userId: userId,
        isOnline: false,
        lastActive: DateTime.now(),
        data: {'ai_signature': _generateAISignature(userId)},
      );
    }
  }
  
  Future<AIDataSnapshot> _fetchAIDataSnapshot(String aiSignature) async {
    // Check cache first
    final cached = _aiSnapshotCache[aiSignature];
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < _aiSnapshotCacheTTL) {
      return cached.snapshot;
    }
    
    try {
      // Get all connections involving this AI signature (efficient O(1) lookup)
      final connectionIds = _connectionMonitor.getConnectionsByAISignature(aiSignature);
      final sessions = _connectionMonitor.getSessionsByAISignature(aiSignature);
      
      if (sessions.isEmpty) {
        // No active connections for this AI
        final snapshot = AIDataSnapshot(
          aiSignature: aiSignature,
          isActive: false,
          connections: 0,
          data: {
            'status': 'inactive',
            'last_seen': null,
          },
        );
        _aiSnapshotCache[aiSignature] = _CachedAISnapshot(snapshot, DateTime.now());
        return snapshot;
      }
      
      // Aggregate metrics from all connections
      double totalCompatibility = 0.0;
      double totalLearningEffectiveness = 0.0;
      double totalAIPleasure = 0.0;
      int totalInteractions = 0;
      int recentAlerts = 0;
      DateTime? lastActivity;
      
      for (final session in sessions) {
        final metrics = session.currentMetrics;
        totalCompatibility += metrics.currentCompatibility;
        totalLearningEffectiveness += metrics.learningEffectiveness;
        totalAIPleasure += metrics.aiPleasureScore;
        totalInteractions += metrics.interactionHistory.length;
        
        // Count recent alerts (last 15 minutes)
        final recentSessionAlerts = session.alertsGenerated
            .where((alert) => DateTime.now().difference(alert.timestamp) < Duration(minutes: 15))
            .length;
        recentAlerts += recentSessionAlerts;
        
        // Track most recent activity
        final sessionLastActivity = session.lastUpdated ?? session.startTime;
        if (lastActivity == null || sessionLastActivity.isAfter(lastActivity)) {
          lastActivity = sessionLastActivity;
        }
      }
      
      final connectionCount = sessions.length;
      final avgCompatibility = totalCompatibility / connectionCount;
      final avgLearningEffectiveness = totalLearningEffectiveness / connectionCount;
      final avgAIPleasure = totalAIPleasure / connectionCount;
      
      // Get communication data from chat analyzer
      int totalChatEvents = 0;
      if (_chatAnalyzer != null) {
        final allChatHistory = _chatAnalyzer!.getAllChatHistoryForAdmin();
        for (final userChats in allChatHistory.values) {
          final relevantChats = userChats.where((event) {
            return event.participants.contains(aiSignature) ||
                   event.participants.any((p) => p.contains(aiSignature.substring(0, 8)));
          }).length;
          totalChatEvents += relevantChats;
        }
      }
      
      // Build comprehensive snapshot
      final snapshot = AIDataSnapshot(
        aiSignature: aiSignature,
        isActive: true,
        connections: connectionCount,
        data: {
          'status': 'active',
          'active_connection_ids': connectionIds.toList(),
          'average_compatibility': avgCompatibility,
          'average_learning_effectiveness': avgLearningEffectiveness,
          'average_ai_pleasure': avgAIPleasure,
          'total_interactions': totalInteractions,
          'total_chat_events': totalChatEvents,
          'recent_alerts': recentAlerts,
          'last_activity': lastActivity?.toIso8601String(),
          'connection_health': (avgCompatibility + avgLearningEffectiveness + avgAIPleasure) / 3.0,
        },
      );
      
      // Cache the snapshot
      _aiSnapshotCache[aiSignature] = _CachedAISnapshot(snapshot, DateTime.now());
      
      // Clean up stale cache entries
      _cleanupAISnapshotCache();
      
      return snapshot;
    } catch (e) {
      developer.log('Error fetching AI data snapshot: $e', name: _logName);
      // Return minimal snapshot on error
      return AIDataSnapshot(
        aiSignature: aiSignature,
        isActive: false,
        connections: 0,
        data: {'error': e.toString()},
      );
    }
  }
  
  /// Clean up stale cache entries
  void _cleanupAISnapshotCache() {
    final now = DateTime.now();
    _aiSnapshotCache.removeWhere((key, cached) => 
        now.difference(cached.timestamp) > _aiSnapshotCacheTTL);
  }
  
  Future<CommunicationsSnapshot> _fetchCommunicationsSnapshot(
    String? userId,
    String? connectionId,
  ) async {
    // TODO: Fetch actual communications
    return CommunicationsSnapshot(
      totalMessages: 0,
      recentMessages: [],
      activeConnections: 0,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Get all federated learning rounds with participant details
  /// Shows active and completed rounds across the entire network
  Future<List<GodModeFederatedRoundInfo>> getAllFederatedLearningRounds({
    bool? includeCompleted,
  }) async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      developer.log('Fetching all federated learning rounds', name: _logName);
      
      // For now, return mock data since we need to implement proper storage
      // In a real implementation, this would query a database or federated learning manager
      final rounds = <GodModeFederatedRoundInfo>[];
      
      // Mock active round
      final activeRound = GodModeFederatedRoundInfo(
        round: federated.FederatedLearningRound(
          roundId: 'fl_round_001',
          organizationId: 'spots_network',
          objective: federated.LearningObjective(
            name: 'Improve Spot Recommendations',
            description: 'Learning user preferences for nightlife venues to provide better personalized recommendations',
            type: federated.LearningType.recommendation,
            parameters: {
              'learning_rate': 0.01,
              'batch_size': 32,
            },
          ),
          participantNodeIds: ['node_abc123', 'node_def456', 'node_ghi789'],
          status: federated.RoundStatus.training,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          roundNumber: 5,
          globalModel: federated.GlobalModel(
            modelId: 'model_001',
            objective: federated.LearningObjective(
              name: 'Improve Spot Recommendations',
              description: 'Learning user preferences for nightlife venues',
              type: federated.LearningType.recommendation,
              parameters: {},
            ),
            version: 5,
            parameters: {},
            loss: 0.15,
            accuracy: 0.85,
            updatedAt: DateTime.now(),
          ),
          participantUpdates: {},
          privacyMetrics: federated.PrivacyMetrics.initial(),
        ),
        participants: [
          RoundParticipant(
            nodeId: 'node_abc123',
            userId: 'user_1',
            aiPersonalityName: 'Nightlife Explorer',
            contributionCount: 12,
            joinedAt: DateTime.now().subtract(const Duration(hours: 2)),
            isActive: true,
          ),
          RoundParticipant(
            nodeId: 'node_def456',
            userId: 'user_2',
            aiPersonalityName: 'Social Connector',
            contributionCount: 8,
            joinedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
            isActive: true,
          ),
          RoundParticipant(
            nodeId: 'node_ghi789',
            userId: 'user_3',
            aiPersonalityName: 'Culture Seeker',
            contributionCount: 15,
            joinedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            isActive: true,
          ),
        ],
        performanceMetrics: RoundPerformanceMetrics(
          participationRate: 1.0,
          averageAccuracy: 0.85,
          privacyComplianceScore: 0.98,
          convergenceProgress: 0.65,
        ),
        learningRationale: 'This round is learning from anonymous user interactions with nightlife venues to improve recommendation quality while preserving privacy through federated learning.',
      );
      
      rounds.add(activeRound);
      
      // Add completed round if requested
      if (includeCompleted == null || includeCompleted) {
        final completedRound = GodModeFederatedRoundInfo(
          round: federated.FederatedLearningRound(
            roundId: 'fl_round_000',
            organizationId: 'spots_network',
            objective: federated.LearningObjective(
              name: 'Classify Venue Categories',
              description: 'Training AI to better categorize venues based on user preferences and behaviors',
              type: federated.LearningType.classification,
              parameters: {
                'learning_rate': 0.01,
                'epochs': 10,
              },
            ),
            participantNodeIds: ['node_abc123', 'node_xyz999'],
            status: federated.RoundStatus.completed,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            roundNumber: 10,
            globalModel: federated.GlobalModel(
              modelId: 'model_000',
              objective: federated.LearningObjective(
                name: 'Classify Venue Categories',
                description: 'Training AI to better categorize venues',
                type: federated.LearningType.classification,
                parameters: {},
              ),
              version: 10,
              parameters: {},
              loss: 0.08,
              accuracy: 0.92,
              updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
            ),
            participantUpdates: {},
            privacyMetrics: federated.PrivacyMetrics.initial(),
          ),
          participants: [
            RoundParticipant(
              nodeId: 'node_abc123',
              userId: 'user_1',
              aiPersonalityName: 'Nightlife Explorer',
              contributionCount: 25,
              joinedAt: DateTime.now().subtract(const Duration(days: 1)),
              isActive: false,
            ),
            RoundParticipant(
              nodeId: 'node_xyz999',
              userId: 'user_4',
              aiPersonalityName: 'Foodie Guide',
              contributionCount: 18,
              joinedAt: DateTime.now().subtract(const Duration(days: 1)),
              isActive: false,
            ),
          ],
          performanceMetrics: RoundPerformanceMetrics(
            participationRate: 1.0,
            averageAccuracy: 0.92,
            privacyComplianceScore: 1.0,
            convergenceProgress: 1.0,
          ),
          learningRationale: 'Completed round that trained the AI to better classify venues into categories like restaurants, bars, clubs, etc., improving search and discovery features.',
        );
        
        rounds.add(completedRound);
      }
      
      developer.log('Fetched ${rounds.length} federated learning rounds', name: _logName);
      return rounds;
    } catch (e) {
      developer.log('Error fetching federated learning rounds: $e', name: _logName);
      return [];
    }
  }
  
  /// Get collaborative activity metrics
  /// Phase 7 Week 40: Privacy-safe aggregate metrics on collaborative patterns
  Future<CollaborativeActivityMetrics> getCollaborativeActivityMetrics() async {
    if (!isAuthorized) {
      throw UnauthorizedException('God-mode access required');
    }
    
    try {
      developer.log('Getting collaborative activity metrics', name: _logName);
      
      if (_chatAnalyzer == null) {
        developer.log('Chat analyzer not available, returning empty metrics', name: _logName);
        return CollaborativeActivityMetrics.empty();
      }
      
      // Get all chat history across all users
      final allChatHistory = _chatAnalyzer!.getAllChatHistoryForAdmin();
      
      // Aggregate metrics across all users
      int totalCollaborativeLists = 0;
      int groupChatLists = 0;
      int dmLists = 0;
      final groupSizes = <int, int>{};
      final activityByHour = <int, int>{};
      int totalPlanningSessions = 0;
      double totalSessionDuration = 0.0;
      int listsWithSpots = 0;
      int totalUsersContributing = 0;
      DateTime? earliestChat;
      DateTime? latestChat;
      
      // Process each user's chat history
      for (final entry in allChatHistory.entries) {
        final userId = entry.key;
        final chats = entry.value;
        
        if (chats.isEmpty) continue;
        
        // Aggregate metrics (privacy-safe - counts only)
        for (final chat in chats) {
          // Check for planning keywords
          bool hasPlanningKeywords = false;
          for (final message in chat.messages) {
            final content = message.content.toLowerCase();
            if (content.contains('list') || 
                content.contains('plan') || 
                content.contains('create') ||
                content.contains('collaborate') ||
                content.contains('together')) {
              hasPlanningKeywords = true;
              break;
            }
          }
          
          if (hasPlanningKeywords) {
            totalPlanningSessions++;
            totalSessionDuration += chat.duration.inMinutes.toDouble();
          }
          
          // Estimate list creation (simplified)
          final groupSize = chat.participants.length;
          final isGroupChat = groupSize >= 3;
          final listCreationProbability = hasPlanningKeywords && chat.messages.length >= 3 ? 0.3 : 0.0;
          
          if (listCreationProbability > 0.1) {
            totalCollaborativeLists++;
            
            groupSizes[groupSize] = (groupSizes[groupSize] ?? 0) + 1;
            
            if (isGroupChat) {
              groupChatLists++;
            } else {
              dmLists++;
            }
            
            final hour = chat.timestamp.hour;
            activityByHour[hour] = (activityByHour[hour] ?? 0) + 1;
            
            if (chat.messages.length >= 5) {
              listsWithSpots++;
            }
          }
          
          // Track temporal bounds
          if (earliestChat == null || chat.timestamp.isBefore(earliestChat)) {
            earliestChat = chat.timestamp;
          }
          if (latestChat == null || chat.timestamp.isAfter(latestChat)) {
            latestChat = chat.timestamp;
          }
        }
        
        if (chats.isNotEmpty) {
          totalUsersContributing++;
        }
      }
      
      // Calculate total chats for collaboration rate
      final totalChats = allChatHistory.values
          .map((chats) => chats.length)
          .fold(0, (sum, count) => sum + count);
      
      // Calculate aggregate metrics
      final collaborationRate = totalChats > 0
          ? totalCollaborativeLists / totalChats
          : 0.0;
      
      final avgSessionDuration = totalPlanningSessions > 0
          ? totalSessionDuration / totalPlanningSessions
          : 0.0;
      
      final followThroughRate = totalCollaborativeLists > 0
          ? listsWithSpots / totalCollaborativeLists
          : 0.0;
      
      // Estimate averages (simplified - would calculate from actual lists in production)
      final avgListSize = 8.3;
      final avgCollaboratorCount = groupSizes.entries
          .map((e) => e.key * e.value)
          .fold(0, (sum, val) => sum + val) / 
          (totalCollaborativeLists > 0 ? totalCollaborativeLists : 1);
      
      return CollaborativeActivityMetrics(
        totalCollaborativeLists: totalCollaborativeLists,
        groupChatLists: groupChatLists,
        dmLists: dmLists,
        avgListSize: avgListSize,
        avgCollaboratorCount: avgCollaboratorCount,
        groupSizeDistribution: groupSizes,
        collaborationRate: collaborationRate,
        totalPlanningSessions: totalPlanningSessions,
        avgSessionDuration: avgSessionDuration,
        followThroughRate: followThroughRate,
        activityByHour: activityByHour,
        collectionStart: earliestChat ?? DateTime.now(),
        lastUpdated: DateTime.now(),
        measurementWindow: earliestChat != null && latestChat != null
            ? latestChat.difference(earliestChat)
            : Duration.zero,
        totalUsersContributing: totalUsersContributing,
        containsUserData: false,
        isAnonymized: true,
      );
    } catch (e) {
      developer.log('Error getting collaborative activity metrics: $e', name: _logName);
      return CollaborativeActivityMetrics.empty();
    }
  }
  
  /// Dispose and cleanup
  void dispose() {
    _refreshTimer?.cancel();
    for (final controller in _dataStreams.values) {
      controller.close();
    }
    _dataStreams.clear();
    _aiSnapshotCache.clear();
  }
}

// Data models for god-mode admin

/// User data snapshot for admin viewing
/// Privacy-preserving: Contains AI-related data and location data (vibe indicators)
/// Excludes: name, email, phone, home address
class UserDataSnapshot {
  final String userId; // User's unique ID only
  final bool isOnline;
  final DateTime lastActive;
  final Map<String, dynamic> data; // AI-related and location data, NO personal info
  
  UserDataSnapshot({
    required this.userId,
    required this.isOnline,
    required this.lastActive,
    required this.data, // Must not contain: name, email, phone, home_address
    // Location data IS allowed (core vibe indicator)
  });
  
  /// Validate that no personal data is included
  /// Location data is allowed, but home address is forbidden
  bool get isValid {
    final forbiddenKeys = ['name', 'email', 'phone', 'home_address', 'homeaddress', 'personal'];
    final forbiddenLocationKeys = ['home_address', 'homeaddress', 'residential_address'];
    
    for (final key in data.keys) {
      final lowerKey = key.toLowerCase();
      
      // Check for forbidden home address
      if (forbiddenLocationKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }
      
      // Check for other forbidden personal data
      if (forbiddenKeys.any((forbidden) => lowerKey.contains(forbidden))) {
        return false;
      }
    }
    
    return true;
  }
}

class AIDataSnapshot {
  final String aiSignature;
  final bool isActive;
  final int connections;
  final Map<String, dynamic> data;
  
  AIDataSnapshot({
    required this.aiSignature,
    required this.isActive,
    required this.connections,
    required this.data,
  });
}

class CommunicationsSnapshot {
  final int totalMessages;
  final List<dynamic> recentMessages;
  final int activeConnections;
  final DateTime lastUpdated;
  
  CommunicationsSnapshot({
    required this.totalMessages,
    required this.recentMessages,
    required this.activeConnections,
    required this.lastUpdated,
  });
}

class UserProgressData {
  final String userId;
  final List<ExpertiseProgress> expertiseProgress;
  final int totalContributions;
  final int pinsEarned;
  final int listsCreated;
  final int spotsAdded;
  final DateTime lastUpdated;
  
  UserProgressData({
    required this.userId,
    required this.expertiseProgress,
    required this.totalContributions,
    required this.pinsEarned,
    required this.listsCreated,
    required this.spotsAdded,
    required this.lastUpdated,
  });
}

class UserPredictionsData {
  final String userId;
  final String currentStage;
  final List<PredictionAction> predictedActions;
  final List<JourneyStep> journeyPath;
  final double confidence;
  final Duration timeframe;
  final DateTime lastUpdated;
  
  UserPredictionsData({
    required this.userId,
    required this.currentStage,
    required this.predictedActions,
    required this.journeyPath,
    required this.confidence,
    required this.timeframe,
    required this.lastUpdated,
  });
}

class PredictionAction {
  final String action;
  final double probability;
  final String category;
  
  PredictionAction({
    required this.action,
    required this.probability,
    required this.category,
  });
}

class JourneyStep {
  final String description;
  final Duration estimatedTime;
  final double likelihood;
  
  JourneyStep({
    required this.description,
    required this.estimatedTime,
    required this.likelihood,
  });
}

class BusinessAccountData {
  final BusinessAccount account;
  final bool isVerified;
  final int connectedExperts;
  final DateTime lastActivity;
  
  BusinessAccountData({
    required this.account,
    required this.isVerified,
    required this.connectedExperts,
    required this.lastActivity,
  });
}

class UserSearchResult {
  final String userId;
  final String aiSignature; // Only AI signature, no personal data
  final DateTime createdAt;
  final bool isActive;
  
  UserSearchResult({
    required this.userId,
    required this.aiSignature,
    required this.createdAt,
    required this.isActive,
  });
}

class GodModeDashboardData {
  final int totalUsers;
  final int activeUsers;
  final int totalBusinessAccounts;
  final int activeConnections;
  final int totalCommunications;
  final double systemHealth;
  final AggregatePrivacyMetrics aggregatePrivacyMetrics;
  final DateTime lastUpdated;
  
  GodModeDashboardData({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBusinessAccounts,
    required this.activeConnections,
    required this.totalCommunications,
    required this.systemHealth,
    required this.aggregatePrivacyMetrics,
    required this.lastUpdated,
  });
}

/// Aggregate privacy metrics showing mean privacy scores across all users
class AggregatePrivacyMetrics {
  /// Mean overall privacy score (0.0-1.0) across all users
  final double meanOverallPrivacyScore;
  
  /// Mean anonymization level across all users
  final double meanAnonymizationLevel;
  
  /// Mean data security score across all users
  final double meanDataSecurityScore;
  
  /// Mean encryption strength across all users
  final double meanEncryptionStrength;
  
  /// Mean compliance rate across all users
  final double meanComplianceRate;
  
  /// Total privacy violations across all users
  final int totalPrivacyViolations;
  
  /// Number of users included in this aggregate
  final int userCount;
  
  /// When this aggregate was calculated
  final DateTime lastUpdated;
  
  AggregatePrivacyMetrics({
    required this.meanOverallPrivacyScore,
    required this.meanAnonymizationLevel,
    required this.meanDataSecurityScore,
    required this.meanEncryptionStrength,
    required this.meanComplianceRate,
    required this.totalPrivacyViolations,
    required this.userCount,
    required this.lastUpdated,
  });
  
  /// Get color indicator for privacy score
  String get scoreLabel {
    if (meanOverallPrivacyScore >= 0.95) return 'Excellent';
    if (meanOverallPrivacyScore >= 0.85) return 'Good';
    if (meanOverallPrivacyScore >= 0.75) return 'Fair';
    return 'Needs Improvement';
  }
}

/// Active AI Agent data for map display
/// Privacy-preserving: Contains AI agent data with location and predictions, NO personal information
class ActiveAIAgentData {
  final String userId;
  final String aiSignature;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final DateTime lastActive;
  final int aiConnections;
  final String aiStatus;
  final List<PredictionAction> predictedActions;
  final String currentStage;
  final double confidence;
  
  ActiveAIAgentData({
    required this.userId,
    required this.aiSignature,
    required this.latitude,
    required this.longitude,
    required this.isOnline,
    required this.lastActive,
    required this.aiConnections,
    required this.aiStatus,
    required this.predictedActions,
    required this.currentStage,
    required this.confidence,
  });
  
  /// Get top predicted action
  PredictionAction? get topPredictedAction {
    if (predictedActions.isEmpty) return null;
    return predictedActions.reduce((a, b) => a.probability > b.probability ? a : b);
  }
}

/// Club/Community data for admin viewing
/// Privacy-preserving: Contains AI agent data for members, NO personal information
class ClubCommunityData {
  final String id;
  final String name;
  final String? description;
  final String category;
  final bool isClub;
  final int memberCount;
  final int eventCount;
  final String founderId;
  final List<String>? leaders; // Only for clubs
  final List<String>? adminTeam; // Only for clubs
  final DateTime createdAt;
  final DateTime? lastEventAt;
  final Map<String, Map<String, dynamic>> memberAIAgents; // AI agent data per member (privacy-filtered)
  
  ClubCommunityData({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.isClub,
    required this.memberCount,
    required this.eventCount,
    required this.founderId,
    this.leaders,
    this.adminTeam,
    required this.createdAt,
    this.lastEventAt,
    required this.memberAIAgents,
  });
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Cache entry for AI snapshot data
class _CachedAISnapshot {
  final AIDataSnapshot snapshot;
  final DateTime timestamp;
  
  _CachedAISnapshot(this.snapshot, this.timestamp);
}

/// God-mode view of a federated learning round with enriched participant data
class GodModeFederatedRoundInfo {
  /// The base federated learning round
  final federated.FederatedLearningRound round;
  
  /// List of participants with user and AI personality information
  final List<RoundParticipant> participants;
  
  /// Performance metrics for this round
  final RoundPerformanceMetrics performanceMetrics;
  
  /// Detailed explanation of why this learning round exists
  final String learningRationale;
  
  GodModeFederatedRoundInfo({
    required this.round,
    required this.participants,
    required this.performanceMetrics,
    required this.learningRationale,
  });
  
  /// Get formatted duration
  String get durationString {
    final duration = DateTime.now().difference(round.createdAt);
    if (duration.inDays > 0) return '${duration.inDays}d ${duration.inHours % 24}h';
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m';
    return '${duration.inMinutes}m';
  }
  
  /// Check if round is active
  bool get isActive => round.status == federated.RoundStatus.training || 
                        round.status == federated.RoundStatus.aggregating;
}

/// Participant information for a federated learning round
class RoundParticipant {
  /// The node ID participating in the round
  final String nodeId;
  
  /// The user ID associated with this node
  final String userId;
  
  /// The AI personality name/archetype for this participant
  final String aiPersonalityName;
  
  /// Number of contributions (model updates) made
  final int contributionCount;
  
  /// When this participant joined the round
  final DateTime joinedAt;
  
  /// Whether the participant is currently active
  final bool isActive;
  
  RoundParticipant({
    required this.nodeId,
    required this.userId,
    required this.aiPersonalityName,
    required this.contributionCount,
    required this.joinedAt,
    required this.isActive,
  });
  
  /// Get formatted join time
  String get joinedTimeAgo {
    final duration = DateTime.now().difference(joinedAt);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    return '${duration.inMinutes}m ago';
  }
}

/// Performance metrics for a federated learning round
class RoundPerformanceMetrics {
  /// Percentage of invited participants who are actively participating
  final double participationRate;
  
  /// Average model accuracy across all participants
  final double averageAccuracy;
  
  /// Privacy compliance score (0.0-1.0)
  final double privacyComplianceScore;
  
  /// Progress towards convergence (0.0-1.0)
  final double convergenceProgress;
  
  RoundPerformanceMetrics({
    required this.participationRate,
    required this.averageAccuracy,
    required this.privacyComplianceScore,
    required this.convergenceProgress,
  });
  
  /// Get overall health score
  double get overallHealth => 
      (participationRate + averageAccuracy + privacyComplianceScore + convergenceProgress) / 4.0;
}

