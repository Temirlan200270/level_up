import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_up/src/core/system_visuals_extension.dart';
import 'package:level_up/src/core/widgets/world_surface_panel.dart';

void main() {
  testWidgets('WorldSurfacePanel оборачивает содержимое (digital)', (
    tester,
  ) async {
    const visuals = SystemVisuals(
      backgroundKind: SystemBackgroundKind.grid,
      backgroundAssetPath: '',
      particlesKind: SystemParticlesKind.none,
      panelRadius: 12,
      panelBorderWidth: 1,
      panelBlur: 0,
      titleLetterSpacing: 2.2,
      surfaceKind: SystemSurfaceKind.digital,
      glowIntensity: 0.35,
      borderRadiusScale: 1.0,
      shadowProfile: SystemShadowProfile.soft,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          extensions: const <ThemeExtension<dynamic>>[visuals],
        ),
        home: const Scaffold(
          body: WorldSurfacePanel(
            visuals: visuals,
            child: Center(child: Text('inner')),
          ),
        ),
      ),
    );

    expect(find.text('inner'), findsOneWidget);
  });
}
