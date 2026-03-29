import 'package:flutter/material.dart';

import '../system_visuals_extension.dart';

/// Внутренние акценты «материала мира» для карточек и панелей (Фаза 7.6).
///
/// Digital: вертикальная неоновая полоска слева.
/// Glass: мягкий верхний блик.
/// Parchment: тонкая «сепия»-линия сверху.
class WorldMaterialChrome extends StatelessWidget {
  const WorldMaterialChrome({
    super.key,
    required this.visuals,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final SystemVisuals visuals;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inner = Padding(padding: padding, child: child);

    switch (visuals.surfaceKind) {
      case SystemSurfaceKind.digital:
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.95),
                      scheme.secondary.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: inner,
            ),
          ],
        );
      case SystemSurfaceKind.glass:
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              height: 22,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.onSurface.withValues(alpha: 0.11),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            inner,
          ],
        );
      case SystemSurfaceKind.parchment:
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 5,
              left: 16,
              right: 16,
              height: 1.5,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0),
                        scheme.primary.withValues(alpha: 0.42),
                        scheme.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            inner,
          ],
        );
    }
  }
}
