import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/theme_controller.dart';
import 'choice_tiles.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<ThemeController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) => AppChoiceTiles<ThemeMode>(
        selected: mode,
        onSelected: controller.select,
        options: [
          AppChoiceTileOption(
            value: ThemeMode.light,
            icon: LucideIcons.sun,
            label: 'theme.light'.tr(),
          ),
          AppChoiceTileOption(
            value: ThemeMode.dark,
            icon: LucideIcons.moon,
            label: 'theme.dark'.tr(),
          ),
          AppChoiceTileOption(
            value: ThemeMode.system,
            icon: LucideIcons.smartphone,
            label: 'theme.system'.tr(),
          ),
        ],
      ),
    );
  }
}
