import 'package:flutter/material.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';

class UniversalAISearch extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final Function(String)? onCommand;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;

  const UniversalAISearch({
    super.key,
    this.hintText,
    this.initialValue,
    this.onCommand,
    this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  State<UniversalAISearch> createState() => _UniversalAISearchState();
}

class _UniversalAISearchState extends State<UniversalAISearch> {
  late TextEditingController _controller;
  bool _hasFocus = false;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _updateSuggestions('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final command = _controller.text.trim();
    if (command.isNotEmpty && widget.onCommand != null) {
      widget.onCommand!(command);
      _controller.clear();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _updateSuggestions(String query) {
    final suggestions = [
      'Create a new list called "Coffee Shops"',
      'Add Central Park to my "Outdoor Spots" list',
      'Find restaurants near me',
      'Show me events this weekend',
      'Find users who like hiking',
      'Help me discover new places',
      'Create a list for date night spots',
      'Add this location to my favorites',
      'Show me trending spots',
      'Find coffee shops with good wifi',
      'Create a weekend adventure list',
      'Find users in my area',
      'Show me upcoming events',
      'Help me plan a trip',
      'Find quiet study spots',
    ];

    if (query.isEmpty) {
      _suggestions = suggestions.take(5).toList();
    } else {
      _suggestions = suggestions
          .where((suggestion) =>
              suggestion.toLowerCase().contains(query.toLowerCase()))
          .take(3)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.grey100
                : AppColors.grey800,
            borderRadius: BorderRadius.circular(25),
            border: _hasFocus
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : Border.all(color: AppColors.grey300, width: 1),
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _hasFocus = hasFocus;
                if (hasFocus) {
                  _showSuggestions = true;
                }
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled && !widget.isLoading,
                    onChanged: (value) {
                      _updateSuggestions(value);
                      setState(() {
                        _showSuggestions = true;
                      });
                    },
                    onSubmitted: (_) => _handleSubmit(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.hintText ??
                          'Ask me anything... (create lists, find spots, etc.)',
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.auto_awesome,
                        color: _hasFocus
                            ? AppTheme.primaryColor
                            : AppColors.grey600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (widget.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _controller.text.trim().isNotEmpty
                          ? AppTheme.primaryColor
                          : AppColors.grey400,
                    ),
                    onPressed: _controller.text.trim().isNotEmpty
                        ? _handleSubmit
                        : null,
                  ),
              ],
            ),
          ),
        ),
        // Suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.white
                  : AppColors.grey900,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getSuggestionIcon(suggestion),
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    suggestion,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    _controller.text = suggestion;
                    _handleSubmit();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getSuggestionIcon(String suggestion) {
    if (suggestion.contains('list')) return Icons.list;
    if (suggestion.contains('add')) return Icons.add_location;
    if (suggestion.contains('find') || suggestion.contains('restaurant'))
      return Icons.search;
    if (suggestion.contains('event')) return Icons.event;
    if (suggestion.contains('user')) return Icons.people;
    if (suggestion.contains('help') || suggestion.contains('discover'))
      return Icons.auto_awesome;
    if (suggestion.contains('trip') || suggestion.contains('adventure'))
      return Icons.explore;
    if (suggestion.contains('coffee') || suggestion.contains('wifi'))
      return Icons.coffee;
    if (suggestion.contains('study')) return Icons.school;
    return Icons.auto_awesome;
  }
}
