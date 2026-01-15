import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/public_profile_analysis_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;

/// Public Handles Page
///
/// Allows users to optionally provide public social media handles
/// for profile analysis (with explicit consent).
///
/// **Privacy:** All analysis is opt-in and user-controlled.
class PublicHandlesPage extends StatefulWidget {
  const PublicHandlesPage({super.key});

  @override
  State<PublicHandlesPage> createState() => _PublicHandlesPageState();
}

class _PublicHandlesPageState extends State<PublicHandlesPage> {
  final PublicProfileAnalysisService _analysisService =
      di.sl<PublicProfileAnalysisService>();
  final AgentIdService _agentIdService = di.sl<AgentIdService>();

  final Map<String, TextEditingController> _controllers = {};
  bool _consentGiven = false;
  bool _isLoading = false;
  bool _hasStoredHandles = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadStoredHandles();
  }

  void _initializeControllers() {
    _controllers['instagram'] = TextEditingController();
    _controllers['tiktok'] = TextEditingController();
    _controllers['twitter'] = TextEditingController();
  }

  Future<void> _loadStoredHandles() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      final handles = await _analysisService.getStoredHandles(agentId);
      final hasConsent = await _analysisService.hasConsent(agentId);

      if (mounted) {
        setState(() {
          _hasStoredHandles = handles.isNotEmpty;
          _consentGiven = hasConsent;
          handles.forEach((platform, handle) {
            if (_controllers.containsKey(platform)) {
              _controllers[platform]!.text = handle;
            }
          });
        });
      }
    } catch (e) {
      // Ignore errors when loading
    }
  }

  Future<void> _saveHandles() async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide consent to analyze public profiles'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);
      if (!mounted) return;

      // Collect handles (only non-empty)
      final handles = <String, String>{};
      _controllers.forEach((platform, controller) {
        final handle = controller.text.trim();
        if (handle.isNotEmpty) {
          handles[platform] = handle;
        }
      });

      if (handles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide at least one handle'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final success = await _analysisService.storeHandlesWithConsent(
        agentId: agentId,
        handles: handles,
        consentGiven: _consentGiven,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasStoredHandles = success;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Handles saved and analysis started!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save handles'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _revokeConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Consent?'),
        content: const Text(
          'This will delete all stored handles and analysis results. You can add handles again later if you change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      final success = await _analysisService.revokeConsent(agentId);

      if (mounted) {
        setState(() {
          _consentGiven = false;
          _hasStoredHandles = false;
          _controllers.forEach((_, controller) => controller.clear());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Consent revoked' : 'Failed to revoke consent'),
            backgroundColor: success ? Colors.orange : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    Color color;
    switch (platform.toLowerCase()) {
      case 'instagram':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case 'tiktok':
        icon = Icons.music_note;
        color = Colors.black;
        break;
      case 'twitter':
        icon = Icons.chat_bubble_outline;
        color = Colors.lightBlue;
        break;
      default:
        icon = Icons.link;
        color = AppTheme.primaryColor;
    }
    return Icon(icon, color: color);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Profile Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Public Profile Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optionally provide your public social media handles to enhance your AI personality. We\'ll analyze your public posts and interests (with your explicit consent).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 24),

            // Consent Section
            Card(
              color: _consentGiven
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _consentGiven,
                          onChanged: (value) {
                            setState(() {
                              _consentGiven = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I consent to public profile analysis',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'I understand that avrai will analyze my public posts, interests, and content to enhance my AI personality. I can revoke this consent at any time.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.grey700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Handles Input Section
            Text(
              'Social Media Handles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your public handles (without @ symbol)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 16),

            // Instagram Handle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getPlatformIcon('instagram'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers['instagram'],
                            decoration: const InputDecoration(
                              labelText: 'Instagram Username',
                              hintText: 'username',
                              border: OutlineInputBorder(),
                            ),
                            enabled: _consentGiven,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TikTok Handle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getPlatformIcon('tiktok'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers['tiktok'],
                            decoration: const InputDecoration(
                              labelText: 'TikTok Username',
                              hintText: 'username',
                              border: OutlineInputBorder(),
                            ),
                            enabled: _consentGiven,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Twitter Handle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getPlatformIcon('twitter'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers['twitter'],
                            decoration: const InputDecoration(
                              labelText: 'Twitter/X Username',
                              hintText: 'username',
                              border: OutlineInputBorder(),
                            ),
                            enabled: _consentGiven,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_consentGiven ? null : _saveHandles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Handles & Start Analysis'),
              ),
            ),

            // Revoke Consent Button (if handles are stored)
            if (_hasStoredHandles) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _revokeConsent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Revoke Consent & Delete Handles'),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Privacy Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy & Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• We only analyze public content (posts, bio, interests)\n'
                    '• Analysis results are stored locally on your device\n'
                    '• You can revoke consent and delete data anytime\n'
                    '• We never share your handles or analysis with third parties\n'
                    '• Analysis enhances your AI personality insights',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
