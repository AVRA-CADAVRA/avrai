// Knot Distribution Tab
// 
// Admin tab for viewing knot distributions
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/admin/knot_admin_service.dart';
import 'package:avrai_knot/models/knot/knot_distribution_data.dart';
import 'package:avrai/presentation/widgets/admin/knot_type_distribution_chart.dart';
import 'package:avrai/presentation/widgets/admin/knot_complexity_distribution_chart.dart';

/// Tab for viewing knot distributions
class KnotDistributionTab extends StatefulWidget {
  const KnotDistributionTab({super.key});

  @override
  State<KnotDistributionTab> createState() => _KnotDistributionTabState();
}

class _KnotDistributionTabState extends State<KnotDistributionTab> {
  final _knotAdminService = GetIt.instance<KnotAdminService>();
  KnotDistributionData? _distributionData;
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedLocation;
  String? _selectedCategory;
  DateTime? _selectedTimeRange;

  @override
  void initState() {
    super.initState();
    _loadDistributionData();
  }

  Future<void> _loadDistributionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _knotAdminService.getKnotDistributionData(
        location: _selectedLocation,
        category: _selectedCategory,
        timeRange: _selectedTimeRange,
      );

      setState(() {
        _distributionData = data;
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
        // Filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Locations')),
                    DropdownMenuItem(value: 'Brooklyn', child: Text('Brooklyn')),
                    DropdownMenuItem(value: 'Manhattan', child: Text('Manhattan')),
                    // Add more locations as needed
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                    _loadDistributionData();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Categories')),
                    DropdownMenuItem(value: 'coffee', child: Text('Coffee')),
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    // Add more categories as needed
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    _loadDistributionData();
                  },
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text('Error: $_errorMessage'))
                  : _distributionData == null
                      ? const Center(child: Text('No distribution data available'))
                      : _buildDistributionContent(),
        ),
      ],
    );
  }

  Widget _buildDistributionContent() {
    final data = _distributionData!;

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
                Text('Total Knots: ${data.totalKnots}'),
                Text('Calculated At: ${data.calculatedAt}'),
                if (data.location != null) Text('Location: ${data.location}'),
                if (data.category != null) Text('Category: ${data.category}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Knot Type Distribution
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Knot Type Distribution',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (data.knotTypeDistribution.isEmpty)
                  const Text('No knot type data available')
                else
                  KnotTypeDistributionChart(
                    distribution: data.knotTypeDistribution,
                    size: 200.0,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Crossing Number Distribution
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crossing Number Distribution',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (data.crossingNumberDistribution.isEmpty)
                  const Text('No crossing number data available')
                else
                  KnotCrossingNumberChart(
                    distribution: data.crossingNumberDistribution,
                    height: 200.0,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Writhe Distribution
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Writhe Distribution',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (data.writheDistribution.isEmpty)
                  const Text('No writhe data available')
                else
                  KnotWritheChart(
                    distribution: data.writheDistribution,
                    height: 200.0,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
