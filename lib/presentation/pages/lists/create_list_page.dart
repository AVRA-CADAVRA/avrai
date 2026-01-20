import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/controllers/list_creation_controller.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';

class CreateListPage extends StatefulWidget {
  const CreateListPage({super.key});

  @override
  State<CreateListPage> createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isPublic = true;
  bool _isCreating = false;
  String? _error;

  late ListCreationController _listCreationController;

  final List<String> _categories = [
    'General',
    'Food & Dining',
    'Entertainment',
    'Shopping',
    'Outdoors',
    'Travel',
    'Work',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    _listCreationController = GetIt.instance<ListCreationController>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    if (!_formKey.currentState!.validate() || _isCreating) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      // Get current user from AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        setState(() {
          _error = 'Please sign in to create lists';
          _isCreating = false;
        });
        return;
      }

      final authUser = authState.user;
      final unifiedUser = UnifiedUser(
        id: authUser.id,
        email: authUser.email,
        displayName: authUser.displayName ?? authUser.name,
        createdAt: authUser.createdAt,
        updatedAt: authUser.updatedAt,
        isOnline: authUser.isOnline ?? false,
      );

      // Prepare form data
      final data = ListFormData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        isPublic: _isPublic,
        curator: unifiedUser,
      );

      // Create list via controller
      final result = await _listCreationController.createList(
        data: data,
        curator: unifiedUser,
      );

      if (!result.success) {
        setState(() {
          _error = result.error ?? 'Failed to create list';
          _isCreating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Show warning if present (partial success)
      if (result.warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.warning!),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }

      // Refresh lists via BLoC
      if (mounted) {
        context.read<ListsBloc>().add(LoadLists());
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('List "${result.list?.title ?? ''}" created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create List'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createList,
              child: const Text(
                'Create',
                style: TextStyle(color: AppColors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'List Title',
                  hintText: 'Enter a title for your list',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this list is about',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
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
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Privacy Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Public List'),
                  subtitle: const Text('Make this list visible to others'),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About Lists',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lists help you organize your spots into meaningful collections. You can add spots to your lists later.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
