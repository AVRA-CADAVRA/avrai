// Knot Pattern Analysis Tab
// 
// Admin tab for analyzing knot patterns
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/admin/knot_admin_service.dart';
import 'package:avrai_knot/models/knot/knot_pattern_analysis.dart';
import 'package:avrai/presentation/widgets/admin/knot_pattern_heatmap.dart';

/// Tab for analyzing knot patterns
class KnotPatternAnalysisTab extends StatefulWidget {
  const KnotPatternAnalysisTab({super.key});

  @override
  State<KnotPatternAnalysisTab> createState() =>
      _KnotPatternAnalysisTabState();
}

class _KnotPatternAnalysisTabState extends State<KnotPatternAnalysisTab> {
  final _knotAdminService = GetIt.instance<KnotAdminService>();
  KnotPatternAnalysis? _patternAnalysis;
  bool _isLoading = false;
  String? _errorMessage;
  AnalysisType _selectedAnalysisType = AnalysisType.weavingPatterns;

  @override
  void initState() {
    super.initState();
    _loadPatternAnalysis();
  }

  Future<void> _loadPatternAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analysis = await _knotAdminService.getKnotPatternAnalysis(
        type: _selectedAnalysisType,
      );

      setState(() {
        _patternAnalysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Analysis Type Selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<AnalysisType>(
            initialValue: _selectedAnalysisType,
            decoration: const InputDecoration(
              labelText: 'Analysis Type',
              border: OutlineInputBorder(),
            ),
            items: AnalysisType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getAnalysisTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedAnalysisType = value;
                });
                _loadPatternAnalysis();
              }
            },
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text('Error: $_errorMessage'))
                  : _patternAnalysis == null
                      ? const Center(child: Text('No pattern analysis available'))
                      : _buildPatternAnalysisContent(),
        ),
      ],
    );
  }

  Widget _buildPatternAnalysisContent() {
    final analysis = _patternAnalysis!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Total Patterns: ${analysis.statistics.totalPatterns}'),
                Text(
                  'Average Strength: ${analysis.statistics.averageStrength.toStringAsFixed(2)}',
                ),
                Text(
                  'Diversity: ${analysis.statistics.diversity.toStringAsFixed(2)}',
                ),
                if (analysis.statistics.mostCommonPattern != null)
                  Text(
                    'Most Common: ${analysis.statistics.mostCommonPattern}',
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Pattern Heatmap
        if (analysis.patterns.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: KnotPatternHeatmap(
                patterns: analysis.patterns,
                cellSize: 40.0,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Patterns
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pattern Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (analysis.patterns.isEmpty)
                  const Text('No patterns found')
                else
                  ...analysis.patterns.map((pattern) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pattern.description,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Strength: ${pattern.strength.toStringAsFixed(2)}',
                            ),
                            if (pattern.metrics.isNotEmpty)
                              ...pattern.metrics.entries.map((entry) => Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Text('${entry.key}: ${entry.value}'),
                                  )),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getAnalysisTypeLabel(AnalysisType type) {
    switch (type) {
      case AnalysisType.weavingPatterns:
        return 'Weaving Patterns';
      case AnalysisType.compatibilityPatterns:
        return 'Compatibility Patterns';
      case AnalysisType.evolutionPatterns:
        return 'Evolution Patterns';
      case AnalysisType.communityFormation:
        return 'Community Formation';
    }
  }
}
