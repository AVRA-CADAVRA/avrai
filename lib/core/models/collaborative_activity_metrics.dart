/// Collaborative Activity Metrics Model
/// 
/// Privacy-safe aggregate metrics for collaborative list creation during AI2AI conversations.
/// Per COLLABORATIVE_ACTIVITY_ANALYTICS_SPEC.md - all data is anonymized aggregates only.
/// 
/// Philosophy Alignment:
/// - Opens doors to understanding collaboration patterns
/// - Privacy-preserving (aggregate data only, no user content)
/// - Enables data-driven feature optimization
class CollaborativeActivityMetrics {
  // List creation counts
  final int totalCollaborativeLists;
  final int groupChatLists; // 3+ participants
  final int dmLists; // 2 participants
  final double avgListSize; // Average spots per list
  final double avgCollaboratorCount; // Average collaborators per list
  
  // Activity context
  final Map<int, int> groupSizeDistribution; // {2: 823, 3: 298, 4: 95, 5+: 31}
  final double collaborationRate; // % of conversations with outcomes
  final int totalPlanningSessions; // Conversations with planning keywords
  
  // Engagement patterns
  final double avgSessionDuration; // Average planning session length (minutes)
  final double followThroughRate; // % lists with spots actually added
  final Map<int, int> activityByHour; // {7: 45, 8: 67, ...} - hour distribution
  
  // Temporal data
  final DateTime collectionStart;
  final DateTime lastUpdated;
  final Duration measurementWindow;
  
  // Privacy metadata
  final int totalUsersContributing; // Count only, no IDs
  final bool containsUserData; // Always false
  final bool isAnonymized; // Always true

  CollaborativeActivityMetrics({
    required this.totalCollaborativeLists,
    required this.groupChatLists,
    required this.dmLists,
    required this.avgListSize,
    required this.avgCollaboratorCount,
    required this.groupSizeDistribution,
    required this.collaborationRate,
    required this.totalPlanningSessions,
    required this.avgSessionDuration,
    required this.followThroughRate,
    required this.activityByHour,
    required this.collectionStart,
    required this.lastUpdated,
    required this.measurementWindow,
    required this.totalUsersContributing,
    this.containsUserData = false,
    this.isAnonymized = true,
  });

  /// Create empty metrics for when no data is available
  factory CollaborativeActivityMetrics.empty() {
    final now = DateTime.now();
    return CollaborativeActivityMetrics(
      totalCollaborativeLists: 0,
      groupChatLists: 0,
      dmLists: 0,
      avgListSize: 0.0,
      avgCollaboratorCount: 0.0,
      groupSizeDistribution: {},
      collaborationRate: 0.0,
      totalPlanningSessions: 0,
      avgSessionDuration: 0.0,
      followThroughRate: 0.0,
      activityByHour: {},
      collectionStart: now,
      lastUpdated: now,
      measurementWindow: const Duration(days: 30),
      totalUsersContributing: 0,
      containsUserData: false,
      isAnonymized: true,
    );
  }

  /// Get group chat percentage
  double get groupChatPercentage {
    if (totalCollaborativeLists == 0) return 0.0;
    return (groupChatLists / totalCollaborativeLists) * 100;
  }

  /// Get DM percentage
  double get dmPercentage {
    if (totalCollaborativeLists == 0) return 0.0;
    return (dmLists / totalCollaborativeLists) * 100;
  }

  /// Get collaboration rate as percentage
  double get collaborationRatePercentage => collaborationRate * 100;

  /// Get follow-through rate as percentage
  double get followThroughRatePercentage => followThroughRate * 100;
}

