import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

@RoutePage()
class SuccessScreen extends StatefulWidget {
  const SuccessScreen({
    super.key,
    this.title,
    this.subtitle,
    this.buttonText,
    this.secondaryButtonText,
    this.autoRedirectDuration = 5,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  /// Textes par défaut : ceux du dépôt d'un bien, traduits à l'affichage.
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final String? secondaryButtonText;
  final int autoRedirectDuration;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  /// Une seule entrée, fondu et léger glissement, sans rebond : l'écran
  /// confirme une action, il n'a pas à la célébrer.
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(_fade);

  /// Le décompte et le bouton mènent à la même sortie : sans ce garde, les
  /// deux pourraient se déclencher et dépiler deux écrans.
  bool _hasLeft = false;

  /// Quitte l'écran, une seule fois.
  void _leave() {
    if (_hasLeft || !mounted) return;
    _hasLeft = true;

    final action = widget.onPrimaryAction;
    if (action != null) {
      action();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Sortie par l'action secondaire, soumise au même garde.
  void _leaveSecondary() {
    if (_hasLeft || !mounted) return;
    _hasLeft = true;

    final action = widget.onSecondaryAction;
    if (action != null) {
      action();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: t.glowGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: _Confirmation(
                            title: widget.title ?? 'success.title'.tr(),
                            subtitle:
                                widget.subtitle ?? 'success.subtitle'.tr(),
                            entrance: _fade,
                          ),
                        ),
                      ),
                    ),
                    // Le décompte en jauge : on voit le temps qui reste avant
                    // le retour automatique, sans avoir à lire le chiffre.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 0),
                      duration: Duration(seconds: widget.autoRedirectDuration),
                      onEnd: _leave,
                      builder: (context, value, _) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.pill,
                            child: SizedBox(
                              height: 6,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(color: t.border),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: value,
                                    child: ColoredBox(color: t.foreground),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'success.redirect'.tr(
                              args: [
                                '${(value * widget.autoRedirectDuration).ceil()}',
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: widget.buttonText ?? 'success.button'.tr(),
                      trailingIcon: LucideIcons.arrowRight,
                      expand: true,
                      onPressed: _leave,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label:
                          widget.secondaryButtonText ??
                          'success.secondary'.tr(),
                      icon: LucideIcons.plus,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: _leaveSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte de confirmation des maquettes : lavande, halo discret, coche sur
/// disque blanc qui apparaît en grossissant, titre en grand.
class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.title,
    required this.subtitle,
    required this.entrance,
  });

  final String title;
  final String subtitle;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.lavender,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: HaloSurface(
        radius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: entrance,
                  curve: Curves.easeOutBack,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.onOverlay,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 72,
                    child: Icon(
                      LucideIcons.check,
                      size: 34,
                      color: t.onLavender,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: context.text.displaySmall!.copyWith(
                  fontSize: 30,
                  color: t.onLavender,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: context.text.bodyMedium!.copyWith(
                  color: t.onLavender.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
