import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 18),
    this.maxLines,
    this.onDone,
  });

  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final int? maxLines;
  final VoidCallback? onDone;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.charDelay, (t) {
      if (!mounted) return;
      if (_n >= widget.text.length) {
        t.cancel();
        widget.onDone?.call();
        return;
      }
      setState(() => _n++);
    });
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _n = 0;
      _timer = Timer.periodic(widget.charDelay, (t) {
        if (!mounted) return;
        if (_n >= widget.text.length) {
          t.cancel();
          widget.onDone?.call();
          return;
        }
        setState(() => _n++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        GoogleFonts.manrope(
          color: SoloLevelingColors.textSecondary,
          height: 1.45,
          fontSize: 14,
        );
    return Text(
      widget.text.substring(0, _n.clamp(0, widget.text.length)),
      style: style,
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}

