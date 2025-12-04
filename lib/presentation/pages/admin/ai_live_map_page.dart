import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:intl/intl.dart';

/// AI Live Map Page
/// Shows all active AI agents on a live map with their location, data, and predictions
class AILiveMapPage extends StatefulWidget {
  final AdminGodModeService? godModeService;
  
  const AILiveMapPage({
    super.key,
    this.godModeService,
  });

  @override
  State<AILiveMapPage> createState() => _AILiveMapPageState();
}

class _AILiveMapPageState extends State<AILiveMapPage> {
  List<ActiveAIAgentData> _activeAgents = [];
  bool _isLoading = true;
  gmap.GoogleMapController? _mapController;
  ActiveAIAgentData? _selectedAgent;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveAgents();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadActiveAgents());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadActiveAgents() async {
    if (widget.godModeService == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final agents = await widget.godModeService!.getAllActiveAIAgents();
      setState(() {
        _activeAgents = agents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading AI agents: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Set<gmap.Marker> _buildMarkers() {
    return _activeAgents.map((agent) {
      return gmap.Marker(
        markerId: gmap.MarkerId(agent.userId),
        position: gmap.LatLng(agent.latitude, agent.longitude),
        icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
          agent.isOnline
              ? gmap.BitmapDescriptor.hueGreen
              : gmap.BitmapDescriptor.hueOrange,
        ),
        infoWindow: gmap.InfoWindow(
          title: 'AI Agent: ${agent.aiSignature.substring(0, 12)}...',
          snippet: 'Status: ${agent.aiStatus} • Connections: ${agent.aiConnections}',
        ),
        onTap: () {
          setState(() {
            _selectedAgent = agent;
          });
        },
      );
    }).toSet();
  }

  gmap.LatLng _getMapCenter() {
    if (_activeAgents.isEmpty) {
      return const gmap.LatLng(37.7749, -122.4194); // Default: San Francisco
    }
    
    // Calculate center of all agents
    double sumLat = 0;
    double sumLng = 0;
    for (final agent in _activeAgents) {
      sumLat += agent.latitude;
      sumLng += agent.longitude;
    }
    
    return gmap.LatLng(
      sumLat / _activeAgents.length,
      sumLng / _activeAgents.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : gmap.GoogleMap(
                  initialCameraPosition: gmap.CameraPosition(
                    target: _getMapCenter(),
                    zoom: 10,
                  ),
                  markers: _buildMarkers(),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
          
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Agents Live Map',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_activeAgents.length} active agents',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadActiveAgents,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
          ),
          
          // Selected Agent Info Panel
          if (_selectedAgent != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedAgent = null;
                          });
                        },
                      ),
                    ),
                    
                    // Agent Info
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildAgentInfo(_selectedAgent!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgentInfo(ActiveAIAgentData agent) {
    final topAction = agent.topPredictedAction;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: agent.isOnline
                  ? AppColors.electricGreen.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              child: Icon(
                Icons.smart_toy,
                color: agent.isOnline ? AppColors.electricGreen : AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Agent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    agent.aiSignature,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(agent.isOnline ? 'Online' : 'Offline'),
              backgroundColor: agent.isOnline
                  ? AppColors.electricGreen.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Location
        _buildInfoRow('Location', '${agent.latitude.toStringAsFixed(4)}, ${agent.longitude.toStringAsFixed(4)}'),
        _buildInfoRow('Last Active', DateFormat('MMM d, y • h:mm a').format(agent.lastActive)),
        
        const Divider(),
        
        // AI Data
        Text(
          'AI Data',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Status', agent.aiStatus),
        _buildInfoRow('Connections', '${agent.aiConnections}'),
        _buildInfoRow('Current Stage', agent.currentStage),
        if (agent.confidence > 0)
          _buildInfoRow('Prediction Confidence', '${(agent.confidence * 100).toStringAsFixed(1)}%'),
        
        const Divider(),
        
        // Predictions
        Text(
          'Predicted Next Actions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (agent.predictedActions.isEmpty)
          Text(
            'No predictions available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500
                ),
          )
        else
          ...agent.predictedActions.take(5).map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.action,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          action.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500
                              ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text('${(action.probability * 100).toStringAsFixed(0)}%'),
                    backgroundColor: AppColors.electricGreen.withValues(alpha: 0.2),
                  ),
                ],
              ),
            );
          }),
        
        if (topAction != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.electricGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Most Likely Next Action',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        topAction.action,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Privacy Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.privacy_tip, color: AppColors.electricGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Privacy: Only AI-related data and location (vibe indicators) are shown. No personal information (name, email, phone, home address) is displayed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

