import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.padding,
    this.fontSize = 15,
    this.elevation = 0,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final bool isLoading;
  final AppButtonIcon? leadingIcon;
  final AppButtonIcon? trailingIcon;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final BorderRadiusGeometry? borderRadius;
  final double elevation;

  Color get _defaultBackgroundColor {
    if (backgroundColor != null) return backgroundColor!;
    return variant == AppButtonVariant.primary
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color(0xFF1A1A2E);
  }

  Color get _defaultForegroundColor {
    if (foregroundColor != null) return foregroundColor!;
    return Colors.white;
  }

  Color get _defaultDisabledBackgroundColor {
    if (disabledBackgroundColor != null) return disabledBackgroundColor!;
    return Colors.grey.shade300;
  }

  EdgeInsetsGeometry get _defaultPadding {
    if (padding != null) return padding!;
    return variant == AppButtonVariant.primary
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  }

  BorderRadiusGeometry get _defaultBorderRadius {
    if (borderRadius != null) return borderRadius!;
    return switch (variant) {
      AppButtonVariant.primary => BorderRadius.circular(40),
      AppButtonVariant.secondary => BorderRadius.circular(8),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _defaultBackgroundColor,
          foregroundColor: _defaultForegroundColor,
          disabledBackgroundColor: _defaultDisabledBackgroundColor,
          elevation: elevation,
          padding: _defaultPadding,
          shape: RoundedRectangleBorder(borderRadius: _defaultBorderRadius),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    final hasLeadingIcon = leadingIcon != null;
    final hasTrailingIcon = trailingIcon != null;

    if (!hasLeadingIcon && !hasTrailingIcon) {
      return Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasLeadingIcon) ...[leadingIcon!.build(), const SizedBox(width: 8)],
        Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
        if (hasTrailingIcon) ...[
          const SizedBox(width: 8),
          trailingIcon!.build(),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────
// AppButtonIcon — wrapper qui supporte
// Material Icons, FontAwesome, et Widget custom
// ─────────────────────────────────────────
class AppButtonIcon {
  const AppButtonIcon._({
    this.materialIcon,
    this.faIcon,
    this.custom,
    this.size = 18,
    this.color,
  });

  // Material Icons
  factory AppButtonIcon.material(
    IconData icon, {
    double size = 18,
    Color? color,
  }) => AppButtonIcon._(materialIcon: icon, size: size, color: color);

  // Font Awesome
  factory AppButtonIcon.fa(FaIconData icon, {double size = 16, Color? color}) =>
      AppButtonIcon._(faIcon: icon, size: size, color: color);

  // Widget custom (SVG, Image, etc.)
  factory AppButtonIcon.widget(Widget widget) =>
      AppButtonIcon._(custom: widget);

  final IconData? materialIcon;
  final FaIconData? faIcon;
  final Widget? custom;
  final double size;
  final Color? color;

  Widget build() {
    if (custom != null) return custom!;
    if (faIcon != null) {
      return FaIcon(faIcon, size: size, color: color);
    }
    if (materialIcon != null) {
      return Icon(materialIcon, size: size, color: color);
    }
    return const SizedBox.shrink();
  }
}
