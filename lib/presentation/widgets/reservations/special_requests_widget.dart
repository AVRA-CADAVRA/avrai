// Special Requests Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Widget for entering special requests

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Special Requests Widget
///
/// **Purpose:** Allow users to enter special requests for reservations
///
/// **Features:**
/// - Multi-line text input
/// - Character limit (optional)
/// - Common requests suggestions (optional)
/// - Validation
class SpecialRequestsWidget extends StatefulWidget {
  final String? initialValue;
  final int? maxLength;
  final Function(String?) onChanged;
  final List<String>? suggestions;

  const SpecialRequestsWidget({
    super.key,
    this.initialValue,
    this.maxLength,
    required this.onChanged,
    this.suggestions,
  });

  @override
  State<SpecialRequestsWidget> createState() => _SpecialRequestsWidgetState();
}

class _SpecialRequestsWidgetState extends State<SpecialRequestsWidget> {
  late final TextEditingController _controller;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _characterCount = _controller.text.length;
    _controller.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCharacterCount);
    _controller.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxLen = widget.maxLength ?? 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Special Requests (Optional)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.note, color: AppTheme.primaryColor),
            helperText: widget.maxLength != null
                ? '$_characterCount/$maxLen characters'
                : 'Any special accommodations or requests',
            suffixIcon: _characterCount > 0
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged(null);
                    },
                  )
                : null,
          ),
          maxLines: 5,
          maxLength: widget.maxLength,
          onChanged: (value) {
            widget.onChanged(value.isEmpty ? null : value);
          },
        ),
        if (widget.suggestions != null && widget.suggestions!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.suggestions!.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  final currentText = _controller.text;
                  final newText = currentText.isEmpty
                      ? suggestion
                      : '$currentText, $suggestion';
                  _controller.text = newText;
                  widget.onChanged(newText);
                },
                backgroundColor: AppColors.grey100,
                labelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
