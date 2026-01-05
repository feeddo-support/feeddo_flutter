import 'package:flutter/material.dart';
import '../../theme/feeddo_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final bool isSending;
  final String hintText;
  final bool withShadow;
  final FeeddoTheme? theme;
  final FocusNode? focusNode;

  const ChatInputArea({
    Key? key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.isSending = false,
    this.hintText = 'Type a message...',
    this.withShadow = false,
    this.theme,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentTheme = theme ?? FeeddoTheme.light();

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: currentTheme.colors.surface,
        border: Border(top: BorderSide(color: currentTheme.colors.border)),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: currentTheme.colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: currentTheme.colors.border),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file,
                        color: currentTheme.colors.iconColor, size: 18),
                    onPressed: onAttachment,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle:
                            TextStyle(color: currentTheme.colors.textSecondary),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: TextStyle(color: currentTheme.colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: currentTheme.colors.primary,
              shape: BoxShape.circle,
            ),
            child: isSending
                ? Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          currentTheme.colors.surface),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.arrow_upward,
                        color: currentTheme.colors.surface, size: 16),
                    onPressed: onSend,
                  ),
          ),
        ],
      ),
    );
  }
}
