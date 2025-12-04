import 'package:flutter/material.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';

class CustomSearchBar extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showClearButton;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.showClearButton = true,
    this.controller,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search',
      hint: widget.hintText ?? 'Search...',
      textField: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppColors.grey100
              : AppColors.grey800,
          borderRadius: BorderRadius.circular(12),
          border: _hasFocus
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : Border.all(color: AppColors.grey300, width: 1),
        ),
        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _hasFocus = hasFocus;
            });
          },
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Search...',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _hasFocus ? AppTheme.primaryColor : AppColors.grey600,
              ),
              suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
                  ? Semantics(
                      label: 'Clear search',
                      button: true,
                      child: IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.grey600,
                        ),
                        onPressed: () {
                          _controller.clear();
                          if (widget.onChanged != null) {
                            widget.onChanged!('');
                          }
                        },
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
