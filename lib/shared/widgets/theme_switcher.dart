import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/theme_controller.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<ThemeController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(LucideIcons.sun, size: 16),
              label: Text('Clair'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(LucideIcons.moon, size: 16),
              label: Text('Sombre'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(LucideIcons.monitor, size: 16),
              label: Text('Système'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => controller.select(selection.first),
        ),
      ),
    );
  }
}
