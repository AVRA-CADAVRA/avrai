import 'package:flutter/material.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';

class AIChatBar extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onSendMessage;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;

  const AIChatBar({
    super.key,
    this.hintText,
    this.initialValue,
    this.onSendMessage,
    this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  State<AIChatBar> createState() => _AIChatBarState();
}

class _AIChatBarState extends State<AIChatBar> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(message);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          });
        },
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled && !widget.isLoading,
                onTap: widget.onTap,
                onSubmitted: (_) => _handleSendMessage(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: widget.hintText ??
                      'Ask AI about spots, recommendations...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.smart_toy,
                    color: _hasFocus ? AppTheme.primaryColor : AppColors.grey600,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
                    ? _handleSendMessage
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
