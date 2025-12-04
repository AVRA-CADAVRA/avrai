import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_expert_preferences.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_community.dart';
import 'package:spots/core/services/expertise_matching_service.dart';
import 'package:spots/core/services/expertise_community_service.dart';
import 'package:spots/core/services/llm_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/partnership_service.dart';

/// Business Expert Matching Service
/// 
/// Matches businesses with experts using vibe-first matching approach.
/// 
/// **Matching Philosophy:**
/// - **Vibe compatibility is PRIMARY** (50% weight) - Personality fit is most important
/// - **Expertise match** (30% weight) - Required expertise categories
/// - **Location match** (20% weight) - Preference boost, NOT a filter
/// 
/// **Key Principles:**
/// - Local experts are ALWAYS included (not excluded by level filtering)
/// - Level is a preference boost only (in scoring, not filtering)
/// - Location is a preference boost only (remote experts with great vibe/expertise are included)
/// - Vibe compatibility is calculated for all matches (0.0 to 1.0)
/// - 70%+ vibe compatibility is considered (but not required - lower vibe matches still included)
/// 
/// **What Doors Does This Open?**
/// - Connection Doors: Local experts can connect with businesses, not excluded by level filtering
/// - Vibe Doors: Vibe matches prioritized over geographic level - best fit experts found regardless of location
/// - Opportunity Doors: Remote experts with great vibe/expertise can connect with businesses
/// - Authentic Matching Doors: Matching based on personality fit, not just geographic proximity
class BusinessExpertMatchingService {
  static const String _logName = 'BusinessExpertMatchingService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final ExpertiseMatchingService _expertiseMatchingService;
  final ExpertiseCommunityService _communityService;
  final LLMService? _llmService;
  final PartnershipService? _partnershipService;

  BusinessExpertMatchingService({
    ExpertiseMatchingService? expertiseMatchingService,
    ExpertiseCommunityService? communityService,
    LLMService? llmService,
    PartnershipService? partnershipService,
  }) : _expertiseMatchingService = expertiseMatchingService ?? ExpertiseMatchingService(),
       _communityService = communityService ?? ExpertiseCommunityService(),
       _llmService = llmService,
       _partnershipService = partnershipService;

  /// Find experts for a business account
  /// Uses community membership, expertise matching, and AI suggestions
  /// Applies business expert preferences for filtering and ranking
  Future<List<BusinessExpertMatch>> findExpertsForBusiness(
    BusinessAccount business, {
    int maxResults = 20,
  }) async {
    try {
      _logger.info('Finding experts for business: ${business.id}', tag: _logName);

      final preferences = business.expertPreferences;
      final matches = <BusinessExpertMatch>[];

      // Get expertise categories from preferences or legacy fields
      final requiredCategories = preferences?.requiredExpertiseCategories.isNotEmpty == true
          ? preferences!.requiredExpertiseCategories
          : business.requiredExpertise;
      
      final preferredCategories = preferences?.preferredExpertiseCategories ?? [];

      // STEP 1: Find experts by required expertise categories
      for (final category in requiredCategories) {
        final expertMatches = await _findExpertsByCategory(
          business,
          category,
          maxResults: maxResults ~/ requiredCategories.length,
        );
        matches.addAll(expertMatches);
      }

      // STEP 2: Find experts from preferred communities
      final communities = preferences?.preferredCommunities ?? business.preferredCommunities;
      for (final communityId in communities) {
        final communityMatches = await _findExpertsFromCommunity(
          business,
          communityId,
          maxResults: 5,
        );
        matches.addAll(communityMatches);
      }

      // STEP 3: Use AI to suggest additional experts (with preferences)
      if (_llmService != null) {
        final aiMatches = await _findExpertsWithAI(business, preferences, maxResults: 10);
        matches.addAll(aiMatches);
      }

      // STEP 4: Apply preference filters
      final filteredMatches = _applyPreferenceFilters(matches, business, preferences);

      // STEP 5: Rank matches using preferences
      final rankedMatches = _rankAndDeduplicate(filteredMatches, business, preferences);

      // STEP 6: Apply minimum match score threshold
      final thresholdMatches = preferences?.minMatchScore != null
          ? rankedMatches.where((m) => m.matchScore >= preferences!.minMatchScore!).toList()
          : rankedMatches;

      _logger.info('Found ${thresholdMatches.length} expert matches', tag: _logName);
      return thresholdMatches.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding experts for business', error: e, tag: _logName);
      return [];
    }
  }

  /// Find experts by expertise category
  Future<List<BusinessExpertMatch>> _findExpertsByCategory(
    BusinessAccount business,
    String category, {
    int maxResults = 10,
  }) async {
    try {
      // Create a temporary user object for matching
      final tempUser = UnifiedUser(
        id: business.id,
        email: business.email,
        displayName: business.name,
        location: business.preferredLocation ?? business.location,
        createdAt: business.createdAt,
        updatedAt: business.updatedAt,
        expertiseMap: {}, // Business doesn't have expertise, they need it
      );

      // Find similar experts (businesses need experts, so we find experts)
      final expertMatches = await _expertiseMatchingService.findSimilarExperts(
        tempUser,
        category,
        location: business.preferredLocation,
        maxResults: maxResults,
      );

      // Apply vibe-first matching to expertise matches
      // CRITICAL: Vibe compatibility is PRIMARY (50% weight)
      // All experts with required expertise are included (level/location are preference boosts)
      final vibeFirstMatches = <BusinessExpertMatch>[];
      for (final match in expertMatches) {
        // Calculate vibe-first score (50% vibe, 30% expertise, 20% location)
        // Vibe compatibility is PRIMARY factor - personality fit is most important
        final vibeCompatibility = await _calculateVibeCompatibility(match.user, business);
        final expertiseMatch = _calculateExpertiseMatchScore(match.user, [category]);
        final locationMatch = _calculateLocationMatchScore(match.user, business);
        
        // Vibe-first matching formula: 50% vibe + 30% expertise + 20% location
        // This ensures vibe compatibility is the PRIMARY factor in ranking
        final vibeFirstScore = (vibeCompatibility * 0.5) + (expertiseMatch * 0.3) + (locationMatch * 0.2);
        
        vibeFirstMatches.add(BusinessExpertMatch(
          expert: match.user,
          business: business,
          matchScore: vibeFirstScore,
          matchReason: 'Expertise match: $category (vibe-first)',
          matchType: MatchType.expertise,
          matchedCategories: [category],
          matchedCommunities: [],
        ));
      }
      
      return vibeFirstMatches;
    } catch (e) {
      _logger.error('Error finding experts by category', error: e, tag: _logName);
      return [];
    }
  }

  /// Find experts from a specific community
  Future<List<BusinessExpertMatch>> _findExpertsFromCommunity(
    BusinessAccount business,
    String communityId, {
    int maxResults = 5,
  }) async {
    try {
      // Get community
      final communities = await _communityService.searchCommunities();
      final communityMatches = communities.where((c) => c.id == communityId);
      if (communityMatches.isEmpty) {
        _logger.warning('Community not found: $communityId', tag: _logName);
        return [];
      }
      final community = communityMatches.first;

      // Get community members
      final members = await _communityService.getCommunityMembers(community);
      
      // Filter members who match business requirements
      final matches = <BusinessExpertMatch>[];
      
      for (final member in members) {
        // Check if member has required expertise
        bool hasRequiredExpertise = business.requiredExpertise.isEmpty ||
            business.requiredExpertise.any((cat) => member.hasExpertiseIn(cat));

        if (!hasRequiredExpertise) continue;

        // CRITICAL: Level-based filtering is REMOVED
        // - All experts with required expertise are included (regardless of level)
        // - Level is used as preference boost in scoring only (see _applyPreferenceScoring)
        // - Local experts are ALWAYS included in matching pool
        
        // CRITICAL: Location-based filtering is REMOVED
        // - All experts with required expertise are included (regardless of location)
        // - Location is used as preference boost in scoring only (20% weight in vibe-first matching)
        // - Remote experts with great vibe/expertise are included
        // - Local experts in locality get boost, but not required
        if (hasRequiredExpertise) {
          final matchedCategories = business.requiredExpertise
              .where((cat) => member.hasExpertiseIn(cat))
              .toList();

          final matchScore = await _calculateCommunityMatchScore(
            member,
            business,
            community,
            matchedCategories,
          );

          matches.add(BusinessExpertMatch(
            expert: member,
            business: business,
            matchScore: matchScore,
            matchReason: 'Member of ${community.name}',
            matchType: MatchType.community,
            matchedCategories: matchedCategories,
            matchedCommunities: [community.id],
          ));
        }
      }

      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return matches.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding experts from community', error: e, tag: _logName);
      return [];
    }
  }

  /// Use AI to suggest experts (with preferences)
  Future<List<BusinessExpertMatch>> _findExpertsWithAI(
    BusinessAccount business,
    BusinessExpertPreferences? preferences, {
    int maxResults = 10,
  }) async {
    try {
      if (_llmService == null) return [];

      // Build AI prompt with preferences
      final prompt = _buildAIMatchingPrompt(business, preferences);
      
      // Get AI suggestions
      final aiResponse = await _llmService!.generateRecommendation(
        userQuery: prompt,
      );

      // Parse AI response to extract expert suggestions
      final suggestions = _parseAISuggestions(aiResponse);
      
      // Find actual experts based on AI suggestions
      final matches = <BusinessExpertMatch>[];
      
      for (final suggestion in suggestions) {
        // Find experts matching AI suggestions
        final expertMatches = await _findExpertsByAISuggestion(
          business,
          suggestion,
        );
        matches.addAll(expertMatches);
      }

      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return matches.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding experts with AI', error: e, tag: _logName);
      return [];
    }
  }

  /// Find experts based on AI suggestion
  Future<List<BusinessExpertMatch>> _findExpertsByAISuggestion(
    BusinessAccount business,
    AISuggestion suggestion,
  ) async {
    try {
      final matches = <BusinessExpertMatch>[];

      // Find experts in suggested category
      if (suggestion.category != null) {
        final categoryMatches = await _findExpertsByCategory(
          business,
          suggestion.category!,
          maxResults: 3,
        );
        matches.addAll(categoryMatches);
      }

      // Find experts from suggested community
      if (suggestion.communityId != null) {
        final communityMatches = await _findExpertsFromCommunity(
          business,
          suggestion.communityId!,
          maxResults: 3,
        );
        matches.addAll(communityMatches);
      }

      // Boost match score for AI-suggested matches
      return matches.map((match) {
        return BusinessExpertMatch(
          expert: match.expert,
          business: match.business,
          matchScore: match.matchScore * 1.2, // Boost AI suggestions
          matchReason: 'AI suggested: ${suggestion.reason}',
          matchType: MatchType.aiSuggestion,
          matchedCategories: match.matchedCategories,
          matchedCommunities: match.matchedCommunities,
        );
      }).toList();
    } catch (e) {
      _logger.error('Error finding experts by AI suggestion', error: e, tag: _logName);
      return [];
    }
  }

  /// Build AI prompt for expert matching (with preferences)
  String _buildAIMatchingPrompt(BusinessAccount business, BusinessExpertPreferences? preferences) {
    final buffer = StringBuffer();
    
    buffer.writeln('A business "${business.name}" (${business.businessType}) is looking for experts to connect with.');
    buffer.writeln('');
    buffer.writeln('Business Details:');
    buffer.writeln('- Type: ${business.businessType}');
    buffer.writeln('- Categories: ${business.categories.join(', ')}');
    buffer.writeln('- Location: ${business.location ?? 'Not specified'}');
    buffer.writeln('- Description: ${business.description ?? 'No description'}');
    buffer.writeln('');
    
    if (preferences != null) {
      buffer.writeln('EXPERT PREFERENCES (CRITICAL - Use these to filter and rank matches):');
      
      if (preferences.requiredExpertiseCategories.isNotEmpty) {
        buffer.writeln('- REQUIRED Expertise: ${preferences.requiredExpertiseCategories.join(', ')}');
      }
      if (preferences.preferredExpertiseCategories.isNotEmpty) {
        buffer.writeln('- PREFERRED Expertise: ${preferences.preferredExpertiseCategories.join(', ')}');
      }
      if (preferences.minExpertLevel != null) {
        buffer.writeln('- Preferred Expertise Level: ${preferences.minExpertLevel} (preference boost, not requirement)');
      }
      if (preferences.preferredLocation != null) {
        buffer.writeln('- Preferred Location: ${preferences.preferredLocation} (preference boost, not requirement)');
      }
      if (preferences.maxDistanceKm != null) {
        buffer.writeln('- Maximum Distance: ${preferences.maxDistanceKm}km');
      }
      if (preferences.preferredAgeRange != null) {
        buffer.writeln('- Preferred Age Range: ${preferences.preferredAgeRange!.displayText}');
      }
      if (preferences.preferredPersonalityTraits?.isNotEmpty == true) {
        buffer.writeln('- Preferred Personality: ${preferences.preferredPersonalityTraits!.join(', ')}');
      }
      if (preferences.preferredWorkStyles?.isNotEmpty == true) {
        buffer.writeln('- Preferred Work Styles: ${preferences.preferredWorkStyles!.join(', ')}');
      }
      if (preferences.preferredCommunicationStyles?.isNotEmpty == true) {
        buffer.writeln('- Preferred Communication: ${preferences.preferredCommunicationStyles!.join(', ')}');
      }
      if (preferences.preferredAvailability?.isNotEmpty == true) {
        buffer.writeln('- Preferred Availability: ${preferences.preferredAvailability!.join(', ')}');
      }
      if (preferences.preferredEngagementTypes?.isNotEmpty == true) {
        buffer.writeln('- Preferred Engagement: ${preferences.preferredEngagementTypes!.join(', ')}');
      }
      if (preferences.aiKeywords?.isNotEmpty == true) {
        buffer.writeln('- AI Keywords: ${preferences.aiKeywords!.join(', ')}');
      }
      if (preferences.aiMatchingPrompt != null) {
        buffer.writeln('- Custom Matching Criteria: ${preferences.aiMatchingPrompt}');
      }
      if (preferences.excludedExpertise?.isNotEmpty == true) {
        buffer.writeln('- EXCLUDE Expertise: ${preferences.excludedExpertise!.join(', ')}');
      }
      if (preferences.excludedLocations?.isNotEmpty == true) {
        buffer.writeln('- EXCLUDE Locations: ${preferences.excludedLocations!.join(', ')}');
      }
      buffer.writeln('');
    } else {
      buffer.writeln('Required Expertise: ${business.requiredExpertise.join(', ')}');
      buffer.writeln('');
    }
    
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('MATCHING PRIORITY (CRITICAL - Follow this order exactly):');
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('1. VIBE/PERSONALITY COMPATIBILITY (PRIMARY - 50% weight)');
    buffer.writeln('   ⚠️ THIS IS THE MOST IMPORTANT FACTOR - VIBE MATCH IS PRIMARY');
    buffer.writeln('   - Personality compatibility (do they align in values and style?)');
    buffer.writeln('   - Value alignment (authentic vs. commercial focus)');
    buffer.writeln('   - Quality focus (attention to detail, craftsmanship)');
    buffer.writeln('   - Community orientation (building connections vs. transactions)');
    buffer.writeln('   - Event style preferences (intimate vs. large, casual vs. formal)');
    buffer.writeln('   - Authenticity vs. commercial focus');
    buffer.writeln('   - VIBE fit for event/product/idea/community is PRIMARY');
    buffer.writeln('');
    buffer.writeln('2. Expertise Match (30% weight)');
    buffer.writeln('   - Category expertise (required expertise categories)');
    buffer.writeln('   - Quality of contributions (thoughtful, balanced feedback)');
    buffer.writeln('   - Community recognition (respected by community)');
    buffer.writeln('   - Event/product/idea fit (relevant experience)');
    buffer.writeln('');
    buffer.writeln('3. Geographic Fit (20% weight - PREFERENCE BOOST, NOT REQUIREMENT)');
    buffer.writeln('   ⚠️ LOCATION IS A FACTOR, NOT A BLOCKER');
    buffer.writeln('   - Local experts in locality = boost (but not required)');
    buffer.writeln('   - Remote experts with great vibe/expertise = INCLUDED');
    buffer.writeln('   - Geographic level (local/city/state/national) = LOWEST PRIORITY');
    buffer.writeln('   - Do NOT exclude experts based on location or level');
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('CRITICAL RULES (MUST FOLLOW):');
    buffer.writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('❌ DO NOT exclude local experts just because they are local');
    buffer.writeln('❌ DO NOT exclude experts based on geographic level');
    buffer.writeln('❌ DO NOT exclude remote experts if they have great vibe/expertise');
    buffer.writeln('');
    buffer.writeln('✅ DO include experts from different regions if vibe/expertise match');
    buffer.writeln('✅ DO prioritize vibe compatibility over geographic level');
    buffer.writeln('✅ DO suggest best match for event/product/idea/community/VIBE');
    buffer.writeln('✅ DO remember: VIBE MATCH IS PRIMARY - geographic level is lowest priority');
    buffer.writeln('');
    buffer.writeln('Based on this information, suggest:');
    buffer.writeln('1. What expertise categories would be most valuable for this business?');
    buffer.writeln('2. What communities should this business connect with?');
    buffer.writeln('3. What specific expert profiles would be ideal matches (prioritize VIBE)?');
    buffer.writeln('');
    buffer.writeln('Provide specific, actionable suggestions for expert matching, prioritizing VIBE compatibility.');
    
    return buffer.toString();
  }

  /// Parse AI response into structured suggestions
  List<AISuggestion> _parseAISuggestions(String aiResponse) {
    final suggestions = <AISuggestion>[];

    // Simple parsing - in production, use structured output or JSON parsing
    // For now, extract categories and communities mentioned
    final lines = aiResponse.split('\n');
    
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Look for category mentions
      final commonCategories = ['coffee', 'restaurant', 'food', 'bar', 'cafe', 'retail', 'service'];
      for (final category in commonCategories) {
        if (lowerLine.contains(category)) {
          suggestions.add(AISuggestion(
            category: category,
            reason: 'AI identified $category as relevant',
          ));
        }
      }
    }

    return suggestions;
  }

  /// Calculate match score for community-based matches
  /// 
  /// **Vibe-First Matching Formula:**
  /// - 50% vibe compatibility (PRIMARY factor)
  /// - 30% expertise match
  /// - 20% location match (preference boost, not filter)
  /// 
  /// **Philosophy:**
  /// - Vibe compatibility is the most important factor
  /// - Expertise ensures required skills are present
  /// - Location is a preference boost only (remote experts still included)
  /// 
  /// **Returns:** Match score (0.0 to 1.0)
  Future<double> _calculateCommunityMatchScore(
    UnifiedUser expert,
    BusinessAccount business,
    ExpertiseCommunity community,
    List<String> matchedCategories,
  ) async {
    // Calculate vibe compatibility (PRIMARY - 50% weight)
    double vibeCompatibility = await _calculateVibeCompatibility(expert, business);
    
    // Calculate expertise match (30% weight)
    double expertiseMatch = _calculateExpertiseMatchScore(expert, matchedCategories);
    
    // Calculate location match (20% weight - preference boost, not filter)
    double locationMatch = _calculateLocationMatchScore(expert, business);
    
    // Vibe-first matching formula: 50% vibe + 30% expertise + 20% location
    double score = (vibeCompatibility * 0.5) + (expertiseMatch * 0.3) + (locationMatch * 0.2);
    
    // Small boost for community membership
    score += 0.05;
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Calculate vibe compatibility between expert and business
  /// 
  /// **This is the PRIMARY factor in matching (50% weight)**
  /// 
  /// Uses PartnershipService.calculateVibeCompatibility() to determine
  /// personality fit between expert and business.
  /// 
  /// **Returns:** Vibe compatibility score (0.0 to 1.0)
  /// - 0.7+ is considered high compatibility (but not required)
  /// - Lower compatibility matches are still included (just ranked lower)
  Future<double> _calculateVibeCompatibility(
    UnifiedUser expert,
    BusinessAccount business,
  ) async {
    try {
      if (_partnershipService != null) {
        // Use PartnershipService to calculate vibe compatibility
        return await _partnershipService!.calculateVibeCompatibility(
          userId: expert.id,
          businessId: business.id,
        );
      }
      
      // Fallback: Return moderate compatibility if service not available
      // In production, this should always use the vibe service
      return 0.7;
    } catch (e) {
      _logger.warning('Error calculating vibe compatibility, using fallback', tag: _logName);
      return 0.7;
    }
  }
  
  /// Calculate expertise match score (30% weight)
  double _calculateExpertiseMatchScore(
    UnifiedUser expert,
    List<String> matchedCategories,
  ) {
    if (matchedCategories.isEmpty) return 0.0;
    
    // Base score from number of matched categories
    double score = (matchedCategories.length / 5.0).clamp(0.0, 1.0);
    
    // Boost for higher expertise levels
    double levelBoost = 0.0;
    for (final category in matchedCategories) {
      final level = expert.getExpertiseLevel(category);
      if (level != null) {
        // Higher levels get more boost
        levelBoost += (level.index + 1) / ExpertiseLevel.values.length;
      }
    }
    score += (levelBoost / matchedCategories.length) * 0.3;
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Calculate location match score (20% weight - preference boost, not filter)
  /// 
  /// **CRITICAL: Location is NOT a filter - all experts are included regardless of location**
  /// 
  /// **Scoring:**
  /// - Location match (expert in preferred location): 1.0 (full boost)
  /// - Remote experts: 0.3 (partial score, still included)
  /// - No location preference: 0.5 (neutral score)
  /// 
  /// **Philosophy:**
  /// - Remote experts with great vibe/expertise are included
  /// - Local experts in locality get boost, but not required
  /// - Location matching doesn't exclude any experts
  double _calculateLocationMatchScore(
    UnifiedUser expert,
    BusinessAccount business,
  ) {
    if (business.preferredLocation == null || expert.location == null) {
      return 0.5; // Neutral score if no location preference
    }
    
    // Location match = boost, not requirement
    if (expert.location!.toLowerCase().contains(
          business.preferredLocation!.toLowerCase(),
        )) {
      return 1.0; // Full boost for location match
    }
    
    // Remote experts still get some score (not filtered out)
    return 0.3; // Partial score for remote experts
  }

  /// Apply preference filters to matches
  /// 
  /// **CRITICAL: This method does NOT filter by level or location**
  /// - Level-based filtering is REMOVED (all experts with required expertise included)
  /// - Location-based filtering is REMOVED (remote experts included)
  /// 
  /// **What IS filtered:**
  /// - Excluded expertise categories (if specified)
  /// - Excluded locations (if specified)
  /// - Age range (if specified and available)
  /// 
  /// **What is NOT filtered:**
  /// - Expertise level (level is preference boost only)
  /// - Location/distance (location is preference boost only)
  /// - Geographic level (local/city/state/national)
  List<BusinessExpertMatch> _applyPreferenceFilters(
    List<BusinessExpertMatch> matches,
    BusinessAccount business,
    BusinessExpertPreferences? preferences,
  ) {
    if (preferences == null) return matches;
    
    return matches.where((match) {
      final expert = match.expert;
      
      // Check excluded expertise
      if (preferences.excludedExpertise?.isNotEmpty == true) {
        final hasExcludedExpertise = preferences.excludedExpertise!.any(
          (cat) => expert.hasExpertiseIn(cat),
        );
        if (hasExcludedExpertise) return false;
      }
      
      // Check excluded locations
      if (preferences.excludedLocations?.isNotEmpty == true && expert.location != null) {
        final isExcludedLocation = preferences.excludedLocations!.any(
          (loc) => expert.location!.toLowerCase().contains(loc.toLowerCase()),
        );
        if (isExcludedLocation) return false;
      }
      
      // Check age range if specified
      // Note: Age data would need to be available in UnifiedUser model
      // For now, we'll skip this check
      
      // Location distance is a preference boost, not a filter
      // Remote experts with great vibe/expertise should be included
      // Distance will be used for scoring boost, not filtering
      if (preferences.maxDistanceKm != null && 
          preferences.preferredLocation != null &&
          expert.location != null) {
        // In production, calculate actual distance for scoring boost
        // For now, location matching is handled in scoring, not filtering
        // All experts are included regardless of distance
      }
      
      return true;
    }).toList();
  }

  /// Rank and deduplicate matches (with preferences)
  List<BusinessExpertMatch> _rankAndDeduplicate(
    List<BusinessExpertMatch> matches,
    BusinessAccount business,
    BusinessExpertPreferences? preferences,
  ) {
    // Group by expert ID
    final Map<String, BusinessExpertMatch> uniqueMatches = {};

    for (final match in matches) {
      final expertId = match.expert.id;
      
      if (uniqueMatches.containsKey(expertId)) {
        // Combine match scores and reasons
        final existing = uniqueMatches[expertId]!;
        final combinedScore = (existing.matchScore + match.matchScore) / 2;
        final combinedReason = '${existing.matchReason}; ${match.matchReason}';
        final combinedCategories = {...existing.matchedCategories, ...match.matchedCategories}.toList();
        final combinedCommunities = {...existing.matchedCommunities, ...match.matchedCommunities}.toList();
        
        // Apply preference-based score adjustments
        final adjustedScore = _applyPreferenceScoring(
          combinedScore,
          match.expert,
          business,
          preferences,
        );
        
        uniqueMatches[expertId] = BusinessExpertMatch(
          expert: match.expert,
          business: match.business,
          matchScore: adjustedScore,
          matchReason: combinedReason,
          matchType: _combineMatchTypes(existing.matchType, match.matchType),
          matchedCategories: combinedCategories,
          matchedCommunities: combinedCommunities,
        );
      } else {
        // Apply preference-based score adjustments to new match
        final adjustedScore = _applyPreferenceScoring(
          match.matchScore,
          match.expert,
          business,
          preferences,
        );
        uniqueMatches[expertId] = BusinessExpertMatch(
          expert: match.expert,
          business: match.business,
          matchScore: adjustedScore,
          matchReason: match.matchReason,
          matchType: match.matchType,
          matchedCategories: match.matchedCategories,
          matchedCommunities: match.matchedCommunities,
        );
      }
    }

    // Sort by match score
    final ranked = uniqueMatches.values.toList();
    ranked.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return ranked;
  }

  MatchType _combineMatchTypes(MatchType type1, MatchType type2) {
    // Prefer AI suggestions, then community, then expertise
    if (type1 == MatchType.aiSuggestion || type2 == MatchType.aiSuggestion) {
      return MatchType.aiSuggestion;
    }
    if (type1 == MatchType.community || type2 == MatchType.community) {
      return MatchType.community;
    }
    return MatchType.expertise;
  }

  /// Apply preference-based scoring adjustments
  /// 
  /// **Note:** Vibe-first matching (50% vibe, 30% expertise, 20% location) is already
  /// applied in _calculateCommunityMatchScore(). This method adds additional preference boosts.
  /// 
  /// **Preference Boosts (not filters):**
  /// - Preferred expertise categories: +0.1 per match
  /// - Preferred location match: +0.1 boost
  /// - Preferred expert level: +0.05 boost (preference, not requirement)
  /// 
  /// **Philosophy:**
  /// - All experts are included regardless of preferences
  /// - Preferences provide scoring boosts to rank matches
  /// - Level and location are preference boosts, not filters
  double _applyPreferenceScoring(
    double baseScore,
    UnifiedUser expert,
    BusinessAccount business,
    BusinessExpertPreferences? preferences,
  ) {
    if (preferences == null) return baseScore;
    
    double adjustedScore = baseScore;
    
    // Boost for preferred expertise categories (expertise is 30% of base score)
    if (preferences.preferredExpertiseCategories.isNotEmpty) {
      final preferredMatches = preferences.preferredExpertiseCategories
          .where((cat) => expert.hasExpertiseIn(cat))
          .length;
      if (preferredMatches > 0) {
        adjustedScore += (preferredMatches / preferences.preferredExpertiseCategories.length) * 0.1;
      }
    }
    
    // Boost for preferred location match (location is 20% of base score, this is additional boost)
    if (preferences.preferredLocation != null && expert.location != null) {
      if (expert.location!.toLowerCase().contains(
            preferences.preferredLocation!.toLowerCase(),
          )) {
        adjustedScore += 0.1; // Additional boost for location match
      }
      // Note: Remote experts are NOT filtered out - they just get lower location score
      // The base score already includes location (20% weight), so this is just an extra boost
    }
    
    // Boost for preferred expert level (preference, not requirement)
    if (preferences.preferredExpertLevel != null) {
      final hasPreferredLevel = preferences.requiredExpertiseCategories.any((cat) {
        final level = expert.getExpertiseLevel(cat);
        return level != null && level.index == preferences.preferredExpertLevel!;
      });
      if (hasPreferredLevel) {
        adjustedScore += 0.05; // Small boost for preferred level
      }
    }
    
    // Boost for community leaders if preferred
    if (preferences.preferCommunityLeaders) {
      // Check if expert is a community leader (would need additional data)
      // For now, skip this boost
    }
    
    return adjustedScore.clamp(0.0, 1.0);
  }
}

/// Business Expert Match Result
class BusinessExpertMatch {
  final UnifiedUser expert;
  final BusinessAccount business;
  final double matchScore; // 0.0 to 1.0
  final String matchReason;
  final MatchType matchType;
  final List<String> matchedCategories;
  final List<String> matchedCommunities;

  const BusinessExpertMatch({
    required this.expert,
    required this.business,
    required this.matchScore,
    required this.matchReason,
    required this.matchType,
    required this.matchedCategories,
    required this.matchedCommunities,
  });
}

/// Match Type
enum MatchType {
  expertise,      // Matched by expertise category
  community,       // Matched by community membership
  aiSuggestion,    // Suggested by AI
}

/// AI Suggestion
class AISuggestion {
  final String? category;
  final String? communityId;
  final String reason;

  const AISuggestion({
    this.category,
    this.communityId,
    required this.reason,
  });
}

