import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:geolocator/geolocator.dart';

class EditSpotPage extends StatefulWidget {
  final Spot spot;

  const EditSpotPage({super.key, required this.spot});

  @override
  State<EditSpotPage> createState() => _EditSpotPageState();
}

class _EditSpotPageState extends State<EditSpotPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late String _selectedCategory;
  late double _latitude;
  late double _longitude;
  late List<String> _tags;
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _hasChanges = false;

  final List<String> _categories = [
    'Restaurant',
    'Cafe',
    'Bar',
    'Shop',
    'Park',
    'Museum',
    'Theater',
    'Hotel',
    'Landmark',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.spot.name);
    _descriptionController = TextEditingController(text: widget.spot.description);
    _addressController = TextEditingController(text: widget.spot.address ?? '');
    _selectedCategory = widget.spot.category;
    _latitude = widget.spot.latitude;
    _longitude = widget.spot.longitude;
    _tags = List.from(widget.spot.tags);

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable location services.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _hasChanges = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedSpot = widget.spot.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        category: _selectedCategory,
        latitude: _latitude,
        longitude: _longitude,
        tags: _tags,
        updatedAt: DateTime.now(),
      );

      context.read<SpotsBloc>().add(UpdateSpot(updatedSpot));

      Navigator.pop(context, updatedSpot);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spot updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spot'),
        content: Text(
          'Are you sure you want to delete "${widget.spot.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SpotsBloc>().add(DeleteSpot(widget.spot.id));
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous page
              Navigator.pop(context); // Go back to spots list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.spot.name} deleted'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Spot'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text('Delete Spot', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Spot Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Spot name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                                _hasChanges = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Latitude: ${_latitude.toStringAsFixed(6)}'),
                                  Text('Longitude: ${_longitude.toStringAsFixed(6)}'),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(_isLoadingLocation ? 'Updating...' : 'Update'),
                            ),
                          ],
                        ),
                        if (_locationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _locationError!,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final shouldDiscard = await _onWillPop();
                          if (!mounted) return;
                          if (!shouldDiscard) return;
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        // Use global ElevatedButtonTheme
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}