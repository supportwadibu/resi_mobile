import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_typography.dart';
import 'resi_tokens.dart';

/// Thèmes clair et sombre, construits sur [ResiTokens].
///
/// Le `ColorScheme` est posé à la main, jamais dérivé d'une graine : Material
/// inventerait des teintes intermédiaires (conteneurs lavande, surfaces
/// teintées) qui n'existent pas dans le backoffice. Chaque thème de composant
/// est déclaré ici une fois, à angles droits, si bien qu'un widget Material
/// laissé tel quel dans un écran prend déjà l'allure commune.
abstract final class AppTheme {
  static ThemeData light() => _build(ResiTokens.light, Brightness.light);

  static ThemeData dark() => _build(ResiTokens.dark, Brightness.dark);

  /// Angles droits partout : bordures, boutons, champs, cartes, feuilles.
  static const _square = RoundedRectangleBorder();

  static ThemeData _build(ResiTokens t, Brightness brightness) {
    final text = AppTypography.textTheme(t);
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.primaryForeground,
      primaryContainer: t.background,
      onPrimaryContainer: t.foreground,
      secondary: t.primary,
      onSecondary: t.primaryForeground,
      secondaryContainer: t.background,
      onSecondaryContainer: t.foreground,
      tertiary: t.accentViolet,
      onTertiary: t.surface,
      error: t.danger,
      onError: t.surface,
      errorContainer: t.dangerSurface,
      onErrorContainer: t.danger,
      surface: t.surface,
      onSurface: t.foreground,
      onSurfaceVariant: t.muted,
      surfaceContainerLowest: t.surface,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surface,
      surfaceContainerHighest: t.background,
      outline: t.border,
      outlineVariant: t.border,
      inverseSurface: t.foreground,
      onInverseSurface: t.background,
      inversePrimary: t.primaryForeground,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
    );

    final borderSide = BorderSide(color: t.border);
    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color, width: width),
        );

    const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const buttonMinSize = Size(0, 44);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [t],
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.surface,
      dividerColor: t.border,
      disabledColor: t.muted,
      hintColor: t.muted,
      splashFactory: InkRipple.splashFactory,
      splashColor: t.foreground.withValues(alpha: 0.06),
      highlightColor: t.foreground.withValues(alpha: 0.04),
      hoverColor: t.background,
      focusColor: t.foreground.withValues(alpha: 0.08),
      iconTheme: IconThemeData(color: t.foreground, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: t.surface,
        foregroundColor: t.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 56,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: t.foreground, size: 20),
        actionsIconTheme: IconThemeData(color: t.foreground, size: 20),
        shape: Border(bottom: borderSide),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.primaryForeground,
          disabledBackgroundColor: t.primary.withValues(alpha: 0.4),
          disabledForegroundColor: t.primaryForeground,
          shape: _square,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.primaryForeground,
          disabledBackgroundColor: t.primary.withValues(alpha: 0.4),
          disabledForegroundColor: t.primaryForeground,
          shape: _square,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: text.labelLarge,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: t.surface,
          foregroundColor: t.foreground,
          side: borderSide,
          shape: _square,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.foreground,
          shape: _square,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.foreground,
          shape: _square,
          iconSize: 20,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: t.primaryForeground,
        shape: _square,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        extendedTextStyle: text.labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_square),
          side: WidgetStatePropertyAll(borderSide),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? t.primary : t.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? t.primaryForeground
                : t.foreground,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? t.primaryForeground
                : t.muted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        hintStyle: text.bodyMedium!.copyWith(color: t.muted),
        labelStyle: text.bodyMedium!.copyWith(color: t.muted),
        floatingLabelStyle: text.bodyMedium!.copyWith(color: t.foreground),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall!.copyWith(color: t.danger),
        prefixIconColor: t.muted,
        suffixIconColor: t.muted,
        border: field(t.border),
        enabledBorder: field(t.border),
        focusedBorder: field(t.primary),
        errorBorder: field(t.danger),
        focusedErrorBorder: field(t.danger),
        disabledBorder: field(t.border.withValues(alpha: 0.6)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.foreground,
        selectionColor: t.foreground.withValues(alpha: 0.2),
        selectionHandleColor: t.foreground,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(side: borderSide),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: t.muted,
        textColor: t.foreground,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: _square,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minLeadingWidth: 20,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: _square,
        collapsedShape: _square,
        iconColor: t.muted,
        collapsedIconColor: t.muted,
        textColor: t.foreground,
        collapsedTextColor: t.foreground,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(side: borderSide),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium!.copyWith(color: t.muted),
        barrierColor: Colors.black.withValues(alpha: 0.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        modalBackgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        modalElevation: 2,
        shape: const RoundedRectangleBorder(),
        showDragHandle: true,
        dragHandleColor: t.border,
        dragHandleSize: const Size(32, 4),
        modalBarrierColor: Colors.black.withValues(alpha: 0.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.foreground,
        contentTextStyle: text.bodyMedium!.copyWith(color: t.background),
        actionTextColor: t.background,
        shape: _square,
        elevation: 2,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: t.foreground),
        textStyle: text.bodySmall!.copyWith(color: t.background),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(side: borderSide),
        textStyle: text.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(text.bodyMedium),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(side: borderSide)),
          elevation: const WidgetStatePropertyAll(2),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(side: borderSide)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.primary,
        disabledColor: t.background,
        checkmarkColor: t.primaryForeground,
        side: borderSide,
        shape: _square,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium!.copyWith(
          color: t.primaryForeground,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        showCheckmark: false,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: t.danger,
        textColor: t.surface,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: _square,
        side: BorderSide(color: t.muted, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(t.primaryForeground),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : t.muted,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.primaryForeground
              : t.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : t.background,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : t.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.primary,
        inactiveTrackColor: t.border,
        thumbColor: t.primary,
        overlayColor: t.foreground.withValues(alpha: 0.08),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.foreground,
        linearTrackColor: t.border,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
        borderRadius: BorderRadius.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: t.background,
        indicatorShape: RoundedRectangleBorder(side: borderSide),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium!.copyWith(
            color: s.contains(WidgetState.selected) ? t.foreground : t.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 20,
            color: s.contains(WidgetState.selected) ? t.foreground : t.muted,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.foreground,
        unselectedLabelColor: t.muted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: t.foreground,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: t.border,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: t.foreground, width: 2),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(side: borderSide),
        headerBackgroundColor: t.surface,
        headerForegroundColor: t.foreground,
        dividerColor: t.border,
        dayShape: const WidgetStatePropertyAll(_square),
        dayForegroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) {
            return t.muted.withValues(alpha: 0.5);
          }
          if (s.contains(WidgetState.selected)) return t.primaryForeground;
          return t.foreground;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : null,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.primaryForeground
              : t.foreground,
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : null,
        ),
        todayBorder: BorderSide(color: t.foreground),
        yearShape: const WidgetStatePropertyAll(_square),
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.primaryForeground
              : t.foreground,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : null,
        ),
        rangeSelectionBackgroundColor: t.background,
        rangePickerBackgroundColor: t.surface,
        rangePickerSurfaceTintColor: Colors.transparent,
        rangePickerShape: const RoundedRectangleBorder(),
        rangePickerHeaderBackgroundColor: t.surface,
        rangePickerHeaderForegroundColor: t.foreground,
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: t.foreground),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: t.muted),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(side: borderSide),
        hourMinuteShape: _square,
        dayPeriodShape: _square,
        dayPeriodBorderSide: borderSide,
        hourMinuteColor: t.background,
        hourMinuteTextColor: t.foreground,
        dialBackgroundColor: t.background,
        dialHandColor: t.primary,
        dialTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.primaryForeground
              : t.foreground,
        ),
        entryModeIconColor: t.muted,
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(t.background),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(side: borderSide)),
        textStyle: WidgetStatePropertyAll(text.bodyMedium),
        hintStyle: WidgetStatePropertyAll(
          text.bodyMedium!.copyWith(color: t.muted),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
