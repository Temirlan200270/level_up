import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Неоновая «консоль» ввода: быстрый квест без формы (Enter / кнопка отправки).
class MasterCommandBar extends StatelessWidget {
  const MasterCommandBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.sendTooltip,
    required this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String sendTooltip;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.12),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: TextField(
            controller: controller,
            style: GoogleFonts.manrope(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.manrope(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                tooltip: sendTooltip,
                icon: Icon(
                  Icons.send_rounded,
                  color: primary.withValues(alpha: 0.9),
                ),
                onPressed: () => onSubmitted(controller.text),
              ),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
