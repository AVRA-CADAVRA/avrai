import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/widgets/ai2ai/personality_overview_card.dart';
import 'package:spots/presentation/widgets/ai2ai/user_connections_display.dart';
import 'package:spots/presentation/widgets/ai2ai/learning_insights_widget.dart';
import 'package:spots/presentation/widgets/ai2ai/evolution_timeline_widget.dart';
import 'package:spots/presentation/widgets/ai2ai/privacy_controls_widget.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:spots/core/services/storage_service.dart' show SharedPreferences;
import 'package:get_it/get_it.dart';
import 'package:spots/core/ai/personality_learning.dart';

/// User-facing AI Personality Status Page
/// Shows user's AI personality overview, connections, learning insights, evolution timeline, and privacy controls
class AIPersonalityStatusPage extends StatefulWidget {
  const AIPersonalityStatusPage({super.key});

  @override
  State<AIPersonalityStatusPage> createState() => _AIPersonalityStatusPageState();
}

class _AIPersonalityStatusPageState extends State<AIPersonalityStatusPage> {
  PersonalityProfile? _personalityProfile;
  ActiveConnectionsOverview? _connectionsOverview;
  List<SharedInsight>? _recentInsights;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalityData();
  }

  Future<void> _loadPersonalityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userId = authState.user.id;

        // Get personality profile - try to load from PersonalityLearning, otherwise create initial
        // Note: PersonalityLearning expects SharedPreferencesCompat (via typedef), so we use GetIt
        final sharedPrefsCompat = GetIt.instance<SharedPreferences>();
        final personalityLearning = PersonalityLearning.withPrefs(sharedPrefsCompat);
        
        // Try to get existing personality profile
        // Note: PersonalityLearning doesn't expose a direct getter, so we'll create initial for now
        // In a real implementation, you'd load from storage or get from a service
        _personalityProfile = PersonalityProfile.initial(userId);

        // Get connections overview - ConnectionMonitor expects real SharedPreferences
        final realSharedPrefs = await real_prefs.SharedPreferences.getInstance();
        final connectionMonitor = ConnectionMonitor(prefs: realSharedPrefs);
        _connectionsOverview = await connectionMonitor.getActiveConnectionsOverview();

        // Get recent learning insights - AI2AIChatAnalyzer expects real SharedPreferences
        final ai2aiLearning = AI2AIChatAnalyzer(
          prefs: realSharedPrefs,
          personalityLearning: personalityLearning,
        );
        // Note: Would need to get actual chat history to generate insights
        _recentInsights = [];
      }
    } catch (e) {
      debugPrint('Error loading personality data: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadPersonalityData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Personality Status'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Personality Overview
                    if (_personalityProfile != null)
                      PersonalityOverviewCard(profile: _personalityProfile!),

                    const SizedBox(height: 24),

                    // Connections Display
                    if (_connectionsOverview != null)
                      UserConnectionsDisplay(overview: _connectionsOverview!),

                    const SizedBox(height: 24),

                    // Learning Insights
                    LearningInsightsWidget(insights: _recentInsights ?? []),

                    const SizedBox(height: 24),

                    // Evolution Timeline
                    if (_personalityProfile != null)
                      EvolutionTimelineWidget(profile: _personalityProfile!),

                    const SizedBox(height: 24),

                    // Privacy Controls
                    const PrivacyControlsWidget(),
                  ],
                ),
              ),
            ),
    );
  }
}

